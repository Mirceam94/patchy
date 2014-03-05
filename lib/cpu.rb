require "lib/cpu/instruction.rb"
require "lib/cpu/instruction_set.rb"
require "lib/cpu/register.rb"
require "lib/cpu/ram.rb"

module Patchy
  class CPU

    attr_reader :registers, :ram

    @@frequencyHz = 10

    def self.frequency
      @@frequencyHz
    end

    def initialize(debug=false)
      @debug = debug
      @halt = false

      puts "- Initializing CPU" if @debug

      initialize_registers
      initialize_memory
    end

    def initialize_registers
      puts "- Initializing registers" if @debug

      @registers = {
        :a => Patchy::CPU::Register16.new(0x0),
        :b => Patchy::CPU::Register16.new(0x1),
        :c => Patchy::CPU::Register16.new(0x2),
        :d => Patchy::CPU::Register16.new(0x3),
        :e => Patchy::CPU::Register16.new(0x4),
        :f => Patchy::CPU::Register16.new(0x5),
        :g => Patchy::CPU::Register16.new(0x6),
        :h => Patchy::CPU::Register16.new(0x7),

        # Current page in RAM; pages are 64KB in size
        :dp => Patchy::CPU::Register8.new(0xa),

        # Stack page pointer; the stack gets a page to itself
        :sp => Patchy::CPU::Register8.new(0xb),

        :flgs => Patchy::CPU::Register8.new(0xe),
        :pc => Patchy::CPU::Register16.new(0xf)
      }
    end

    def initialize_memory
      puts "- Initializing RAM [#{Patchy::RAM.size} bytes]" if @debug

      @ram = Patchy::RAM.new
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
      cycle_max_time = 1.0 / @@frequencyHz

      loop do
        break if @halt
        start = Time.now

        # Cycle execution, with temporal padding
        @@frequencyHz.times do
          cycle_start = Time.now

          cycle_execute

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
    end

    # The heart of the beast
    def cycle_execute
      @halt = true
    end
  end
end
