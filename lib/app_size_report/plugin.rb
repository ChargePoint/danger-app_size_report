#require 'ReporterConverter.rb'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Rishab Sukumar/danger-app_size_report
  # @tags monday, weekends, time, rattata
  #
  require 'json'
  require_relative '../converter/parser/ReportParser'
  require_relative '../converter/helper/MemorySize'

  class DangerAppSizeReport < Plugin

    # A method that you can call from your Dangerfile
    # @return   [Array<String>]
    #
    def flag_violations (report_path, build_type: "App", size_limit: 4, limit_unit: "GB", fail_on_warning: false)
      report_text = File.read(report_path)
      variants = ReportParser.parse(report_text)

      unless(["App", "Clip"].include? build_type)
        raise ArgumentError.new("The 'build_type' argument only accepts the values \"App\" and \"Clip\"")
      end

      unless(size_limit.is_a? Numeric)
        raise ArgumentError.new("The 'size_limit' argument only accepts numeric values")
      end

      limit_unit.upcase!
      unless(["KB", "MB", "GB"].include? limit_unit)
        raise ArgumentError.new("The 'build_type' argument only accepts the values \"KB\", \"MB\" and \"GB\"")
      end

      unless([true, false].include? fail_on_warning)
        raise ArgumentError.new("The 'fail_on_warning' argument only accepts the values 'true' and 'false'")
      end

      generate_size_report_markdown(variants, build_type, size_limit, limit_unit, fail_on_warning)
      generate_variant_descriptors_markdown(variants)
      generate_ads_label_markdown

    end

    def report_json (report_path)
      report_text = File.read(report_path)
      variants = ReportParser.parse(report_text)
      report_json_data = JSON.pretty_generate(variants)

      return report_json_data
    end

    private

    def generate_size_report_markdown (variants, build_type, size_limit, limit_unit, fail_on_warning)
      limit_size = MemorySize.new("#{size_limit}#{limit_unit}")
      
      if build_type == "Clip" && limit_size.megabytes > 10
        message "The size limit was set to 10 MB as the given limit of #{size_limit} #{limit_unit} exceeds Apple's App Clip size restrictions"
        size_limit = 10
        limit_unit = "MB"
        limit_size.kilobytes = 10 * 1024
      elsif build_type == "App" && limit_size.gigabytes > 4
        message "The size limit was set to 4 GB as the given limit of #{size_limit} #{limit_unit} exceeds Apple's App size restrictions"
        size_limit = 4
        limit_unit = "GB"
        limit_size.kilobytes = 4 * 1024 * 1024
      end

      flagged_variant_names = []
      for variant in variants
        if (variant.app_size.uncompressed.value > limit_size.megabytes || variant.on_demand_resources_size.uncompressed.value > limit_size.megabytes)
          flagged_variant_names.append(variant.variant)
        end
      end
      
      if flagged_variant_names.length > 0
        if (fail_on_warning)
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
     
      for variant in variants
        is_violating = flagged_variants_set.include?(variant.variant) ? "❌" : "✅"
        app_size_compressed = "#{variant.app_size.compressed.value} #{variant.app_size.compressed.unit}"
        app_size_uncompressed = "#{variant.app_size.uncompressed.value} #{variant.app_size.uncompressed.unit}" 
        odr_size_compressed = "#{variant.on_demand_resources_size.compressed.value} #{variant.on_demand_resources_size.compressed.unit}"
        odr_size_uncompressed = "#{variant.on_demand_resources_size.uncompressed.value} #{variant.on_demand_resources_size.uncompressed.unit}"

        size_report << "#{is_violating} | #{variant.variant} | #{app_size_compressed} | #{app_size_uncompressed} | #{odr_size_compressed} | #{odr_size_uncompressed} |\n"
      end

      markdown size_report
    end

    def generate_variant_descriptors_markdown (variants)
      variant_descriptors_report = "### Supported Variant Descriptors \n\n"
      for variant in variants
        variant_descriptors_report << "<details> \n"
        variant_descriptors_report << "<summary> #{variant.variant} </summary> \n\n"
        variant_descriptors_report << "| Model | Operating System | \n"
        variant_descriptors_report << "| - | :-: |\n"
        for variant_descriptor in variant.supported_variant_descriptors
          variant_descriptors_report << "#{variant_descriptor.device} | #{variant_descriptor.os_version} | \n"
        end
        variant_descriptors_report << "</details> \n\n"
      end

      markdown variant_descriptors_report
    end

    def generate_ads_label_markdown
      ads_label = "Powered by [danger-app_size_report](https://github.com/ChargePoint)"
      markdown ads_label
    end

  end
end
