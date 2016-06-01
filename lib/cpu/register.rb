require "bindata"

module Patchy
  class CPU

    class Register < BinData::Record
      endian :little

      # Addresses should be explicitly specified for registers exposed to the
      # instruction set!
      attr_accessor :address

      def value=(value)
        self[:bdata].assign(value)
      end
    end

    class Register8 < Register
      bit8 :bdata, initial_value: 0
    end

    class Register16 < Register
      bit16 :bdata, initial_value: 0
    end

  end
end
