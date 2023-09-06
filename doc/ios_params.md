# Parameters

## Core

- ILEN:
    - length of an instruction
    - 32 (bits)
    - can't be changed
    - default: 32

- XLEN:
    - data bus widness
    - 32 or 64 (bits)
    - architecture dependent
    - default: 32

- BOOT_ADDR:
    - address the core will boot from
    - any value (byte)
    - platform dependent
    - default: 0

- INST_OSTDREQ_NUM
    - number of oustanding instruction read the control can issue
    - any value from 1
    - default: 8

- DATA_OSTDREQ_NUM
    - number of oustanding read/write the load/store module can issue
    - any value from 1
    - default: 8

- HART_ID
    - RISCV core identifier (MHART CSR)
    - any value from 0
    - default: 0

- RV32E
    - use only 16 registers (RV32E extension activation, MISA CSR [4])
    - 0 or 1
    - default: 0, 32 registers available

- F_EXTENSION
    - activate floating point extension  (MISA CSR [5])
    - 0 or 1
    - default: 0, no floating point support

- M_EXTENSION
    - activate multiply/divide extension  (MISA CSR [12])
    - 0 or 1
    - default: 0, no multiply/divide support

- PROCESSING_BUS_PIPELINE
    - insert a pipeline at processing unit input bus
    - 0 or 1
    - default: 0, no pipeline

- AXI_ADDR_W
    - wideness of any AXI address bus
    - any value (bits)
    - default: `XLEN`, 32 bits

- AXI_ID_W
    - widness of any AXI ID bus
    - any value greater than 1 (bits)
    - default: 8 bits

- AXI_IMEM_W
    - wideness of any AXI data bus for instruction
    - 32 (bits)
    - default: `XLEN`, 32 bits

- AXI_DMEM_W
    - wideness of any AXI data bus for data
    - 32 or 64 (bits)
    - default: `XLEN`, 32 bits

- AXI_IMEM_MASK
    - mask applied to instruction AXI ID bus to identify it
    - any value matching `AXI_ID_W` wideness
    - default: 0x10

- AXI_DMEM_MASK
    - mask applied to data AXI ID bus to identify it
    - any value matching `AXI_ID_W` wideness
    - default: 0x20

- CACHE_EN
    - enable both instruction and data cache stages
    - 0 or 1
    - default: 0, disabled

- ICACHE_PREFETCH_EN
    - enable next instrutction prefetch on continuous address parsing
    - 0 or 1
    - default: 0, disabled

- ICACHE_BLOCK_W
    - number of instruction per cache block
    - any multiple of `ILEN` (bits)
    - default: 4*`ILEN`

- ICACHE_DEPTH
    - number of cache block
    - any value greater than 1
    - default: 512

- DCACHE_PREFETCH_EN
    - enable next data prefetch on continuous address parsing
    - 0 or 1
    - default: 0, disabled

- DCACHE_BLOCK_W
    - number of data per cache block
    - any multiple of `XLEN` (bits)
    - default: 4*`XLEN`

- DCACHE_DEPTH
    - number of cache block
    - any value greater than 1
    - default: 512

- IO_MAP_NB
    - number of I/O (device) memory map (to bypass data cache fetch)
    - any value equal or greater than 0
    - default: 0, no device mapped

- IO_MAP
    - Start / End address of the IO (device) memory map
    - any value mapped in the memory, organized like `END-ADDR`_`START-ADDR`, matching
      `AXI_ADDR_W` * 2 * `IO_MAP_NB` (bits)
    - default: 64'h001000FF_00100000

## Platform

All parameters listed in [core](#core) section apply here

# Inputs / Outputs

## Core

- aclk
    - the main clock of the core
    - input

- aresetn
    - the main asynchronous active low reset
    - input
    - don't use it if already using srst

- srst
    - the main synchronous active high reset
    - input
    - don't use it if already using aresetn

- ext_irq
    - external interrupt, from any hardware source
    - input

- sw_irq
    - software interrupt, from any other hart or PLIC controller
    - input

- timer_irq
    - timer interrupt, from CLINT controller
    - input

- status
    - debug bus
    - output

- dbg_regs
    - all the ISA registers
    - output

- imem_*
    - AXI4-lite instruction bus (read channels only)
    - input/output

- dmem_*
    - AXI4-lite data bus
    - input/output
