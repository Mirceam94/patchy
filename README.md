Patchy
======

16-bit virtual CPU, with unclear goals. Mainly a personal experiment, started as
a python project to define a prospective IRL hobby processor, grew into an actual
project. Everything at this point needs to be refined, as patchy itself is not
structured "as it should be". I'm not sure myself what that means, all I know is
I started this project months ago, and remember the need for refactoring.

So! A todo list! How grand.

## Todo

* Port everything? I picked python since I was dabbling with it; I no longer am.
* Define a proper instruction set
* Implement a compiler capable of handling said instruction set
* Get the processor to run it (to be clarified later)

## Useage
  >./compiler.py <source (.s)>
  >./patchy.py <program (.bin)>

## Example
# test.s
```
ldh 0, 128
ldh 2, 50
mov 4, 2
hlt
```
# Compiling and Running
```
cris@home ~/d/p/patchy> ./compiler.py test.s
cris@home ~/d/p/patchy> ./patchy.py test.bin
Running test.bin

Program is 8 bytes long, 4 Instructions


Dumping Patchy Core

Registers
A: 0b1000000000000000 32768
B: 0b0000000000000000 0
C: 0b0011001000000000 12800
D: 0b0000000000000000 0
E: 0b0011001000000000 12800
F: 0b0000000000000000 0

RET: 0b0000000000000000 0
X: 0b0000000000000000 0
```

Clearly the compiler or processor is doing something wrong,
as can be seen from the core dump and code listing. I'm leaving
it be for the time being, until I decide what to do with it.
