require "bindata"

module Patchy
  class Instruction < BinData::Record
    endian :little

    bit8 :opcode
    bit4 :dest
    bit4 :src
    bit16 :immediate
  end
end
