require "yaml"

module Patchy
  class Assembler

    attr_accessor :debug

    def initialize(debug=false)
      @debug = debug
      @instructions = YAML.load_file("lib/arch/instructions.yaml")
    end

    def assemble(source)
      while(rawLine = source.gets)

        rawLine.delete! "\n"      # String newlines
        rawLine.sub! /\s*#.*/, "" # Strip comments

        # Split line on semicolon to allow support for multiple instructions
        # per line
        rawLine.split(";").each do |line|

          line.strip! # Remove excess whitespace

          if not line.empty?

            puts "Parsing line [#{line}]..." if @debug

            @instructions.each do |i|
              if /\s*#{i[:mnemonic]}\s*/ =~ line

                parsed = i[:op]

                puts "  - Found i #{i[:name]} in line #{line}" if @debug
                puts "  - Parsed to #{parsed}" if @debug

              end
            end
          end # Line processing
        end #rawLine split

      end
    end

  end
end
