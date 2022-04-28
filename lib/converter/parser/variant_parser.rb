# frozen_string_literal: false

require_relative './model_parser'

# Parse Variant section of App Thinning Size Report.
# Example: 'Variant: ChargePointAppClip-35AD0331-EA57-4B82-B8E6-029D7786B9B7.ipa'
class VariantParser < ModelParser
  def parse
    @text = @text.strip
    @result = (@text.strip unless @text.empty?)
  end
end
