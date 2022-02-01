require_relative '../helper/JSONConverter'
class VariantModel < JSONConverter
    attr_reader :variant, :supported_variant_descriptors, :app_on_demand_resources_size, :app_size, :on_demand_resources_size
    PARSING_KEYS = {
        :variant => "Variant: ", 
        :supported_variant_descriptors => "Supported variant descriptors: ", 
        :app_on_demand_resources_size => "App + On Demand Resources size: ",
        :app_size => "App size: ",
        :on_demand_resources_size => "On Demand Resources size: "
    }.freeze

    def initialize(variant, supported_variant_descriptors, app_on_demand_resources_size, app_size, on_demand_resources_size)
        @variant = variant
        @supported_variant_descriptors = supported_variant_descriptors
        @app_on_demand_resources_size = app_on_demand_resources_size
        @app_size = app_size
        @on_demand_resources_size = on_demand_resources_size
    end
end
