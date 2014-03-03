# Todo: Document instruction width

module Patchy
  class Architecture

    @@instructions = []

    # System operations
    @@instructions.push(:name => "No operation", :mnemonic => "nop", :op => 0x00)
    @@instructions.push(:name => "Halt", :mnemonic => "hlt", :op => 0xff)

    # Register/Memory operations
    @@instructions.push(:name => "Move", :mnemonic => "mov", :op => 0x01, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Load immediate", :mnemonic => "ldi", :op => 0x02, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :immediate,
          :name => "immediate"
        }
      ])

    @@instructions.push(:name => "Load RAM", :mnemonic => "ldm", :op => 0x03, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :address,
          :name => "RAM address relative to DP"
        }
      ])

    @@instructions.push(:name => "Store RAM", :mnemonic => "store", :op => 0x04, :args => [
        {
          :type => :address,
          :name => "RAM address relative to DP"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    # Stack operations
    @@instructions.push(:name => "Push register", :desc => "Push register on stack", :mnemonic => "push", :op => 0x05, :args => [
        {
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Push immediate", :desc => "Push immediate on stack", :mnemonic => "pushi", :op => 0x06, :args => [
        {
          :type => :immediate,
          :name => "immediate"
        }
      ])

    @@instructions.push(:name => "Push RAM", :desc => "Push RAM contents on stack", :mnemonic => "pushm", :op => 0x07, :args => [
        {
          :type => :address,
          :name => "RAM address relative to DP"
        }
      ])

    @@instructions.push(:name => "Pop register", :desc => "Pop stack contents into register", :mnemonic => "pop", :op => 0x08, :args => [
        {
          :type => :register,
          :name => "destination"
        }
      ])

    @@instructions.push(:name => "Pop RAM", :desc => "Pop stack contents into RAM", :mnemonic => "popm", :op => 0x09, :args => [
        {
          :type => :address,
          :name => "RAM address relative to DP"
        }
      ])

    # Arithmetic and logic operations
    @@instructions.push(:name => "Add registers", :desc => "Rd = Rd + Rs", :mnemonic => "add", :op => 0x0a, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Add immediate", :desc => "Rd = Rd + I", :mnemonic => "addi", :op => 0x0b, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :immediate,
          :name => "immediate"
        }
      ])

    @@instructions.push(:name => "Subtract registers", :desc => "Rd = Rd - Rs", :mnemonic => "sub", :op => 0x0c, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Subtract immediate", :desc => "Rd = Rd - I", :mnemonic => "subi", :op => 0x0d, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :immediate,
          :name => "immediate"
        }
      ])

    @@instructions.push(:name => "Compare registers", :mnemonic => "cmp", :op => 0x0e, :args => [
        {
          :type => :register,
          :name => "register a"
        },{
          :type => :register,
          :name => "register b"
        }
      ])

    @@instructions.push(:name => "AND registers", :mnemonic => "and", :op => 0x0f, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "OR registers", :mnemonic => "and", :op => 0x10, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "XOR registers", :mnemonic => "and", :op => 0x11, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Shift register left", :mnemonic => "shl", :op => 0x12, :args => [
        {
          :type => :register,
          :name => "target"
        }
      ])

    @@instructions.push(:name => "Shift register right", :mnemonic => "shr", :op => 0x13, :args => [
        {
          :type => :register,
          :name => "target"
        }
      ])

    # Branching operations (operate with addy in reg C)
    @@instructions.push(:name => "Jump", :desc => "Jump to address in register", :mnemonic => "jmp", :op => 0x14, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Jump immediate", :desc => "Jump to immediate address", :mnemonic => "jmpi", :op => 0x15, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if ==", :desc => "Branch if equal to address in register", :mnemonic => "breq", :op => 0x16, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if !=", :desc => "Branch if not equal to address in register", :mnemonic => "brne", :op => 0x17, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if >", :desc => "Branch if greater than to address in register", :mnemonic => "brgt", :op => 0x18, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if >=", :desc => "Branch if greater than or equal to address in register", :mnemonic => "brge", :op => 0x19, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if <", :desc => "Branch if less than to address in register", :mnemonic => "brlt", :op => 0x1a, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch if <=", :desc => "Branch if less than or equal to address in register", :mnemonic => "brle", :op => 0x1b, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if ==", :desc => "Branch if equal to immediate", :mnemonic => "breqi", :op => 0x1c, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if !=", :desc => "Branch if not equal to immediate", :mnemonic => "brnei", :op => 0x1d, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if >", :desc => "Branch if greater than to immediate", :mnemonic => "brgti", :op => 0x1e, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if >=", :desc => "Branch if greater than or equal to immediate", :mnemonic => "brgei", :op => 0x1f, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if <", :desc => "Branch if less than to immediate", :mnemonic => "brlti", :op => 0x20, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Branch immediate if <=", :desc => "Branch if less than or equal to immediate", :mnemonic => "brlei", :op => 0x21, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Call", :desc => "Push PC onto stack, and jump to address in register", :mnemonic => "call", :op => 0x22, :args => [
        {
          :type => :register,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Call immediate", :desc => "Push PC onto stack, and jump to immediate address", :mnemonic => "calli", :op => 0x23, :args => [
        {
          :type => :immediate,
          :name => "target address"
        }
      ])

    @@instructions.push(:name => "Return", :desc => "Alias for pop pc", :mnemonic => "ret", :op => 0x24)

    # Port operations
    @@instructions.push(:name => "Out", :desc => "Write register to port", :mnemonic => "out", :op => 0x25, :args => [
        {
          :type => :port,
          :name => "destination"
        },{
          :type => :register,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "Out immediate", :desc => "Write immediate to port", :mnemonic => "outi", :op => 0x26, :args => [
        {
          :type => :port,
          :name => "destination"
        },{
          :type => :immediate,
          :name => "immediate"
        }
      ])

    @@instructions.push(:name => "Out RAM", :desc => "Write RAM entry to port", :mnemonic => "outm", :op => 0x27, :args => [
        {
          :type => :port,
          :name => "destination"
        },{
          :type => :address,
          :name => "RAM address"
        }
      ])

    @@instructions.push(:name => "In", :desc => "Read port value into register", :mnemonic => "in", :op => 0x28, :args => [
        {
          :type => :register,
          :name => "destination"
        },{
          :type => :port,
          :name => "source"
        }
      ])

    @@instructions.push(:name => "In RAM", :desc => "Read port value into RAM", :mnemonic => "inm", :op => 0x29, :args => [
        {
          :type => :address,
          :name => "RAM destination"
        },{
          :type => :port,
          :name => "source"
        }
      ])

  end
end
