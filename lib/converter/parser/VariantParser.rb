require_relative './ModelParser'

class VariantParser < ModelParser

    def parse
        @text = @text.strip
        if !@text.empty?
            @result = @text.strip
        else
            @result = nil
        end
    end

end