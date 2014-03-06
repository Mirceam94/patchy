module Patchy
  module FunctionUnits
    class System

      def initialize(cpu)
        @cpu = cpu
      end

      # 0x00 - NOP
      # 0x01 - MOV
      # 0xff - HLT
      def handle(instruction)

        case instruction.opcode
        when 0xff then @cpu.needs_halt = true
        when 0x01 then perform_mov(instruction)
        end

      end

      def perform_mov(instruction)
        @cpu.set_reg_by_address(@cpu.get_reg_by_address(instruction.src), instruction.dest)
      end
    end
  end
end
