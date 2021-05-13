# DOING

- [-] Develop top testbench to use asm programs and rely only on RAM to drive
      instructions and data into the core
    - [ ] Develop a unit test framework for ASM
    - [ ] Test memfy
    - [ ] Test processing + memory

- [ ] Develop C testuite
    - [ ] Test pointers with int, char et function
    - [ ] Write a bridge to print from processor to a shell thru Verilator

# BACKLOG

- [ ] Design a generic pipeline stage for processing front-end
    1. Driver is always ready and feed the consumer. Consumer is not always ready
        - one cycle pause
        - one cycle pause several time, not frequently
        - pause every 2 cycles
    2. Driver throttle the valid, consumer is always ready
    3. Both Driver and consumer throttle the valid/ready handshake
- [ ] Support IRQ (PLIC/CLINT), timer, GPIOs
- [ ] Design a generic memory bus
    - AMBA-like
    - Support outstanding requests
    - Support ID, OR, PROT and ERROR
    - Write completion
    - Detect IO request
    - forward info for FENCE(i)
- [ ] Implement in-house profiler to check branching, stall time, ...
- [ ] Synthesis project
- [ ] Document specification,architecture, possible evolution and timing
      diagrams. Spec: in-order, stage depth, interupt, GPIOs, memory init
    - Read processor datasheet and grab dev ideas
- [ ] Support multiple ALUs in parallel, differents spec (integer/float, mult/div)
      Processing scheduler to assert readiness according the instruction and ISA regs accessed
- [ ] Implement instruction cache with branch prediction and outstanding request
- [ ] Implement data cache
- [ ] Support privilieged instructions (virtualization, hypevisor support)
- [ ] Study MMU topic for RISCV (think about linux driver dev, use same interface than ARM?)
- [ ] Next CPU architecture:
    - [ ] Study SIMD architecture
    - [ ] Study vector architecture (IBM Cell like?)
    - [ ] Application to GPGPU area
    - [ ] Many-core architecture
    - [ ] Support float16 & float8, more generaly low-precision arithmetic like int8...


# Verification/Validation Backlog

- [ ] Design a UART and its DPI to scanf/printf from a terminal
      https://github.com/rdiez/uart_dpi
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

- [X] Define the architecture of the first testbench. Goal: use C/asm to produce
      a RAM init file to drive the testcases. Break with a EBREAK instruction
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
