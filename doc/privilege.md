# Privilege Modes Support

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


## User Mode

- Support U-mode:
    - Previous privilege mode interrupt is stored in xPP to support nested trap
    - Ecall move to M-mode
    - Mret move to U-mode
- Support exceptions
    - M-mode instructions executed in U-mode must raise an illegal instruction exception
    - Access to M-mode only registers must raise an illegal instruction exception
    - ecall code when coming from U-mode in mcause
- Support PMP (Physical Memory Protection)
    - Instruction read or data R/W access are checked against PMP to secure the hart
    - Address is checked with CSRs pmpcfg
    - Up to 16 zones can be defined
    - A zone can be readable, writable, executable
    - PMP checks are applied to all accesses whose effective privilege mode is S or U, including
      instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the
      MPRV bit in mstatus is set and the MPP field in mstatus contains S or U (page 56 & page 23)
- Study PMA (Physical Memory Attribute) (section 3.6)
    - Replace existing IO_MAP by PMP & PMA
- Support cycle registers per mode
- Pass compliance with U-mode
- WFI:
    - Support MSTATUS.TW (timeout platform-dependant)
    - if MIE/SIE=1, wait for one of them and trap. Resume to mepc=pc+4
    - if MIE/SIE=0, wait for any intp and move forward
- mcounteren: accessibility to lower privilege modes
- mcountinhibit: stop a specific counter
- Machine Environment Configuration Registers (menvcfg and menvcfgh)

## PMP

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

R/W/X fields

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

A field

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

## Interrupts

- WFI:
    - if MIE/SIE, wait for one of them and trap. Resume to mepc=pc+4
    - Can be executed evn if MIE/SIE are disabled
        - if any MTIE/MEIE/MSIE asserted, wait for them and move to pc+4
        - NOP if MTIE/MEIE/MSIE are disabled and move to pc+4

- Bits mip.MEIP and mie.MEIE are the interrupt-pending and interrupt-enable bits for machine-level
  external interrupts. MEIP is read-only in mip, and is set and cleared by a platform-specific
  interrupt controller.
- Bits mip.MTIP and mie.MTIE are the interrupt-pending and interrupt-enable bits for machine timer
  interrupts. MTIP is read-only in mip, and is cleared by writing to the memory-mapped machine-mode
  timer compare register.
- Bits mip.MSIP and mie.MSIE are the interrupt-pending and interrupt-enable bits for machine- level
  software interrupts. MSIP is read-only in mip, and is written by accesses to memory-mapped control
  registers, which are used by remote harts to provide machine-level interprocessor interrupts. A
  hart can write its own MSIP bit using the same memory-mapped control register. If a system has
  only one hart, or if a platform standard supports the delivery of machine-level interprocessor
  interrupts through external interrupts (MEI) instead, then mip.MSIP and mie.MSIE may both be
  read-only zeros.

- An interrupt i will trap to M-mode (causing the privilege mode to change to M-mode) if all of the
  following are true: (a) either the current privilege mode is M and the MIE bit in the mstatus
  register is set, or the current privilege mode has less privilege than M-mode; (b) bit i is set in
  both mip and mie; and (c) if register mideleg exists, bit i is not set in mideleg.

- Each individual bit in register mip may be writable or may be read-only. When bit i in mip is
  writable, a pending interrupt i can be cleared by writing 0 to this bit. If interrupt i can become
  pending but bit i in mip is read-only, the implementation must provide some other mechanism for
  clearing the pending interrupt.


## Doc review

- mstatus OK
- mtvec NO CHANGES
- mideleg / medeleg NA
- mip / mep NA
    - no delegation
    - everything is handled by m-mode
- mcycle / minstret NO CHANGES
- mcounteren / mcountinhibit OK
- mscratch NA
- mepc NA
- mcause NA
- mtval NA
- menvcfg and menvcfgh OK
- mtime and mtimecmp NA

## Supervisor

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

## Hypervisor

To be documented
