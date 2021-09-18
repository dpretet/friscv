# Volume 1 (Exception Occurences)

Exceptions, Traps, and Interrupts (specs v1.6) :

- We use the term exception to refer to an unusual condition occurring at run
  time associated with an instruction in the current RISC-V hart.

- We use the term interrupt to refer to an external asynchronous event that may
  cause a RISC-V hart to experience an unexpected transfer of control.

- We use the term trap to refer to the transfer of control to a trap handler
  caused by either an exception or an interrupt.

  The general behavior of most RISC-V EEIs is that a trap to some handler
  occurs when an exception is signaled on an instruction


Misc. :

An instruction-address-misaligned exception is generated on a taken branch or
unconditional jump if the target address is not four-byte aligned. This
exception is reported on the branch or jump instruction, not on the target
instruction

Ordinarily, if an instruction attempts to access memory at an inaccessible
address, an exception is raised for the instruction.

No integer computational instructions cause arithmetic exceptions.

The JAL and JALR instructions will generate an instruction-address-misaligned
exception if the target address is not aligned to a four-byte boundary.

Loads with a destination of x0 must still raise any exceptions and cause any
other side effects even though the load value is discarded.

Loads and stores where the effective address is not naturally aligned to the
referenced datatype (i.e., on a four-byte boundary for 32-bit accesses, and a
two-byte boundary for 16-bit accesses) have behavior dependent on the EEI. An
EEI may not guarantee misaligned loads and stores are handled invisibly. In
this case, loads and stores that are not naturally aligned may either complete
execution successfully or raise an exception. The exception raised can be
either an address-misaligned exception or an access-fault exception


No special mentions to take in account for interrupts in this volume


# Volume 2 (Exception Occruences, to be continued... )

## Misc.

CSR Chapter:

Attempts to access a non-existent CSR raise an illegal instruction exception.
Attempts to access a CSR without appropriate privilege level or to write a
read-only register also raise illegal instruction exceptions.

Machine-mode standard read-write CSRs 0x7A0–0x7BF are reserved for use by the
debug system.  Implementations should raise illegal instruction exceptions on
machine-mode access to the latter set of registers.

Implementations are permitted but not required to raise an illegal instruction
exception if an instruction attempts to write a non-supported value to a WLRL
field.

MSTATUS Chapter:

The mstatus register keeps track of and controls the hart’s current operating state.

Virtual memory, N/A

Extension Context Status in mstatus Register

When an extension’s status is set to off, any instruction that attempts to read
or write the corresponding state will cause an illegal instruction exception

MTVEC:

The mtvec register is an MXLEN-bit read/write register that holds trap vector configuration,
consisting of a vector base address (BASE) and a vector mode (MODE).

Vectored mode: Asynchronous interrupts set pc to BASE+4×cause, else BASE

MEDELEG / MIDELEG

To indicate that certain exceptions and interrupts should be processed directly by a lower privilege level


MIP / MIE


Synchronous exceptions are of lower priority than all interrupts.

MEPC

When a trap is taken into M-mode, mepc is written with the virtual address of
the instruction that was interrupted or that encountered the exception

MCAUSE

Machine exception code

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

 mtval may be written with the first XLEN or ILEN bits of the faulting instruction on:
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

The Wait for Interrupt instruction (WFI) provides a hint to the implementation
that the current hart can be stalled until an interrupt might need servicing

This instruction may raise an illegal instruction exception when TW=1 in mstatus


If an enabled interrupt is present or later becomes present while the hart is
stalled, the interrupt exception will be taken on the following instruction,
i.e., execution resumes in the trap handler and mepc = pc + 4.


Mentions in Virtual Memory, Atomic operations and Supervisor mode


# Trap Management:

xCAUSE: store the trap cause
xEPC: address of the instruction triggering the trap
xTVAL: written with exception specific datum
xPP in STATUS: active privilege mode at the moment of the trap
xPIE: written with the current xIE value
xIE: cleared

# Clint from other IPS:

https://riscv.org/wp-content/uploads/2018/05/riscv-privileged-BCN.v7-2.pdf

Armleo:

https://github.com/armleo/ArmleoCPU/blob/main-development/src/armleosoc_axi_clint.sv

out: software interrupt s-mode (ssip)
out: software interrupt m-mode (msip)
out: timer interrupt
in: timer increment

Pulp-Platform:

https://github.com/pulp-platform/clint/blob/master/src/clint.sv

out: software interrupt m-mode (msip)
out: timer interrupt
in: timer increment

Hazard 3:

https://github.com/Wren6991/Hazard3/blob/master/hdl/peri/hazard3_riscv_timer.v

out: timer interrupt
in: timer increment

How are they connected in a SOC based on these IPs?

# Notes

3 interrupts:

- external: Simple IO or from PLIC (?)
- timer: memory-mapped peripheral, shared across a multi core architecture
- sotware: ecrire dans mip qui est une sortie, mais peut elle rentrer ensuite?
  Peut etre par une IRQ externe?


Stackoverflow thread about software interrupts:

https://stackoverflow.com/questions/64863737/risc-v-software-interrupts

Stackoverflow about RISC-V Interrupt Handling Flow

https://stackoverflow.com/questions/61913210/risc-v-interrupt-handling-flow/61916199#61916199

# RISCV Esperanto slides

https://riscv.org/wp-content/uploads/2018/05/riscv-privileged-BCN.v7-2.pdf

PLIC:
- gathers external interrupt and route them to the different harts
- Interrupts can target multiple harts simultaneously

Sotfware interrupts:

Software interrupt are how harts interrupt each other
- Mechanism for inter-hart interrupts (IPIs)
- Setting the appropriate <x>SIP bit in another hart is performed by a MMIO write
- But a hart can set its own <x>SIP bit if currmode >= <x>
