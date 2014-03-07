module Patchy
  module FunctionUnits
    class ALU

      def initialize(cpu)
        @cpu = cpu
      end

      # 0x0a - ADD
      # 0x0b - ADDI
      # 0x0c - SUB
      # 0x0d - SUBI
      # 0x0e - CMP
      # 0x0f - AND
      # 0x10 - OR
      # 0x11 - XOR
      # 0x12 - SHL
      # 0x13 - SHR
      def handle(instruction)

        case instruction.opcode
        when 0x0a then add(instruction)
        when 0x0b then addi(instruction)
        when 0x0c then sub(instruction)
        when 0x0d then subi(instruction)
        when 0x0e then cmp(instruction)
        when 0x0f then b_and(instruction)
        when 0x10 then b_or(instruction)
        when 0x11 then b_xor(instruction)
        when 0x12 then shl(instruction)
        when 0x13 then shr(instruction)
        end

      end

      # Add src and dest together, store sum in dest
      def add(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(src + dest, instruction.dest)
      end

      # Add dest with immediate, store sum in dest
      def add(instruction)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(instruction.immediate + dest, instruction.dest)
      end

      # Subtract src from dest, store difference in dest
      def sub(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest - src, instruction.dest)
      end

      # Subtract immediate from dest, store difference in dest
      def subi(instruction)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest - instruction.immediate, instruction.dest)
      end

      # Compare src and dest, set FLAGS
      def cmp(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        lt = src < dest
        gt = src > dest
        eq = src == dest

        @cpu.set_flag(:lt, lt)
        @cpu.set_flag(:gt, gt)
        @cpu.set_flag(:eq, eq)
      end

      # AND src and dest together, store result in dest
      def b_and(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest & src, instruction.dest)
      end

      # OR src and dest together, store result in dest
      def b_or(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest | src, instruction.dest)
      end

      # XOR src and dest together, store result in dest
      def b_xor(instruction)
        src = @cpu.get_reg_by_address(instruction.src)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest ^ src, instruction.dest)
      end

      # Shift dest register left, store result in dest
      def shl(instruction)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest << 1, instruction.dest)
      end

      # Shift dest register right, store result in dest
      def shr(instruction)
        dest = @cpu.get_reg_by_address(instruction.dest)

        @cpu.set_reg_by_address(dest >> 1, instruction.dest)
      end

    end
  end
end
