# Week 15

Found a nasty bug in testbenchs preventing to find a misconception in the
control unit. I removed the random sequencial testbench and merged the two
others in a single one. The misconception issue will be tracked and fixed when
the testbench testing the top level with a c/asm program will be alive.

ALU is under development, lui/load/store instructions are ready. No performance
chasing for the moment, back-to-back operations are not yet supported.

# Week 13 & 14

Drafted the FRISCV RV32i top level and ALU skeletons. Developed the ISA
registers and control unit. No testbench developed for registers while the
componenent is simple. The control unit was more complex and three testbenchs
are alive: one to check jump and branching, one to test ALU instruction bus and
the third testing random instruction injection to test the branching/jumping
while processing instructions are also injected.

# Week 12

Wrote an empty program, just a C file, compiled it with Vexrisv makefile
then wrote a stupid python script to produce the file to load in testbench,
sounds OK. Still pretty primitive but this will make the work for the moment
to let me move to digital design of the core :)


# Week 11

Found a good resource in Vertex repository to compile an asm program with
RISCV toolchain and produce a verilog memory init file:

https://github.com/SpinalHDL/VexRiscv/blob/master/src/test/cpp/custom/simd_add/makefile

The assembler file exposes a unit test suite structure which is pretty
great to find, I never thought I could do that :) The makefile is clear, simple
and self explained by its stucture. A linker file is present along the test
suite and let me specify the start address.

I will start to code the processor front-end and use directly assembler to
inject command into the processor. The process to boot the processor and link
for instance an OS bootloader or the way to load the instructions from a
SOC crossbar are not clear but this will not be a blocking point, only possibly
a refactoring of the front-end booting and driving the processor core.

Goal of the week: write a basic asm program, compile it and init a testbench
loading the memory content into a IP core shell.

# Week 10

Thursday:

Starting point of the activities. The goal before diving into the architecture
is to understand the ISA, how to compile and produce an ELF, then how to create
a file to feed the processor memory and use it for simulation.

On ISA side: the way it works is more or less clear. Few points to clarify but
good enough understanding to start thinking about architecture. The hierarchy
is clear but the point I don't know is how to organize the memory, Harvard vs
Von Neumann architecture. Is it RISCV specific or an architecture choice?
Then again related to memory plan, how to boot the processor. Do I need a
bootstrap in an internal "ROM", can I boot from the host bus, ... and so
related to the memory issue, how to setup the compilation/linking flow.

So the focus is on understanding the compilation flow and produce a hex file.
Converting the file to hex is not a problem and fairly easy to do. Setting up
the linker is the main challenge, with learning RSICV asm :)
