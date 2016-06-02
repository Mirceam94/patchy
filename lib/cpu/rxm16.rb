require "narray"

# Serves as a 16-bit RAM/ROM memory bank
module Patchy
  class RXM16

    attr_reader :size

    # Only bytes are unsigned, stored as AB (MSB LSB)
    def initialize(size)
      @raw_a = NArray.byte(size)
      @raw_b = NArray.byte(size)

      @size = size
    end

    def read(address)
      a = @raw_a[address]
      b = @raw_b[address]

      (a << 8) | b
    end

    def write(address, data)
      a = (data >> 8) & 0xFF
      b = data & 0xFF

      @raw_a[address] = a
      @raw_b[address] = b
    end

    def bounds_check(address)
      address <= @size and address >= 0
    end
  end
end
