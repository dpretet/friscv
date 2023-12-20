# Atomic Operations Support

## Overview

The aim of this dev (made from v1.6.1) is to support atomic operation instructions. Atomic
operations will bring synchronization techniques required by kernels. The goal for FRISCV is to be
able to boot a kernel like FreeRTOS or Linux (without MMU) and makes the core a platform for real
worl usecases.

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

    n multiprocessor systems, ensuring atomicity exists is a little harder. It is still possible to
    use a lock (e.g. a spinlock) the same as on single processor systems, but merely using a single
    instruction or disabling interrupts will not guarantee atomic access. You must also ensure that
    no other processor or core in the system attempts to access the data you are working with.

In summary, an atomic operation can be useful to:
- synchronize threads among a core
- synchronize cores in a SOC
- ensure a memory location can be read-then-update in any situation, including exceptions handling

Atomic operations will be implemented in the load/store stage (`memfy`). dCache stage will also be
updated to better support `ACACHE`, slighlty change `AID` handling and put in place exclusive access
support (a new special routing). Finally, AXI memory model Needs to support this new access type.

## Design Plan

- Document and list all AXI usage and limitations in the IP.
- The core, `memfy` and `dCache` stages, will be updated on `AID` usage. Please refer
  to [AMBA spec](./axi_id_ordering.md) for further details of `AID` usage and ordering model.

### Atomic Operation Execution Overview

When `memfy` unit receives an atomic operation:
- it reserves its `rs1`/`rs2`/`rd` registers in processing scheduler
- it issues a read request to a memory register with:
    - a specific `AID` (e.g. `0x50`), dedicated to exclusive access
    - `ALOCK=0x1` making the request an `exclusive access`
    - `ACACHE=0x0` making the request `non-cachable` and `non-bufferable`
- it executes the atomic operation
- it issues to memory a request with the same attributes than read operation
    - a write request to update the memory register
    - a read request to release the memory register

### Processing Unit

Nothing expected to be changed

### Memfy Unit

- Issue with a single dedicated ID, so all reponse will be in-order, one for `exclusive` request,
  one for `normal` request, another for `device` request
- Issue a `device` access, `non-cachable` and `non-bufferable`
- Could manage multiple `amo` request if don't target the same `rs1`, `rs2` & `rd`
  and not the same address (see memfy_opt branch)
- First implementation, executes `amo` only if no other `normal` read/write is not ongoing

### dCache Unit

Needs to support exclusive access
- Exclusive access is a `device` access (`non-cachable` and `non-bufferable`), read/write trough access
- Don't replace ID for exclusive access ? So reponse could be driven to the master
  before another reponse, possibly issued before the amo request

Out of exclusive access scope:

### AXI Memory
- Support exclusive access, managed by a dedicated LUT
    - Reserve if first access
    - Release on a second (either with read or write)
    - Based only on ID, not address
- Correctly support in-order if same ID issued multiple times

### Cortex-M7 ID Usage example

Read IDs:
- ID O: Normal Non-Cacheable, Device and Strongly-ordered reads
- ID 2: Data cache linefills from linefill buffer 0
- ID 3: Data cache linefills from linefill buffer 1
- ID 4: Any instruction fetch

Write IDs:
- ID O: Normal non-cacheable memory and all store-exclusive transactions
- ID 1: Stores to Normal cacheable memory
- ID 2: Writes to Device or Strongly-ordered memory
- ID 3: Evictions to Normal cacheable Write-Back memory

### Future Enhancement

Memfy
- Can handle exclusive access and normal access for best bandwidth
- manage multiple requests with a LUT (see memfy_opt branch)
- Should be able to manage completion reodering (possible enhancement)

dCache
- the cache should be able to manage different IDs and don't substitute all the time them. Better
  performance. Reordering should be done only on different IDs.
- Use WRAP mode for read request, INCR for write request


## Test Plan

- An atomic operation can't be stopped if control unit manages async/sync exceptions
