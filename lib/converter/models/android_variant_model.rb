# frozen_string_literal: true

# Android variant model
class AndroidVariant
  attr_reader :sdk, :abi, :screen_density, :language, :texture_compression_format, :device_tire, :min, :max

  PARSING_KEYS = {
    sdk: 'SDK',
    abi: 'ABI',
    screen_density: 'SCREEN_DENSITY',
    language: 'LANGUAGE',
    texture_compression_format: 'TEXTURE_COMPRESSION_FORMAT',
    device_tire: 'DEVICE_TIER',
    min: 'MIN',
    max: 'MAX'
  }.freeze

  def initialize(sdk, abi, screen_density, language, texture_compression_format, device_tire, min, max)
    @sdk = sdk
    @abi = abi
    @screen_density = screen_density
    @language = language
    @texture_compression_format = texture_compression_format
    @device_tire = device_tire
    @min = min.to_i
    @max = max.to_i
  end
end
