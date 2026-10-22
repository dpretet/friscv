[Back to document index](./amba_axi_protocol_spec.md)

# Glossary

## Aligned

A data item stored at an address that is divisible by the highest power of 2 that divides into its size in bytes. Aligned
halfwords, words and doublewords therefore have addresses that are divisible by 2, 4 and 8 respectively.

An aligned access is one where the address of the access is aligned to the size of each element of the access.

At approximately the same time

Two events occur at approximately the same time if a remote observer might not be able to determine the order in
which they occurred.

AXI beat

See Beat.

AXI burst

See Burst.

AXI transaction

See Transaction.

Barrier

Beat

An operation that forces a defined ordering of other actions.

An individual data transfer within an AXI burst.

See also Burst, Transaction.

## Big-endian memory

Means that the most significant byte (MSB) of the data is stored in the memory location with the lowest address.

## Blocking

See also Endianness, Little-endian memory,

Describes an operation that prevents following actions from continuing until the operation completes.

A non-blocking operation can permit following operations to continue before it completes.

## Branch prediction

Is where a processor selects a future execution path to fetch along. For example, after a branch instruction, the
processor can choose to speculatively fetch either the instruction following the branch or the instruction at the
branch target.

See also Prefetching.

In an AXI transaction, the payload data is transferred in a single burst, that can comprise multiple beats, or
individual data transfers.

## Burst

See also Beat, Transaction.

Byte

Cache

Cache hit

Cache line

An 8-bit data item.

Any cache, buffer, or other storage structure in a caching Manager that can hold a copy of the data value for a
particular address location.

A memory access that can be processed at high speed because the data it addresses is already in the cache.

The basic unit of storage in a cache. Its size in words is always a power of two. A cache line must be aligned to the
size of the cache line.

The size of the cache line is equivalent to the coherency granule.

See also Coherency granule.

A memory access that cannot be processed at high speed because the data it addresses is not in the cache.

Cache miss

Caching Manager

A Manager component that has a hardware-coherent cache. A caching Manager has a snoop address and snoop
response channel, and optionally, a snoop data channel.

A Manager component might have only non-coherent caches. These caches can be for private data or they can be
software-managed to ensure coherency. A Manager with a non-coherent cache is not a caching Manager. That is,
the term caching Manager refers to a Manager with a cache that the ACE protocol must keep coherent.

See also Initiating Manager, Manager component, Snooped Manager.

A function that returns the lowest integer value that is equal to or greater than the input to the function.

ceil()

Data accesses from a set of observers to a memory location are coherent accesses to that memory location by the
members of the set of observers are consistent with there being a single total order of all writes to that memory
location by all members of the set of observers.

Coherent

Coherency granule

The minimum size of the block of memory affected by any coherency consideration. For example, an operation to
make two copies of an address coherent makes the two copies of a block of memory coherent, where that block of
memory is:

- at least the size of the coherency granule

- aligned to the size of the coherency granule.

In the ACE specification, the coherency granule is the cache line size.

See also Cache line.

A distinct functional unit that has at least one AMBA interface. Component can be used as a general term for
Manager, Subordinate, peripheral, and interconnect components.

## Component

See also Interconnect component, Manager component, Memory Subordinate component, Peripheral Subordinate
component, Subordinate component.

See Peripheral Subordinate component.

Device

An AXI transaction operates between a Manager component and one or more Subordinate components, and can
pass through one or more intermediate components. At any intermediate component, for a given transaction,
downstream means between that component and a destination Subordinate component, and includes the destination
Subordinate component.

Downstream

Downstream and upstream are defined relative to the transaction as a whole, not relative to individual data flows
within the transaction.

See also Manager component, Subordinate component, Upstream.

## Downstream cache

A downstream cache is defined from the perspective of an initiating Manager. A downstream cache for a Manager
is one that it accesses using the fundamental AXI transaction channels. An initiating Manager can allocate cache
lines into a downstream cache.

See also Downstream, Initiating Manager.

Something that is present in the specification for backwards compatibility. Whenever possible you must avoid using
deprecated features. These features might not be present in future versions of the specification.

## Deprecated

An aspect of the system memory mapping.

Endianness

See also Big-endian memory and Little-endian memory.

A fully coherent Manager can share data with other Managers and allocate that data in its local caches; it can snoop
and be snooped. Managers with an ACE interface are fully coherent whereas Managers with an ACE-Lite interface
are IO coherent.

Full coherency

See also IO coherency

See Cache hit.

Hit

An IO coherent Manager can share data with other Managers but cannot allocate that data in its local caches; it can
snoop but no be snooped. Managers with an ACE interface are fully coherent whereas Managers with an ACE-Lite
interface are IO coherent.

IO coherency

See also Full coherency

