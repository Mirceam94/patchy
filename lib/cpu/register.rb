require "bindata"

module Patchy
  class CPU

    class Register < BinData::Record
      endian :little

      attr_reader :address

      def initialize(address)
        @address = address
      end

      def data=(value)
        self[:data].assign(value)
      end
    end

    class Register8 < Register
      bit8 :data
    end

    class Register16 < Register
      bit16 :data
    end

    class Register32 < Register
      bit32 :data
    end

  end
end
