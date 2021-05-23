#!/usr/bin/env python3
# coding: utf-8

import sys


def main(argv0, in_name, out_name):

    opcodes = []

    hexmem = open(in_name, 'r')
    for strings in hexmem.read().split("\n"):
        if "@" in strings or not strings:
            pass
        else:
            opcodes.extend(strings.split(" "))

    instrs = []
    instr = ""
    i = 0
    for code in opcodes:
        instr += code
        i += 1
        if i == 4:
            instrs.append("".join(reversed([instr[i:i+2] for i in range(0, len(instr), 2)])))
            instr = ""
            i = 0
    # Append zero to have enough room to init the whole RAM
    # i = 0
    # while i < 100000:
        # i += 1
        # instrs.append("00000000")

    verimem = open(out_name, 'w')
    for instr in instrs:
        verimem.write(instr + "\n")


if __name__ == '__main__':
    main(*sys.argv)
