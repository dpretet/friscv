#!/usr/bin/env python3
# coding: utf-8

# FIXME: if a line is not fully filled with instruction and a new code
# section occured, the next section will not be correctly placed.
# A nex code section needs to be placed by the linker at a correct
# position to avoid the bug

import sys

# Read the memory content dropped by the compilation and pack it
# into a cache line. Can have any number of instructions per line, from 1 to N
# Print in stdout the boot address detected in the dumped file

def main(argv0, in_name, out_name, inst_per_line=4, length=1048576):

    opcodes = []
    bootaddr = ''
    newaddr = 0
    bytecount = 0

    hexmem = open(in_name, 'r')
    for strings in hexmem.read().split("\n"):

        # If just empty pass to the next
        if not strings:
            continue

        # If boot address not found yet, store it
        if "@" in strings and bootaddr == '':
            bootaddr = int(strings[1:], base=16)
            # print("Boot address: ", str(bootaddr))
            opcodes = bootaddr * ["00"]
            bytecount = bootaddr
            continue

        linedata = strings.split(" ")

        # Store new bytes until a new address section
        if "@" not in strings:
            opcodes.extend(linedata)
            bytecount += len(linedata)

        # Reached a new address section, fills the gap with 0
        else:
            newaddr = int(strings[1:], base=16)
            # print("Reach new address section: ", newaddr)
            opcodes.extend((newaddr-bytecount)*["00"])
            # print("Bytecount to append: ", newaddr-bytecount)
            bytecount += (newaddr-bytecount)

    if bytecount < length:
        opcodes.extend((length-bytecount)*["00"])

    instrs = []
    instr = ""
    instr_line = ""
    inst_num = 0
    i = 0

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
        if inst_num == int(inst_per_line) or count == len(opcodes)-1:
            instrs.append(instr_line)
            instr_line = ""
            inst_num = 0

    # Write the memory content
    verimem = open(out_name, 'w')
    for instr in instrs:
        verimem.write(instr + "\n")

    print(bootaddr)
    return

if __name__ == '__main__':
    sys.exit(main(*sys.argv))
