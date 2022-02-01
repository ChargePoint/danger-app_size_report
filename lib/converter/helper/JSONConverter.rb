require 'json'

class JSONConverter
    def to_json (options = {})
        hash = Hash.new
        self.instance_variables.each do |var|
            key = var.to_s[1..-1]
            hash[key] = self.instance_variable_get(var)
        end
        JSON.pretty_generate(hash)
    end
end