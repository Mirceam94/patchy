require "narray"

# Serves as a 16-bit RAM/ROM memory bank
module Patchy
  class RXM16

    attr_reader :size

    def initialize(size)
      @raw = NArray.sint(size)
      @size = size
    end

    def read(address)
      @raw[address]
    end

    def write(address, data)
      @raw[address] = data
    end

    def bounds_check(address)
      address <= @size and address >= 0
    end
  end
end
