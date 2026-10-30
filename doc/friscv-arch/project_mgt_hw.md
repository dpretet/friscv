# DOING

- [ ] Kernel-capable Hart
    - [X] Supporter des set de config du core en test bench.
    - [X] Support U-mode
    - [X] Support PMP/PMA
    - [X] https://github.com/eembc/coremark
    - [X] Atomic operations

# BACKLOG

Any new features should be carefully study to ensure a proper exception and interrupt handling


## Processing

- [ ] Support F extension: https://bellard.org/softfp/
- [ ] RVV for machine learning
- [ ] Move LUI into processing to prepare future extension support
    - [ ] Read ASM to be sure its used for processing and not control
    - [ ] Benchmark waveform doesn’t reveal high usage


## Memory

- [ ] Bus fault to route on exceptions https://lists.riscv.org/g/tech-privileged/topic/80351141
- [ ] Support posted-write
    - memfy issues write request without waiting BRESP
    - Manages concurrency with read request
    - Manages hazard
    - https://medium.com/@ryoungsunpark/why-axi-has-a-write-response-channel-a0fe26eebf7d
- [ ] Make memory mapping of the core with:
    - [ ] Normal vs device
    - [ ] Inst vs data zone for cacheability / executability
    - [ ] Sharable for L2 cache
    - [ ] Support exception code for memory access error
    - [ ] Manage write response from cache or interco, don’t wait endpoint
    - [ ] Raise exception also from cache
- [ ] Support fine-grain permission over memory range
    - RISCV doesn't define privilege permission over PMP region
    - raise an exception
    - methode AER-like pour les enregistrer: src, address, permission
    - trig an interrupt catched with PLIC controller
    - https://www.cl.cam.ac.uk/research/security/ctsrd/cheri/cheri-risc-v.html


## Cache Stages

- [ ] Add dedicated RAM interface, not connected thru AXI interconnect
- [ ] AXI4 + Wrap mode for read
- [ ] Support ARLEN / AWLEN in prefetch and AXI4 Ram
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
    - Split memfy in load unit & store unit


## Miscellanous
- [ ] Rework tracing among hierarchy
    - Utiliser svlogger partout.
    - Plus de fwrite et drop dans un fichier avec la ROUTE dans un file.
- [ ] Zc extension
- [ ] Add test for vector table
- [ ] Test MSTATUS.TW
- [ ] mcountinhibit: stop a specific counter
- [ ] Machine Environment Configuration Registers (menvcfg and menvcfgh)
- [ ] Machine Configuration Pointer Register (mconfigptr)
- [ ] Create a HW test platform
    - [ ] Analogue pocket
    - [ ] Cloud
- [ ] Add registers to configure the core in platform
    - Caches
    - Interconnect
    - processing: scheduling, hazard detection
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
- [ ] Support https://riscof.readthedocs.io/en/latest/intro.html


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
- [ ] Pipeline PMP CSR up to MPU setup path and stop the core with csr_ready during few cycles

## Verification/Validation

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
    - [ ] Support GDB: https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html



# Ideas / Applications

- [ ] Include a DMA in platform
    - must respect PMP / PMA
- [ ] Build a testing platform to validate IPs
- [ ] Secure platform https://msrc-blog.microsoft.com/2022/09/06/whats-the-smallest-variety-of-cheri/


# DONE

- [ ] v1.7.0: Atomic Operations support, first version capable to execute a kernel
    - Port RAM model to AXI4
    - RAM rework to support compliance and speed mode on both response channel
    - Support A extension in Memfy
    - Update RISCV testsuite sources
- [X] v1.6.0: User Mode
    - [X] Design
        - [X] Support U-mode:
            - Previous privilege mode interrupt is stored in xPP to support nested trap
            - Ecall move to M-mode
            - Mret move to U-mode
        - [X] Support exceptions
            - M-mode instructions executed in U-mode must raise an illegal instruction exception
            - Access to M-mode only registers must raise an illegal instruction exception
            - ecall code when coming from U-mode in mcause
        - [X] Support PMP (Physical Memory Protection)
            - Instruction read or data R/W access are checked against PMP to secure the hart
            - Address is checked with CSRs pmpcfg
            - Up to 16 zones can be defined
            - A zone can be readable, writable, executable
            - PMP checks are applied to all accesses whose effective privilege mode is S or U, including
            instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the
            MPRV bit in mstatus is set and the MPP field in mstatus contains S or U (page 56 & page 23)
        - [X] Study PMA (Physical Memory Attribute) (section 3.6)
            - define R/W/X et l'address matching
            - le PMA ne permet pas de définir des zones d'IO et/ou si une region peut etre cohérente
        - [X] WFI:
            - [X] if MIE/SIE=1, wait for one of them and trap to m-mode. Resume to mepc=pc+4
            - [X] if MIE/SIE=0, wait for any intp and move forward
            - [X] Support MSTATUS.TW (timeout platform-dependent)
        - [X] add FIFO for memory exceptions
        - [X] Drive aprot[0] based on priviledge mode
        - [X] mcounteren: accessibility to lower privilege modes
            - Bit x = 1, lower privilege mode can read the counter
            - Bit x = 0, lower privilege mode access is forbidden and raise an illegal instruction exception
    -[X] Testcases
        - [X] Faire varier la periode de l'EIRQ
        U-mode
        - [X] pass from/to m-mode/u-mode
        - [X] try mret in u-mode, needs to fail
        - [X] try to access m-mode only CSRs
        Traps
        - [X] Do something within a loop with interrupt enabled, data needs to be OK
        - [X] WFI in u-mode, interrupt enabled, trapped in m-mode
        - [X] WFI in u-mode, interrupt disabled, NOP
        - [X] Test des exception load/store misaligned
        MPU:
        - [X] configure registers
        - [X] all region configuration mode: NA4 / NAPOT / TOR
        - [X] multiple mixed region type and size
        - [-] Access exceptions
            - [X] execute instruction outside allowed regions (U-mode)
            - [X] write data in U-mode
            - [X] read data in U-mode
            - [X] read data in M-mode with MPRV=1 + MPP=U-mode
            - [X] write data in M-mode with MPRV=1 + MPP=U-mode
            - [X] execute in M-mode without X + locked region
        - [X] locked access to change configuration
        MCOUNTEREN:
        - [X] Bit x = 1, lower privilege mode can read the counter
        - [X] Bit x = 0, lower privilege mode access is forbidden and raise an illegal instruction exception
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
