# Specs

Notes found in Volume 1 (Exception Occurences)

Exceptions, Traps, and Interrupts (specs v1.6) :

- We use the term exception to refer to an unusual condition occurring at run
  time associated with an instruction in the current RISC-V hart.

- We use the term interrupt to refer to an external asynchronous event that may
  cause a RISC-V hart to experience an unexpected transfer of control.

- We use the term trap to refer to the transfer of control to a trap handler
  caused by either an exception or an interrupt.

The general behavior of most RISC-V EEIs is that a trap to some handler occurs when an exception is
signaled on an instruction


Various notes taken across the specification about traps:

- An instruction-address-misaligned exception is generated on a taken branch or unconditional jump
  if the target address is not four-byte aligned. This exception is reported on the branch or jump
  instruction, not on the target instruction

- Ordinarily, if an instruction attempts to access memory at an inaccessible address, an exception
  is raised for the instruction.

- No integer computational instructions cause arithmetic exceptions.

- The JAL and JALR instructions will generate an instruction-address-misaligned exception if the
  target address is not aligned to a four-byte boundary.

- Loads with a destination of x0 must still raise any exceptions and cause any other side effects
  even though the load value is discarded.

- Loads and stores where the effective address is not naturally aligned to the referenced datatype
  (i.e., on a four-byte boundary for 32-bit accesses, and a two-byte boundary for 16-bit accesses)
  have behavior dependent on the EEI. An EEI may not guarantee misaligned loads and stores are
  handled invisibly. In this case, loads and stores that are not naturally aligned may either
  complete execution successfully or raise an exception. The exception raised can be either an
  address-misaligned exception or an access-fault exception

CSR Chapter:

- Attempts to access a non-existent CSR raise an illegal instruction exception.

- Attempts to access a CSR without appropriate privilege level or to write a read-only register also
  raise illegal instruction exceptions.

- Machine-mode standard read-write CSRs 0x7A0–0x7BF are reserved for use by the debug system.
  Implementations should raise illegal instruction exceptions on machine-mode access to the latter
  set of registers.

- Implementations are permitted but not required to raise an illegal instruction exception if an
  instruction attempts to write a non-supported value to a WLRL field.

Interrupts:

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

- A xRET instruction is used to return from a trap in M-mode or S-mode respectively

- The mstatus register keeps track of and controls the hart’s current operating state.

- Extension Context Status in mstatus Register

- When an extension’s status is set to off, any instruction that attempts to read
  or write the corresponding state will cause an illegal instruction exception

MTVEC:

- The mtvec register is an MXLEN-bit read/write register that holds trap vector configuration,
  consisting of a vector base address (BASE) and a vector mode (MODE).

- Vectored mode: Asynchronous interrupts set pc to BASE+4×cause, elsepc is to set to BASE

MEPC

When a trap is taken into M-mode, mepc is written with the virtual address of
the instruction that was interrupted or that encountered the exception

MCAUSE

- Machine exception code, store the code associated to the trap

MTVAL

When a trap is taken into M-mode, mtval is either set to zero or written with
exception-specific information to assist software in handling the trap.
Otherwise, mtval is never written by the implementation, though it may be
explicitly written by software. The hardware platform will specify which excep-
tions must set mtval informatively and which may unconditionally set it to
zero.

mtval is written with the faulting virtual address when:

- a hardware breakpoint is triggered
- an instruction-fetch, load, or store address-misaligned, access
- a page-fault exception occurs

- mtval may be written with the first XLEN or ILEN bits of the faulting instruction on:
    - an illegal instruction trap

else setup to 0

ECALL:

The ECALL instruction is used to make a request to the supporting execution environment.
It generates an environment-call-from-x-mode exception

MRET

To return after handling a trap, there are separate trap return instructions
per privilege level: MRET, SRET, and URET. MRET is always provided. SRET must
be provided if supervisor mode is supported, and should raise an illegal
instruction exception otherwise. SRET should also raise an illegal instruction
exception when TSR=1 in mstatus

WFI

The Wait for Interrupt instruction (WFI) provides a hint to the implementation that the current hart
can be stalled until an interrupt might need servicing. Execution of the WFI instruction can also be
used to inform the hardware platform that suitable interrupts should preferentially be routed to
this hart. WFI is available in all privileged modes, and optionally available to U-mode.

If an enabled interrupt is present or later becomes present while the hart is stalled, the interrupt
trap will be taken on the following instruction, i.e., execution resumes in the trap handler and
mepc = pc + 4.

The purpose of the WFI instruction is to provide a hint to the implementation, and so a legal
implementation is to simply implement WFI as a NOP.

The WFI instruction can also be executed when interrupts are disabled. The operation of WFI must be
unaffected by the global interrupt bits in mstatus (MIE and SIE) and the delegation register mideleg
but should honor the individual interrupt enables. If the event that causes the hart to resume
execution does not cause an interrupt to be taken, execution will resume at pc + 4.

Trap Management:

- xCAUSE: store the trap cause
- xEPC: address of the instruction triggering the trap
- xTVAL: written with exception specific datum
- xPP in STATUS: active privilege mode at the moment of the trap
- xPIE: written with the current xIE value
- xIE: cleared


# Implementation choice:

The hart waits for the pipeline is empty before handling a trap, leading to enter the trap mechanism
with few cycles delay. This is true for both asynchronous and synchronous traps.

WFI:
- U-mode doesn't handle `WFI` if interrupts are enabled, it always traps m-mode.
- if MIE/SIE, wait for one of them and trap with m-mode. Resume to mepc=pc+4 with u-mode
- if mie/sie are off:
    - if any MTIE/MEIE/MSIE asserted, wait for them and move to pc+4, stay in u-mode
    - if MTIE/MEIE/MSIE are disabled, acts as a NOP and move to pc+4, stay in u-mode
- `WFI` could trigger a low-power mechanism in the future, enabling clock-gating or power-gating

MIP:

MIP registers contains the three interrupt fiels: external, software and timer interrupts lines.
The hart permits to read and write the three bits.

MEIP:
- MEIP is cleared internally, withtout user intervention, when the interrupt is received. The user
  will most likely not read it high but could read mcause to know external interrupt being the trap 
  source.

MSIP:
- implemented in a memory-mapped register but the input of a hart has never tested because
  no multicore platform as been yet developed.

MTIP:
- can be configured and cleared by memory-mapped timer register
