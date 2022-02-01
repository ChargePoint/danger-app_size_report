require_relative '../models/AppSizeModel'
require_relative '../helper/MemorySize'
require_relative './ModelParser'

class AppSizeParser < ModelParser
    attr_reader :standardized_unit

    def initialize(text, standardized_unit: MemorySize::UNIT[:megabytes])
        super(text)
        @standardized_unit = standardized_unit
    end

    def parse 
        @text = @text.strip
        if @text.empty?
            @result = nil
        else
            parseableText = @text.split(", ")
            properties = Hash.new
            parsing_keys = AppSizeModel::PARSING_KEYS
            for sizeText in parseableText
                parsing_keys.each do |property, key|
                    if (sizeText.include?(key) && !properties.fetch(key,nil))
                        value = sizeText.gsub!(key, "")
                        properties[key] = value.strip
                    end
                end
            end

            compressedString = properties.fetch(parsing_keys[:compressed], nil)
            uncompressedString = properties.fetch(parsing_keys[:uncompressed], nil)
            compressedValue = MemorySize.new(compressedString).megabytes
            uncompressedValue = MemorySize.new(uncompressedString).megabytes

            if (compressedString && uncompressedString && compressedValue && uncompressedValue)
                compressedRawValue = compressedString.downcase == MemorySize::ZERO_SIZE ? "0 KB" : compressedString
                compressed = SizeModel.new(compressedRawValue, compressedValue, @standardized_unit)
                uncompressedRawValue = uncompressedString.downcase == MemorySize::ZERO_SIZE ? "0 KB" : uncompressedString
                uncompressed = SizeModel.new(uncompressedRawValue, uncompressedValue, @standardized_unit)
                @result = AppSizeModel.new(compressed: compressed, uncompressed: uncompressed)
            else
                @result = AppSizeModel.new()
            end
        end
    end
end