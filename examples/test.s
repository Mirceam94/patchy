ldi A, 1
ldi B, 6
calli [resolve_px]
ldi A, 0b001
spx A
addi PX, 1
spx A
addi PX, 1
spx A
hlt

# Sets the PX reg to target a specific x, y screen coordinate
# (B * 16) + [A + 1] -> PX
#
# @param {A} x coord
# @param {B} y coord
resolve_px:
  
  # Load up addresses, we don't yet support jumping to immediate
  ldi E, [_end_mul_resolve_px]
  ldi F, [_do_mul_resolve_px]

  # First, resolve X, Y start position
  # Start by resolving column memory address
  xor C, C                    # Zero out reg C to use as column address
  addi A, 0                   # Touch ALU to set zero flag
  jz E                        # If A (x coord) is 0, continue

  _do_mul_resolve_px:
    addi C, 0x10                 # Advance column by 1 (2 bytes)
    subi A, 1                   # Decrement reg A
    jz E                        # If A is 0, finish
    jmp F                       # else, repeat

  # At this point, reg A points to the first pixel in the requested column
  _end_mul_resolve_px:
    add C, B      # Add Y coord to select target pixel in column
    mov PX, C     # Copy A into pixel address reg
    ret
