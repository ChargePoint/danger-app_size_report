require 'securerandom'
require_relative '../models/VariantModel'
require_relative '../helper/ResultFactory'

class ReportParser
    
    def self.parse (text)
        splitterID = SecureRandom.uuid

        # First we trim the report text
        preprocessedData = text.strip

        preprocessedData.gsub!(/\n{2,3}/, "\n#{splitterID}\n")

        # Also append the splitter ID to the end of the text so we do not miss the last variant
        preprocessedData += "\n#{splitterID}\n"

        data = preprocessedData.split("\n")

        variants = []
        dict = Hash.new

        for value in data
            parsing_keys = VariantModel::PARSING_KEYS
            if (value == splitterID && dict.fetch(parsing_keys[:variant], nil))
                variant = dict.fetch(parsing_keys[:variant], "")
                supportedVariantDescriptors = dict.fetch(parsing_keys[:supported_variant_descriptors], "")
                appOnDemandResourcesSize = dict.fetch(parsing_keys[:app_on_demand_resources_size], "")
                appSize = dict.fetch(parsing_keys[:app_size], "")
                onDemandResourcesSize = dict.fetch(parsing_keys[:on_demand_resources_size], "")

                # initialize variant model from all the parser result
                model = VariantModel.new(variant,
                                         supportedVariantDescriptors,
                                         appOnDemandResourcesSize,
                                         appSize,
                                         onDemandResourcesSize)

                variants.append(model)

                # reset all the properties
                dict = Hash.new
            end

            parsing_keys.each do |property, key|
                if (value.include? key) 
                    # clean the key from the text
                    # i.e. "Variant: ChargePointAppClip-354363463-...." remove the "Variant: " so we have a clean text that we can parse ("ChargePointAppClip-354363463-....")
                    # i.e. "Supported variant descriptors: [device: iPhone10,3, os-version:14.0], ..." will pass only the "[device: iPhone10,3, os-version:14.0], ..." to the parser
                    parseableText = ""
                    if((key == parsing_keys[:on_demand_resources_size]) && (value.include? parsing_keys[:app_on_demand_resources_size]))
                        parseableText = value.gsub(parsing_keys[:app_on_demand_resources_size], "")
                        dict[key] = parseableText
                        dict[key] = ResultFactory.parse(from_text: parseableText, parser: :app_on_demand_resources_size)
                    else 
                        parseableText = value.gsub(key, "")
                        dict[key] = parseableText
                        dict[key] = ResultFactory.parse(from_text: parseableText, parser: property)
                    end 
                end
            end
        end
        return variants
    end
end