## IMPLEMENTATION DEFINED

Means that the behavior is not defined by this specification, but must be defined and documented by individual
implementations.

in a timely manner

The protocol cannot define an absolute time within which something must occur. However, in a sufficiently idle
system, it will make progress and complete without requiring any explicit action.

Initiating Manager

A Manager that issues a transaction that starts a sequence of events. When describing a sequence of transactions,
the term initiating Manager distinguishes the Manager that triggers the sequence of events from any snooped
Manager that is accessed as a result of the action of the initiating Manager.

Initiating Manager is a temporal definition, meaning it applies at particular points in time, and typically is used when
describing sequences of events. A Manager that is an initiating Manager for one sequence of events can be a
snooped Manager for another sequence of events.

See also Caching Manager, Downstream cache, Local cache, Peer cache, Snooped Manager.

Interconnect component

A component with more than one AMBA interface that connects one or more Manager components to one or more
Subordinate components

An interconnect component can be used to group together either:

- A set of Managers so that they appear as a single Manager interface
- A set of Subordinates so that they appear as a single Subordinate interface.

See also Component, Manager component, Subordinate component.

See Cache line.

Line

Little-endian memory

Means that the least significant byte (LSB) of the data is stored in the memory location with the lowest address.

See also Big-endian memory, Endianness.

## Load

The action of a Manager component reading the value held at a particular address location. For a processor, a load
occurs as the result of executing a particular instruction. Whether the load results in the Manager issuing a read
transaction depends on whether the accessed cache line is held in the local cache.

Local cache

See also Caching Manager, Speculative read, Store.

A local cache is defined from the perspective of an initiating Manager. A local cache is one that is internal to the
Manager. Any access to the local cache is performed within the Manager.

Main memory

See also Initiating Manager, Peer cache.

The memory that holds the data value of an address location when no cached copies of that location exist. For any
location, main memory can be out of date with respect to the cached copies of the location, but main memory is
updated with the most recent data value when no cached copies exist.

## Manager

Main memory can be referred to as memory when the context makes the intended meaning clear.

An agent that initiates transactions.

See also Subordinate on page Glossary-497

Manager component

A component that initiates transactions.

It is possible that a single component can act as both a Manager component and as a Subordinate component. For
example, a Direct Memory Access (DMA) component can be a Manager component when it is initiating transactions
to move data, and a Subordinate component when it is being programmed.

See also Component, Interconnect component, Subordinate component.

Memory barrier

See Barrier.

Memory Management Unit (MMU)

Provides detailed control of the part of a memory system that provides address translation. Most of the control is
provided using translation tables that are held in memory, and define the attributes of different regions of the
physical memory map.

See also System Memory Management Unit (SMMU).

## Memory Subordinate component

A Memory Subordinate component, or Memory Subordinate, is a Subordinate component with the following
properties:

- A read of a byte from a Memory Subordinate returns the last value written to that byte location.

A write to a byte location in a Memory Subordinate updates the value at that location to a new value that is
obtained by subsequent reads.

- Reading a location multiple times has no side-effects on any other byte location.

Miss

## MMU

Observer

Peer cache

- Reading or writing one byte location has no side-effects on any other byte location.

- See also Component, Manager component, Peripheral Subordinate component.

See Cache miss.

See Memory Management Unit (MMU).

A processor or other Manager component, such as a peripheral device, that can generate reads from or writes to
memory.

A peer cache is defined from the perspective of an initiating Manager. A peer cache for that Manager is one that is
accessed using the snoop channels. An initiating Manager cannot allocate cache lines into a peer cache.

See also Initiating Manager, Local cache.

## Peripheral Subordinate component

A Peripheral Subordinate component is also described as a Peripheral Subordinate. This specification recommends
that a Peripheral Subordinate has an IMPLEMENTATION DEFINED method of access that is typically described in the
data sheet for the component. Any access that is not defined as permitted might cause the Peripheral Subordinate to
fail, but must complete in a protocol-correct manner to prevent system deadlock. The protocol does not require
continued correct operation of the peripheral.

In the context of the descriptions in this specification, Peripheral Subordinate is synonymous with peripheral,
peripheral component, peripheral device, and device.

See also Memory Subordinate component, Subordinate component.

Permission to store

A Manager component has permission to store if it can perform a store to the associated cache line without
informing any other caching Manager or the interconnect.

See also Caching Manager, Manager component, Permission to update main memory, Store.

Permission to update main memory

A Manager component has permission to update main memory if the Manager can perform a write transaction to
main memory. The ACE protocol ensures that no other Manager performs a write transaction to the same cache
location at the same time.

See also Caching Manager, Manager component, Main memory, Permission to store, Store.

Point of Serialization. The point through which all transactions to a given address must pass and the order in which
the transactions are processed is determined.

