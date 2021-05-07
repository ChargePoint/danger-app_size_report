class AppSizeParser < ModelParser
    def initialiaze(standardized_unit = MemorySize.Unit.megabyte)
        @standardized_unit = standardized_unit
    end

    def parse_text
        if text.to_s.strip.empty?
            return
        end


    end

end