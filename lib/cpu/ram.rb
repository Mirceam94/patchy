require "narray"

module Patchy
  class RAM

    # 16MB of RAM! So sexy it hurts. The word size is 16bits, or 2 bytes
    #
    # Accessing all 16MB requires a 24bit address bus. Since the address bus
    # is actually 16bits wide, we operate on 128KB pages (128 of them)
    #
    # The current page is pointed at by the DP register, and all lookups are
    # performed relative to it.
    #
    # As an example, if DP is 0xa0 and we fetch the value at 0x5000, we
    # access the RAM location at (0xa0 * 0xffff) + 0x5000, meaning 0xa04f60
    @@size = 0x1000000

    def self.size
      @@size
    end

    # Sadly, using uint causes strange issues when the MSB is 1...
    # So we just go with 4-byte fields and treat it as 2-bytes. Whoop.
    def initialize
      @raw = NArray.int(0x1000000 / 16)
    end

    def resolve(dp8, address16)
      (dp8 * 0xffff) + address16
    end

    def read_raw(address24)
      @raw[address24]
    end

    def read(dp8, address16)
      read_raw resolve(dp8, address16)
    end

    def write_raw(address24, data)
      @raw[address24] = data
    end

    def write(dp8, address16, data)
      write_raw resolve(dp8, address16)
    end

    def bounds_check_raw(address)
      address <= @@size and address >= 0
    end

    def bounds_check(dp8, address16)
      bounds_check_raw resolve(dp8, address16)
    end
  end
end
