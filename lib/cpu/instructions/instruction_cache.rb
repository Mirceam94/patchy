require "lib/cpu/register"

# As this is a super-scalar processor, we need to fetch two instructions at a
# time.
#
# I have no idea where to find ICs that allow one to fetch 2 words at a time,
# and since I want to stay as true to the hardware as possible, we will
# simulate the hardware instruction cache.
#
# Basically, instructions are fetched 16bits at a time, and loaded up into four
# 16bit registers, ready for useage (Instructions are 32bits wide). The
# immediate value is passed along on its own special bus, with a buffered
# connection to the data bus.
#
# The instruction cache operates with its own clock, running 8x as fast as the
# rest of the CPU. In hardware this is actually the same clock signal, just
# divided by eight with a shift register. We don't have to be quite so exact
# here, so we just load up the cache on each cycle (assuming 8 cache-cycles).
#
# NOTE: In hardware, the address used as an index into RAM for loading the cache
#       MUST be buffered, so that it is blocked when the CPU is performing a
#       RAM operation!
# 
# We use a multiplier of 8 against the CPU clock since any CPU RAM operations
# will block us from refreshing. The CPU "consumes" the two cached instructions
# every 8 cycles, and *might* (depending on the instruction) block RAM for one
# cycle as it performs a read/write operation. This block means we have 7 cycles
# left to load the next 4 words, something which takes 4 cycles.
#
# 8 is rounder than 5 in CPU-land, and gives us a bit more breathing room since
# both pipelines performing RAM ops at the same time will take up two cycles :)
module Patchy
  class InstructionCache

    def initialize(cpu)
      @cpu = cpu

      @cycles = 0           # Cycle counter, just for the lols
      @offset = 0           # PC offset, incremented by one each cycle
      @shift_reg = 0b0001   # Shift register, used to keep track of op stage.
                            # When this is 0b1000, we wrap and clear @offset

      @insA_wordM = Patchy::CPU::Register16.new
      @insA_wordL = Patchy::CPU::Register16.new

      @insB_wordM = Patchy::CPU::Register16.new
      @insB_wordL = Patchy::CPU::Register16.new
    end

    # The magic! <3 Feel the larv
    def cycle

      # Fetch instructions relative to DP and PC
      pc = @cpu.reg_pc
      dp = @cpu.reg_dp

      instruction_word = @cpu.ram.read dp, pc + @offset

      # Load up register based on offset and shift register
      # In the hardware, the shift register activates the proper buffer between
      # the RAM outputs and one of our 16bit registers
      if @shift_reg & 0b0001 > 0
        @insA_wordM.data = instruction_word
      elsif @shift_reg & 0b0010 > 0
        @insA_wordL.data = instruction_word
      elsif @shift_reg & 0b0100 > 0
        @insB_wordM.data = instruction_word
      elsif @shift_reg & 0b1000 > 0
        @insB_wordL.data = instruction_word
      end

      # Increase offset and shift register
      @offset += 1
      @shift_reg <<= 1

      # If we need to wrap around, do so!
      if @offset == 4
        @offset = 0
        @shift_reg = 0b0001
      end

      @cycles += 1
    end

    def instructionA
      @insA_wordM.bdata
    end

    def immediateA
      @insA_wordL.bdata
    end

    def instructionB
      @insB_wordM.bdata
    end

    def immediateB
      @insB_wordL.bdata
    end
  end
end
