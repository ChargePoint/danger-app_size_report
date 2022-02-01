require_relative '../parser/VariantParser'
require_relative '../parser/VariantDescriptorParser'
require_relative '../parser/AppSizeParser'

class ResultFactory

    def self.parse (from_text: "", parser: nil)
        result = nil
        case parser
        when :variant
            variant_parser = VariantParser.new(from_text)
            variant_parser.parse
            result = variant_parser.result
        when :supported_variant_descriptors
            variant_descriptor_parser = VariantDescriptorParser.new(from_text)
            variant_descriptor_parser.parse
            result = variant_descriptor_parser.result
        when :app_on_demand_resources_size
            app_size_parser = AppSizeParser.new(from_text)
            app_size_parser.parse
            result = app_size_parser.result
        when :app_size
            app_size_parser = AppSizeParser.new(from_text)
            app_size_parser.parse
            result = app_size_parser.result
        when :on_demand_resources_size
            app_size_parser = AppSizeParser.new(from_text)
            app_size_parser.parse
            result = app_size_parser.result
        end
        return result
    end
end