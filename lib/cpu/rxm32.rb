require "narray"

# Serves as a 32-bit RAM/ROM memory bank
module Patchy
  class RXM32

    attr_reader :size

    # Only bytes are unsigned, stored as ABCD (MSB X X LSB)
    def initialize(size)
      @raw_a = NArray.byte(size)
      @raw_b = NArray.byte(size)
      @raw_c = NArray.byte(size)
      @raw_d = NArray.byte(size)
      @size = size
    end

    def read(address)
      a = @raw_a[address]
      b = @raw_b[address]
      c = @raw_c[address]
      d = @raw_d[address]

      (a << 24) | (b << 16) | (c << 8) | d
    end

    def write(address, data)
      a = data >> 24
      b = (data >> 16) & 0xFF
      c = (data >> 8) & 0xFF
      d = data & 0xFF

      @raw_a[address] = a
      @raw_b[address] = b
      @raw_c[address] = c
      @raw_d[address] = d
    end

    def bounds_check(address)
      address <= @size and address >= 0
    end
  end
end
