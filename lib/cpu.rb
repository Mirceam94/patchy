require "lib/cpu/instructions/instruction"
require "lib/cpu/instructions/instruction_set"
require "lib/cpu/register"
require "lib/cpu/rxm16"
require "lib/cpu/rxm32"

module Patchy
  class CPU

    attr_reader :registers, :ram
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

      puts "- Initializing CPU" if @debug

      initialize_registers
      initialize_ram
      initialize_rom
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

    def initialize_ram
      @ram = Patchy::RXM16.new(0x10000)
      puts "  Patchy RAM initialized [#{@ram.size * 2} bytes]" if @debug
    end

    def initialize_rom
      @rom = Patchy::RXM32.new(0x10000)
      puts "  Patchy ROM initialized [#{@rom.size * 4} bytes]" if @debug
    end

    def load_instructions(instructions, offset=0)
      instructions.each_with_index do |i, address|
        @rom.write(
          address + offset,
          (i.immediate << 16) |
          (i.src << 12) |
          (i.dest << 8) |
          i.opcode
        )
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

    rescue SystemExit, Interrupt
      dump_core
    end

    # The heart of the beast
    def cycle_execute
      ip = @registers[:ip]
      instructionRaw = @rom.read(ip.bdata.snapshot * 1)

      # Read it properly! :D
      instruction = Patchy::CPU::Instruction.new(
        opcode: instructionRaw & 0xFF,
        dest: (instructionRaw >> 8) & 0xF,
        src:  (instructionRaw >> 12) & 0xF,
        immediate: instructionRaw >> 16
      )

      case instruction.opcode
      when 0x00 then exec_op_noop(instruction)
      when 0x01 then exec_op_mv(instruction)
      when 0x02 then exec_op_ldi(instruction)
      when 0x03 then exec_op_ldm(instruction)
      when 0x04 then exec_op_lpx(instruction)
      when 0x05 then exec_op_spx(instruction)
      when 0x06 then exec_op_out(instruction)
      when 0x07 then exec_op_in(instruction)
      when 0x08 then exec_op_str(instruction)
      when 0x09 then exec_op_push(instruction)
      when 0x0A then exec_op_pop(instruction)
      when 0x0B then exec_op_add(instruction)
      when 0x0C then exec_op_sub(instruction)
      when 0x0D then exec_op_cmp(instruction)
      when 0x0E then exec_op_and(instruction)
      when 0x0F then exec_op_or(instruction)
      when 0x10 then exec_op_xor(instruction)
      when 0x11 then exec_op_shl(instruction)
      when 0x12 then exec_op_shr(instruction)
      when 0x13 then exec_op_jmp(instruction)
      when 0x14 then exec_op_breq(instruction)
      when 0x15 then exec_op_brne(instruction)
      when 0x16 then exec_op_brgt(instruction)
      when 0x17 then exec_op_brge(instruction)
      when 0x18 then exec_op_brlt(instruction)
      when 0x19 then exec_op_brle(instruction)
      when 0x1A then exec_op_call(instruction)
      when 0x1B then exec_op_ret(instruction)
      when 0xFF then exec_op_hlt(instruction)
      end

      # Increase cycles now, so our halt message shows the true count if neeed
      inc_cycles

      halt if @needs_halt
      inc_ip if !@halt
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
      when :lt then bit = 0
      when :gt then bit = 1
      when :eq then bit = 2
      when :hlt then bit = 3
      else
        raise "Unknown flag: #{flag}"
      end

      if value
        @registers[:flgs].bdata |= 1 << bit
      else
        @registers[:flgs].bdata &= ~(1 << bit)
      end
    end

    def inc_ip
      @registers[:ip].bdata += 1
    end

    def reg_ip
      @registers[:pc].bdata * 1
    end

    def reg_sp
      @registers[:sp].bdata * 1
    end

    def inc_sp
      @registers[:sp].bdata += 1
    end

    def dec_sp
      @registers[:sp].bdata -= 1
    end

    def reg_dp
      @registers[:dp].bdata * 1
    end

    # TODO: Provide bounds-checking when setting registers
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
        b = val.bdata
        dump << "    #{name}: 0x#{b.to_binary_s.unpack('H*')[0]}"

        if name == :flgs then
          dump << " LT" if (b & 0b1) > 0
          dump << " GT" if (b & 0b10) > 0
          dump << " EQ" if (b & 0b100) > 0
          dump << " HLT" if (b & 0b1000) > 0
          dump << "\n"
        else
          dump << "\n"
        end
      end

      dump << "\n  Ran #{@cycles} cycles"
    end

    ###
    # Instruction implementation follows
    ###
    def exec_op_noop(instruction)
    end

    def exec_op_mv(instruction)
      set_reg_by_address(
        get_reg_by_address(instruction.src),
        instruction.dest
      )
    end

    def exec_op_ldi(instruction)
      set_reg_by_address(instruction.immediate, instruction.dest)
    end

    def exec_op_ldm(instruction)
      ram_value = @ram.read(reg_dp)
      set_reg_by_address(ram_value, instruction.dest)
    end

    def exec_op_lpx(instruction)
    end

    def exec_op_spx(instruction)
    end

    def exec_op_out(instruction)
    end

    def exec_op_in(instruction)
    end

    def exec_op_str(instruction)
      @ram.write(reg_dp, get_reg_by_address(instruction.src))
    end

    def exec_op_push(instruction)
      dec_sp
      @ram.write(reg_sp, get_reg_by_address(instruction.src))
    end

    def exec_op_pop(instruction)
      set_reg_by_address(@ram.read(reg_sp), instruction.dest)
      inc_sp
    end

    def exec_op_add(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(src + dest, instruction.dest)
    end

    def exec_op_sub(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest - src, instruction.dest)
    end

    def exec_op_cmp(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      lt = src < dest
      gt = src > dest
      eq = src == dest

      set_flag(:lt, lt)
      set_flag(:gt, gt)
      set_flag(:eq, eq)
    end

    def exec_op_and(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest & src, instruction.dest)
    end

    def exec_op_or(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest | src, instruction.dest)
    end

    def exec_op_xor(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest ^ src, instruction.dest)
    end

    def exec_op_shl(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest << 1, instruction.dest)
    end

    def exec_op_shr(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(dest >> 1, instruction.dest)
    end

    def exec_op_jmp(instruction)
    end

    def exec_op_breq(instruction)
    end

    def exec_op_brne(instruction)
    end

    def exec_op_brgt(instruction)
    end

    def exec_op_brge(instruction)
    end

    def exec_op_brlt(instruction)
    end

    def exec_op_brle(instruction)
    end

    def exec_op_call(instruction)
    end

    def exec_op_ret(instruction)
    end

    def exec_op_hlt(instruction)
      set_flag(:hlt, true)
      @needs_halt = true
    end

  end
end
