require_relative '../models/DeviceModel'
require 'securerandom'
require_relative './ModelParser'

class VariantDescriptorParser < ModelParser

    def parse
        @text = @text.strip
        
        if @text.empty?
            @result = nil
        elsif @text == "Universal"
            @result = [parseToDeviceModel(@text)]
        else
            models = []
            splitterID = SecureRandom.uuid
            @text.sub!("and ", "")
            @text.gsub!("],", "],#{splitterID}")
            descriptors = @text.split(",#{splitterID} ")
        
            for descriptor in descriptors
                descriptor = descriptor[/\[(.*?)\]/m,1]
                model = parseToDeviceModel(descriptor)
                if (model)
                    models.append(model)
                end
            end

            @result = models
        end
    end

    def parseToDeviceModel (text)
        if !text
            return nil
        end

        if (text == "Universal")
            return DeviceModel.new(text, "")
        end

        attributes = text.split(", ")
        parsing_keys = DeviceModel::PARSING_KEYS
        dict = Hash.new
        for attribute in attributes
            parsing_keys.each do |property, key|
                if (attribute.include? key) 
                    # clean the key from the text
                    parseableText = attribute.gsub(key, "")
                    dict[key] = parseableText
                end
            end
        end

        return DeviceModel.new(dict.fetch(parsing_keys[:device], "Unknown"), dict.fetch(parsing_keys[:os_version], "Unknown"))
    end
end