require "lib/cpu/instructions/instruction"
require "lib/cpu/instructions/instruction_set"
require "lib/cpu/register"
require "lib/cpu/rxm16"
require "lib/cpu/rxm32"

module Patchy
  class CPU

    attr_reader :registers, :ram
    attr_accessor :needs_halt

    def initialize(debug=false)
      @debug = debug
      @halt = false
      @needs_halt = false
      @cycles = 0
      @renderer = nil

      puts "- Initializing CPU" if @debug

      initialize_ram
      initialize_rom
      initialize_registers
      initialize_instruction_debug_table
      initialize_register_debug_table
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

      @register_name_hash = get_register_name_hash

      # Set up register addresses
      @register_name_hash.each do |key, val|
        @registers[key].address = val
      end

      # Init stack pointer at end of RAM
      @registers[:sp].bdata = @ram.size
    end

    def get_register_name_hash
      {
        :a => 0x0,
        :b => 0x1,
        :c => 0x2,
        :d => 0x3,
        :e => 0x4,
        :f => 0x5,
        :px => 0x6,
        :flgs => 0x7,
        :in1 => 0x8,
        :in2 => 0x9,
        :out1 => 0xA,
        :out2 => 0xB,
        :dp => 0xC,
        :ip => 0xD,
        :ret => 0xE,
        :sp => 0xF
      }
    end

    def initialize_ram
      @ram = Patchy::RXM16.new(0x10000)
      puts "  Patchy RAM initialized [#{@ram.size * 2} bytes]" if @debug
    end

    def initialize_rom
      @rom = Patchy::RXM32.new(0x10000)
      puts "  Patchy ROM initialized [#{@rom.size * 4} bytes]" if @debug
    end

    ###
    # Sets up a table for easy opcode -> mnemonic + args str conversion
    ###
    def initialize_instruction_debug_table
      @instruction_debug_table = {}

      @@instructions.each do |i|
        @instruction_debug_table[i[:op]] = {
          :mnemonic => i[:mnemonic],
          :args => i[:args]
        }
      end
    end

    ###
    # Sets up a table for easy register address -> name conversion
    ###
    def initialize_register_debug_table
      @register_debug_table = get_register_name_hash.invert
    end

    ###
    # Generates a string representation of the provided instruction object
    #
    # @param {Instruction} instruction
    # @return {String} str
    ###
    def gen_debug_instruction_string(instruction)
      instr_def = @instruction_debug_table[instruction.opcode]
      instruction_s = instr_def[:mnemonic]

      if instr_def[:args]
        instr_def[:args].each_with_index do |arg, i|
          if i > 0
            instruction_s += ","
          end

          if arg[:type] == "register"
            if arg[:name].include?("address")
              instruction_s += " #{@register_debug_table[instruction.dest]}"
            elsif arg[:name] == "source"
              instruction_s += " #{@register_debug_table[instruction.src]}"
            elsif arg[:name] == "destination"
              instruction_s += " #{@register_debug_table[instruction.dest]}"
            end
          elsif arg[:type] == "immediate"
            instruction_s += " 0x#{(instruction.immediate + 0).to_s(16)}"
          else
            instruction_s += " {UNKNOWN ARG TYPE}"
          end
        end
      end

      instruction_s
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
      loop do

        # Update in/out registers
        if !@renderer_output_q.empty?
          handle_renderer_packet(@renderer_output_q.pop)
        end

        cycle_execute

        # Halt check
        break if @halt
      end

    rescue Exception
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

      if @debug
        puts "Exec [#{@cycles}] #{gen_debug_instruction_string(instruction)}"
      end

      case instruction.opcode
      when 0x00 then exec_op_noop(instruction)
      when 0x01 then exec_op_mv(instruction)
      when 0x02 then exec_op_ldi(instruction)
      when 0x03 then exec_op_ldm(instruction)
      when 0x04 then exec_op_lpx(instruction)
      when 0x05 then exec_op_spx(instruction)
      when 0x06 then exec_op_str(instruction)
      when 0x07 then exec_op_push(instruction)
      when 0x08 then exec_op_pop(instruction)
      when 0x09 then exec_op_add(instruction)
      when 0x0A then exec_op_addi(instruction)
      when 0x0B then exec_op_sub(instruction)
      when 0x0C then exec_op_subi(instruction)
      when 0x0D then exec_op_cmp(instruction)
      when 0x0E then exec_op_and(instruction)
      when 0x0F then exec_op_or(instruction)
      when 0x10 then exec_op_xor(instruction)
      when 0x11 then exec_op_shl(instruction)
      when 0x12 then exec_op_shr(instruction)
      when 0x13 then exec_op_jmp(instruction)
      when 0x14 then exec_op_je(instruction)
      when 0x15 then exec_op_jne(instruction)
      when 0x16 then exec_op_jg(instruction)
      when 0x17 then exec_op_jge(instruction)
      when 0x18 then exec_op_jl(instruction)
      when 0x19 then exec_op_jle(instruction)
      when 0x1A then exec_op_jz(instruction)
      when 0x1B then exec_op_jnz(instruction)
      when 0x1C then exec_op_call(instruction)
      when 0x1D then exec_op_calli(instruction)
      when 0x1E then exec_op_ret(instruction)
      when 0xFF then exec_op_hlt(instruction)
      end

      # Increase cycles now, so our halt message shows the true count if neeed
      inc_cycles

      halt if @needs_halt
      inc_ip if !@halt
    end

    def get_reg_by_address(address)
      @registers.each do |name, reg|
        return reg.bdata + 0 if reg.address == address
      end

      raise "Unknown register address #{address}"
    end

    def set_reg_by_address(address, value)
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

    ###
    # Routes renderer data packets to their respective handlers
    #
    # @param {Map} packet
    ###
    def handle_renderer_packet(packet)
      case packet[:cmd]
      when :btn_down then handle_renderer_btn_down(packet)
      when :btn_up then handle_renderer_btn_up(packet)
      end
    end

    ###
    # Sets the corresponding bits in the input registers based on the pressed
    # button.
    #
    # @param {Map} packet
    ###
    def handle_renderer_btn_down(packet)
      bit = nil

      case packet[:id]
      when :w then bit = 0
      when :s then bit = 1
      when :esc then bit = 2
      end

      return if bit.nil?

      @registers[:in1].bdata |= 1 << bit
    end

    ###
    # Clears the corresponding bits in the input registers based on the pressed
    # button.
    #
    # @param {Map} packet
    ###
    def handle_renderer_btn_up(packet)
      bit = nil

      case packet[:id]
      when :w then bit = 0
      when :s then bit = 1
      when :esc then bit = 2
      end

      return if bit.nil?

      @registers[:in1].bdata &= ~(1 << bit)
    end

    def set_flag(flag, value)
      bit = nil

      case flag
      when :lt then bit = 0
      when :gt then bit = 1
      when :eq then bit = 2
      when :hlt then bit = 3
      when :ze then bit = 4
      else
        raise "Unknown flag: #{flag}"
      end

      if value
        @registers[:flgs].bdata |= 1 << bit
      else
        @registers[:flgs].bdata &= ~(1 << bit)
      end
    end

    def get_flag(flag)
      flgs = @registers[:flgs].bdata

      case flag
      when :lt then return (flgs & 0b1) > 0
      when :gt then return (flgs & 0b10) > 0
      when :eq then return (flgs & 0b100) > 0
      when :hlt then return (flgs & 0b1000) > 0
      when :ze then return (flgs & 0b10000) > 0
      end

      raise "Unknown flag: #{flag}"
    end

    def set_renderer_input_q(renderer_input_q)
      @renderer_input_q = renderer_input_q
    end

    def set_renderer_output_q(renderer_output_q)
      @renderer_output_q = renderer_output_q
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

    def jmp_to_reg_by_address(address)
      dest = get_reg_by_address(address)

      set_reg_by_address(@register_name_hash[:ip], dest - 1)
    end

    ###
    # Updates the zero flag automatically based on the provided ALU result, and
    # returns it.
    #
    # @param {Number} res
    # @return {Number} res
    ###
    def flag_safe_alu_op(res)
      if res == 0
        set_flag(:ze, true)
      else
        set_flag(:ze, false)
      end

      res
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
        instruction.dest,
        get_reg_by_address(instruction.src)
      )
    end

    def exec_op_ldi(instruction)
      set_reg_by_address(instruction.dest, instruction.immediate)
    end

    def exec_op_ldm(instruction)
      ram_value = @ram.read(reg_dp)
      set_reg_by_address(instruction.dest, ram_value)
    end

    def exec_op_lpx(instruction)
    end

    def exec_op_spx(instruction)
      return if @renderer_input_q == nil

      col = get_reg_by_address(instruction.src)
      address = get_reg_by_address(0x6) # 0x6 = PX

      # Derive xy coords from the VRAM address
      x = address / 16
      y = address % 16

      @renderer_input_q.set_px(x, y, col)
    end

    def exec_op_str(instruction)
      @ram.write(reg_dp, get_reg_by_address(instruction.src))
    end

    def exec_op_push(instruction)
      dec_sp
      @ram.write(reg_sp, get_reg_by_address(instruction.src))
    end

    def exec_op_pop(instruction)
      set_reg_by_address(instruction.dest, @ram.read(reg_sp))
      inc_sp
    end

    def exec_op_add(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest + src)
      )
    end

    def exec_op_addi(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest + instruction.immediate)
      )
    end

    def exec_op_sub(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest, 
        flag_safe_alu_op(dest - src)
      )
    end

    def exec_op_subi(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest - instruction.immediate)
      )
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

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest & src)
      )
    end

    def exec_op_or(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest | src)
      )
    end

    def exec_op_xor(instruction)
      src = get_reg_by_address(instruction.src)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest ^ src)
      )
    end

    def exec_op_shl(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest << 1)
      )
    end

    def exec_op_shr(instruction)
      dest = get_reg_by_address(instruction.dest)

      set_reg_by_address(
        instruction.dest,
        flag_safe_alu_op(dest >> 1)
      )
    end

    def exec_op_jmp(instruction)
      dest = get_reg_by_address(instruction.dest)

      # IP is immediately incremented
      set_reg_by_address(@register_name_hash[:ip], dest - 1)
    end

    def exec_op_je(instruction)
      return if !get_flag(:eq)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jne(instruction)
      return if get_flag(:eq)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jg(instruction)
      return if !get_flag(:gt)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jge(instruction)
      return if get_flag(:gt)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jl(instruction)
      return if !get_flag(:lt)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jle(instruction)
      return if get_flag(:lt)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jz(instruction)
      return if !get_flag(:ze)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_jnz(instruction)
      return if !get_flag(:ze)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_call(instruction)
      dec_sp
      @ram.write(reg_sp, get_reg_by_address(@register_name_hash[:ip]) + 1)

      jmp_to_reg_by_address(instruction.dest)
    end

    def exec_op_calli(instruction)
      dec_sp
      @ram.write(reg_sp, get_reg_by_address(@register_name_hash[:ip]) + 1)

      # IP is immediately incremented
      set_reg_by_address(@register_name_hash[:ip], instruction.immediate - 1)
    end

    def exec_op_ret(instruction)
      address = @ram.read(reg_sp)
      inc_sp

      # IP is immediately incremented
      set_reg_by_address(@register_name_hash[:ip], address - 1)
    end

    def exec_op_hlt(instruction)
      set_flag(:hlt, true)
      @needs_halt = true
    end

  end
end
