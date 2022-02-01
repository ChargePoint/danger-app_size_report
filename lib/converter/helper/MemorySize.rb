require_relative '../helper/JSONConverter'
class MemorySize < JSONConverter
    attr_accessor :kilobytes
    ZERO_SIZE = "zero kb"

    UNIT = {
        :bytes => "B",
        :kilobytes => "KB",
        :megabytes => "MB",
        :gigabytes => "GB",
    }.freeze

    def bytes 
        return @kilobytes * 1024
    end

    def megabytes
        return @kilobytes / 1024
    end 

    def gigabytes
        return @kilobytes / 1024 / 1024
    end 

    def initialize(text)
        value = parseFrom(text)

        if (value)
            @kilobytes = value
        else
            @kilobytes = 0
        end
    end

    private

    def parseFrom(text)
        textToMemoryUnit = {
            "b" => :bytes,
            "byte" => :bytes,
            "bytes" => :bytes,
            "kb" => :kilobytes,
            "kilobyte" => :kilobytes,
            "kilobytes" => :kilobytes,
            "mb" => :megabytes,
            "megabyte" => :megabytes,
            "megabytes" => :megabytes,
            "gb" => :gigabytes,
            "gigabyte" => :gigabytes,
            "gigabytes" => :gigabytes
        }

        unit = textToMemoryUnit[parseUnits(text)]
        size = parseSize(text)
        
        if (!size)
            return nil
        end
        
        if (!unit)
            unit = :megabytes
        end
        
        case unit
        when :bytes
            return kilobytesFromBytes(size)
        when :kilobytes
            return size
        when :megabytes
            return kilobytesFromMegabytes(size)
        when :gigabytes
            return kilobytesFromGigabytes(size)
        end
    end
    
    def parseUnits(text)
        if text.downcase == ZERO_SIZE
            return "kb"
        end
        
        result = ""

        text.each_char { |char|
            if char.match?(/[[:alpha:]]/) && char != "." && char != ","
                result << char
            end
        }
        
        return result.downcase
    end

    def parseSize(text)
        if text.downcase == ZERO_SIZE
            return 0.to_f
        end

        result = ""

        text.each_char { |char|
            if char.match?(/[[:digit:]]/) || char == "." || char == ","
                result << char
            end
        }
       
        return result.to_f
    end

    def kilobytesFromBytes (bytes)
        return bytes / 1024
    end

    def kilobytesFromMegabytes (megabytes)
        return megabytes * 1024
    end

    def kilobytesFromGigabytes (gigabytes)
        return gigabytes * 1024 * 1024
    end
end