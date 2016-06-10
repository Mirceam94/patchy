Patchy: 16bit CPU
=================

Originally a toy project, this repo now serves as a simulator for a custom CPU
built from 74-series TTL ICs. Assembler included :D

Patchy's structure is still in flux, as the physical CPU is not yet built.
Planned features are:

* 16x16 RGB LED matrix display w/ dedicated VRAM and driver circuitry
* 20x2 character LCD (standard interface, 8-bit bus)
* PS/2 keyboard input
* UART for serial communication

## Architecture
* 16bit data bus (wordsize)
* 16bit RAM address bus (64K RAM max)
* 16bit ROM address bus (64K ROM max)
* Seperate ROM/RAM buses (Harvard architecture)
* 16bit ALU, no hardware multiplier
* 16 registers
  - 0x0 A: general purpose
  - 0x1 B: general purpose
  - 0x2 C: general purpose
  - 0x3 D: general purpose
  - 0x4 E: general purpose
  - 0x5 F: general purpose
  - 0x6 PX: VRAM address, 8bit
  - 0x7 FLGS: various flags, read-only
  - 0x8 IN1: input port, read-only
  - 0x9 IN2: input port, read-only
  - 0xA OUT1: output port, write-only
  - 0xB OUT2: output port, write-only
  - 0xC DP: RAM address
  - 0xD IP: ROM address, read-only
  - 0xE RET: return address, used for CALL
  - 0xF SP: stack pointer

All general purpose registers are available for ALU and memory operations.

## General info
This computer is a hobby project, and is primarily being built to host a simple
Pong game. However, since the physical construction will take quite some time,
I've designed the architecture to support more complex programs in the future.

This readme will be updated as the architecture is fleshed out.

## Instruction structure (32bit wide)
* 8 bit opcode (Highest 3 bits currently unused)
* 4 bit destination
* 4 bit source
* 16 bit immediate

The above allows for Patchy to have up to 256 instructions, and access up to 16
registers. Currently there are 31 instructions, but this leaves plenty of room
for expansion. For the time being there are no immediate/RAM specialised
instructions beyond Register<->RAM/I interaction, but in the future there is
plenty of room left over for things like ADDI, INM, STRI, etc.

## Instruction set
* 0x00 nop          No operation
* 0x01 mov Rd, Rs   Copy Rs value into Rd
* 0x02 ldi Rd, I    Load immediate value into Rd
* 0x03 ldm Rd       Load RAM value into Rd (address set by DP)
* 0x04 lpx Rd       Reads current VRAM value at the address in PX into Rd
* 0x05 spx Rs       Loads bottom 3 bits of Rs into VRAM at the address in PX
* 0x06 str Rs       Copy value in Rs into RAM (address set by DP)
* 0x07 push Rs      Push Rs register value onto stack, decrement SP
* 0x08 pop Rd       Pop top stack value into Rd, increment SP
* 0x09 add Rd, Rs   Rd = Rd + Rs
* 0x0A addi Rd, I   Rd = Rd + I
* 0x0B sub Rd, Rs   Rd = Rd - Rs
* 0x0C subi Rd, I   Rd = Rd - I
* 0x0D cmp Ra, Rb   Compare Ra and Rb, updates FLGS register
* 0x0E and Rd, Rs   Rd = Rd & Rs
* 0x0F or Rd, Rs    Rd = Rd | Rs
* 0x10 xor Rd, Rs   Rd = Rd ^ Rs
* 0x11 shl Rd       Shifts Rd left in place
* 0x12 shr Rd       Shifts Rd right in place
* 0x13 jmp Ra       Jumps to address in Ra
* 0x14 je Ra        Jump if == to address in Ra
* 0x15 jne Ra       Jump if != to address in Ra
* 0x16 jg Ra        Jump if >  to address in Ra
* 0x17 jge Ra       Jump if >= to address in Ra
* 0x18 jl Ra        Jump if <  to address in Ra
* 0x19 jle Ra       Jump if <= to address in Ra
* 0x1A jz Ra        Jump if 0 to address in Ra
* 0x1B jnz Ra       Jump if !0 to the address in Ra
* 0x1C call Ra      Push IP onto stack, and jump to address in Ra
* 0x1D calli I      Push IP onto stack, and jump to immediate address
* 0x1E ret          Alias for pop IP
* 0xFF hlt          Halt
