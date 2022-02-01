require_relative '../helper/JSONConverter'
class DeviceModel < JSONConverter
    attr_reader :device, :os_version

    PARSING_KEYS = {
        :device => "device: ",
        :os_version => "os-version: "
    }.freeze

    def initialize(device, os_version)
        @device = device
        @os_version = os_version
    end

end