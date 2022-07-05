# DOING

# BACKLOG

Misc.

C app

- [ ] Inline Clint.h
- [ ] Interrupt
    - [ ] EIP SIP générée depuis le cpp
    - [ ] https://mullerlee.cyou/2020/07/09/riscv-exception-interrupt/#How-to-run-my-code
- [ ] Micro kermel
- [ ] Unit test framework
- [ ] Binary tree
- [ ] Sorting (bitonic)
- [ ] Matrix computation

Minimalistic Unix
    - Execute, each function must use argc argv > Rewrite application, read original code source
        - [ ] sleep
        - [ ] help
        - [ ] reboot
    - How heap works? Manage malloc/free
    - tool to trace: https://github.com/janestreet/magic-trace
    - Support privileged instructions, supervisor mode & user mode
    - Add counters
    - 64 bits support
    - Support MMU extension

- [ ] Processor profiling
    - https://github.com/LucasKl/riscv-function-profiling

- [ ] Support PLIC (only for multi-core)
- [ ] Support CLIC controller


# Ideas / Applications

- [ ] Support Linux / FreeBSD / NetBSD
- [ ] Benchmark
    - [ ] https://github.com/riscv-software-src/riscv-tests
    - [ ] Run SPEC benchmark
    - [ ] Run NBench
- [ ] Run Doom
- [ ] Code the game of life
- [ ] Code Tetris
- [ ] Build a synth
- [ ] Built-in TCP/UDP engine, streamed thru the UART or any other interface
- [ ] Be able to inject ASM in the processor with the UART and run a test

- [ ] Build an Amiga: Emulate M68K and build an emulation platform
- [ ] Logicstic regression to setup optimized procesor configuration
- [ ] Possibility to use a program executed upon a testbench or on board
    - bash front-end, getting a folder. The folder contains the sources and
      the makefile or just the sources. Can also support only a source or set
      of sources.
    - Launch the flow, connect the UART to the DPI or the board, output the
      processor printf and wait for a key to exit.
    - Should support sim and hw execution in the same way. Auto search the FPGA
      and auto-connect the UART
    - Able to update the FPGA bitstream with the new program
- [ ] Implement a neural network with the processor and TF lite
- [ ] Retro gaming platform