## PoS

Prefetching refers to speculatively fetching instructions or data from the memory system. In particular, instruction
prefetching is the process of fetching instructions from memory before the instructions that precede them, in simple
sequential execution of the program, have finished executing. Prefetching an instruction does not mean that the
instruction has to be executed.

## Prefetching

In this manual, references to instruction or data fetching apply also to prefetching, unless the context explicitly
indicates otherwise.

An agent that agent that receives and responds to requests.

## Subordinate

See also Manager on page Glossary-496

## Subordinate component

A component that receives transactions and responds to them.

It is possible that a single component can act as both a Subordinate component and as a Manager component. For
example, a Direct Memory Access (DMA) component can be a Subordinate component when it is being
programmed and a Manager component when it is initiating transactions to move data.

See also Manager component, Memory Subordinate component, Peripheral Subordinate component.

A hardware-coherent cache on a snooped Manager. That is, it is a hardware-coherent cache that receives snoop
transactions.

## Snooped cache

The term snooped cache is used in preference to the term snooped Manager when the sequence of events being
described only involves the cache and does not involve any actions or events on the associated Manager.

See also Snooped Manager,

A precise snoop filter that is able to track precisely the cache lines that might be allocated within a Manager.

Snoop filter

Snooped Manager

A caching Manager that receives snoop transactions.

Snooped Manager is a temporal definition, meaning it applies at particular points in time, and typically is used when
describing sequences of events. A Manager that is a snooped Manager for one sequence of events can be an
initiating Manager for another sequence of events.

See also Caching Manager, Initiating Manager, Snooped cache.

## Speculative read

A transaction that a Manager issues when it might not need the transaction to be performed because it already has
a copy of the accessed cache line in its local cache. Typically, a Manager issues a speculative read in parallel with
a local cache lookup. This gives lower latency than looking in the local cache first, and then issuing a read
transaction only if the required cache line is not found in the local cache.

Store

See also Caching Manager, Load.

The action of a Manager component changing the value held at a particular address location. For a processor, a store
occurs as the result of executing a particular instruction. Whether the store results in the Manager issuing a read or
write transaction depends on whether the accessed cache line is held in the local cache, and if it is in the local cache,
the state it is in.

See also Caching Manager, Load, Permission to update main memory, Permission to store.

## Synchronization barrier

See Barrier.

System Memory Management Unit (SMMU)

A system-level MMU. That is, a system component that provides address translation from a one address space to
another. An SMMU provides one or more of:

- virtual address (VA) to physical address (PA) translation
- t VAo intermediate physical address (IPA) translation
- IPA to PA translation.

See Translation Lookaside Buffer (TLB).

## TLB

An AXI Manager initiates an AXI transaction to communicate with an AXI Subordinate. Typically, the transaction
requires information to be exchanged between the Manager and Subordinate on multiple channels. The complete
set of required information exchanges form the AXI transaction.

Transaction

See also Beat, Burst.

Translation Lookaside Buffer (TLB)

A memory structure containing the results of translation table walks. TLBs help to reduce the average cost of a
memory access.

Translation table

See also System Memory Management Unit (SMMU), Translation table, Translation table walk.

A table held in memory that defines the properties of memory areas of various sizes from 1KB.

See also Translation Lookaside Buffer (TLB), Translation table walk.

Translation table walk

The process of doing a full translation table lookup.

See also Translation Lookaside Buffer (TLB), Translation table.

An unaligned access is an access where the address of the access is not aligned to the size of an element of the access.

Unaligned

Unaligned memory accesses

Are memory accesses that are not, or might not be, appropriately halfword-aligned, word-aligned, or
doubleword-aligned.

See also Aligned on page Glossary-493

## UNPREDICTABLE

In the AMBA AXI and ACE Architecture means that the behavior cannot be relied upon.

UNPREDICTABLE behavior must not be documented or promoted as having a defined effect.

## Upstream

## Write-Back cache

An AXI transaction operates between a Manager component and one or more Subordinate components, and can
pass through one or more intermediate components. At any intermediate component, for a given transaction,
upstream means between that component and the originating Manager component, and includes the originating
Manager component.

Downstream and upstream are defined relative to the transaction as a whole, not relative to individual data flows
within the transaction.

See also Downstream, Manager component, Subordinate component.

A cache in which when a cache hit occurs on a store access, the data is only written to the cache. Data in the cache
can therefore be more up-to-date than data in main memory. Any such data is written back to main memory when
the cache line is cleaned or re-allocated. Another common term for a Write-Back cache is a copy-back cache.

## Write-Through cache

A cache in which when a cache hit occurs on a store access, the data is written both to the cache and to main memory.
This is normally done via a write buffer, to avoid slowing down the processor.
