module Patchy
  module FunctionUnits
    class Stack

      def initialize(cpu)
        @cpu = cpu
      end

      # 0x05 - PUSH
      # 0x06 - PUSHI
      # 0x07 - PUSHM
      # 0x08 - POP
      # 0x09 - POPM
      def handle(instruction)

        case instruction.opcode
        when 0x05 then push(instruction)
        when 0x06 then pushi(instruction)
        when 0x07 then pushm(instruction)
        when 0x08 then pop(instruction)
        when 0x09 then popm(instruction)
        end

      end

      def raw_push(data)
        @cpu.inc_sp
        @cpu.ram.write(@cpu.stack_page, @cpu.reg_sp, data)
      end

      def raw_pop
        data = @cpu.ram.read(@cpu.stack_page, @cpu.reg_sp)
        @cpu.dec_sp
        data
      end

      # Push src register onto stack
      def push(instruction)
        raw_push(@cpu.get_reg_by_address(instruction.src))
      end

      # Push immediate onto stack
      def pushi(instruction)
        raw_push(instruction.immediate)
      end

      # Push contents of RAM address in immediate onto stack
      def pushm(instruction)
        raw_push(@cpu.ram.read(@cpu.reg_dp, instruction.immediate))
      end

      # Pop stack contents into register
      def pop(instruction)
        @cpu.set_reg_by_address(raw_pop, instruction.dest)
      end

      # Pop stack contents into immediate RAM address
      def popm(instruction)
        @cpu.ram.write(@cpu.reg_dp, instruction.immediate, raw_pop)
      end
    end
  end
end
