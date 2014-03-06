require "lib/cpu/instructions/instruction"
require "lib/cpu/instructions/instruction_set"
require "lib/cpu/instructions/instruction_cache"
require "lib/cpu/register"
require "lib/cpu/ram"

module Patchy
  class CPU

    attr_reader :registers, :ram

    # TODO: Move the clock out of the CPU, since we use it in the instruction
    #       cache, and divide it by 8 for actual CPU-stepping
    @@frequencyHz = 80

    def self.frequency
      @@frequencyHz
    end

    def initialize(debug=false)
      @debug = debug
      @halt = false
      @cycles = 0

      puts "- Initializing CPU" if @debug

      initialize_registers
      initialize_memory
      initialize_modules
    end

    def initialize_registers
      puts "- Initializing registers" if @debug

      @registers = {
        :a => Patchy::CPU::Register16.new,
        :b => Patchy::CPU::Register16.new,
        :c => Patchy::CPU::Register16.new,
        :d => Patchy::CPU::Register16.new,
        :e => Patchy::CPU::Register16.new,
        :f => Patchy::CPU::Register16.new,
        :g => Patchy::CPU::Register16.new,
        :h => Patchy::CPU::Register16.new,

        # Current page in RAM; pages are 64KB in size
        :dp => Patchy::CPU::Register8.new,

        # Stack page pointer; the stack gets a page to itself
        :sp => Patchy::CPU::Register8.new,

        :flgs => Patchy::CPU::Register8.new,
        :pc => Patchy::CPU::Register16.new
      }

      @registers[:a].address = 0x0
      @registers[:b].address = 0x1
      @registers[:c].address = 0x2
      @registers[:d].address = 0x3
      @registers[:e].address = 0x4
      @registers[:g].address = 0x5
      @registers[:g].address = 0x6
      @registers[:h].address = 0x7
      @registers[:dp].address = 0xa
      @registers[:sp].address = 0xb
      @registers[:flgs].address = 0xe
      @registers[:pc].address = 0xf
    end

    def initialize_memory
      puts "- Initializing RAM [#{Patchy::RAM.size} bytes]" if @debug

      @ram = Patchy::RAM.new
    end

    def initialize_modules
      puts "- Initializing instruction cache" if @debug
      @instruction_cache = Patchy::InstructionCache.new self
    end

    def load_instructions(instructions, offset=0)
      address = 0

      instructions.each do |i|
        @ram.write_raw address + offset, (i.opcode << 8) | ((i.dest << 4) | i.src)
        address += 1
        @ram.write_raw address + offset, i.immediate
        address += 1
      end
    end

    def run
      puts "  Starting execution at #{@@frequencyHz}Hz" if @debug
      cycle_max_time = 1.0 / @@frequencyHz

      loop do
        break if @halt
        start = Time.now

        # Cycle execution, with temporal padding
        @@frequencyHz.times do |i|
          cycle_start = Time.now

          # Clock instruction cache
          @instruction_cache.cycle

          # Only perform a CPU op every 8th clock cycle; this gives the
          # instruction cache time to fill and keep up with us
          if i % 8 == 0 and i != 0
            cycle_execute
          end

          # Halt check in here as well
          break if @halt

          # Pad! Note that we sleep with 99% of the needed time, since there
          # is some overhead in doing so (8ms on my MBP)
          cycle_elapsed = Time.now - cycle_start

          if cycle_elapsed < cycle_max_time
            sleep((cycle_max_time - cycle_elapsed) * 0.99)
          end
        end

        elapsed = ((Time.now - start) * 1000000).to_i
        puts "#{elapsed - 1000000}us overrun!" if elapsed > 1000000
      end

    rescue SystemExit, Interrupt
      dump_core
    end

    # The heart of the beast
    def cycle_execute

      ##
      ## I'm too lazy to actually make this super-scalar now, so for the time
      ## being we'll just go with a single execution pathway (and in-place!)
      ##

      # Grab instruction
      instructionRaw = @instruction_cache.instructionA
      immediateRaw = @instruction_cache.immediateA

      # Read it properly! :D
      instruction = Patchy::CPU::Instruction.new(
        opcode: instructionRaw >> 8,
        dest: (instructionRaw >> 4) & 0b000000001111,
        src:  instructionRaw & 0b0000000000001111,
        immediate: immediateRaw
        )

      # For now, just halt when needed
      if instruction.opcode == 0xff
        halt
      end

      inc_pc
      inc_cycles
    end

    def halt
      @halt = true
      puts "  Halted\n\n"
    end

    def inc_cycles
      @cycles += 1
    end

    # NOTE: This advances the PC by two, since instructions are two words!
    def inc_pc
      @registers[:pc].bdata += 2
    end

    def reg_pc
      @registers[:pc].bdata
    end

    def reg_dp
      @registers[:dp].bdata
    end

    # TODO: Provide boundes-checking when setting registers
    def reg_dp=(val)
      @registers[:dp] = val
    end

    def dump_core
      puts generate_core_dump
    end

    def generate_core_dump
      dump = "\n\n"
      dump << "  Registers\n"

      @registers.each do |name, val|
        dump << "    #{name}: 0x#{val.bdata.to_binary_s.unpack('h*')[0]}\n"
      end

      dump << "\n  Ran #{@cycles} cycles"
    end
  end
end
