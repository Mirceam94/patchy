#! /usr/bin/python2
# Patchy, takes a program as an argument

import sys
import os
import struct


class ALU:
    def __init__(self):
        self.inA_CLK = False
        self.inB_CLK = False
        self.__comp_aG = False  # A > B
        self.__comp_aS = False  # A < B
        self.__comp_aE = False
        self.OE = False


# RAM addy tied to A-Bus
class RAM:
    def __init__(self):
        self.data = []  # List of 16bit values

    def getVal(self, addr):
        if addr < 0 or addr > 65535:
            raise MSGException("Invalid address into RAM [" + addr + "]")
        return self.data[addr]

    def setVal(self, addr, val):
        if addr < 0 or addr > 65535:
            raise MSGException("Invalid address into RAM [" + addr + "]")

        if val < 0 or val > 65535:
            raise MSGException("Value too big or too small for RAM [" + val + "]")
        self.data[addr] = val


# Patchy is a 16bit processor
class Processor:

    # Start of processor functionality
    def __init__(self):
        # Register defitions
        # All regs are 16 bits wide
        self.regA = 0
        self.regB = 0
        self.regC = 0
        self.regD = 0
        self.regE = 0
        self.regF = 0
        self.regRET = 0

        self.regX = 0  # Output tied to A-Bus and D-Bus

        self.PC = 0  # 16bit, R/W access

        self.dBus = 0  # 16 bits
        self.aBus = 0  # 16 bits -> 0-65535

        self.PY_ticks = 0  # Purely for simulation, ++ per clk pulse

        self.RAM = RAM()
        self.ALU = ALU()

    def run(self):
        pass

    def CLK(self):
        # If stepping, pause somehow
        self.PY_ticks += 1

    def __getreg(self, reg):
        if reg == 0:
            return self.regA
        elif reg == 1:
            return self.regB
        elif reg == 2:
            return self.regC
        elif reg == 3:
            return self.regD
        elif reg == 4:
            return self.regE
        elif reg == 5:
            return self.regF
        elif reg == 6:
            return self.regRET
        elif reg == 7:
            return self.regX
        else:
            raise MSGException("Undefined register " + reg)

    def __setreg(self, val, reg):

        if val > 65535 or val < 0:
            raise MSGException("Value too big or too small [" + val + "] for reg " + bin(reg))

        if reg == 0:
            self.regA = val
        elif reg == 1:
            self.regB = val
        elif reg == 2:
            self.regC = val
        elif reg == 3:
            self.regD = val
        elif reg == 4:
            self.regE = val
        elif reg == 5:
            self.regF = val
        elif reg == 6:
            self.regRET = val
        elif reg == 7:
            self.regX = val
        else:
            raise MSGException("Undefined register " + reg)

    def __getRAM(self):
        return self.RAM.getVal(self.regX)

    # Instructions
    def rst(self):
        self.PC = 0
        self.CLK()
        self.PC += 1

    def hlt(self):
        self.__clockENBL = False
        self.CLK()
        self.PC += 1

    # 0b000 = regA
    # 0b001 = regB
    # 0b010 = regC
    # 0b011 = regD
    # 0b100 = regE
    # 0b101 = regF
    # 0b110 = regRET
    # 0b111 = regX
    def mov(self, dst, src):
        self.__setreg(self.__getreg(src), dst)
        self.CLK()
        self.PC += 1

    def ldr(self, dst):
        self.__setreg(self.__getRAM(), dst)
        self.CLK()
        self.PC += 1

    def ldh(self, dst, i):
        self.__setreg((self.__getreg(dst) & 0b0000000011111111) | (i * 256), dst)
        self.CLK()
        self.PC += 1

    def formatVal(self, val):
        return "0b" + str(bin(val)[2:].zfill(16))

    def dumpCore(self):
        print "Dumping Patchy Core"
        print " "
        print "Registers"
        print "A: " + self.formatVal(self.regA) + " " + str(self.regA)
        print "B: " + self.formatVal(self.regB) + " " + str(self.regB)
        print "C: " + self.formatVal(self.regC) + " " + str(self.regC)
        print "D: " + self.formatVal(self.regD) + " " + str(self.regD)
        print "E: " + self.formatVal(self.regE) + " " + str(self.regE)
        print "F: " + self.formatVal(self.regF) + " " + str(self.regF)
        print " "
        print "RET: " + self.formatVal(self.regRET) + " " + str(self.regRET)
        print "X: " + self.formatVal(self.regX) + " " + str(self.regX)


class MSGException(Exception):
    def __init__(self, str):
        self.str = str

    def __str__(self):
        return self.str


# Actual start
if len(sys.argv) == 1:
    raise MSGException("Usage: patchy prog")


prog = open(sys.argv[1], 'rb')

print "Running " + sys.argv[1]
print " "
print "Program is " + str(os.fstat(prog.fileno()).st_size) + " bytes long, " + str(os.fstat(prog.fileno()).st_size/2) + " Instructions"
print " "
print " "


cpu = Processor()

try:
    instruction = prog.read(2)
    while instruction != "":

        byte1 = struct.unpack('B', instruction[0])[0]
        byte2 = struct.unpack('B', instruction[1])[0]

        opcode = byte1 / pow(2, 4)

        if opcode == 0:
            cpu.dumpCore()
            pass
        elif opcode == 1:
            #rst
            pass
        elif opcode == 2:
            # SSSD DD-
            src = (byte1 / 2) & 0b00000111
            dst = ((byte1 & 1) * 4) | ((byte2 & 0b11000000) / pow(2, 6))
            cpu.mov(dst, src)
            pass
        elif opcode == 3:
            #ldr
            pass
        elif opcode == 4:
            dst = (byte1 / 2) & 0b00000111
            cpu.ldh(dst, byte2)
            pass
        elif opcode == 5:
            #ldl
            pass

        instruction = prog.read(2)

finally:
    prog.close()
