# frozen_string_literal: true

require_relative '../helper/json_converter'

# Device Model
# @example 'device: iPhone10,3, os-version: 14.0'
class DeviceModel < JSONConverter
  attr_reader :device, :os_version

  PARSING_KEYS = {
    device: 'device: ',
    os_version: 'os-version: '
  }.freeze

  def initialize(device, os_version)
    super()
    @device = device
    @os_version = os_version
  end
end
