# frozen_string_literal: false

require_relative '../helper/json_converter'
# Defines memory size object to be used to parse the App Thinning Size Report
class MemorySize < JSONConverter
  attr_accessor :kilobytes

  ZERO_SIZE = 'zero kb'.freeze

  UNIT = {
    bytes: 'B',
    kilobytes: 'KB',
    megabytes: 'MB',
    gigabytes: 'GB'
  }.freeze

  def bytes
    @kilobytes * 1024
  end

  def megabytes
    @kilobytes / 1024
  end

  def gigabytes
    @kilobytes / 1024 / 1024
  end

  def initialize(text)
    super()
    value = parse_from(text)

    @kilobytes = value || 0
  end

  private

  def parse_from(text)
    text_to_memory_unit = {
      'b' => :bytes,
      'byte' => :bytes,
      'bytes' => :bytes,
      'kb' => :kilobytes,
      'kilobyte' => :kilobytes,
      'kilobytes' => :kilobytes,
      'mb' => :megabytes,
      'megabyte' => :megabytes,
      'megabytes' => :megabytes,
      'gb' => :gigabytes,
      'gigabyte' => :gigabytes,
      'gigabytes' => :gigabytes
    }

    unit = text_to_memory_unit[parse_units(text)]
    size = parse_size(text)

    return nil unless size

    unit ||= :megabytes

    case unit
    when :bytes
      kilobytes_from_bytes(size)
    when :kilobytes
      size
    when :megabytes
      kilobytes_from_megabytes(size)
    when :gigabytes
      kilobytes_from_gigabytes(size)
    end
  end

  def parse_units(text)
    return 'kb' if text.downcase == ZERO_SIZE

    result = ''

    text.each_char do |char|
      result << char if char.match?(/[[:alpha:]]/) && char != '.' && char != ','
    end

    result.downcase
  end

  def parse_size(text)
    return 0.to_f if text.downcase == ZERO_SIZE

    result = ''

    text.each_char do |char|
      result << char if char.match?(/[[:digit:]]/) || char == '.' || char == ','
    end

    result.to_f
  end

  def kilobytes_from_bytes(bytes)
    bytes / 1024
  end

  def kilobytes_from_megabytes(megabytes)
    megabytes * 1024
  end

  def kilobytes_from_gigabytes(gigabytes)
    gigabytes * 1024 * 1024
  end
end
