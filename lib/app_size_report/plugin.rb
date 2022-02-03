# frozen_string_literal: false

module Danger
  require 'json'
  require_relative '../converter/parser/report_parser'
  require_relative '../converter/helper/memory_size'

  # A Danger plugin for reporting iOS app size violations.
  # A valid App Thinning Size Report must be passed to the plugin
  # for accurate functionality.
  #
  # @example Report app size violations if one or more App variants
  # exceed 4GB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_violations(
  #             report_path,
  #             build_type: 'App',
  #             size_limit: 4,
  #             limit_unit: 'GB',
  #             fail_on_warning: false
  #          )
  #
  # @example Report app size violations if one or more App Clip variants
  # exceed 8MB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_violations(
  #             report_path,
  #             build_type: 'Clip',
  #             size_limit: 8,
  #             limit_unit: 'MB',
  #             fail_on_warning: false
  #          )
  #
  # @example Fail PR if one or more App Clip variants exceed 8MB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_violations(
  #             report_path,
  #             build_type: 'Clip',
  #             size_limit: 8,
  #             limit_unit: 'MB',
  #             fail_on_warning: true
  #          )
  #
  # @example Get JSON string representation of app thinning size report
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_json = app_size_report.report_json(report_path)
  #
  # @see  ChargePoint/danger-app_size_report
  # @tags ios, xcode, appclip, thinning, size
  #
  class DangerAppSizeReport < Plugin
    # Reports app size violations given a valid App Thinning Size Report.
    # @param [String, required] report_path
    #        Path to valid App Thinning Size Report text file.
    # @param [String, optional] build_type
    #        Specify whether the report corresponds to an App or an App Clip.
    #        Default: 'App'
    #        Supported values: 'App', 'Clip'
    # @param [Numeric, optional] size_limit
    #        Specify the app size limit.
    #        Default: 4
    # @param [String, optional] limit_unit
    #        Specific the unit for the given size limit.
    #        Default: 'GB'
    #        Supported values: 'KB', 'MB', 'GB'
    # @param [Boolean, optional] fail_on_warning
    #        Specify whether the PR should fail if one or more app variants
    #        exceed the given size limit. By default, the plugin issues
    #        a warning in this case.
    #        Default: 'false'
    # @return   [void]
    #
    def flag_violations(report_path, build_type: 'App', size_limit: 4, limit_unit: 'GB', fail_on_warning: false)
      report_text = File.read(report_path)
      variants = ReportParser.parse(report_text)

      unless %w[App Clip].include? build_type
        raise ArgumentError, "The 'build_type' argument only accepts the values \"App\" and \"Clip\""
      end

      raise ArgumentError, "The 'size_limit' argument only accepts numeric values" unless size_limit.is_a? Numeric

      limit_unit.upcase!
      unless %w[KB MB GB].include? limit_unit
        raise ArgumentError, "The 'build_type' argument only accepts the values \"KB\", \"MB\" and \"GB\""
      end

      unless [true, false].include? fail_on_warning
        raise ArgumentError, "The 'fail_on_warning' argument only accepts the values 'true' and 'false'"
      end

      generate_size_report_markdown(variants, build_type, size_limit, limit_unit, fail_on_warning)
      generate_variant_descriptors_markdown(variants)
      generate_ads_label_markdown
    end

    # Returns a JSON string representation of the given App Thinning Size Report.
    # @param [String, required] report_path
    #        Path to valid App Thinning Size Report text file.
    # @return   [String]
    #
    def report_json(report_path)
      report_text = File.read(report_path)
      variants = ReportParser.parse(report_text)
      JSON.pretty_generate(variants)
    end

    private

    def generate_size_report_markdown(variants, build_type, size_limit, limit_unit, fail_on_warning)
      limit_size = MemorySize.new("#{size_limit}#{limit_unit}")

      if build_type == 'Clip' && limit_size.megabytes > 10
        message "The size limit was set to 10 MB as the given limit of #{size_limit} #{limit_unit} exceeds Apple's App Clip size restrictions"
        size_limit = 10
        limit_unit = 'MB'
        limit_size.kilobytes = 10 * 1024
      elsif build_type == 'App' && limit_size.gigabytes > 4
        message "The size limit was set to 4 GB as the given limit of #{size_limit} #{limit_unit} exceeds Apple's App size restrictions"
        size_limit = 4
        limit_unit = 'GB'
        limit_size.kilobytes = 4 * 1024 * 1024
      end

      flagged_variant_names = []
      variants.each do |variant|
        if variant.app_size.uncompressed.value > limit_size.megabytes || variant.on_demand_resources_size.uncompressed.value > limit_size.megabytes
          flagged_variant_names.append(variant.variant)
        end
      end

      if flagged_variant_names.length.positive?
        if fail_on_warning
          failure "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by one or more variants"
        else
          warn "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by one or more variants"
        end
      end

      size_report = "# App Thinning Size Report\n"
      size_report << "### Size limit = #{size_limit} #{limit_unit.upcase}\n\n"
      size_report << "| Under Limit | Variant | App Size - Compressed | App Size - Uncompressed | ODR Size - Compressed | ODR Size - Uncompressed |\n"
      size_report << "| :-: | :-: | :-: | :-: | :-: | :-: |\n"

      flagged_variants_set = flagged_variant_names.to_set

      variants.each do |variant|
        is_violating = flagged_variants_set.include?(variant.variant) ? '❌' : '✅'
        app_size_compressed = "#{variant.app_size.compressed.value} #{variant.app_size.compressed.unit}"
        app_size_uncompressed = "#{variant.app_size.uncompressed.value} #{variant.app_size.uncompressed.unit}"
        odr_size_compressed = "#{variant.on_demand_resources_size.compressed.value} #{variant.on_demand_resources_size.compressed.unit}"
        odr_size_uncompressed = "#{variant.on_demand_resources_size.uncompressed.value} #{variant.on_demand_resources_size.uncompressed.unit}"

        size_report << "#{is_violating} | #{variant.variant} | #{app_size_compressed} | #{app_size_uncompressed} | #{odr_size_compressed} | #{odr_size_uncompressed} |\n"
      end

      markdown size_report
    end

    def generate_variant_descriptors_markdown(variants)
      variant_descriptors_report = "### Supported Variant Descriptors \n\n"
      variants.each do |variant|
        variant_descriptors_report << "<details> \n"
        variant_descriptors_report << "<summary> #{variant.variant} </summary> \n\n"
        variant_descriptors_report << "| Model | Operating System | \n"
        variant_descriptors_report << "| - | :-: |\n"
        variant.supported_variant_descriptors.each do |variant_descriptor|
          variant_descriptors_report << "#{variant_descriptor.device} | #{variant_descriptor.os_version} | \n"
        end
        variant_descriptors_report << "</details> \n\n"
      end

      markdown variant_descriptors_report
    end

    def generate_ads_label_markdown
      ads_label = 'Powered by [danger-app_size_report](https://github.com/ChargePoint/danger-app_size_report)'
      markdown ads_label
    end
  end
end
