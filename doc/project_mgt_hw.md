# DOING

- [ ] v1.6.0: Kernel-capable Hart
    - [X] Supporter des set de config du core en test bench.
    - [-] Support U-mode
    - [-] Support PMP/PMA
    - [ ] Atomic operations for single core
    - [ ] AXI Exception management with a CLIC
    - [ ] Zc extension


# BACKLOG

Any new features should be carefully study to ensure a proper exception and interrupt handling

## Memory

- [ ] Better manage ACACHE attribute
    - [ ] Correct value driven from memfy
    - [ ] Use it correctly across the cache
    - [ ] Read/write allocate based on memory map
    - [ ] Check impossible combination
    - [ ] IO map bufferable / non-bufferable
- [ ] Make memory mapping of the core with:
    - [ ] Normal vs device
    - [ ] Inst vs data zone for cacheability / executability
    - [ ] Sharable for L2 cache
    - [ ] Support exception code for memory access error
    - [ ] Manage write response from cache or interco, don’t wait endpoint
    - [ ] Raise exception also from cache
- [ ] Support AXI response
    - drive APROT with priv_mode
    - raise an exception (which one? a custom mcause?)
    - test with mapping outside interconnect memory region
    - manage in a clic controller and so avoid custom spec implementation
      could be used for other purpose later
- [ ] Support fine-grain permission over memory range
    - RISCV doesn't define privilege permission over PMP region
    - raise an exception
    - methode AER-like pour les enregistrer: src, address, permission
    - trig an interrupt catched with PLIC controller


## Cache Stages

- [ ] AXI4 + Wrap mode for read
- [ ] Support datapath adaptation from memory controller
    - [ ] Narrow transfer support?
    - [ ] Gather/merge multiple continuous transactions?
- [ ] Bien définir la politique write through no allocate
    - [ ] Write thru n’a pas besoin de n’a pas besoin d’eviction buffer https://stackoverflow.com/questions/23635284/what-is-the-difference-between-eviction-buffer-and-merging-store-buffer-on-arm-c
    - [ ] Renommer le write stage pour merging store buffer et essayer de merger les acces au besoin
    - [ ] https://en.wikipedia.org/wiki/Write_buffer
    - [ ] Write back policy permet de sauver de la BW mais rend la structure plus évoluée
