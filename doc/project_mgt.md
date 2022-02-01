# DOING

- [ ] Review WARL CSR implementation
- [ ] enhance processing unit
    - control checks registers under use in an instruction
    - processing clear the tickets once instruction is finished
    - processing knows if a ALU can be used based register targeted
    - control knows if it can branch
    - could speed up the execution and could branch even if ALUs are running

# BACKLOG

Any new feature and ISA should be carefully study to ensure a proper
exception and interrupt handling

Misc.
- [ ] Add counters
- [ ] 64 bits support
- [ ] Support privileged instructions, supervisor mode & user mode
      https://danielmangum.com/posts/risc-v-bytes-privilege-levels/
- [ ] Support MMU extension
- [ ] JTAG interface / GDB Usage
      https://github.com/BLangOS/VexRiscV_with_HW-GDB_Server
- [ ] Removed the 2 LSBs in instruction cache while always 2'b11 (6.25% saving)
- [ ] AXI4 Infrastructure
    - [ ] Check des IDs de control sent. Should be incremented in memory
          controller and not used directly
    - [ ] Write completion usage in memfy or dcache? Could raise an exception?
    - [ ] Support different clock for AXI4 memory interface, cache and internal core
- [ ] Support PLIC (Only for multi-core)
- [ ] Support CLIC controller

Control:
- [ ] Optimize control unit by removing dead cycles on jump
    - Study how to reduce jump/branch time
    - Don't increment araddr when received branch?
- [ ] Support branch prediction & out-of-order execution
- [ ] [Multiple issue processor](https://www.youtube.com/watch?v=wGpkiNb_V9c)

Processing:
https://www.youtube.com/channel/UCPSsA8oxlSBjidJsSPdpjsQ/videos
- [ ] Support multiple ALUs in parallel, differents extensions (float, mult/div, ...)
      Processing scheduler to assert readiness according the instruction and
      ISA regs accessed. Could be reused in control to avoid blocking AUIPC
      and LUI. Use Tomasulo algorithm and reservation station
- [ ] Out-of-order execution
- [ ] Memfy enhancement
    - Support outstanding requests
    - Write completion: how to support BRESP error
    - Read completion: how to support RRESP error
    - Detect IO requests to forward info for FENCE execution
- [ ] Support floating point
- [ ] Support FENCE if AXI4-lite & OR support

Cache Stages:
- [ ] Support prefetch: if no jump/branch detected in fetched instructions
      grab the next line, else give a try to fetch the branch address
- [ ] Implement a data cache stage
    - Support MSI/MOSI/MESI protocol
    - None-cachable address
- [ ] Review flush/reboot in fetcher & memctrl
- [ ] Support datapath adaptation from memory controller
- [ ] Enhance cache reboot when ARID changes. Today just flush the FIFO,
      could restart the whole fetcher stages
- [ ] Write cache read and cache lines on the same cycle to save latency


To finalize:
- [ ] Ensure interrupt and trap are correctly supported
- [ ] UART: Support 9/10 bits & parity
- [-] VPI for UART:
    - [X] update SVUT to pass extra string to vvp
    - [-] module for the agent, instanciating the UART agent
        - [X] task to initalize the UART agent in the testbench thru APB
        - [-] function to open a socket and configure it
        - [-] task to write in UART, reading periodically the socket
        - [-] task to read the UART (periodically) and send dat to the socket


Verification/Validation:

- [ ] Rework AXI4-lite RAM model to throttle valid/ready handshakes
- [ ] Testcases to write in ASM testsuite
    - IRQ & WFI
    - add a IRQ generation in the testbench
- [ ] Port to LiteX
- [ ] Define the hardware platform to use
- [ ] Port simulation flow to Verilator
- [ ] Update synthesis flow
    - [ ] Standard cells library for Yosys
    - [ ] https://github.com/dpretet/ascend-freepdk45/tree/master/lib
    - [ ] https://github.com/chipsalliance/Surelog
    - [ ] https://stackoverflow.com/questions/65534532/how-to-estimation-a-chip-size-with-standard-cell-library
- [ ] Formal verification tutorial https://zipcpu.com/tutorial/
- [ ] Develop some ASM programs
    - Benchmark (Dhrystone or others)
    - Binary tree
    - Matrix computation
    - mean of an array
- [ ] Develop C testuite: test pointers with int, char & function
- [ ] Prepare a hardware execution environment for preliminary testing
- [ ] Prepare a hardware execution environment for OS testing
- [ ] Mettre en place de la CI (Need Iverilog v11 and RISCV toolchain)
    https://github.com/vortexgpgpu/vortex/blob/master/ci/toolchain_install.sh


# Ideas / Applications

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
- [ ] Next CPU architecture:
    - Study SIMD architecture
    - Study vector architecture
    - Application to GPGPU area
    - Many-core / NoC architecture (power/interupt consideration)
    - Support float16 & float8, more generaly low-precision arithmetic like int8...
- [ ] Build a testing platform to validate IPs
- [ ] Retro gaming platform
- [ ] Openlane submission


# DONE

- [X] Add M extension
- [X] Simplifier les r/w de CSR, save one cycle to execute an op
- [X] Option to read ISA registers on falling edge, not combinatorial read
- [X] Design a generic pipeline stage for processing front-end
- [X] Support trap and interupts
- [X] Add clint controller
- [X] first documentation
- [X] Add external IRQ
- [X] Add software IRQ
- [X] Add timer IRQ
- [X] Parse doc and verify the trap handling (MCAUSE / ... fields)
- [X] Support traps
- [X] Convertir la testsuite ASM avec le format riscv-tests
- [x] Clean up repo after
- [X] Fix an isseu when rebooting teh cache, it issued a addr=0 request
- [X] Better handle traps on bad instruction
- [X] Support AXI4-lite for data interface
- [X] Pass RISCV compliance
- [X] Study how to use CSR
- [X] Partager les testbench et scripts entre les envs (use verilator?)
- [X] Define for SVLogger
- [X] Rename sources to remove rv32 mentions
- [X] Ajouter de check de parameters dans le top level
- [X] Print state with function and a verbosity level
- [X] Implement a generic logger
- [X] Implement instruction cache
    - [X] Support AXI4-lite from control unit
    - [X] Pipeline operations
    - [X] Support outstanding requests
    - [X] Bundle fetcher in a dedicated module
    - [X] Configure the testbench for command line
        - cache line width define, used to setup bin2hex.py
        - cache enabling
    - [X] Debug the core
    - [X] Reboot fetcher if new ID incomes
- [X] Write-thru FIFO: If pull and empty, write directly the output not the RAM
- [X] Use AXI4-lite to fetch instruction
- [X] Always forward and define addressing in byte
- [X] Move CSR out of control unit
- [X] Synthesis session: OK for Yosys, needs to use another or lib to map
      async/sync reset FFD.
- [X] Add a debug interface (UART, JTAG) + DPI
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
