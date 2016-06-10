ldi D, 6     # Initial player paddle Y coord
ldi E, 6     # Initial CPU paddle Y coord

ldi c, 0b001 # Draw color

# Draw player paddle with x = 1
ldi a, 1
mov b, d
calli [draw_paddle]

# Draw CPU paddle with x = 14
ldi a, 14
mov b, e
calli [draw_paddle]

main_loop:

  # Check/handle W keypress
  ldi a, [_check_s_keypress]
  ldi f, 0b001
  and f, in1
  jz a
  calli [handle_w_press]

_check_s_keypress:

  # Check/handle S keypress
  ldi a, [_check_esc_keypress]
  ldi f, 0b010
  and f, in1
  jz a
  calli [handle_s_press]

_check_esc_keypress:

  # Check/handle ESC keypress
  ldi a, [_do_loop]
  ldi f, 0b100
  and f, in1
  jz a
  calli [handle_esc_press]

_do_loop:

  ldi f, [main_loop]
  jmp f

hlt

# Moves the player's paddle down by 1px if possible, and clears the pixel
# immediately above it
handle_w_press:
  push a
  push b
  push c
  push f

  ldi f, [_done_handling_w]

  addi d, 0
  jz f        # Paddle already at the top, can't go further

  # Unset bottom paddle pixel
  ldi a, 1
  mov b, d
  addi b, 2
  ldi c, 0
  calli [resolve_px]
  spx c

  # Move paddle up
  subi d, 1

  # Set new paddle top pixel
  subi px, 3
  ldi c, 0b001 # draw color
  spx c

  _done_handling_w:
    pop f
    pop c
    pop b
    pop a
    ret

# Moves the player's paddle up by 1px if possible, and clears the pixel
# immediately below it
handle_s_press:
  push a
  push b
  push c
  push f

  ldi f, [_done_handling_s]

  ldi a, 0xd
  cmp a, d
  je f # Paddle already at the bottom, can't go further

  # Unset top paddle pixel
  ldi a, 1
  mov b, d
  ldi c, 0
  calli [resolve_px]
  spx c

  # Move paddle down
  addi d, 1

  # Set new paddle bottom pixel
  addi px, 3
  ldi c, 0b001 # draw color
  spx c

  _done_handling_s:
    pop f
    pop c
    pop b
    pop a
    ret

# Stops everything! :D
handle_esc_press:
  hlt
  ret # Just to be sure. One can never be sure.

# Draws a 1x3 paddle at the coords in A, B with the color in C
#
# @param {A} x coord
# @param {B} y coord
# @param {C} color
draw_paddle:
  push PX

  calli [resolve_px]
  spx C
  addi PX, 1
  spx C
  addi PX, 1
  spx C

  pop PX
  ret

# Sets the PX reg to target a specific x, y screen coordinate
# (B * 16) + [A + 1] -> PX
#
# @param {A} x coord
# @param {B} y coord
resolve_px:
  push C
  push E
  push F
  
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

    pop F
    pop E
    pop C

    ret
