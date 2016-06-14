require "bindata"

module Patchy
  class CPU

    # Stored as Opcode-Dest-Src-Immediate
    # Or 00000000-0000-0000-0000000000000000
    class Instruction < BinData::Record
      bit8le :opcode
      bit4le :dest
      bit4le :src

      # Addresses are stored in the immediate
      # Ports are stored in the lower 8 bits of the immediate
      bit16le :immediate
    end
  end
end
