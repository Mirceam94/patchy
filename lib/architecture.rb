require_relative "arch/instructions.rb"

module Patchy
  class Architecture

    def instructions
      @@instructions
    end

    def instructions_s
      out = "Instructions:\n\n"

      out << @@instructions.map {|i|
        "    #{i[:mnemonic].ljust(6)} #{i[:name].ljust(32)} #{i[:desc]}"
      }.join("\n")
    end

  end
end
