# frozen_string_literal: true

require_relative '../helper/json_converter'

# App Size Model.
# Example: 'App size: 6.6 MB compressed, 12.9 MB uncompressed'
class AppSizeModel < JSONConverter
  attr_reader :compressed, :uncompressed

  PARSING_KEYS = {
    compressed: 'compressed',
    uncompressed: 'uncompressed'
  }.freeze

  def initialize(compressed: SizeModel.placeholder, uncompressed: SizeModel.placeholder)
    super()
    @compressed = compressed
    @uncompressed = uncompressed
  end
end

# Size Model
class SizeModel < JSONConverter
  attr_reader :raw_value, :value, :unit

  def initialize(raw_value, value, unit)
    super()
    @raw_value = raw_value
    @value = value
    @unit = unit
  end

  def self.placeholder
    SizeModel.new('Unknown', 0, MemorySize::UNIT[:bytes])
  end
end
