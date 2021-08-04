#!/usr/bin/env python3
# coding: utf-8

import sys

# Read the memory content dropped by the compilation and pack it
# into a cache line. Can have any number of instructions per line, from 1 to N
# Print in stdout the boot address detected in the dumped file

def main(argv0, in_name, out_name, inst_per_line=4):

    opcodes = []
    bootaddr=''
    newaddr=0
    linew=0
    bytecount=0
    linebytecount = 0

    hexmem = open(in_name, 'r')
    # print(hexmem.read())
    for strings in hexmem.read().split("\n"):

        # If just empty pass to the next
        if not strings:
            pass

        # If boot address not found yet, store it
        elif "@" in strings and bootaddr=='':
            bootaddr = int(strings[1:], base=16)
            # print("Boot address: ", str(bootaddr))
            opcodes = bootaddr * ["00"]
            bytecount = bootaddr
        else:

            linedata = strings.split(" ")

            # Grab the line byte count right after the first address
            if bootaddr!='' and linebytecount==0:
                linebytecount = len(linedata)
                # print("Line byte count: ", linebytecount)
                # print(strings)

            # Store new bytes until a new address section
            if "@" not in strings:
                opcodes.extend(linedata)
                opcodes.extend((linebytecount-len(linedata))*["00"])
                bytecount += len(linedata)

            # Reached a new address section, fills the gap with 0
            else:
                newaddr = int(strings[1:], base=16)
                opcodes.extend((newaddr-bytecount)*["00"])
                # print("Reach new address section: ", newaddr)

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

    print(bootaddr)
    return

if __name__ == '__main__':
    sys.exit(main(*sys.argv))
