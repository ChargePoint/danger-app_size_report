# frozen_string_literal: false

require_relative './model_parser'

class VariantParser < ModelParser
  def parse
    @text = @text.strip
    @result = (@text.strip unless @text.empty?)
  end
end
