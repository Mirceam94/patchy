require "yaml"
require "lib/cpu"

module Patchy
  class Assembler

    attr_accessor :debug

    def initialize(debug=false)
      @debug = debug
      @cpu = Patchy::CPU.new debug
    end

    def assemble(source)
      program_instructions = process_source(source)
      display_summary(program_instructions)
      program_instructions
    end

    def display_summary(instructions)
      puts generate_summary(instructions)
    end

    def generate_summary(instructions)
      "\n" <<
      "  Read #{instructions.length} instructions\n" <<
      "  Program size #{instructions.length * 4} bytes\n" <<
      "\n"
    end

    def process_source(source)
      instructions = []

      while(rawLine = source.gets)

        rawLine.delete! "\n"      # String newlines
        rawLine.sub! /\s*#.*/, "" # Strip comments

        # Split line on semicolon to allow support for multiple instructions
        # per line
        rawLine.split(";").each do |line|

          line.strip! # Remove excess whitespace

          if not line.empty?

            puts "Parsing line [#{line}]..." if @debug

            instructions.push parse_line line
          end
        end
      end

      instructions
    end

    def parse_line(line)
      Patchy::CPU.instructions.each do |i|
        if /\s*#{i[:mnemonic]}\s*/ =~ line

          src = 0x0
          dest = 0x0
          immediate = 0x0

          # Because instructions can take up to two arguments, and the
          # first is always a destination while the second is always
          # a source, we can find them manually.
          if i[:args]
            if i[:args][0]
              type = i[:args][0][:type]
              name = i[:args][0][:name]

              arg_raw = read_src_arg(line)
              arg = process_arg(arg_raw, type, name)

              if type == "register"
                src = arg
              elsif ["address", "port", "immediate"].include? type
                immediate = arg
              end
            end

            if i[:args][1]
              type = i[:args][1][:type]
              name = i[:args][1][:name]

              arg_raw = read_dest_arg(line)
              arg = process_arg(arg_raw, type, name)

              if type == "register"
                dest = arg
              elsif ["address", "port", "immediate"].include? type
                immediate = arg
              end
            end
          end

          bin_ins = Patchy::CPU::Instruction.new(
            :opcode => i[:op],
            :dest => dest,
            :src => src,
            :immediate => immediate
            )

          puts "  - Found #{i[:mnemonic]} in line #{line}" if @debug
          puts "  - Parsed to 0x#{bin_ins.to_binary_s.unpack('h*')[0]}" if @debug
          puts "    - #{bin_ins}" if @debug

          # Return the first instruction matched
          return bin_ins
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
      reg = @cpu.registers[arg.to_sym]

      if not reg
        raise "Invalid register provided: #{arg}"
      end

      reg.address
    end

    # Addresses are always into RAM
    def process_arg_address(arg)
      address = read_number(arg)

      if address < 0
        raise "Can't have negative addresses: #{address}"
      end

      # We force the highest page to make sure we don't over-run memory
      if not @cpu.ram.bounds_check(0xff, address)
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
