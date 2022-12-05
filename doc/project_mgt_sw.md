# DOING

- [X] Benchmark
    - [ ] Run NBench
    - [ ] https://github.com/darklife/darkriscv/tree/master/src/coremark
    - [ ] Tiny tracer
        - [ ] https://github.com/Naitsirc98/Tiny-Ray-Tracer
        - [ ] https://github.com/ssloy/tinyraytracer

# BACKLOG

C app

- [ ] Micro kernel
    - [ ] Interrupt
        - [ ] EIP SIP générée depuis le cpp
        - [ ] https://mullerlee.cyou/2020/07/09/riscv-exception-interrupt/#How-to-run-my-code
    - [ ] Use little script lang Beariish/little
- [ ] Pool arena / malloc-free
- [ ] Unit test framework
- [ ] Sorting (bitonic)
- [ ] Neural network like layer
- [ ] Binary tree
- [ ] Msgpk like library
- [ ] Graphic tests and rendering
    - Generate images and convert in ASCII
    - fractal: https://en.m.wikipedia.org/wiki/Menger_sponge
- [ ] Jeu utilisant le moins de KB possible
    - [ ] Lldvelh
    - [ ] Zelda like
    - [ ] Casse tête
    - [ ] 2048

Misc.

- [ ] Testcase C (Rand access) pour les ORs de memory
- [ ] Testsuite Rust https://danielmangum.com/posts/risc-v-bytes-rust-cross-compilation/
- [ ] Testsuite Go

Minimalistic Unix
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

- [ ] Support Linux / FreeBSD / NetBSD: https://github.com/cnlohr/mini-rv32ima
- [ ] Code Pong with AI for auto game
- [ ] Run Doom: https://www.youtube.com/watch?v=uZMNK17VCMU&list=WL&index=1&t=2s
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

DONE:

- [X] Add Xoshiro++ benchmark
- [X] Testcase C de mult/div: done in matrix and printf
- [X] Testcase WBA div / mult
- [X] Enhance print, tend to have native printf
- [X] Benchmark command
    - chacha20
    - matrix computation
- [X] Dev some basic commands
    - [X] must use argc argv
    - [X] sleep
    - [X] help
    - [X] reboot
    - [X] exit
