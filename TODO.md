# DOING

- [ ] Implement control unit and its testbench
    - be able to handle ALU halts for long instruction execution
    - support branching / system instructions
    - support pc correctly

# Design Backlog

- [ ] Implement ALU
- [ ] Implement instruction cache with branch prediction and outstanding request
- [ ] Implement data cache
- [ ] Support privilieged instructions (virtualization)
- [ ] Study MMU topic for RISCV (think about linux driver)
- [ ] Implement in-house profiler to check branching, stall time, ...

# Verification Backlog

- [ ] Populate modules' unit tests
- [~] Define the architecture of the first testbench. Goal: use C/asm to produce
      a RAM init file to drive the testcases
    - [ ] how to stop a tescase? on certain amount of data? by spying gpio
          status? taking a look to a CSR register?
- [ ] Explore and prepare RISCV compliance testbench
- [ ] Prepare a hardware execution environment for preliminary testing
- [ ] Prepare a hardware execution environment for OS testing

# Ideas

- [ ] Possibility to use a program executed upon a testbench
- [ ] Print instruction received and execution steps in a log for debug purpose
- [ ] Use qemu to learn instruction
- [ ] Try GOTO for branching instruction
- [ ] Test pointers with int, char et function
- [ ] implement a neural network with the processor and TF lite

# DONE

- [X] Understand vexrisc and picorv32 make file
- [X] Write a simple program, compile it, understand the asm
- [X] transform object into hex file
- [X] Understand the toolchain
    - [~] Understand the linker description to be able to initialize the processor instruction memory
- [X] Read RISCV unpriviligied specification
