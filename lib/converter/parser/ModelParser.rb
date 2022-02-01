class ModelParser
    attr_reader :text, :result

    def initialize (text)
        @text = text
    end

    def parse 
        raise NotImplementedError, "Implement this method in a child class"
    end
end