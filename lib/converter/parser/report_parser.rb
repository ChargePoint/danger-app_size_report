# frozen_string_literal: false

require 'securerandom'
require_relative '../models/variant_model'
require_relative '../helper/result_factory'

# Parses App Thinning Size Report in its entirety
class ReportParser
  def self.parse(text)
    splitter_id = SecureRandom.uuid

    # First we trim the report text
    preprocessed_data = text.strip

    preprocessed_data.gsub!(/\n{2,3}/, "\n#{splitter_id}\n")

    # Also append the splitter ID to the end of the text so we do not miss the last variant
    preprocessed_data += "\n#{splitter_id}\n"

    data = preprocessed_data.split("\n")

    variants = []
    dict = {}

    data.each do |value|
      parsing_keys = VariantModel::PARSING_KEYS
      if value == splitter_id && dict.fetch(parsing_keys[:variant], nil)
        variant = dict.fetch(parsing_keys[:variant], '')
        supported_variant_descriptors = dict.fetch(parsing_keys[:supported_variant_descriptors], '')
        app_on_demand_resources_size = dict.fetch(parsing_keys[:app_on_demand_resources_size], '')
        app_size = dict.fetch(parsing_keys[:app_size], '')
        on_demand_resources_size = dict.fetch(parsing_keys[:on_demand_resources_size], '')

        # initialize variant model from all the parser result
        model = VariantModel.new(variant,
                                 supported_variant_descriptors,
                                 app_on_demand_resources_size,
                                 app_size,
                                 on_demand_resources_size)

        variants.append(model)

        # reset all the properties
        dict = {}
      end

      parsing_keys.each do |property, key|
        next unless value.include? key

        # clean the key from the text
        # i.e. "Variant: ChargePointAppClip-354363463-...." remove the "Variant: " so we have a clean text that we can parse ("ChargePointAppClip-354363463-....")
        # i.e. "Supported variant descriptors: [device: iPhone10,3, os-version:14.0], ..." will pass only the "[device: iPhone10,3, os-version:14.0], ..." to the parser
        if (key == parsing_keys[:on_demand_resources_size]) && (value.include? parsing_keys[:app_on_demand_resources_size])
          parseable_text = value.gsub(parsing_keys[:app_on_demand_resources_size], '')
          dict[key] = parseable_text
          dict[key] = ResultFactory.parse(from_text: parseable_text, parser: :app_on_demand_resources_size)
        else
          parseable_text = value.gsub(key, '')
          dict[key] = parseable_text
          dict[key] = ResultFactory.parse(from_text: parseable_text, parser: property)
        end
      end
    end
    variants
  end
end
