# DOING

# BACKLOG

N.B. : Any new feature and ISA should be carefully study to ensure a proper
exception and interrupt handling

Misc.
- [ ] Deactivate trace with define
- [ ] Rework pipeline to avoid double not
- [ ] Add counters
- [ ] 64 bits support
- [ ] Atomic operations
- [ ] Support privileged instructions, supervisor mode & user mode
      https://danielmangum.com/posts/risc-v-bytes-privilege-levels/
      https://mobile.twitter.com/hasheddan/status/1514581031092899843?s=12&t=MMNTY_iRC48CjykLQBdTkQ
      https://man7.org/linux/man-pages/man2/syscall.2.html
      https://www.youtube.com/watch?app=desktop&v=1-8oYzL_Thk
      https://jborza.com/emulation/2021/04/22/ecalls-and-syscalls.html
- [ ] Support MMU extension
- [ ] JTAG interface / GDB Usage / OpenOCD
        - https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html
        - https://tomverbeure.github.io/2022/02/20/GDBWave-Post-Simulation-RISCV-SW-Debugging.html
        - https://github.com/BLangOS/VexRiscV_with_HW-GDB_Server
- [ ] Support PLIC (only for multi-core)
- [ ] Support CLIC controller
- [ ] UART: Support 9/10 bits & parity


AXI4 Infrastructure
- [ ] Support different clock for AXI4 memory interface, cache and internal core
- [ ] Out of order support in AXI
- [ ] Support ECC bits in core/crossbar 
- [ ] Rework GPIOs sub-system
    - [ ] Reduce latency in switching logic
    - [ ] Ajouter PERROR sur l’APB, to log on error reporting bus


Control:
- [ ] [Multiple instruction issue](https://www.youtube.com/watch?v=wGpkiNb_V9c)
- [ ] Enable flow-thru mode in instruction FIFO
- [ ] Reduce cache jump


Processing:

https://www.youtube.com/channel/UCPSsA8oxlSBjidJsSPdpjsQ/videos

- [ ] Scheduler to run multiple operations in parallel
- [ ] Memfy:
    - [ ] Support outstanding write request
    - [ ] Manage RRESP/BRESP
    - [ ] Don’t block write if AW / W are ready
    - [ ] Don’t block write until BCH but block any further read if pending write (in-order only)
    - [ ] Detect IO requests to forward info for FENCE execution
- [ ] Support F extension
- [ ] Support FENCE if AXI4-lite + OR support
- Division
    - [ ] Save bandwidth by removing dead cycles
    - [ ] Manage pow2 division by shifting
    - [ ] Start division from first non-zero digit
- [ ] Out-of-order execution


Cache Stages:
- [ ] Walk thru FIFO to reduce latency on jump
- [ ] AXI4 + Wrap mode
- [ ] Support prefetch: if no jump/branch detected in fetched instructions
      grab the next line, else give a try to fetch the branch address
- [ ] Implement a L2 cache stage
- [ ] Support datapath adaptation from memory controller
- [ ] Removed the 2 LSBs in instruction cache while always 2'b11 (6.25% saving)


dCache
- [ ] Derive from iCache
- [ ] Uncachable memory region for IOs region
- [ ] Write-then-read if same memory address accessed to avoid collision 


Verification/Validation:

- [ ] Testcases to write in ASM testsuite
    - IRQ & WFI
    - add a IRQ generation in the testbench
- [ ] Update synthesis flow
    - [ ] Standard cells library for Yosys
    - [ ] https://github.com/dpretet/ascend-freepdk45/tree/master/lib
    - [ ] https://github.com/chipsalliance/Surelog
    - [ ] https://stackoverflow.com/questions/65534532/how-to-estimation-a-chip-size-with-standard-cell-library
- [ ] Core config
    - [ ] Supporter des set de config du core en test bench.
    - [ ] Faire un test de synthèse selon les configs du core
- [ ] Error Logger Interface
    - [ ] Shared bus des CSRs, privilege mode, event, …
    - [ ] stream the event like a write memory error
    - [ ] log error in a file
    - [ ] Support GDB:  https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html


Hardware Test:
- [ ] Support LiteX: https://github.com/litex-hub/litex-boards, https://pcotret.gitlab.io/blog/processor_in_litex/ 
- [ ] Azure: https://www.xilinx.com/products/boards-and-kits/alveo/cloud-solutions/microsoft-azure.html
- [ ] AWS: https://www.xilinx.com/products/design-tools/acceleration-zone/aws.html


# Ideas / Applications

- [ ] Next CPU architecture:
    - Study SIMD architecture
    - Study vector architecture
    - Application to GPGPU area
    - Many-core / NoC architecture (power/interupt consideration)
    - Support float16 & float8, more generaly low-precision arithmetic like int8...
- [ ] Build a testing platform to validate IPs
- [ ] Openlane submission


# DONE

- [X] Add Github actions
- [X] Support unaligned address in APB sub-system
- [X] Add Clint peripheral
- [X] Output ISA regs on top level for debug purpose
- [X] Create a tesbench for iCache
- [X] Add C testsuite and Apps testsuite (interactive)
- [X] Add almost empty full flags to scfifo
- [X] Ensure interrupt and trap are correctly supported
- [X] Update SVUT to pass extra string to vvp for VPI
- [X] Review flush/reboot in fetcher & memctrl
- [X] Enhance cache reboot when ARID changes. Today just flush the FIFO,
      could restart the whole fetcher stages
- [X] Make AXI4-lite RAM throtteling
- [X] Enhance processing unit (CANCELLED: implementation is too big for too few benefits)
        - control checks registers under use in an instruction and knows if can branch, LUI, AUIPC
        - processing clear the tickets once instruction is finished
        - processing knows if a ALU can be used based register targeted
- [X] Support multiple ALUs in parallel, differents extensions (float, mult/div, ...)
- [X] Better print control status when branching and trapping (MAUSE info)
- [X] Add Github Actions and deploy CI flow
- [X] Support both Icarus and Verilator in simulation flow
- [X] Add M extension
- [X] Share common sources between ASM and Compliance testsuite
- [X] Testbench supports both CORE and platform configuration
- [X] Develop FRISCV platform including the core, an AXI4 crossbar and peripherals
- [X] Simplifier les r/w de CSR, save one cycle to execute an op
- [X] Option to read ISA registers on falling edge, not combinatorial read
- [X] Design a generic pipeline stage for processing front-end
- [X] Support trap and interupts
- [X] Add clint controller
- [X] First documentation
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