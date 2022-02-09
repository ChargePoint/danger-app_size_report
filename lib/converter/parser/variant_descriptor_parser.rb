# frozen_string_literal: false

require_relative '../models/device_model'
require 'securerandom'
require_relative './model_parser'

class VariantDescriptorParser < ModelParser
  def parse
    @text = @text.strip

    if @text.empty?
      @result = nil
    elsif @text == 'Universal'
      @result = [parse_to_device_model(@text)]
    else
      models = []
      splitter_id = SecureRandom.uuid
      @text.sub!('and ', '')
      @text.gsub!('],', "],#{splitter_id}")
      descriptors = @text.split(",#{splitter_id} ")

      descriptors.each do |descriptor|
        descriptor = descriptor[/\[(.*?)\]/m, 1]
        model = parse_to_device_model(descriptor)
        models.append(model) if model
      end

      @result = models
    end
  end

  def parse_to_device_model(text)
    return nil unless text

    return DeviceModel.new(text, '') if text == 'Universal'

    attributes = text.split(', ')
    parsing_keys = DeviceModel::PARSING_KEYS
    dict = {}
    attributes.each do |attribute|
      parsing_keys.each do |_property, key|
        next unless attribute.include? key

        # clean the key from the text
        parseable_text = attribute.gsub(key, '')
        dict[key] = parseable_text
      end
    end

    DeviceModel.new(dict.fetch(parsing_keys[:device], 'Unknown'),
                    dict.fetch(parsing_keys[:os_version], 'Unknown'))
  end
end
