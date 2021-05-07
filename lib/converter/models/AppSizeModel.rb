class AppSizeModel < ActiveRecord::Base
    attr_reader :compressed, :uncompressed

    enum CodingKeys: {compressed: "compressed", uncompressed: "uncompressed"}

    def initialiaze(compressed = SizeModel.placeholder, uncompressed = SizeModel.placeholder)
        @compressed = compressed
        @uncompressed = uncompressed
    end
end

class SizeModel
    attr_reader :raw_value, :value, :unit

    def initialiaze(raw_value, value, unit)
        @raw_value = raw_value
        @value = value
        @unit = unit
    end

    def self.placeholder
        SizeModel("Unknown", 0, MemorySize.Unit.bytes)
    end
end