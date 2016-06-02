# Run and inspect the core dump
ldi dp, 0x10

ldi a, 2
ldi b, 2
add a, b
str a
add a, b
ldm c

hlt
