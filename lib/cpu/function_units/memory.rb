module Patchy
  module FunctionUnits
    class Memory

      def initialize(cpu)
        @cpu = cpu
      end

      # 0x02 - LDI
      # 0x03 - LDM
      # 0x04 - STORE
      def handle(instruction)

        case instruction.opcode
        when 0x02 then ldi(instruction)
        when 0x03 then ldm(instruction)
        when 0x04 then store(instruction)
        end

      end

      # Load immediate into dest register
      def ldi(instruction)
        @cpu.set_reg_by_address(instruction.immediate, instruction.dest)
      end

      # Load data at immediate address into dest register
      def ldm(instruction)
        ram_value = @cpu.ram.read(@cpu.reg_dp, instruction.immediate)
        @cpu.set_reg_by_address(ram_value, instruction.dest)
      end

      # Store contents of source register into RAM at immediate address
      def store(instruction)
        @rcpu.ram.write(@cpu.reg_dp, @cpu.get_reg_by_address(instruction.src))
      end
    end
  end
end
