# Privilege Mode Support

## Overview

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

The privilege modes support have been designed based on RISC-V ISA specification version 20211203

## PMP / PMA

To support secure processing and contain faults, it is desirable to limit the physical addresses
accessible by software running on a hart. PMP violations are always trapped precisely at the
processor.

PMP checks are applied to all accesses whose effective privilege mode is S or U, including
instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the MPRV bit
in mstatus is set and the MPP field in mstatus contains S or U.

Optionally, PMP checks may additionally apply to M-mode accesses, in which case the PMP registers
themselves are locked, so that even M-mode software cannot change them until the hart is reset. In
effect, PMP can grant permissions to S and U modes, which by default have none, and can revoke
permissions from M-mode, which by default has full permissions.

pmpcfg0–pmpcfg15 hold the configurations for the 64 PMP entries:

```
 31     24  23    16  15     8  7      0
┌─────────┬─────────┬─────────┬─────────┐
│ pmp3cfg │ pmp2cfg │ pmp1cfg │ pmp0cfg │ pmpcfg0
└─────────┴─────────┴─────────┴─────────┘
┌─────────┬─────────┬─────────┬─────────┐
│ pmp7cfg │ pmp6cfg │ pmp5cfg │ pmp4cfg │ pmpcfg1
└─────────┴─────────┴─────────┴─────────┘
 ........................................
┌─────────┬─────────┬─────────┬─────────┐
│pmp63cfg │pmp62cfg │pmp61cfg │pmp60cfg │ pmpcfg15
└─────────┴─────────┴─────────┴─────────┘
```

The PMP address registers are CSRs named pmpaddr0–pmpaddr63. Each PMP address register encodes bits
33–2 of a 34-bit physical address for RV32:

```
┌───────────────────────────────────────┐
│         address[33:2] (WARL)          │
└───────────────────────────────────────┘
```

PMP configuration register format:

```
     7      6    5   4     3      2         1         0
┌─────────┬────────┬─────────┬─────────┬─────────┬─────────┐
│    L    │  ----  │    A    │    X    │    W    │    R    │
└─────────┴────────┴─────────┴─────────┴─────────┴─────────┘
```

- R: region is readable
- W: region is writable
- X: region is executable
- A: address-matching mode
- L: entry is locked

**R/W/X fields**

The R, W, and X bits, when set, indicate that the PMP entry permits read, write, and instruction
execution, respectively.

- When one of these bits is clear, the corresponding access type is denied.
- Combinations with R=0 and W=1 are reserved
- Attempting to fetch an instruction from a PMP region that does not have execute permissions raises
  an instruction access-fault exception.
- Attempting to execute a load or load-reserved instruction which accesses a physical address within
  a PMP region without read permissions raises a load access-fault exception.
- Attempting to execute a store, store-conditional, or AMO instruction which accesses a physical
  address within a PMP region without write permissions raises a store access-fault exception.

**A field**

The A field in a PMP entry’s configuration register encodes the address-matching mode of the
associated PMP address register.

- When A=0, this PMP entry is disabled and matches no addresses
- Two other address-matching modes with four-byte granularity are supported:
    - naturally aligned power-of-2 regions (NAPOT), including the special case of naturally aligned
      four-byte regions (NA4)
    - the top boundary of an arbitrary range (TOR).

---------------------------------------------------------------
Value | Name  | Description
---------------------------------------------------------------
  0   | OFF   | Null region (disabled)
  1   | TOR   | Top of range
  2   | NA4   | Naturally aligned four-byte region
  3   | NAPOT | Naturally aligned power-of-two region, ≥8 bytes

NA4: a four byte region
NAPOT: Uses first zero bit of pmpaddrX to encode region size (unary encoding)
    => Region Size = 2^(first zero bit position+3)
    => all ones: 2^(XLEN+3)
    => yyyy...yyy0 = 8 bytes
    => yyyy...y011 = 32 bytes
    => 0111...1111 = 2^(XLEN+2) bytes
TOR: preceding PMP address register forms the bottom of the address range (If region 0 is set
to TOR, address 0x00 is the lower bound)

[Sifive slides](https://cdn2.hubspot.net/hubfs/3020607/SiFive-RISCVCoreIP.pdf?t=1512606290763)

**L field**
- Writes to the configuration register and associated address registers are ignored. 
- Locked PMP entries remain locked until the hart is reset
- If PMP entry i is locked, writes to pmpicfg and pmpaddri are ignored.
- When the L bit is set, these permissions are enforced for all privilege modes


TOR / NAPOT: What about TOR following a NAPOT region?
- advice from stackoverflow recommends to set a region as OFF before the TOR region
- coding of NAPOT used for TOR address matching is unclear to be function as is


## Supervisor

To be documented

## Hypervisor

To be documented
