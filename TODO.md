# DOING

- [-] Implement ALU


# BACKLOG

- [ ] Implement in-house profiler to check branching, stall time, ...
- [ ] Explore and prepare RISCV compliance testbench
- [ ] Try GOTO for branching instruction
- [ ] Test pointers with int, char et function
- [ ] synthesis project


# Design Backlog

- [ ] Support multiple ALUs in parallel, differents spec (integer/float, mult/div)
- [ ] Support oustanding requests
    - Separate read and write memory channels
    - Control: always
    - ALU: in-order, read rquests initiated by the scheduler, data arrives with
      instruction write requests initiated by the ALU
- [ ] Implement instruction cache with branch prediction and outstanding request
- [ ] Implement data cache
- [ ] Support privilieged instructions (virtualization, hypevisor support)
- [ ] Study MMU topic for RISCV (think about linux driver)
- [ ] Support SIMD architecture

- [ ] Write architecture and timing diagrams


# Verification/Validation Backlog

- [-] Populate modules' unit tests
- [~] Define the architecture of the first testbench. Goal: use C/asm to produce
      a RAM init file to drive the testcases
    - [ ] how to stop a testcase? on certain amount of data? by spying gpio
          status? taking a look to a CSR register?
- [ ] Define the hardware platform to use
- [ ] Prepare a hardware execution environment for preliminary testing
- [ ] Prepare a hardware execution environment for OS testing


# Ideas / Applications

- [ ] Possibility to use a program executed upon a testbench
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

