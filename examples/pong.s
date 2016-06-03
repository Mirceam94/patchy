; The display consists of 256 individual RGB LEDs, organised in a 16x16 grid
; 3 bits are used per LED, in the format 0bRGB:
; 0b001: blue
; 0b110: red, green
; etc ...
;
; 3*256 = 768 bits = 96 bytes required to represent the entire display
; 6 bytes per column, 16 columns
;
; PX - register used for pixel address into VRAM
;
; lpx <reg> - load bottom 3 bits of reg into current pixel address
; mpx <reg> - read current pixel value into bottom 3 bits of reg
; fsp - framebuffer swap, switches active framebuffer

; Draws a paddle, performs no sanity/bounds checks
;
; @param {B} color
; @param {C} x coord
; @param {D} y coord
draw_paddle:
  call resolve_px ; Sets up PX

  ; Set pixels to the requested color
  lpx B
  inc PX
  lpx B
  inc PX
  lpx B

  ret

; Draw the ball
;
; @param {B} color
; @param {C} x coord
; @param {D} y coord
draw_ball:
  call set_px
  ret

; Set a pixel to a specific color
;
; @param {B} color
; @param {C} x coord
; @param {D} y coord
set_px:
  call resolve_px ; Sets up PX

  lpx B

  ret

; Sets the PX reg to target a specific x, y screen coordinate
; ([SP] * 16) + [SP + 1] -> PX
;
; @param {C} x coord
; @param {D} y coord
resolve_px:

  ; First, resolve X,Y start position
  ; Start by resolving column memory address
  xor A, A               ; Zero out reg A to use as column address
  jz C, _end_mul_resolve_px ; If C (x coord) is 0, continue

_do_mul_resolve_px:
  addi A, 0xf            ; Advance column by 1 (2 bytes)
  dec  C                 ; Decrement reg C
  jz C, _end_mul_resolve_px ; If C is 0, finish
  jmp _do_mul_resolve_px    ; else, repeat

  ; At this point, reg A points to the first pixel in the requested column
_end_mul_resolve_px:
  add A, D      ; Add Y coord to select target pixel in column
  mov PX, A     ; Copy A into pixel address reg
  ret

; Start of the actual pong game (no frame speed limitation, very naive!)
;
; E - stores paddle y-coords for both players as 0bAAAABBBB (players A & B)
; F - stores ball x, y-coords as 0bXXXXYYYY
; G - stores ball velocity vector as 0bUR
;     0b00: down + left
;     0b01: down + right
;     0b10: up + left
;     0b11: up + right
main:
  ldi E, 0b01100110 ; Both players start at y-coord 6 ((16/2) - 2)
  ldi F, 0b01110111 ; Center the ball at (7, 7)

_do_loop:
  mov C, IN         ; Read input register

__check_player_a_down:
  mov A, C
  andi A, 0b1       ; Mask player A down button
  jz A, __check_player_a_up
  call move_player_a_down

__check_player_a_up:
  mov A, C
  andi A, 0b10      ; Mask player A up button
  jz A, __check_player_b_down
  call move_player_a_up

__check_player_b_down:
  mov A, C
  andi A, 0b100     ; Mask player B down button
  jz A, __check_player_b_up
  call move_player_b_down

__check_player_b_up:
  mov A, C
  andi A, 0b1000    ; Mask player B up button
  jz A, _do_ball_v_coll
  call move_player_b_up

; Handle vertical ball (non-player) collisions
_do_ball_v_coll:
  mov A, F
  mov B, G

  andi A, 0b00001111 ; Grab only the Y coords
  andi B, 0b10       ; Grab vertical velocity

  jnz A, __check_ball_bottom_coll ; Ball isn't at the top of the col -> skip
  jz B, __check_ball_bottom_coll  ; Ball isn't moving upwards -> skip

  ; At this point, the ball is both at the top of the screen, and still rising
  andi G, 0b01        ; Zero out the vertical component, keep horizontal
  jmp _do_ball_h_coll ; Check for horizontal collisions

__check_ball_bottom_coll:
  cmpi A, 0b1111
