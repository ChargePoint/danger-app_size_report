class SizeModel
    String raw_value
    Double value

    enum
end

class AppSizeModel < ActiveRecord::Base
    SizeModel compressed
    SizeModel uncompressed

    enum CodingKeys: {compressed: "compressed", uncompressed: "uncompressed"}
end