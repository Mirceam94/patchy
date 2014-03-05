require "bindata"

module Patchy
  class CPU

    # Stored as Opcode-Dest-Src-Immediate
    # Or 00000000-0000-0000-0000000000000000
    class Instruction < BinData::Record
      endian :little

      bit8 :opcode
      bit4 :dest
      bit4 :src

      # Addresses are stored in the immediate
      # Ports are stored in the lower 8 bits of the immediate
      bit16 :immediate
    end
  end
end
