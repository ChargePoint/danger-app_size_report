# frozen_string_literal: true

require 'json'

# Generate pretty JSON from list of variants
class JSONConverter
  def to_json(_options = {})
    hash = {}
    instance_variables.each do |var|
      key = var.to_s[1..]
      hash[key] = instance_variable_get(var)
    end
    JSON.pretty_generate(hash)
  end
end
