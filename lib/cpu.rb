require "lib/cpu/instruction.rb"
require "lib/cpu/instruction_set.rb"
require "lib/cpu/register.rb"
require "lib/cpu/ram.rb"

module Patchy
  class CPU

    attr_reader :registers, :ram

    def initialize(debug=false)
      @debug = debug

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
  end
end
