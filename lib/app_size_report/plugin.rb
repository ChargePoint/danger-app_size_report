# frozen_string_literal: false

module Danger
  require 'json'
  require 'open-uri'
  require 'fileutils'

  require_relative '../converter/parser/report_parser'
  require_relative '../converter/helper/memory_size'
  require_relative '../converter/helper/android_utils'

  $project_root = Dir.pwd
  $temp_path = "#{$project_root}/temp"
  $apks_path = "#{$temp_path}/output.apks"
  $size_csv_path = "#{$temp_path}/output.csv"
  $bundletool_path = "#{$temp_path}/bundletool.jar"
  $bundletool_version = "1.8.2"
  $variants_limit = 30

  $default_screen_densities = ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"]
  $default_languages = ["en"]

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
    # Reports IOS app size violations given a valid App Thinning Size Report.
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


    # Reports Android app size violations given a valid AAB.
    # @param [String, required] aab_path
    #        Path to valid AAB file.
    # @param [String, required] ks_path
    #        Path to valid signing key file.
    # @param [String, required] ks_alias
    #        Alias of signing key
    # @param [String, required] ks_password
    #        Password of signing key
    # @param [Array, optional] screen_densities
    #        Array of screen densities to check APK size 
    #        Default: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"]
    # @param [Array, optional] languages
    #        Array of languages to check APK size 
    #        Default: ["en"]
    # @param [String, optional] build_type
    #        Specify whether the report corresponds to an App, Instant.
    #        Default: 'App'
    #        Supported values: 'App', 'Instant'
    # @param [Numeric, optional] size_limit
    #        Specify the app size limit.
    #        Default: 150
    # @param [String, optional] limit_unit
    #        Specific the unit for the given size limit.
    #        Default: 'MB'
    #        Supported values: 'KB', 'MB', 'GB'
    # @param [Boolean, optional] fail_on_warning
    #        Specify whether the PR should fail if one or more app variants
    #        exceed the given size limit. By default, the plugin issues
    #        a warning in this case.
    #        Default: 'false'
    # @return   [void]
    #

    def flag_android_violations(aab_path, ks_path, ks_alias, ks_password, ks_alias_password, screen_densities: $default_screen_densities, languages: $default_languages, build_type: 'App', size_limit: 150, limit_unit: 'MB', fail_on_warning: false)
      unless %w[App Instant].include? build_type
        raise ArgumentError, "The 'build_type' argument only accepts the values \"App\" and \"Instant\""
      end

      raise ArgumentError, "The 'size_limit' argument only accepts numeric values" unless size_limit.is_a? Numeric

      limit_unit.upcase!
      unless %w[KB MB GB].include? limit_unit
        raise ArgumentError, "The 'limit_unit' argument only accepts the values \"KB\", \"MB\" and \"GB\""
      end

      unless [true, false].include? fail_on_warning
        raise ArgumentError, "The 'fail_on_warning' argument only accepts the values 'true' and 'false'"
      end

      create_temp_dir

      unless AndroidUtils.download_bundletool($bundletool_version, $bundletool_path)
        clean_temp!
        return
      end

      AndroidUtils.generate_apks(aab_path, ks_path, ks_alias, ks_password, ks_alias_password, $apks_path, $bundletool_path) 
      AndroidUtils.generate_estimated_sizes($apks_path, $size_csv_path, $bundletool_path, build_type)
      filtered_sizes = AndroidUtils.filter_estimated_sizes($size_csv_path, screen_densities, languages)
      sorted_sizes = AndroidUtils.sort_estimated_sizes(filtered_sizes)

      clean_temp!

      generate_android_size_report_markdown(sorted_sizes, build_type, size_limit, limit_unit, fail_on_warning, $variants_limit)
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

    def create_temp_dir()
      Dir.mkdir $temp_path
    end

    def clean_temp!()
      FileUtils.rm_rf($temp_path)
    end

    def generate_android_size_report_markdown(sorted_sizes, build_type, size_limit, limit_unit, fail_on_warning, variants_limit)
      limit_size = MemorySize.new("#{size_limit}#{limit_unit}")

      if build_type == 'Instant' && limit_size.megabytes > 4
        message "The size limit was set to 4 MB as the given limit of #{size_limit} #{limit_unit} exceeds Android Instant App size restrictions"
        size_limit = 4
        limit_unit = 'MB'
        limit_size.kilobytes = 4 * 1024
      elsif build_type == 'App' && limit_size.megabytes > 150
        message "The size limit was set to 150 MB as the given limit of #{size_limit} #{limit_unit} exceeds Android App size restrictions"
        size_limit = 150
        limit_unit = 'MB'
        limit_size.kilobytes = 150 * 1024
      end

      violation_count = AndroidUtils.violations_count(sorted_sizes, limit_size.bytes) 
      
      if violation_count>0
        if fail_on_warning
          failure "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by #{violation_count} variants"
        else
          warn "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by #{violation_count} variants"
        end
      end

      size_report = "# Android #{build_type} Size Report\n"
      size_report << "### Size limit = #{size_limit} #{limit_unit.upcase}\n\n"
      size_report << "| Under Limit | SDK | ABI | Screen Density | Language | Size (Bytes) |\n"
      size_report << "| :-: | :-: | :-: | :-: | :-: | :-: |\n"

      if(sorted_sizes.length < variants_limit) 
        variants_limit = sorted_sizes.length
      end

      counter = 0
      while(counter < variants_limit)
        variant = sorted_sizes[counter]
        is_violating = variant.max >= limit_size.bytes ? '❌' : '✅'
        size_report << "#{is_violating} | #{variant.sdk} | #{variant.abi} | #{variant.screen_density} | #{variant.language} | #{variant.max} |\n"
        counter+=1
      end

      markdown size_report
      
    end

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
