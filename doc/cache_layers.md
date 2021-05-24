# Cache Layers

This chapter describes the architecture and the behavior of the instruction and
data cache layers. It also introduces the basic concepts of the cache technology.

## Key Concepts


**Temporal locality**: if a byte of memory was used recently, it's likely to be
used again soon.

**Spatial locality**: if a byte of memory was used recently, nearby bytes are
likely to be needed soon.

**Working set**: the set of bytes that were used recently or will be needed soon


**Cache entry**:

When the cache reads a data block, called cache line or cache block, from the
central memory, it creates a record into its internal RAM storing the data and
its address, the data tag. When the processor reads an instruction, a cache hit
occurs if it's present into the cache, else it occurs a cache miss leading to
read the instruction in central memory and store it to the cache. The hit/miss
happens based on the cache architecture (its associativity) and the tag.

**Replacement Policy**:

When the cache fetchs and stores new instructions, it needs to make room
periodically. It predicts the least likely used cache line in the future, an
operation very tricky. The least recently used (LRU) algorithm is a good
compromise between efficienty and easiness of the implementation. But the LRU
can be complex to compute with high associativity placement. A (pseudo) random
replacement policy can be a good candidate while closely approaching the LRU
performance and being very simple to implement. A FIFO (First In, First Out)
startegy can also be a good implementation.

**Placement Policy, Associativity**:

The placement policy decides the allocation into the internal RAM of the
fetched instruction. If a cache line can be stored into any location, the
cache is defined as fully ssociative. At the opposite, if a cache line can be
stored in a single location, it's defined as direct-mapped. A fully-associative
cache architecture increases the cache hit and so the processor bandwidth, but
it makes the design more complex. A trade-off between fully-associative and
direct-mapped allows to match a good cache hit, contains architecture
complexity and reduces the latency of the cache layer.

A direct-mapped cache is considered as a one-way associative cache. Doubling
the associativity from direct-mapped to two-way, two-way to four-way, etc...,
has the same effect than doubling the cache size.


## Instruction Cache Architecture

The instruction cache stage acts a local buffer storing the most frequently
used instructions to avoid doing read requests to the central memory, which
would take significantly longer time to be accessed than a local memory. This
stage increases the bandwidth when fetching the next instructions to process
and thus increases the overall processor performance.

Features:

- Direct-mapped placement policy
- Random replacement policy
- Parametrizable cache depth
- Parametrizable cache line width
- Software-based flush control with RISCV FENCE.i instruction
- Transparent operation for user, no need of user management
- Cache control & status observable by a debug interface
- APB slave interface to fetch an instruction
- AXI4 master interface to read the system memory


## Notes

Bandwidth / efficienty:

32 bits: 1 instruction => 256 instructions per AXI4 request
128 bits: 4 instructions => 1024 instructions per AXI4 request
512 bits: 16 instructions => 4096 instructions per AXI4 request


Block size: if 8 bytes, uses the 3 LSBs of the address

Address of 32 bits with block size of 64 bytes

17 bits of tag stored along the 64 bytes of the block
9 bits of index to parse the RAM storing the tag and the block
6 bits of offset to parse the block
