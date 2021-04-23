# DOING

Memoire index en word et pas en byte sur l’ALU
Trap des c-c pour kill le process dans run.sh
Support timeout

- [ ] Develop top testbench to use C/asm programs and rely only on RAM to drive
      instructions and data into the core
    - [ ] Try GOTO for branching instruction
    - [ ] Test pointers with int, char et function
- [ ] Explore and prepare RISCV compliance testbench

# BACKLOG

- [ ] Design a generic pipeline stage for ALU front-end
- [ ] Read processor datasheet and grab dev ideas
- [ ] Implement in-house profiler to check branching, stall time, ...
- [ ] synthesis project

- [ ] Document specification,architecture, possible evolution and timing
      diagrams. Spec: in-order, stage depth, interupt, GPIOs, memory init

- [ ] Trap des c-c pour kill le process dans run.sh
- [ ] Support timeout

# Design Backlog

- [ ] Support IRQ, timer, GPIOs
- [ ] Support multiple ALUs in parallel, differents spec (integer/float, mult/div)
      How to dispatch workloqd and share ISA registers
- [ ] Support oustanding requests (in-order)
    - Separate read and write memory channels
- [ ] Implement instruction cache with branch prediction and outstanding request
- [ ] Implement data cache
- [ ] Support privilieged instructions (virtualization, hypevisor support)
- [ ] Study MMU topic for RISCV (think about linux driver dev, use same interface than ARM?)
- [ ] Study SIMD architecture
- [ ] Study vector architecture (IBM Cell like?)
- [ ] Application to GPGPU area
- [ ] Many-core architecture
- [ ] Support float16 & float8, more generaly low-precision arithmetic like int8...
l


# Verification/Validation Backlog

- [~] Define the architecture of the first testbench. Goal: use C/asm to produce
      a RAM init file to drive the testcases
    - [ ] how to stop a testcase? on certain amount of data? by spying gpio
          status? taking a look to a CSR register?
- [ ] Define the hardware platform to use
- [ ] Prepare a hardware execution environment for preliminary testing
- [ ] Prepare a hardware execution environment for OS testing


# Ideas / Applications

- [ ] Possibility to use a program executed upon a testbench, with qemu?
- [ ] Print instruction received and execution steps in a log for debug purpose
- [ ] Use qemu to learn instruction
- [ ] Implement a neural network with the processor and TF lite
- [ ] Implement a GPGPU


# DONE

- [X] Understand vexrisc and picorv32 make file
- [X] Write a simple program, compile it, understand the asm
- [X] transform object into hex file
- [X] Understand the toolchain
    - [~] Understand the linker description to be able to initialize the processor instruction memory
- [X] Read RISCV unpriviligied specification
- [X] Implement control unit and its testbench
    - [X] be able to handle ALU halts for long instruction execution
    - [X] support branching / system instructions
    - [X] support pc correctly
- [X] Implement ALU
- [X] Populate modules' unit tests (control & alu)
