# DOING

- [-] Add a debug interface (UART, JTAG) + DPI
- [ ] Synthesis session

# BACKLOG

Control:
- [ ] Add IRQ (CLINT/CLIC/PLIC) + timer
- [ ] Support privileged instructions

Cache stages:
- [ ] Design a generic memory bus
    - AMBA-like
    - Support outstanding requests
    - Support ID, OR, PROT and ERROR
    - Write completion
    - Detect IO request
    - forward info for FENCE(.i)
- [ ] Implement instruction cache with branch prediction
- [ ] Implement data cache

Processing:
- [ ] Design a generic pipeline stage for processing front-end
- [ ] Support multiple ALUs in parallel, differents spec (float, mult/div, ...)
      Processing scheduler to assert readiness according the instruction and
      ISA regs accessed

Documentation:
- [ ] specification: spec: in-order, stage depth, interupt, GPIOs...
- [ ] architecture, possible evolution
- [ ] timing diagrams
- [ ] Read processor datasheet and grab dev ideas

# Verification/Validation Backlog

- [ ] Develop some ASM programs
- [ ] Develop C testuite: test pointers with int, char & function
- [ ] Define the hardware platform to use
- [ ] Prepare a hardware execution environment for preliminary testing
- [ ] Prepare a hardware execution environment for OS testing


# Ideas / Applications

- [ ] Possibility to use a program executed upon a testbench or on board
    - bash front-end, getting a folder. The folder contains the sources and
      the makefile or just the sources. Can also support only a source or set
      of sources.
    - Launch the flow, connect the UART to the DPI or the board, output the
      processor printf and wait for a key to exit.
    - Should support sim and hw execution in the same way. Auto search the FPGA
      and auto-connect the UART
    - Able to update the FPGA bitstream with the new program
    - Interactive mode or non-blocking mode.
- [ ] Study MMU topic for RISCV (think about linux driver dev, use same interface than ARM?)
- [ ] Implement a neural network with the processor and TF lite
- [ ] Next CPU architecture:
    - Study SIMD architecture
    - Study vector architecture (IBM Cell like?)
    - Application to GPGPU area
    - Many-core architecture
    - Support float16 & float8, more generaly low-precision arithmetic like int8...
- [ ] Build a testing platform to validate IPs
- [ ] Retro gaming platform
- [ ] Build an Amiga



# DONE

- [X] Add GPIOs
- [X] Implement in-house profiler to check branching, stall time, ...
- [X] Develop top testbench to use asm programs and rely only on RAM to drive
      instructions and data into the core
    - Develop a unit test framework for ASM
    - Test memfy
    - Test processing + memory
    - Test processing vs JAL/JALR
    - Test JAL/JALR vs CSRs vs Processing
- [X] Define the architecture of the first testbench. Goal: use C/asm to produce
      a RAM init file to drive the testcases. Break with a EBREAK instruction
- [X] Understand vexrisc and picorv32 make file
- [X] Write a simple program, compile it, understand the asm
- [X] transform object into hex file
- [X] Understand the toolchain
    - Understand the linker description to be able to initialize the processor instruction memory
- [X] Read RISCV unpriviligied specification
- [X] Implement control unit and its testbench
    - be able to handle ALU halts for long instruction execution
    - support branching / system instructions
    - support pc correctly
- [X] Implement ALU
- [X] Populate modules' unit tests (control & alu)
