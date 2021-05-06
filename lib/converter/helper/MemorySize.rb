class MemorySize < ActiveRecord::Base
    attr_accessor :kilobytes

    enum Unit: {
        bytes: = "B",
        kilobytes: = "KB",
        megabytes: = "MB",
        gigabytes: = "GB",
    }

    def bytes
        return kilobytes * 1024
    end

    def megabytes
        return kilobytes / 1024
    end

    def gigabytes
        return self.megabytes / 1024
    end

    def initialiaze(args)
        if args.has_key? "bytes"
            @kilobytes = bytes / 1024
        end

        if args.has_key? "megabytes"
            @kilobytes = bytes * 1024
        end
                
        if args.has_key? "gigabytes"
            @kilobytes = bytes * 1024 * 1024
        end
    end

    def parseFrom(text)
        textToMemoryUnit = {
            "b" => .bytes,
            "byte" => .bytes,
            "bytes" => .bytes,
            "kb" => .kilobytes,
            "kilobyte" => .kilobytes,
            "kilobytes" => .kilobytes,
            "mb" => .megabytes,
            "megabyte" => .megabytes,
            "megabytes" => .megabytes,
            "gb" => .gigabytes,
            "gigabyte" => .gigabytes,
            "gigabytes" => .gigabytes
        }

        if textToMemoryUnit[parseUnits(text: text)] == null || parseSize(text: text) == null 
            return nil
        end
        
        unit = textToMemoryUnit[parseUnits(text: text)]
        size = parseSize(text: text)

        case unit
        when bytes
            return MemorySize({bytes: size})
        when kilobytes
            return MemorySize({kilobytes: size})
        when megabytes
            return MemorySize({megabytes: size})
        when gigabytes
            return MemorySize({gigabytes: size})
    end
end