- [ ] New cache associativity (2 / 4 / 8 ways configurable)
- [ ] OoO read: miss could be stacked and served later waiting for cache fill and continue reading the next address
- [ ] Fully concurrent read / write access (Issue #1)


## Miscellanous

- [ ] mcountinhibit: stop a specific counter
- [ ] Machine Environment Configuration Registers (menvcfg and menvcfgh)
- [ ] Machine Configuration Pointer Register (mconfigptr)
- [ ] Create a HW test platform
    - [ ] Analogue pocket
    - [C] Cloud
- [ ] Add registers to configure the core in platform (use custom CSR)
- [ ] Support CLIC controller
- [ ] Random peripheral
- [ ] UART: Support 9/10 bits & parity
- [ ] Deactivate the core with WFI (clock gating)
- [ ] Security Extension
    - Custom pmpsec CSR
        - priv/non-priv
        - cacheability
        - shareability
        - io/mem
    - HW isolation by CPU / Thread IDs



## Next-Gen Architecture

- [ ] High-end architecture
    - [ ] Supervisor mode
        - https://danielmangum.com/posts/risc-v-bytes-privilege-levels/
        - https://mobile.twitter.com/hasheddan/status/1514581031092899843?s=12&t=MMNTY_iRC48CjykLQBdTkQ
        - https://man7.org/linux/man-pages/man2/syscall.2.html
        - https://www.youtube.com/watch?app=desktop&v=1-8oYzL_Thk
        - https://jborza.com/emulation/2021/04/22/ecalls-and-syscalls.html
    - [ ] 64 bits support
    - [ ] Support MMU extension
- [ ] Multi-core platform:
    - [ ] Counters and timers should be reworked
    - [ ] Nb core configurable
    - [ ] PLIC controller
    - [ ] Extended atomic operation support
    - [ ] Implement a L2 cache stage
    - [ ] Extended Security / Sandboxing
- [ ] Debug Support / JTAG interface / GDB Usage / OpenOCD
        - https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html
        - https://tomverbeure.github.io/2022/02/20/GDBWave-Post-Simulation-RISCV-SW-Debugging.html
        - https://github.com/BLangOS/VexRiscV_with_HW-GDB_Server


## AXI4 Infrastructure

- [ ] Detect address collision in memfy for better performance
    - support concurrent r/w in dCache
    - merge memfy_opt for memfy core udpate
- [ ] Support different clock for AXI4 memory interface, cache and internal core
- [ ] Support ECC bits in core/crossbar
- [ ] Rework GPIOs sub-system
    - [ ] Reduce latency in switching logic
    - [ ] Ajouter PERROR sur l’APB, to log on error reporting bus
    - [ ] Rework IO APB interconnect
        - Fix IO subsystem misrouted
        - Fix IO subsystem bridge
- [ ] Out of order support in AXI (memfy if not using cache)


## Control / CSR

- [ ] Detect IO requests to forward info for FENCE execution
- [ ] Branch prediction
    - [ ] https://en.wikipedia.org/wiki/Branch_target_predictor
    - [ ] https://www.tutorialspoint.com/what-are-the-types-of-dynamic-branch-prediction
    - [ ] https://www.youtube.com/watch?app=desktop&v=hl4eiN8ZMJg
    - [ ] https://github.com/tommythorn/yarvi/blob/master/rtl/yarvi.v#L184
    - [ ] https://danluu.com/branch-prediction
- [ ] Rewind pipeline (L0 local cache)
- [ ] Pipeline PMP CSR up to MPU setup path and stop the core with csr_ready during few cycles


## Processing

- [ ] Parameter to deactivate hazard detection, save logic and measure gain
- [ ] Memfy:
    - If not ready, and request present, the FSM can’t drive further data
    - Manage RRESP/BRESP in the exception bus
- [ ] Support F extension: https://bellard.org/softfp/
- [ ] Division
    - [ ] Save bandwidth by removing dead cycles
    - [ ] Manage pow2 division by shifting
    - [ ] Start division from first non-zero digit
- [ ] OoO execution with Tomasulo algorithm
    - [ ] https://en.m.wikipedia.org/wiki/Hazard_(computer_architecture)#Data_hazards
    - [ ] https://en.m.wikipedia.org/wiki/Tomasulo%27s_algorithm
- [ ] RVV for machine learning
- [ ] Move LUI into processing to prepare future extension support
    - [ ] Read ASM to be sure its used for processing and not control
    - [ ] Benchmark waveform doesn’t reveal high usage


## Verification/Validation

- [ ] Drop lxt2 waveform
- [ ] Create app per benchmark
- [ ] Testcase C ASM cache stress
- [ ] Update synthesis flow
    - [ ] Standard cells library for Yosys
    - [ ] https://github.com/dpretet/ascend-freepdk45/tree/master/lib
    - [ ] https://github.com/The-OpenROAD-Project/asap7
    - [ ] https://github.com/chipsalliance/Surelog
    - [ ] https://stackoverflow.com/questions/65534532/how-to-estimation-a-chip-size-with-standard-cell-library
- [ ] Core config
    - [ ] Faire un test de synthèse selon les configs du core
    - [ ] Support cache disable in testbench
- [ ] Error Logger Interface
    - [ ] Shared bus des CSRs, privilege mode, event, …
    - [ ] Stream the event like a write memory error
    - [ ] log error in a file
    - [ ] Support GDB:  https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html
- [ ] Update RISCV testsuite sources
- [ ] SV Testbench: be able to assert or not a flush req along a new request on the same cycle
- [ ] Revoir la RAM AXI pour les temps de réponses write compliance et speed


## Hardware Tests

- [ ] Support LiteX: https://github.com/litex-hub/litex-boards, https://pcotret.gitlab.io/blog/processor_in_litex/
- [ ] Azure: https://www.xilinx.com/products/boards-and-kits/alveo/cloud-solutions/microsoft-azure.html
- [ ] AWS: https://www.xilinx.com/products/design-tools/acceleration-zone/aws.html
- [ ] Openlane submission


# Ideas / Applications

- [ ] Include a DMA in platform
    - must respect PMP / PMA
- [ ] Next CPU architecture:
    - Super scalar architecture
        - https://en.m.wikipedia.org/wiki/Instruction-level_parallelism
        - https://en.m.wikipedia.org/wiki/Data_dependency
        - https://www.youtube.com/channel/UCPSsA8oxlSBjidJsSPdpjsQ/videos
    - SIMD architecture
    - Vector architecture
    - Application to GPGPU area
    - Many-core / NoC architecture (power/interrupt consideration)
    - Support float16 & float8, more generaly low-precision arithmetic like int8...
- [ ] Build a testing platform to validate IPs
- [ ] Secure platform https://msrc-blog.microsoft.com/2022/09/06/whats-the-smallest-variety-of-cheri/


# DONE

- [X] v1.5.1: maintenance
    - [X] Preload jal even if processing is busy
    - [X] Print des tests qui ne marchent pas, un par un, dans le bash
    - [X] Join errors after a test status
    - [X] Review readme files
    - [X] Revoir tous les paramètres de chaque instance et les documenter
- [X] v1.5.0: Mesure et amélioration des performances
    - [X] Print et save des registres CSRs pour chaque test, garde la trace des performances dans Git
    - [X] IP point de mesure des différents bus en bandwidth
    - [X] CPI measure in benchmark
    - [X] Augmenter le nombre d’OR max de dCache
    - [X] Prefetch read request
    - [X] Optimize write pusher to save a cycle
    - [X] Optimize Memfy dead cycle (RD write comb & pending request =0 if == 1 & valid)
    - [X] Enhance read outstanding requests in MemFy
    - [X] No more pending flags in caches, BCH / RCH handshake is used to manage reording in Memfy
    - [X] Enhance completion in OoO
    - [X] Save a cycle on RD write in Memfy
    - [X] Pending flag to deassert on completion if or=1
    - [X] OoO write completion, response needs to come from the destination if IO write
    - [X] Support prefetch: if no jump/branch detected in fetched instructions
          grab the next line, else give a try to fetch the branch address. AXI hint?
    - [X] Reduce cache jump
- [X] v1.4.0
    - [X] Rework Control for faster jump.
    - [X] Rework iCache block fetcher to simplify it
    - [X] Block fetcher: pass-thru front-end FIFO to reduce latency on jump
    - [X] Scheduler to run multiple operations in parallel. ALU can run along LD/ST if no hazard
    - [X] CSR executes in a single cycle
    - [X] Enhance Memfy outstanding request support
- [X] Add Zihpm
- [X] Fix TX read of UART which is blocking
- [X] Develop dCache
    - [X] Uncachable access for IOs region
    - [X] Derive from iCache
    - [X] Add pusher stage for write access
    - [X] APROT[2] pour instruction or data hint
- [X] Develop dCache testbench
- [X] Fix lint error code management in CI
- [X] Memfy:
    - [X] Support outstanding read/write request
    - [X] Don’t block write if AW / W are ready
    - [X] Don’t block write until BCH but block any further read if pending write (in-order only)
- [X] Testcase WFI
- [X] Testcase outstanding requests
- [X] Testcase Zicnt
- [X] Add Zicntr
- [X] Rework trace among the modules
- [X] Deactivate trace with define for every module
- [X] AXI RAM model: add a performance mode
- [X] Add unsupported cache setup in core checkers
- [X] Add Github actions
- [X] Support unaligned address in APB sub-system
- [X] Add Clint peripheral
- [X] Output ISA regs on top level for debug purpose
- [X] Create a tesbench for iCache
- [X] Support script in App interactive testsuite
- [X] Add C testsuite
- [X] Add Apps testsuite, interactive tb with UART link from Verilator
- [X] Add almost empty/full flags to scfifo
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
