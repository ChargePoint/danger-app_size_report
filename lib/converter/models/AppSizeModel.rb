require_relative '../helper/JSONConverter'
class AppSizeModel < JSONConverter
    attr_reader :compressed, :uncompressed

    PARSING_KEYS = {
        :compressed => "compressed", 
        :uncompressed => "uncompressed"
    }.freeze

    def initialize(compressed: SizeModel.placeholder, uncompressed: SizeModel.placeholder)
        @compressed = compressed
        @uncompressed = uncompressed
    end
end

class SizeModel < JSONConverter
    attr_reader :raw_value, :value, :unit

    def initialize(raw_value, value, unit)
        @raw_value = raw_value
        @value = value
        @unit = unit
    end

    def self.placeholder
        SizeModel.new("Unknown", 0, MemorySize::UNIT[:bytes])
    end
end