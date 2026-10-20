# dCache

dCache is an AXI4-lite cache core, providing local buffering of data memory for FRISCV data path.
dCache module is derived from iCache, reusing it's block fetcher stage, but adding a parallel path
to manage I/O request (which can't be locally stored/loaded) to drive them to external devices. The
core also embeddeds an out-of-order management stage to ensure a correct ordering of read request
from the CPU.

## AMBA

### Ordering Rules

AXI4 ordering rules are basic and simple:
- Transactions from multiple masters can't be ordered
- Transactions to different peripheral / memory regions can't be ordered
- Transactions using the same ID are completed in-order
- Transactions using different IDs could be completed in-order or out-of-order
- Read and write paths are uncorrelated:
    - Write-then-read: a master must wait for a write completion before issuing a read request to
      the same memory location to ensure data read correctness.
    - Read-then-write: a master must wait for a read completion before issuing a write request
      if aiming to update a memory location and not force abitrary its value.

Completion channels (write response or read data channel) indicates to a master a read or write 
request has been terminated to apply the above rules. A completion can be driven from:
- The final destination, if memory is marked as 'device" and data can't buffered (cached) in 
    intermediate stage. For instance a peripheral like an external memory, a GPIO, ...
- An intermediate stage across the AXI infrastructure if the memory destination is marked as 
    'normal'. For instance a buffer, a cache, a FIFO...

### ACACHE

ACACHE signal indicates the property of a transaction to drive an AXI interconnect in the transfer
hanlding.

AxCACHE[0]: Bufferability
- AxCACHE[0] = 0 indicates a completion can be issued from an intermediate point
- AxCACHE[0] = 1 indicates a completion must be issued from the destination

AxCACHE[1]: Cacheability
- AxCACHE[1] = 0 defines a request to a device region or a memory region
- AxCACHE[1] = 1 defines a request to a memory region

AxCACHE[3:2]: Allocation hint
- AxCACHE[2]: Read-allocate    
- AxCACHE[3]: Write-allocate    
- AxCACHE[3:2] can't be asserted if AxCACHE[1] is not asserted

## Core Design

CPU load-store [module](../rtl/friscv_memfy.sv), in order to drive correctly the cache must:
- tracks the addresses it issues and avoid concurrent read/write to the same memory regions
  to prevent memory corruption in the cache. Therefore, a read-then-write or write-then-read
  sequence are blocking the CPU pipeline.
- use the completion channels (read data and write response) to sequence above mentioned 
  instruction sequence.
- indicates in ACACHE signal the appropriate information for the cache in order to:
    - target a device or a memory
    - write policy (write-through or write-back)
    - hint for allocation in cache blocks
- could use different IDs across the different transactions


## dCache Design

dCache core:
- manage read and write transactions in parallel
- ensure read / write execution in timely manner. 
    - write issued before read ensured to be correctly executed
    - read issued before write ensured to be correctly executed
- doesn't handle data corruption if read/write hazard occurs on a memory location and issued at the
  cycle
- support out-of-order completion and reorder them if the source issued or not the request with them
  same ID. Completion are always issued in-order, but read/write completion channels are independent
- support device and normal transaction attribute
- use read-allocate hint
- doesn't use write-allocate hint
- support write-through only write policy
