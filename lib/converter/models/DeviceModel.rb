class DeviceModel < ActiveRecord::Base
    attr_reader :device, :os_version

    enum ParsingKeys: {
        device: "device"
        os_version: "os-version"
    }

    enum CodingKeys: {
        device: "device"
        os_version: "os_version"
    }
end