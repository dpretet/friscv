
## Overview

The aim of this dev (made from v1.6.1) is to support atomic operation instructions. Atomic
operations will bring synchronization techniques required by kernels. The goal for FRISCV is to be
able to boot a kernel like FreeRTOS or Linux (without MMU) and makes the core a platform for real
world usecases.

From [OS dev wiki](https://wiki.osdev.org/Atomic_operation):

    An atomic operation is an operation that will always be executed without any other process being
    able to read or change state that is read or changed during the operation. It is effectively
    executed as a single step, and is an important quality in a number of algorithms that deal with
    multiple independent processes, both in synchronization and algorithms that update shared data
    without requiring synchronization.

For single core system:

    If an operation requires multiple CPU instructions, then it may be interrupted in
    the middle of executing. If this results in a context switch (or if the interrupt handler refers
    to data that was being used) then atomicity could be compromised. It is possible to use any
    standard locking technique (e.g. a spinlock) to prevent this, but may be inefficient. If it is
    possible, disabling interrupts may be the most efficient method of ensuring atomicity (although
    note that this may increase the worst-case interrupt latency, which could be problematic if it
    becomes too long).

For multi core system:

    In multiprocessor systems, ensuring atomicity exists is a little harder. It is still possible to
    use a lock (e.g. a spinlock) the same as on single processor systems, but merely using a single
    instruction or disabling interrupts will not guarantee atomic access. You must also ensure that
    no other processor or core in the system attempts to access the data you are working with.

[Wiki Linearizability](https://en.m.wikipedia.org/wiki/Linearizability)

[Wiki Load-link/Store-Conditional](https://en.wikipedia.org/wiki/Load-link/store-conditional)

In summary, an atomic operation can be useful to:
- synchronize threads among a core
- synchronize cores in a SOC
- ensure a memory location can be read-then-update in any situation, including exceptions handling
  and avoid any hazards

Atomic operations will be implemented in the load/store stage (`memfy`). dCache stage will also be
updated to better support `ACACHE`, slighlty change `AID` handling and put in place exclusive access
support (a new special routing). Finally, AXI memory model needs to support this new access type.

## Implementation

From [Y-Combinator](https://news.ycombinator.com/item?id=27674238)

LR/SC stands for load-reserved/store-conditional, also called load-linked/store-conditional.
In a traditional atomic implementation using Compare-and-Swap, the order of execution is as follows:

1. Read value X into register A.
2. Do computation using register A, creating a new value in register B.
3. Do a compare-and-swap on value X: If X == A, then set X to B. The operation was successful. If X
   != A, another thread changed X while we were using it, so the operation failed. Rollback and
   retry.

This suffers from the ABA problem: it does not detect the case where another thread changes X to a
new value C, but then changed it back to A before the compare-and-swap happens.

[Google Group](https://groups.google.com/a/groups.riscv.org/g/isa-dev/c/bdiZ9QANeQM?pli=1a)




## RISCV Specification v1.0 - Chapter 8 - “A” Standard Extension

Instructions that atomically read-modify-write memory to support synchronization between multiple
RISC-V harts running in the same memory space.

The two forms of atomic instruction provided are load-reserved/store-conditional instruction and
atomic fetch-and-op memory instruction.

### Ordering

The base RISC-V ISA has a relaxed memory model, with the FENCE instruction used to impose additional
ordering constraints. The address space is divided by the execution environment into memory and I/O
domains, and the FENCE instruction provides options to order accesses to one or both of these two
address domains.

To provide more efficient support for release consistency, each atomic instruction has two bits,
aq and rl, used to specify additional memory ordering constraints as viewed by other RISC-V harts.

If both bits are clear, no additional ordering constraints are imposed on the atomic memory op-
eration.

If only the aq bit is set, the atomic memory operation is treated as an acquire access,
i.e., no following memory operations on this RISC-V hart can be observed to take place before the
acquire memory operation.

=> All memory instructions must be executed before the AMO.

If only the rl bit is set, the atomic memory operation is treated as a release access, i.e., the
release memory operation cannot be observed to take place before any earlier memory operations on
this RISC-V hart.

=> All memory instructions must be executed after the AMO.

If both the aq and rl bits are set, the atomic memory operation is sequentially consistent and
cannot be observed to happen before any earlier memory operations or after any later memory
operations in the same RISC-V hart and to the same address domain.

=> All memory instructions must be executed before & after the AMO.


## Design Plan

- Document and list all AXI usage and limitations in the IP.
- The core, `memfy` and `dCache` stages, will be updated on `AID` usage. Please refer
  to [AMBA spec](./axi_id_ordering.md) for further details of `AID` usage and ordering model.


### Global Update

- Add ALOCK among the core & the platorm
- Resize ALOCK to 1 bit in interconnect

### Processing Unit

Nothing expected to be changed

### Memfy Unit

When `memfy` unit receives an atomic operation:
- it reserves its `rs1`/`rs2`/`rd` registers in processing scheduler
- it issues a read request to a memory register with:
    - a specific `AID` (e.g. `0x50`), dedicated to exclusive access
    - `ALOCK=0x1` making the request an `exclusive access`
    - `ACACHE=0x0` making the request `non-cachable` and `non-bufferable`, a `device` access
- it executes the atomic operation
- it issues to memory a request with the same attributes than read operation
    - a write request to update the memory register
    - a read request to release the memory register

### dCache Unit

Needs to support exclusive access
- Exclusive access is a `device` access (`non-cachable` and `non-bufferable`), read/write trough
  policy
- Don't replace ID for exclusive access
- Invalidate cache line if exclusive access occurs on a cache hit. Even if memory map should ensure
  a proper attribute to a memory cell, it will ease software design without hardware knowledge
- dCache will not be responsible of concurrency between exclusive access and regular access.
  Memfy needs to handle correctly requests

### AXI Memory

- Upgrade to AXI4
- Support exclusive access, managed by a dedicated LUT
    - Reserve if first access
    - Release on a second (either with read or write)
    - Based on ID and address
    - Release exclusivity if write non-exclusive target a reserved-exclusive access
- Correctly support in-order if same ID issued multiple times

### Core

- Upgrade interfaces to AXI4

### Platform

- Upgrade to AXI interconnect


## Test Plan

- An atomic operation can't be stopped if control unit manages async/sync exceptions
- Check ordering with aq & rl bits combinations
- Used an unaligned address to raise an exception
- Read-exclusive followed by a write non-exclusive to check exclusivity in RAM
- Concurrent excusive accesses to check exclusivity in RAM
- Write applications
    - https://begriffs.com/posts/2020-03-23-concurrent-programming.html
    - voir les livres / pdf sur le sujet OS et semaphores
