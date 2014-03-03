require "trollop"
require_relative "../architecture.rb"

module Patchy
  class Assembler

    attr_accessor :debug

    def initialize
      @arch = Patchy::Architecture.new
      @debug = false
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

            @arch.instructions.each do |i|
              if /\s*#{i["mnemonic"]}\s*/ =~ line

                parsed = i["op"]

                puts "  - Found i #{i["name"]} in line #{line}" if @debug
                puts "  - Parsed to #{parsed}" if @debug

              end
            end
          end # Line processing
        end #rawLine split

      end
    end

  end
end
