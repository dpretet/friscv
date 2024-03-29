# Cache Basics


**Temporal locality**: 

If a byte of memory was used recently, it's likely to be used again soon.


**Spatial locality**: 

If a byte of memory was used recently, nearby bytes are likely to be needed soon.


**Working set**: 

Ihe unset of bytes that were used recently or will be needed soon


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

**Write Allocation**

For STORE instruction, a cache-miss can occur on a write request and so lead to read a cache block
then update it with the new value.

**Read Allocation**

For LOAD instruction, a cache-miss leads to read the system memory and allocate the block
in the cache.

**Write-Back**

A write request updates only the cache. The system memory is not up-to-date and will
be written later by the eviction buffer. Before that, the cache block is marked as dirty.

**Write-Through**

A write request updates both the cache and the system memory.
