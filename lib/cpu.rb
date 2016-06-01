require "lib/cpu/instructions/instruction"
require "lib/cpu/instructions/instruction_set"
require "lib/cpu/instructions/instruction_cache"
require "lib/cpu/decoder"
require "lib/cpu/register"
require "lib/cpu/ram"

module Patchy
  class CPU

    attr_reader :registers, :ram, :stack_page
    attr_accessor :needs_halt

    # TODO: Move the clock out of the CPU, since we use it in the instruction
    #       cache, and divide it by 8 for actual CPU-stepping
    @@frequencyHz = 8000

    def self.frequency
      @@frequencyHz
    end

    def initialize(debug=false)
      @debug = debug
      @halt = false
      @needs_halt = false
      @cycles = 0
      @stack_page = 0xff

      puts "- Initializing CPU" if @debug

      initialize_registers
      initialize_memory
      initialize_modules
    end

    def initialize_registers
      puts "- Initializing registers" if @debug

      @registers = {

        # General purpose
        :a => Patchy::CPU::Register16.new,
        :b => Patchy::CPU::Register16.new,
        :c => Patchy::CPU::Register16.new,
        :d => Patchy::CPU::Register16.new,
        :e => Patchy::CPU::Register16.new,
        :f => Patchy::CPU::Register16.new,

        # VRAM address
        :px => Patchy::CPU::Register8.new,

        # Various flags (comparison, halt, etc)
        :flgs => Patchy::CPU::Register16.new,

        # Hardware I/O ports, read/write only respectively
        :in1 => Patchy::CPU::Register16.new,
        :in2 => Patchy::CPU::Register16.new,
        :out1 => Patchy::CPU::Register16.new,
        :out2 => Patchy::CPU::Register16.new,

        # RAM address
        :dp => Patchy::CPU::Register16.new,

        # ROM address
        :ip => Patchy::CPU::Register16.new,

        # Return address for CALL
        :ret => Patchy::CPU::Register16.new,

        # Stack pointer (current head)
        :sp => Patchy::CPU::Register16.new
      }

      # Used to address registers in instructions
      @registers[:a].address = 0x0
      @registers[:b].address = 0x1
      @registers[:c].address = 0x2
      @registers[:d].address = 0x3
      @registers[:e].address = 0x4
      @registers[:f].address = 0x5
      @registers[:px].address = 0x6
      @registers[:flgs].address = 0x7
      @registers[:in1].address = 0x8
      @registers[:in2].address = 0x9
      @registers[:out1].address = 0xA
      @registers[:out2].address = 0xB
      @registers[:dp].address = 0xC
      @registers[:ip].address = 0xD
      @registers[:ret].address = 0xE
      @registers[:sp].address = 0xF
    end

    def initialize_memory
      @ram = Patchy::RAM.new
      puts "  Patchy RAM initialized [#{Patchy::RAM.size} bytes]" if @debug
    end

    def initialize_modules
      @instruction_cache = Patchy::InstructionCache.new self
      @decoder = Patchy::Decoder.new self
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

      # Pass instruction into decoder
      # TODO: Implement pipeline
      @decoder.decode instruction

      # Increase cycles now, so our halt message shows the true count if neeed
      inc_cycles

      halt if @needs_halt
      inc_pc if !@halt
    end

    def get_reg_by_address(address)
      @registers.each do |name, reg|
        return reg.bdata if reg.address == address
      end

      raise "Unknown register address #{address}"
    end

    def set_reg_by_address(value, address)
      @registers.each do |name, reg|
        if reg.address == address
          return reg.bdata = value
        end
      end

      raise "Unknown register address #{address}"
    end

    def halt
      @halt = true

      puts "  Halted"
      dump_core
      puts "\n"
    end

    def inc_cycles
      @cycles += 1
    end

    def set_flag(flag, value)
      bit = nil

      case flag
      when :lt then bit = 1
      when :gt then bit = 2
      when :eq then bit = 3
      else
        raise "Unknown flag: #{flag}"
      end

      if value
        @registers[:flgs].bdata |= 1 << bit
      else
        @registers[:flgs].bdata &= ~(1 << bit)
      end
    end

    # NOTE: This advances the PC by two, since instructions are two words!
    def inc_pc
      @registers[:pc].bdata += 2
    end

    def reg_pc
      @registers[:pc].bdata
    end

    def reg_sp
      @registers[:sp].bdata
    end

    def inc_sp
      @registers[:sp].bdata += 1
    end

    def dec_sp
      @registers[:sp].bdata -= 1
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
      dump = "\n"
      dump << "  Registers\n"

      @registers.each do |name, val|
        dump << "    #{name}: 0x#{val.bdata.to_binary_s.unpack('H*')[0]}\n"
      end

      dump << "\n  Ran #{@cycles} cycles"
    end
  end
end
