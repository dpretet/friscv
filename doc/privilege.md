# Privilege Modes Support

FRISCV supports machine mode as default mode. it's always implemented as required by the
specification. The core can also support user, supervisor and hypervisor modes, activable 
all by paramters, `USER_MODE`, `SUPERVISOR_MODE`, `HYPERVISOR_MODE`.

All modes use the same `XLEN` width. If `XLEN` = 32 bits, `MXLEN`, `SXLEN`, `UXLEN` and 
`HXLEN` will be setup to 32 bits.

The software navigates through the privilege levels with ECALL / xRET instructions

```
                   ┌────────────────────────────────┐   
                   │            MACHINE             │   
                   └────────────────────────────────┘   
                        │                     ▲         
                 MRET   │                     │  ECALL  
                        ▼                     │         
                   ┌────────────────────────────────┐   
                   │           SUPERVISOR           │   
                   └────────────────────────────────┘   
                        │                     ▲         
                 SRET   │                     │   ECALL 
                        ▼                     │         
                   ┌────────────────────────────────┐   
                   │              USER              │   
                   └────────────────────────────────┘   
```

CSR registers address encodes inner attributes:

```
                11/10      9/8         7/4         3/0     
              ┌───────┬───────────┬───────────┬───────────┐
              │  R/W  │ Privilege │    Use    │  Address  │
              └───────┴───────────┴───────────┴───────────┘
```

Bit[11:10]:
- `11`: read-only
- Others: read/write

Bits [9:8]:
- `00`: User
- `01`: Supervisor
- `10`: Hypervisor
- `11`: Machine


# TODO

Plan:
- 1. user mode + PMP
- 2. supervisor mode + virtual memory support
- 3. hypervisor mode
- 4. debug mode

1. User mode

- Implement MSTATUS based on latest spec
- Support U-mode: 
    - Previous privilege mode interrupt is stored in xPP to support nested trap
    - Ecall move to M-mode
    - Mret move to U-mode
- Support exceptions
    - M-mode instructions executed in U-mode must raise an illegal instruction exception
    - Access to M-mode only registers must raise an illegal instruction exception
- Support PMP (Physical Memory Protection)
    - Instruction read or data R/W access are checked against PMP to secure the hart
    - Address is checked with CSRs pmpcfg
    - Up to 16 zones can be defined
    - A zone can be readable, writable, executable
    - PMP checks are applied to all accesses whose effective privilege mode is S or U, including
      instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the
      MPRV bit in mstatus is set and the MPP field in mstatus contains S or U (page 56)
- Study PMA (section 3.6)

2. Supervisor
- Support interrupts
    - disable them for lower mode. If is SUPERVISOR, USER interrupts are disabled
    - interrupts for higher mode are enabled, whatever xIE bit. If is SUPERVISOR, 
      HYPERVISOR interrupt are enabled
    - previous privilege mode interrupt is stored in xPP to support nested trap
    - medeleg & mideleg: delegate an trap to a mode means this mode can handle it. Traps never
      transition from a more-privileged mode to a less-privileged mode (page 45)
- Support virtual memory for supervisor mode (TVM correct support)
- Support timer extension for each modes
- Support priv mode in cache stages
- Support TW (section 3.1.6.5)
- V & F extensions support: XS, FS, VS fields
