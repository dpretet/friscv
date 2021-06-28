#!/usr/bin/env python3
# coding: utf-8

import sys

# Read the memory content dropped by the compilation and pack it
# into a cache line. Can have any number of instructions per line, from 1 to N

def main(argv0, in_name, out_name, inst_per_line=4):

    opcodes = []

    hexmem = open(in_name, 'r')
    # print(hexmem.read())
    for strings in hexmem.read().split("\n"):
        if "@" in strings or not strings:
            pass
        else:
            opcodes.extend(strings.split(" "))

    instrs = []
    instr = ""
    instr_line = ""
    inst_num = 0
    i = 0

    # print(opcodes)

    # Parse one by one the bytes composing the instructions
    for count, code in enumerate(opcodes):
        instr += code
        i += 1
        # once reach 4 bytes, revert the byte for little endianess
        if i == 4:
            instr_line = "".join(reversed([instr[i:i+2] for i in range(0, len(instr), 2)])) + instr_line
            instr = ""
            i = 0
            inst_num += 1
        # If reached the end of the cache line, store in the list and continue
        if inst_num == int(inst_per_line) or count==len(opcodes)-1:
            instrs.append(instr_line)
            instr_line=""
            inst_num=0

    # Write the memory content
    verimem = open(out_name, 'w')
    for instr in instrs:
        verimem.write(instr + "\n")


if __name__ == '__main__':
    main(*sys.argv)
