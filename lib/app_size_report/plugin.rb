# frozen_string_literal: false

module Danger
  require 'json'
  require 'open-uri'
  require 'fileutils'

  require_relative '../converter/parser/report_parser'
  require_relative '../converter/helper/memory_size'
  require_relative '../converter/helper/android_utils'

  # A Danger plugin for reporting iOS and Android app size violations.
  #
  #
  # A valid App Thinning Size Report must be passed to the plugin
  # for accurate functionality in case of iOS.
  #
  # @example Report iOS app size violations if one or more App variants exceed 4GB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_ios_violations(
  #             report_path,
  #             build_type: 'App',
  #             limit_size: 4,
  #             limit_unit: 'GB',
  #             fail_on_warning: false
  #          )
  #
  # @example Report iOS app size violations if one or more App Clip variants exceed 8MB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_ios_violations(
  #             report_path,
  #             build_type: 'Clip',
  #             limit_size: 8,
  #             limit_unit: 'MB',
  #             fail_on_warning: false
  #          )
  #
  # @example Fail PR if one or more iOS App Clip variants exceed 8MB.
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_report.flag_ios_violations(
  #             report_path,
  #             build_type: 'Clip',
  #             limit_size: 8,
  #             limit_unit: 'MB',
  #             fail_on_warning: true
  #          )
  #
  # @example Get JSON string representation of iOS app thinning size report
  #
  #          report_path = "/Path/to/AppSize/Report.txt"
  #          app_size_json = app_size_report.report_json(report_path)
  #
  # @example Report Android app size violations if one or more App variants
  #
  #          aab_path = "/Path/to/app.aab"
  #          ks_path = "/Path/to/keyStore"
  #          ks_alias = "KeyAlias"
  #          ks_password = "Key Password"
  #          ks_alias_password = "Key Alias Password"
  #          app_size_report.flag_android_violations(
  #             aab_path,
  #             ks_path,
  #             ks_alias,
  #             ks_password,
  #             ks_alias_password,
  #             screen_densities: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"],
  #             languages: ["en", "de", "da", "es", "fr", "it", "nb", "nl", "sv"],
  #             build_type: 'App',
  #             limit_size: 14,
  #             limit_unit: 'MB',
  #             fail_on_warning: false
  #          )
  #
  # @example Report Android Instant app size violations if one or more App variants
  #
  #          aab_path = "/Path/to/app.aab"
  #          ks_path = "/Path/to/keyStore"
  #          ks_alias = "KeyAlias"
  #          ks_password = "Key Password"
  #          ks_alias_password = "Key Alias Password"
  #          app_size_report.flag_android_violations(
  #             aab_path,
  #             ks_path,
  #             ks_alias,
  #             ks_password,
  #             ks_alias_password,
  #             screen_densities: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"],
  #             languages: ["en", "de", "da", "es", "fr", "it", "nb", "nl", "sv"],
  #             build_type: 'Instant',
  #             limit_size: 4,
  #             limit_unit: 'MB',
  #             fail_on_warning: false
  #          )
  #
  # @example Fail PR if one or more Android Instant App variants exceed 4MB.
  #
  #          aab_path = "/Path/to/app.aab"
  #          ks_path = "/Path/to/keyStore"
  #          ks_alias = "KeyAlias"
  #          ks_password = "Key Password"
  #          ks_alias_password = "Key Alias Password"
  #          app_size_report.flag_android_violations(
  #             aab_path,
  #             ks_path,
  #             ks_alias,
  #             ks_password,
  #             ks_alias_password,
  #             screen_densities: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"],
  #             languages: ["en", "de", "da", "es", "fr", "it", "nb", "nl", "sv"],
  #             build_type: 'Instant',
  #             limit_size: 4,
  #             limit_unit: 'MB',
  #             fail_on_warning: true
  #          )
  #
  # @see  ChargePoint/danger-app_size_report
  # @tags ios, xcode, appclip, thinning, size
  #
  class DangerAppSizeReport < Plugin
    # Reports IOS app size violations given a valid App Thinning Size Report.
    # @overload flag_ios_violations(report_path, build_type, limit_size, limit_unit, fail_on_warning)
    #   @param [String, required] report_path
    #         Path to valid App Thinning Size Report text file.
    #   @param [String, optional] build_type
    #         Specify whether the report corresponds to an App or an App Clip.
    #         Default: 'App'
    #         Supported values: 'App', 'Clip'
    #   @param [Numeric, optional] limit_size
    #         Specify the app size limit. If the build type is set to 'Clip' and the
    #         specified app size limit exceeds 10 MB, the 10 MB limit will be enforced
    #         to meet Apple's App Clip size requirements.
    #         Default: 4
    #   @param [String, optional] limit_unit
    #         Specific the unit for the given size limit.
    #         Default: 'GB'
    #         Supported values: 'KB', 'MB', 'GB'
    #   @param [Boolean, optional] fail_on_warning
    #         Specify whether the PR should fail if one or more app variants
    #         exceed the given size limit. By default, the plugin issues
    #         a warning in this case.
    #         Default: 'false'
    # @return   [void]
    #
    def flag_ios_violations(report_path, **kargs)
      supported_kargs = %i[build_type limit_size limit_unit size_limit fail_on_warning]

      # Identify any unsupported arguments passed to method
      unsupported_kargs = kargs.keys - supported_kargs

      raise ArgumentError, "The argument '#{unsupported_kargs[0]}' is not supported by flag_ios_violations" if unsupported_kargs.count == 1

      raise ArgumentError, "The arguments #{unsupported_kargs} are not supported by flag_ios_violations" if unsupported_kargs.count > 1

      # Set up optional arguments with default values if needed
      build_type = kargs[:build_type] || 'App'
      limit_size = kargs[:limit_size] || kargs[:size_limit] || 4
      limit_unit = kargs[:limit_unit] || 'GB'
      fail_on_warning = kargs[:fail_on_warning] || false

      report_text = File.read(report_path)
      variants = ReportParser.parse(report_text)

      raise ArgumentError, "The 'build_type' argument only accepts the values \"App\" and \"Clip\"" unless %w[App Clip].include? build_type

      if kargs[:limit_size]
        raise ArgumentError, "The 'limit_size' argument only accepts numeric values" unless limit_size.is_a? Numeric
      elsif kargs[:size_limit]
        raise ArgumentError, "The 'size_limit' argument only accepts numeric values" unless limit_size.is_a? Numeric
      end

      limit_unit.upcase!
      raise ArgumentError, "The 'build_type' argument only accepts the values \"KB\", \"MB\" and \"GB\"" unless %w[KB MB GB].include? limit_unit

      raise ArgumentError, "The 'fail_on_warning' argument only accepts the values 'true' and 'false'" unless [true, false].include? fail_on_warning

      generate_size_report_markdown(variants, build_type, limit_size, limit_unit, fail_on_warning)
      generate_variant_descriptors_markdown(variants)
      generate_ads_label_markdown
    end

    # Reports Android app size violations given a valid AAB.
    # @overload flag_android_violations(aab_path, ks_path, ks_alias, ks_password, ks_alias_password, screen_densities, languages, build_type, limit_size, size_limit, limit_unit, fail_on_warning)
    #   @param [String, required] aab_path
    #         Path to valid AAB file.
    #   @param [String, required] ks_path
    #         Path to valid signing key file.
    #   @param [String, required] ks_alias
    #         Alias of signing key.
    #   @param [String, required] ks_password
    #         Password of signing key.
    #   @param [String, required] ks_alias_password
    #         Alias Password of signing key.
    #   @param [Array, optional] screen_densities
    #         Array of screen densities to check APK size.
    #         Default: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"]
    #   @param [Array, optional] languages
    #         Array of languages to check APK size.
    #         Default: ["en"]
    #   @param [String, optional] build_type
    #         Specify whether the report corresponds to an App, Instant.
    #         Default: 'App'
    #         Supported values: 'App', 'Instant'
    #   @param [Numeric, optional] limit_size
    #         Specify the app size limit. If the build type is set to 'Instant' and the
    #         specified app size limit exceeds 4 MB, the 4 MB limit will be enforced to
    #         meet Android Instant App size requirements.
    #         Default: 150
    #   @param [String, optional] limit_unit
    #         Specific the unit for the given size limit.
    #         Default: 'MB'
    #         Supported values: 'KB', 'MB', 'GB'
    #   @param [Boolean, optional] fail_on_warning
    #         Specify whether the PR should fail if one or more app variants
    #         exceed the given size limit. By default, the plugin issues
    #         a warning in this case.
    #         Default: 'false'
    # @return   [void]
    #
    def flag_android_violations(aab_path, ks_path, ks_alias, ks_password, ks_alias_password, **kargs)
      project_root = Dir.pwd
      temp_path = "#{project_root}/temp"
      apks_path = "#{temp_path}/output.apks"
      size_csv_path = "#{temp_path}/output.csv"
      bundletool_path = "#{temp_path}/bundletool.jar"
      bundletool_version = '1.8.2'
      variants_limit = 25

      supported_kargs = %i[screen_densities languages build_type limit_size size_limit limit_unit fail_on_warning]
      unsupported_kargs = kargs.keys - supported_kargs

      raise ArgumentError, "The argument #{unsupported_kargs[0]} is not supported by flag_android_violations" if unsupported_kargs.count == 1

      raise ArgumentError, "The arguments #{unsupported_kargs} are not supported by flag_android_violations" if unsupported_kargs.count > 1

      # Set up optional arguments with default values if needed
      screen_densities = kargs[:screen_densities] || %w[MDPI HDPI XHDPI XXHDPI XXXHDPI]
      languages = kargs[:languages] || ['en']
      build_type = kargs[:build_type] || 'App'
      limit_size = kargs[:limit_size] || kargs[:size_limit] || 150
      limit_unit = kargs[:limit_unit] || 'MB'
      fail_on_warning = kargs[:fail_on_warning] || false

      raise ArgumentError, "The 'build_type' argument only accepts the values \"App\" and \"Instant\"" unless %w[App Instant].include? build_type

      if kargs[:limit_size]
        raise ArgumentError, "The 'limit_size' arguments only accepts numeric values" unless limit_size.is_a? Numeric
      elsif kargs[:size_limit]
        raise ArgumentError, "The 'size_limit' argument only accepts numeric values" unless limit_size.is_a? Numeric
      end

      limit_unit.upcase!
      raise ArgumentError, "The 'limit_unit' argument only accepts the values \"KB\", \"MB\" and \"GB\"" unless %w[KB MB GB].include? limit_unit

      raise ArgumentError, "The 'fail_on_warning' argument only accepts the values 'true' and 'false'" unless [true, false].include? fail_on_warning

      create_temp_dir(temp_path)

      unless AndroidUtils.download_bundletool(bundletool_version, bundletool_path)
        clean_temp!
        return
      end

      AndroidUtils.generate_apks(aab_path, ks_path, ks_alias, ks_password, ks_alias_password, apks_path,
                                 bundletool_path)
      AndroidUtils.generate_estimated_sizes(apks_path, size_csv_path, bundletool_path, build_type)
      filtered_sizes = AndroidUtils.filter_estimated_sizes(size_csv_path, screen_densities, languages)
      sorted_sizes = AndroidUtils.sort_estimated_sizes(filtered_sizes)

      clean_temp!(temp_path)

      generate_android_size_report_markdown(sorted_sizes, build_type, limit_size, limit_unit, fail_on_warning,
                                            variants_limit)
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

    def create_temp_dir(temp_path)
      Dir.mkdir temp_path
    end

    def clean_temp!(temp_path)
      FileUtils.rm_rf(temp_path)
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

      if violation_count.positive?
        if fail_on_warning
          failure "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by #{violation_count} variants"
        else
          warn "The size limit of #{size_limit} #{limit_unit.upcase} has been exceeded by #{violation_count} variants"
        end
      end

      exceed_size_report = "| Under Limit | SDK | ABI | Screen Density | Language | Size (Bytes) |\n"
      exceed_size_report << "| :-: | :-: | :-: | :-: | :-: | :-: |\n"

      more_exceed_size_report = "| Under Limit | SDK | ABI | Screen Density | Language | Size (Bytes) |\n"
      more_exceed_size_report << "| :-: | :-: | :-: | :-: | :-: | :-: |\n"

      under_size_report = "| Under Limit | SDK | ABI | Screen Density | Language | Size (Bytes) |\n"
      under_size_report << "| :-: | :-: | :-: | :-: | :-: | :-: |\n"

      counter = sorted_sizes.length - 1
      exceed_counter = 1
      under_counter = 1

      while counter >= 0
        variant = sorted_sizes[counter]
        is_violating = variant.max > limit_size.bytes ? '❌' : '✅'
        variant_report = "#{is_violating} | #{variant.sdk} | #{variant.abi} | #{variant.screen_density} | #{variant.language} | #{variant.max} |\n"

        if variant.max > limit_size.bytes
          if exceed_counter <= variants_limit
            exceed_counter += 1
            exceed_size_report << variant_report
          else
            more_exceed_size_report << variant_report
          end
        elsif under_counter <= variants_limit
          under_counter += 1
          under_size_report << variant_report
        end

        counter -= 1
      end

      size_report = "# Android #{build_type} Size Report\n"
      size_report << "### Size limit = #{size_limit} #{limit_unit.upcase}\n\n"

      if violation_count.positive?
        size_report << "## Variants exceeding the size limit\n\n"
        size_report << exceed_size_report
        size_report << "\n"

        if violation_count > variants_limit
          size_report << "<details>\n<summary>Click to view more violating variants!</summary>\n\n"
          size_report << more_exceed_size_report
          size_report << "</details>\n\n"
        end
      end

      size_report << "## Variants under or equal to the size limit\n\n"
      size_report << "<details>\n<summary>Click to expand!</summary>\n\n"

      size_report << under_size_report
      size_report << "</details>\n"

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
        flagged_variant_names.append(variant.variant) if variant.app_size.uncompressed.value > limit_size.megabytes || variant.on_demand_resources_size.uncompressed.value > limit_size.megabytes
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
