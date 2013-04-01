#! /usr/bin/python2
# Compiler for patchy, a 16 bit computer
#
# Instruction set
#
#   4bInst 12bData [6b reg def, dst/src]
#   0xIIII DDDDDDDDDDDD
#   16bit-wide instructions
#
#   0x0000      hlt
#   0x0001      rst
#   0x0010      mov dst, src
#   0x0011      ldr dst
#   0x0100      ldh dst, i
#   0x0101      ldl dst, i

import sys
import struct


class MSGException(Exception):
    def __init__(self, str):
        self.str = str


def byteToHex(B):
    return ("\\x" + hex(int(B, 2))[2:].zfill(2)).decode('string_escape')


infile = open(sys.argv[1], 'r')
outfile = None

if sys.argv[1].find('.') == -1:
    outfile = open(sys.argv[1] + ".bin", 'wb')
else:
    outfile = open(sys.argv[1][:sys.argv[1].find('.')] + ".bin", 'wb')

for line in infile:

    line = line[:-1]  # Slice newline

    if line[:2] == "//":
        continue
    elif line.find('hlt') > -1:
        outfile.write("\x00\x00")
    elif line.find('rst') > -1:
        outfile.write(struct.pack("h", b"0001000000000000"))
    elif line.find('mov') > -1:
        dst = line[line.find('mov') + 3:]
        src = bin(int(dst[dst.find(',') + 1:]))[2:].zfill(3)
        dst = bin(int(dst[:dst.find(',')]))[2:].zfill(3)

        outfile.write(byteToHex("0010" + src + dst[:1]))
        outfile.write(byteToHex(dst[1:] + "000000"))

    elif line.find('ldh') > -1:
        dst = line[line.find('ldh') + 3:]
        val = bin(int(dst[dst.find(',') + 1:]))[2:].zfill(8)
        dst = bin(int(dst[:dst.find(',')]))[2:].zfill(3)

        outfile.write(byteToHex("0100" + dst + "0"))
        outfile.write(byteToHex(val))


outfile.close()
