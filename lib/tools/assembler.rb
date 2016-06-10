require "yaml"
require "lib/cpu"

module Patchy
  class Assembler

    attr_accessor :debug

    def initialize(debug=false)
      @debug = debug
      @cpu = Patchy::CPU.new debug
    end

    ###
    # Renders a summary of the work done for the provided instructions,
    # including information on program size.
    #
    # @param {Array<Instruction>} instructions
    ###
    def display_summary(instructions)
      puts generate_summary(instructions)
    end

    ###
    # Generates a string summary of the provided program
    #
    # @param {Array<Instruction>} instructions
    ###
    def generate_summary(instructions)
      "\n" <<
      "  Read #{instructions.length} instructions\n" <<
      "  Program size #{instructions.length * 4} bytes\n" <<
      "\n"
    end

    ###
    # Assembles a multi-line string source file and returns an array of the
    # final instructions
    #
    # @param {String} source
    # @return {Array<Instruction>} instructions
    ###
    def assemble(source)

      # Strip comments and clean up lines, generate an array of code
      lines = []

      while(rawLine = source.gets)
        rawLine = rawLine[0...rawLine.index("#")] if rawLine.include?("#")
        rawLine.strip!

        # Split line on semicolon to allow support for multiple instructions
        # per line
        if !rawLine.empty?
          rawLine.split(";").each { |line| lines.push(line) }
        end
      end

      # Initially assemble with placeholder addresses, and keep track of them
      pending_adr_changes = []
      instructions = []
      call_table = {}

      lines.each_with_index do |line, i|
        puts "Parsing line [#{line}]..." if @debug

        # Handle labels
        if line[-1] == ":"
          label = line[0...-1].to_sym

          if call_table.has_key?(label)
            raise "Error, duplicate label found in source: #{label}"
          end

          call_table[label] = instructions.length
        else
          needs_address_change = false
          label = nil

          # Deref address if possible
          if line.include?("[") and line.include?("]")
            derefed, label, success = convert_address(line, call_table)

            # May be nil if we don't know the address yet
            if !success
              needs_address_change = true
            else
              line = derefed
            end
          end

          # Assemble and properly handle complex instructions
          assembled = assemble_instruction_str(line)
          assembled.each { |instr| instructions.push(instr) }

          # For the time being, only instructions at the end of a compiled line
          # sub-prog need address changes (see CALL assembly)
          if needs_address_change and !label.nil?
            pending_adr_changes.push({
              :i => instructions.length - 1,
              :label => label
            })
          end
        end
      end

      # Go back and fill in addresses
      pending_adr_changes.each do |data|
        instructions[data[:i]].immediate = call_table[data[:label]]
      end

      instructions
    end

    ###
    # Parses [LABEL] references to the exact address, as provided by a call
    # table
    #
    # @param {String} line
    # @param {Map} call_table
    # @return {String, Symbol, Bool} converted, label, success
    ###
    def convert_address(line, call_table)
      left = line.index("[")
      right = line.index("]")
      label = line[left + 1...right].to_sym

      # If we don't have an entry for the provided label, return it as-is to
      # be filled in later
      if !call_table.has_key?(label)
        return line.sub("[#{label.to_s}]", "").insert(left, "0"), label, false
      else
        adr = call_table[label]

        return line.sub("[#{label.to_s}]", "").insert(left, adr.to_s), label, true
      end
    end

    ###
    # Parses the provided string instruction and returns its assembled binary
    #
    # @param {String} line
    # @return {Instruction} instruction
    ###
    def assemble_instruction_str(line)
      Patchy::CPU.instructions.each do |i|
        if /\b#{i[:mnemonic]}\b/ =~ line
          src = 0x0
          dest = 0x0
          immediate = 0x0

          args_s = line.sub(i[:mnemonic], "").strip
          args = args_s.split(",").map { |a| a.strip }

          # Because instructions can take up to two arguments, and the
          # first is always a destination while the second is always
          # a source, we can find them manually.
          if i[:args]
            if i[:args][0] and args[0]
              type = i[:args][0][:type]
              name = i[:args][0][:name]

              arg = process_arg(args[0], type, name)

              if type == "register"
                if name == "source"
                  src = arg
                else
                  dest = arg
                end
              elsif ["address", "port", "immediate"].include? type
                immediate = arg
              end
            end

            if i[:args][1] and args[1]
              type = i[:args][1][:type]
              name = i[:args][1][:name]

              arg = process_arg(args[1], type, name)

              if type == "register"
                if name == "source"
                  src = arg
                else
                  dest = arg
                end
              elsif ["address", "port", "immediate"].include? type
                immediate = arg
              end
            end
          end

          bin_ins = Patchy::CPU::Instruction.new(
            opcode: i[:op],
            dest: dest,
            src: src,
            immediate: immediate
          )

          if @debug
            puts "  - Found #{i[:mnemonic]} in line #{line}"
            puts "  - Parsed to 0x#{bin_ins.to_binary_s.unpack('h*')[0]}"
            puts "    - #{bin_ins}"
          end

          # Return the first instruction matched
          return [bin_ins]
        end
      end
    end

    def read_src_arg(line)
      src = line[/\s*(\S*),/]

      if src
        src.delete! ","
        src.strip!
      end

      src
    end

    def read_dest_arg(line)
      dest = line[/,.*(;|\s*)/]

      if dest
        dest.delete! ";"
        dest.delete! ","
        dest.strip!
      end

      dest
    end

    ###
    # Returns the CPU address of the provided register
    #
    # @param {Symbol} reg register name, lowercase
    # @return {Number} address
    ###
    def get_reg_address(name)
      reg = @cpu.registers[name]

      if not reg
        raise "Invalid register provided: #{name}"
      end

      reg.address
    end

    def process_arg(arg, type, name)
      if not arg
        raise "Required argument missing!\n[#{type} - #{name}]"
      end

      case type
      when "register" then process_arg_register(arg)
      when "address" then process_arg_address(arg)
      when "immediate" then process_arg_immediate(arg)
      when "port" then process_arg_port(arg)
      else
        raise "[Internal Error] Unknown argument type: #{type}"
      end
    end

    def process_arg_register(arg)
      arg.downcase!

      get_reg_address(arg.to_sym)
    end

    # Addresses are always into RAM
    def process_arg_address(arg)
      address = read_number(arg)

      if address < 0
        raise "Can't have negative addresses: #{address}"
      end

      if not @cpu.ram.bounds_check(address)
        raise "Out-of-bounds address: #{address}"
      end
    end

    def process_arg_immediate(arg)
      immediate = read_number(arg)

      # Immediates must be 16bit values
      if immediate < 0 or immediate > 0xffff
        raise "Invalid immediate (must be between 0 and 0xffff): #{immediate}"
      end

      immediate
    end

    # OUTDATED, no longer accurate
    def process_arg_port(arg)
      port = read_number(arg)

      # We have 256 ports, so the port must be a valid 8bit value
      if port < 0 or port > 0xff
        raise "Invalid port (must be between 0 and 0xff): #{port}"
      end

      port
    end

    # This is a but ugly, but we need to detect the base in order to decode
    # numbers properly
    def read_number(str_num)
      if str_num.include?("b")
        str_num.to_i(2)
      elsif str_num.include?("x")
        str_num.to_i(16)
      elsif str_num[0] == "0"
        str_num.to_i(8)
      else
        str_num.to_i(10)
      end
    end
  end
end
