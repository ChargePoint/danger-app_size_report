# frozen_string_literal: false

require_relative '../models/app_size_model'
require_relative '../helper/memory_size'
require_relative './model_parser'

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
      parseable_text = @text.split(', ')
      properties = {}
      parsing_keys = AppSizeModel::PARSING_KEYS
      parseable_text.each do |size_text|
        parsing_keys.each do |_property, key|
          if size_text.include?(key) && !properties.fetch(key, nil)
            value = size_text.gsub!(key, '')
            properties[key] = value.strip
          end
        end
      end

      compressed_string = properties.fetch(parsing_keys[:compressed], nil)
      uncompressed_string = properties.fetch(parsing_keys[:uncompressed], nil)
      compressed_value = MemorySize.new(compressed_string).megabytes
      uncompressed_value = MemorySize.new(uncompressed_string).megabytes

      if compressed_string && uncompressed_string && compressed_value && uncompressed_value
        compressed_raw_value = compressed_string.downcase == MemorySize::ZERO_SIZE ? '0 KB' : compressed_string
        compressed_size = SizeModel.new(compressed_raw_value, compressed_value, @standardized_unit)
        uncompressed_raw_value = uncompressed_string.downcase == MemorySize::ZERO_SIZE ? '0 KB' : uncompressed_string
        uncompressed_size = SizeModel.new(uncompressed_raw_value, uncompressed_value, @standardized_unit)
        @result = AppSizeModel.new(compressed: compressed_size, uncompressed: uncompressed_size)
      else
        @result = AppSizeModel.new
      end
    end
  end
end
