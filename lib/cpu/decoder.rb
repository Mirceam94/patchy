require "lib/cpu/function_units/system"
require "lib/cpu/function_units/memory"
require "lib/cpu/function_units/stack"
require "lib/cpu/function_units/alu"

# This is temporary, and fakes the logic inside of a pipeline. At this point I
# only want to get it executing and the instructions all working, then I'll
# simulate a full HW pipeline, and get rid of this.
module Patchy
  class Decoder

    def initialize(cpu)
      @cpu = cpu

      @system_unit = Patchy::FunctionUnits::System.new(cpu)
      @memory_unit = Patchy::FunctionUnits::Memory.new(cpu)
      @stack_unit = Patchy::FunctionUnits::Stack.new(cpu)
      @alu_unit = Patchy::FunctionUnits::ALU.new(cpu)
    end

    def decode(instruction)

      case instruction.opcode
      when 0x00, 0x01, 0xff then @system_unit.handle(instruction)
      when 0x02..0x04 then @memory_unit.handle(instruction)
      when 0x05..0x09 then @stack_unit.handle(instruction)
      when 0x0a..0x13 then @alu_unit.handle(instruction)
      else
        puts "  WARNING: Unknown instruction #{instruction}"
      end

    end
  end
end