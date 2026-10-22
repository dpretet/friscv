# Part D

AMBA ACE and ACE-Lite Protocol Specification

## Chapter D1

### About ACE

This chapter gives an overview of system level coherency and the ACE protocol that supports it. It contains the
following sections:

- Coherency overview on page D1-150
- Protocol overview on page D1-152
- Channel overview on page D1-155
- Transaction overview on page D1-160
- Transaction processing on page D1-164
- Concepts required for the ACE specification on page D1-165
- Protocol errors on page D1-168

### D1.1 Coherency overview

System level coherency enables the sharing of memory by system components without the software requirement to
perform software cache maintenance to maintain coherency between caches.

Regions of memory are coherent if writes to the same memory location by two components are observable in the
same order by all components.

The ACE protocol enables:

- Correctness to be maintained when sharing data across caches

- Components with different characteristics to interact

- The maximum reuse of cached data

- A choice between high performance and low power

The ACE protocol provides a framework for system level coherency. The system designer can determine:

- The ranges of memory that are coherent

- The memory system components that implement the coherency extensions

- The software models that are used to communicate between system components

### D1.1.1 ACE revisions

Issue D of the ACE Protocol Specification first described the AXI Coherency Extensions.

Issue E of the specification adds clarifications, recommendations, and new capabilities to the ACE Protocol
Specification described in Issue D. To maintain compatibility, a property is used to declare a new capability.

Issue F of the ACE Protocol Specification describes extensions to the ACE protocol. The protocol now has four
variants:

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

References to the Low-Power Interface have been removed, this content has been superseded by the AMBA Low
Power Interface Specification (ARM IHI 0068). New appendixes have been added to summarize transaction names
and signal lists.

### D1.1.2 Usage cases

The ACE protocol enables system architects to select the most appropriate technique for sharing data between
system components. The protocol does not define specific usage cases, but typical usage cases are:

- The coherent connection of system components

- The coherent connection of subsystems that have non-uniform memory resources
- The coherent connection of components that have a highly optimized local coherency system
- The filtering of coherency communications
- The coherent connection of components that support different coherency protocols, such as MESI, ESI, MEI, and MOESI
- Wrapping of components that do not support coherency natively, enabling them to be used effectively within a coherent system level design
- Support for cached components that might include multiple levels of cache, and non-cached components
- Support for components that store coherency information at different granularities, including cache line granularity and large buffer granularity

- Implementations that facilitate optimization of:
  - The primary interconnect within a system
  - Multiple subsystems

### D1.1.3 ACE terminology

Terminology on page A1-30 introduces terminology that is used throughout the AXI and ACE specifications, and
indicates that:

- This specification does not define standard cache terminology, as defined in any reference work on caching.
- The Glossary defines terms that are used in the specifications.

ACE introduces additional terms, particularly relating to caching, and to memory operations performed by
Managers. The following subsections summarize those terms. Where appropriate, terms that are listed in this section
link to the corresponding glossary definition.

### AXI components and topology

The following terms describe components in an AXI4 system. Some terms apply, more specifically, to caches on
those components:

- Caching Manager, Initiating Manager, and Snooped Manager
- Downstream cache, Local cache, Peer cache, and Snooped cache

- Main memory and Snoop filter

### Cache state terminology

Cache state model on page D1-153 defines the possible states of a cache entry.

### Actions and permissions

The following terms relate to actions that can be performed by a Manager component, and the permissions to
perform such actions:

- Load, Speculative read, and Store

- Permission to store and Permission to update main memory

### Temporal descriptions

The AXI specification defines in a timely manner. The ACE specification requires the additional concept of At
approximately the same time.

### D1.2 Protocol overview

This section introduces the ACE protocol.

### D1.2.1 About the ACE protocol

The ACE protocol extends the AXI4 protocol and provides support for hardware-coherent caches. The ACE
protocol is realized using:

A five state cache model to define the state of any cache line in the coherent system. The cache line state
determines what actions are required during access to that cache line.

Additional signaling on the existing AXI4 channels that enable new transactions and information to be
conveyed to locations that require hardware coherency support.

Additional channels that enable communication with a caching Manager when another Manager is accessing
an address location that might be shared.

The ACE protocol also provides:

- Barrier transactions that guarantee transaction ordering within a system, see Barriers on page D1-166. Barrier transactions are not supported in ACE5 and ACE5-Lite variant interfaces.

- Distributed Virtual Memory (DVM) functionality to manage virtual memory, see Distributed Virtual Memory on page D1-167.

### D1.2.2 Coherency model

Figure D1-1 shows an example coherent system that includes three Manager components, each with a local cache.
The ACE protocol permits cached copies of the same memory location to reside in the local cache of one or more
Manager components.

<table>
 <tr>
  <th>Manager1 Manager2 Manager3</th>
 </tr>
 <tr>
  <th>Cache Cache Cache</th>
 </tr>
 <tr>
  <th>Coherent interconnect</th>
 </tr>
 <tr>
  <th>Main<br/>memory</th>
 </tr>
</table>

### Figure D1-1 Example coherent system

The ACE coherency protocol ensures that all Managers observe the correct data value at any given address location
by enforcing that only one copy exists whenever a store occurs to the location. After each store to a location, other
Managers can obtain a new copy of the data for their own local cache, allowing multiple copies to exist.

A cache line is defined as a cached copy of a number of sequentially byte addressed memory locations, with the first
address aligned to the total size of the cache line.

There is no requirement to keep main memory up to date at all times. Main memory is only required to be updated
before a copy of the memory location is no longer held in any cache.

### Note

Although not a requirement, it is acceptable to update main memory while cached copies still exist.

The ACE protocol enables Manager components to determine if a cache line is the only copy of a particular memory
location, or if there might be other copies of the same location, so that:

If a cache line is the only copy, a Manager component can change the value of the cache line without notifying
any other Manager components in the system.

If a cache line might also be present in another cache, a Manager component must notify the other caches,
using an appropriate transaction.

### D1.2.3 Cache state model

To determine whether an action is required when a component accesses a cache line, the ACE protocol defines cache
states. Each cache state is based on a cache line characteristic.

The cache line characteristics are:

### Valid, Invalid

When valid, the cache line is present in the cache. When invalid, the cache line is not present
in the cache.

### Unique, Shared

When unique, the cache line exists only in one cache. When shared, the cache line might
exist in more than one cache, but this is not guaranteed.

### Clean, Dirty

When Clean, the cache does not have responsibility for updating main memory. When Dirty,
the cache line has been modified with respect to main memory, and this cache must ensure
that main memory is eventually updated.

Figure D1-2 shows the ACE five state cache model and Table D1-1 on page D1-154 provides more information
about each state:

<table>
 <tr>
  <th></th>
  <th>Valid</th>
  <th>Invalid</th>
 </tr>
 <tr>
  <td></td>
  <td>Unique Shared</td>
  <td></td>
 </tr>
 <tr>
  <td>Dirty</td>
  <td>UD SD</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>UniqueDirty SharedDirty</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>I</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Invalid</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

### Figure D1-2 ACE cache state model

### Table D1-1 ACE cache states

### State Abbreviation Description

| Invalid | I | The cache line does not exist in this cache. |
| --- | --- | --- |
| UniqueClean | UC | The following rules apply to a cache line that is in the UniqueClean state: |
|  |  | - The cache line is held only in this cache and it has not been modified |
|  |  | with respect to main memory. |
|  |  | - A component can perform a store to the cache line without notifying |
|  |  | other caches. |

UniqueDirty UD

| SharedClean | SC | The following rules apply to a cache line that is in the SharedClean state: |
| --- | --- | --- |
|  |  | - The cache line might be shared with another cache. |
|  |  | - It is not known if the cache line is modified with respect to main |
|  |  | memory, but this component is not responsible for updating main |
|  |  | memory. |
|  |  | - A component must notify other caches before performing a store to |
|  |  | the cache line. |

SharedDirty SD

The following rules apply to a cache line that is in the UniqueDirty state:

- The cache line is held only in this cache.

- The cache line has been modified with respect to main memory and this cache must ensure that the changes are subsequently notified to main memory.

- A component can perform subsequent stores to the cache line without notifying other caches.

The following rules apply to a cache line that is in the SharedDirty state:

- The cache line might be shared with another cache.

- The cache line has been modified with respect to main memory and this cache must ensure that the changes are subsequently notified to main memory.

- A component must notify other caches before performing a store to the cache line.

### Cache state rules

The rules that apply to the cache states are:

- A line in a Unique state must only be in one cache.

- A line that is in more than one cache must be in a Shared state in every cache it is in.

When a cache obtains a new copy of a line, other caches that also have a copy of the line must be notified.
This copy might have the line in a Unique state and must be notified to hold the line in a Shared state.

When a cache discards a copy of a line, there is no requirement to inform other caches that also have a copy
of the line. This requirement means that a line in a Shared state might be held in only one cache.

- A line that has been updated, relative to main memory, must be in a Dirty state in one cache.

A line that has been updated relative to main memory and is in more than one cache, must be in a Dirty state
in only one cache.

### D1.3 Channel overview

This section introduces the signals that the ACE protocol provides, and where appropriate, describes their
relationship to the existing AXI4 channels. The ACE protocol defines:

- Signaling on existing AXI4 channels, see Changes to existing AXI4 channels

- Signaling on ACE-specific channels, see Additional channels defined by ACE
- Acknowledge signaling, see Acknowledge signaling on page D1-156

Channel usage examples on page D1-157 gives examples of the use of the ACE signaling.

### D1.3.1 Changes to existing AXI4 channels

Table D1-2 shows the ACE signals provided on existing AXI4 channels.

Table D1-2 ACE signals provided on existing AXI4 channels

| AXI4 channel | Signal | Source | Description |
| --- | --- | --- | --- |
| Read address |  | Manager | See Read address channel (AR) signals on |
|  |  |  | D2-170. |
|  | ARSNOOP[3:0] | Manager |  |
|  | ARBAR[1:0] | Manager |  |

AWDOMAIN[1:0] Manager

See Write address channel (AW) signals on
page D2-170.

|  | AWSNOOP[2:0] | Manager |
| --- | --- | --- |
|  | AWBAR[1:0] | Manager |
|  | AWUNIQUEa | Manager |
| Read | data RRESP[3:2] | Interconnect See Read data channel (R) signals on page D2-171. |

Write address

a. The AWUNIQUE signal is only required by a component that supports the WriteEvict transaction.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>There are no additional signals on the write data or write response channels.</td>
 </tr>
</table>

### D1.3.2 Additional channels defined by ACE

Three new channels are supported, these are:

- Snoop address channel

- Snoop data channel

- Snoop response channel

The snoop address (AC) channel is an input to a caching Manager that provides the address and associated control
information for snoop transactions.

The snoop response (CR) channel is an output channel from a caching Manager that provides a response to a snoop
transaction. Every snoop transaction has a single response that is associated with it. The snoop response indicates
that an associated data transfer on the CD channel is expected.

The snoop data (CD) channel is an optional output channel that passes snoop data out from a Manager. Typically,
this output occurs for a read or clean snoop transaction when the Manager being snooped has a copy of the data
available to return.

Table D1-3 shows the signals provided on the ACE-specific channels.

Table D1-3 ACE signals provided on ACE-specific channels

ACE-specific
channel

Signal Source Description

Snoop address

ACVALID

ACREADY

Interconnect See Snoop address channel (AC) signals on
page D2-172
Manager

ACADDR[ac-1:0]a Interconnect

| ACSNOOP[3:0] | Interconnect |
| --- | --- |
| ACPROT[2:0] | Interconnect |
| CRVALID | Manager |
| CRREADY | Interconnect |
| CRRESP[4:0] | Manager |
| CDVALID | Manager |
| CDREADY | Interconnect |
|  | Manager |

Snoop response

CDLAST Manager

See Snoop response channel (CR) signals on
page D2-172

See Snoop data channel (CD) signals on
page D2-173

Snoop data

1. ac is the width of the snoop address bus.

2. cd is the width of the snoop data bus.

### D1.3.3 Acknowledge signaling

ACE supports two additional acknowledge signals. These signals indicate that a Manager has completed a read or
write transaction.

Table D1-4 shows the acknowledge signals.

Table D1-4 ACE read and write acknowledge signals

| Signal | Source | Description |
| --- | --- | --- |
| RACK | Manager | See Read acknowledge signal on page D2-174 |
| WACK | Manager | See Write acknowledge signal on page D2-174 |

### Channel usage examples

### D1.3.4

This section describes different examples of how the ACE channels are used when performing load and store
operations.

### Performing load operations from Shareable locations

The following procedure is an example of a Manager component loading data from a Shareable address location,
where the Manager component does not already have a copy of this location in its local cache:

1. The Manager component issues a read transaction on the read address channel.

2. The interconnect determines whether any other cache holds a copy of the location by passing the Shareable address to other caching Manager components that can hold a copy on the snoop address channel. In this context, these are snooped Manager components.

3. The snooped Managers respond on the snoop response channel and optionally provide data on the snoop data channel.

4. If a Manager has provided data, the interconnect can respond to the initiating Manager on the read data channel.

5. If no snooped Manager has provided data: a. The interconnect initiates a transaction to main memory, effectively passing on the transaction from the initiating Manager component.

b. The read data is supplied back to the Manager on the read data channel, as for standard transactions.

6. The Manager component indicates that the transaction has completed, using the RACK signal.

If neither the initiating Manager or the snooped cache takes responsibility for writing a Dirty cache line back to main
memory at a later point in time, the interconnect might have to write data back to main memory at the same time
that it is passed to the initiating Manager component.

If this occurs, then the interconnect must generate the transaction address and write the Dirty data that is returned
from a snooped Manager component.

See Transactions for performing load operations from Shareable locations on page D1-160 for more information.

### Performing store operations to Shareable locations

When a Manager stores to a cache line, to a Shareable location, it removes all other copies of the cache line. This
ensures that the Manager component has a unique copy of the cache line when it performs the store. The new value
of the cache line at that location is propagated to other caches when respective caching Manager components
subsequently read the cache line.

This section describes:

- Store operations for a partial cache line

- Store operations for an entire cache line on page D1-158

- Store operations where the cache line is already cached on page
- Overlapping store operations on page D1-159

See Transactions for performing store operations to Shareable locations on page D1-161 and Transactions for
accessing Shareable locations when no cached copy is required on page D1-161 for more information.

### Store operations for a partial cache line

A Manager component storing only a partial cache line must obtain a current copy of the cache line before
performing the store. An example sequence is:

1. The initiating Manager component obtains a pre-store form of the cache line, and requests that other copies
are removed, by issuing a ReadUnique transaction on the read address channel.

1. The interconnect passes the transaction to other caches on the snoop address channel.

2. Where applicable, a snooped Manager component responds to the transaction using the snoop response channel to indicate that it has the requested cache line. It also provides the cache line to the interconnect, using the snoop data channel.

3. The interconnect passes the cache line, together with a response, to the initiating Manager, using the read data channel.

5. The Manager component performs the store and uses the RACK signal to indicate that the transaction has
completed.

### Note

While the cache line remains unique, loads and stores can be performed with no need for transactions to be broadcast
to other caches.

### Store operations for an entire cache line

A Manager component that is storing an entire cache line does not have to obtain data before storing the cache line.
An example sequence is:

1. The initiating Manager component requests a unique copy of the cache line by issuing a MakeUnique transaction on the read address channel. This removes all other copies of the cache line.

2. The interconnect passes the transaction to other caches on the snoop address channel.

3. Snooped Manager components respond to the transaction using the snoop response channel to indicate that the cache line has been successfully removed.

4. A response is provided to the initiating Manager component, using the read data channel.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>Only the response fields are valid. No data transfer occurs.</td>
 </tr>
</table>

5. The Manager component performs the store and uses the RACK signal to indicate that the transaction has
completed.

### Store operations where the cache line is already cached

For a Manager component that already has a shared copy of the cache line, an example store sequence is:

1. The initiating Manager component requests a unique copy of the cache line by issuing a CleanUnique
transaction on the read address channel. This removes all other copies of the cache line and writes any Dirty
copy to main memory.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>This transaction does not return the cache line to the initiating Manager component.</td>
 </tr>
</table>

1. The interconnect passes the transaction to other caches on the snoop address channel. Snooped Manager components respond to the transaction using the snoop response channel to indicate:
- That the cache line has been successfully removed
- Whether a Dirty cache line must be written to main memory by the interconnect

2. If a Dirty cache line is being written to main memory, the appropriate snooped Manager component provides the Dirty cache line to the interconnect, using the snoop data channel. The interconnect then constructs the transaction to write the Dirty cache line back to main memory.

3. A response is provided to the initiating Manager component, using the read data channel.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>Only the response fields are valid. No data transfer occurs.</td>
 </tr>
</table>

5. The Manager component performs the store and uses the RACK signal to indicate that the transaction has
completed.

### Overlapping store operations

If two Manager components attempt simultaneous Shareable store operations to the same cache line, the
interconnect determines the order that the transactions occur. This section uses the convention:

- Manager1 is the component that the interconnect selects to proceed first.

- Manager2 is the component that the interconnect selects to proceed second.

Manager1 proceeds with the operation as described in Performing store operations to Shareable locations on
page D1-157.

Manager2 uses its snoop port to observe the Manager1 store operation, and the following rules apply:

If Manager2 requires data, it receives the data when its own transaction completes, when it can proceed as
normal with its own store operations.

If Manager2 is performing a full cache line store, it removes any original copy of the data when it observes
the snoop transaction relating to the Manager1 store. However, Manager2 can then proceed with its own full
cache line store when its own transaction completes.

If Manager2 is performing a partial line store, and originally had a copy of the cache line and therefore does
not request a copy of the data then special consideration is required. In this case, when Manager2 observes
the snoop transaction relating to the Manager1 store operation, it must remove its original copy of the data.
Manager2 can then take one of the following options when its transaction completes:

For Manager2 to retain the cache line in its cache, it must issue a new transaction to request a copy of
the data, enabling it to complete the store operation.

-

Manager2 can perform a partial line write to main memory, ensuring the line is updated correctly, but
the Manager does not retain a copy of the cache line in its cache. To access the cache line at a later
point in time, it must fetch the data again.

-

See Sequencing transactions on page D6-249 for more information.

### D1.4

### D1.4.1 Transaction overview

This section introduces the different transaction types. It provides information about when the transactions are used
and the required behavior of the various system components. The section describes:

- Non-snooping transactions
- Coherent transactions
- Memory update transactions on page D1-161
- Cache maintenance transactions on page D1-162
- Snoop transactions on page D1-162
- Barrier transactions on page D1-163
- Distributed virtual memory transactions on page D1-163

### Non-snooping transactions

Non-snooping transactions are used to access memory locations that are not in the caches of other Manager
components. These transactions do not cause snoop transactions to be performed and are used for the following
transaction types:

- Non-shareable.

- Device.

Two forms of non-snooping transaction are provided, ReadNoSnoop and WriteNoSnoop.

### Note

Within the context of coherency, ReadNoSnoop and WriteNoSnoop transactions are also referred to as Read and
Write transactions. The extended form of the name can be used to differentiate between this transaction type and the
more generic set of all read or write transactions.

### D1.4.2

### Coherent transactions

In general, coherent transactions are used to access Shareable address locations, which might be held in the coherent
caches of other components.

### Transactions for performing load operations from Shareable locations

When a Manager is required to perform a load operation from a location in a Shareable area of memory, the
following snoop transactions can be used, all of which permit the current holders of the cache line to retain their
copy:

### ReadClean

The ReadClean transaction indicates that the Manager component requesting the read can
only accept a cache line that is Clean, that is, it cannot accept responsibility for a Dirty line
that it must subsequently write back to memory. Typically, the ReadClean transaction is
used by Manager components that do not have the ability to accept a Dirty cache line, or
have a Write-Through cache.

ReadNotSharedDirty The ReadNotSharedDirty transaction indicates that the Manager requesting the read can
accept a line that is in any state except SharedDirty. This means that the line can be passed
as Clean (either unique or shared) or the line can be passed as unique and Dirty.

The ReadShared transaction indicates that the Manager component requesting the read can
accept a cache line in any state.

### ReadShared

For each of these transactions, it is acceptable for a cache that is being snooped to pass a cache line as Dirty, even
if it cannot be accepted by the Manager component that is requesting the cache line. In this situation, the
interconnect is responsible for writing back the Dirty line to main memory.

If a cache that receives one of these snoop transactions has a copy of the data, this specification recommends that it
provides the data to complete the snoop transaction. The interconnect must pass the data back to the initiating
Manager component.

If the cache that provides the data originally held the line in a Unique state then to retain the copy, it must move the
cache line to a Shared state after the operation.

### Transactions for performing store operations to Shareable locations

When a Manager is required to perform a store to a location in a Shareable area of memory, the following
transactions can be used. All the following transactions ensure that there are no other copies of the location when
the store operation occurs.

### ReadUnique

A Manager component uses the ReadUnique transaction when performing a partial cache
line store, storing only some of the bytes of the cache line. The partial store occurs in cases
where the Manager does not already have a copy of the cache line. The ReadUnique
transaction obtains a copy of the data and ensures that no other copies exist.

### CleanUnique

### MakeUnique

A Manager component uses a CleanUnique transaction when performing a partial cache line
store, in cases where it already has a copy of the cache line. The CleanUnique transaction
removes all other copies of the cache line, but if it finds a cache that holds the line in a Dirty
state then the transaction ensures that the Dirty cache line is written to main memory.

A Manager component uses the MakeUnique transaction when performing a full cache line
store. The MakeUnique transaction invalidates all other copies of the cache line.

### Transactions for accessing Shareable locations when no cached copy is required

When a Manager is required to access a Shareable memory location but the issuing Manager is not going to keep a
cached copy of the address, either because it does not want to allocate that cache line or because it does not have a
cache, the following transactions can be used:

ReadOnce

A Manager component uses the ReadOnce transaction to obtain a snapshot of data that it does not
require to copy to its cache. For the ReadOnce transaction, if the cache that provides the data holds
the cache line in a Unique state, there is no requirement to change the cache line to a Shared state
after the ReadOnce transaction.

### WriteUnique

A WriteUnique transaction can be used to remove all copies of a cache line before issuing a write
transaction. The WriteUnique transaction can be used when writing a full or partial cache line, and
ensures that dirty data is written to memory before performing the write transaction.

### WriteLineUnique

A WriteLineUnique transaction can be used to remove all copies of a cache line before issuing a
write transaction. The WriteLineUnique transaction must be used only when writing a full cache
line, where all bytes within the cache line are written by the transaction.

Note

Unlike other transactions to Shareable memory, ReadOnce and WriteUnique transactions issued by a Manager
component are not required to be a full cache line size. However, WriteLineUnique transactions are required to be
a full cache line size.

### Memory update transactions

### D1.4.3

The following transactions are used to update main memory:

WriteBack

A Manager component cache uses a WriteBack transaction to write back a Dirty line to main
memory to free a cache line that is to be used for a different address. The Manager component does
not retain a copy of the cache line.

### WriteClean

A Manager component cache uses a WriteClean transaction to write a Dirty line to main memory,
while permitting that Manager component to retain a copy of the cache line.

### WriteEvict

### Evict

A WriteEvict transaction can be used to evict a Clean cache line. The transaction is used to write the
line to a lower level of the cache hierarchy, such as an L3 or system level cache. The WriteEvict
transaction is not required to update main memory.

A Manager component uses an Evict transaction to indicate the address of a cache line that is evicted
from its local cache when no main memory update is required. The transaction enables cache lines
in a particular component to be tracked, and can be used for applications such as constructing snoop
filters. No data transfer is associated with Evict transactions.

### D1.4.4 Cache maintenance transactions

Manager components use broadcast cache maintenance transactions to access and maintain the caches of other
Manager components in a system. In particular, cache maintenance transactions enable Manager components to
view the effect of load and store operations on system caches that cannot otherwise be accessed. This process is
typically referred to as Software Cache Maintenance. Broadcast cache maintenance operations can also propagate
to downstream caches, permitting all caches in a system to be maintained.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>A Manager component that initiates a cache maintenance transaction is also responsible for performing the</td>
 </tr>
 <tr>
  <td>appropriate operation on its own local cache.</td>
 </tr>
</table>

The following transactions are used to maintain caches:

A Manager component uses a CleanShared transaction to perform a clean operation on the caches
of other components in the system. If a snooped cache that holds a Dirty cache line receives a
CleanShared transaction, it must provide that cache line so that the cache line can be written to main
memory. The snooped cache can retain its local copy of the cache line.

### CleanShared

A Manager component uses a CleanInvalid transaction to perform a clean and invalidate operation
on the caches of other components in the system. If a snooped cache that holds a Clean cache line
receives a CleanInvalid transaction, it must remove its local copy of the cache line. If a snooped
cache that holds a Dirty cache line receives a CleanInvalid transaction, it must provide that cache
line so that the cache line can be written to main memory and remove its local copy of the cache line.

### CleanInvalid

A Manager component uses a MakeInvalid transaction to perform an invalidate operation on the
caches of other components in the system. If a snooped cache receives a MakeInvalid transaction,
it must remove its local copy, but it is not required to provide any data, even if the cache line is Dirty.

### MakeInvalid

### D1.4.5 Snoop transactions

Snoop transactions are transactions that use the snoop address, snoop response, and snoop data channels. Snoop
transactions are a subset of coherent transactions and cache maintenance transactions.

### D1.4.6 Barrier transactions

Barrier transactions provide guarantees about the ordering and observation of transactions in a system. Barrier
transactions are not supported in ACE5 and ACE5-Lite variant interfaces.

ACE supports the following types of barrier:

- Memory barrier

- Synchronization barrier

A Manager component issues a memory barrier to guarantee that if another Manager in the appropriate domain can
observe any transaction after the barrier it must be able to observe every transaction prior to the barrier.

A Manager component issues a synchronization barrier to determine when all transactions issued before the barrier
are observable by every Manager in a particular domain. Some synchronization barriers also have a requirement
that all transactions that are issued before the barrier transaction must have reached the destination Subordinate
component before the barrier completes.

See Chapter D8 Barrier Transactions for more information.

### D1.4.7 Distributed virtual memory transactions

Distributed Virtual Memory (DVM) transactions are used for virtual memory system maintenance, and typically
pass messages between components within distributed virtual memory systems.

See Chapter D13 Distributed Virtual Memory Transactions for more information.

### D1.5 Transaction processing

When a Manager component issues a transaction, the coherency signaling indicates that the transaction is to a
memory location that is Shareable by more than one component, and therefore requires coherency support.
Typically, transactions are processed as follows:

1. The initiating Manager component issues the transaction.

2. Depending on whether coherency support is required, the transaction is either:
- Passed directly to a Subordinate component, subject to the address decode scheme being used
- Passed to the coherency support logic within the interconnect

3. A coherent transaction is checked against subsequent transactions from other Manager components, to ensure correct processing order.

4. The interconnect determines the snoop transactions that are required.

5. Each caching Manager component that receives a snoop transaction must provide a snoop response. Some Managers might provide snoop data to complete the snoop transaction.

6. The interconnect determines whether a main memory access is required.

7. The interconnect collates snoop responses and any required data.

8. The initiating Manager component completes the transaction.

### D1.6 Concepts required for the ACE specification

The ACE specification defines the following concepts:

- Domains

- Barriers on page D1-166
- Distributed Virtual Memory on page D1-167

### D1.6.1 Domains

The ACE protocol uses a concept that is called shareability domains. A shareability domain is a set of Manager
components that enables a Manager component to determine which other Manager components to include when
issuing coherency or barrier transactions.

For coherent transactions, a Manager component uses the shareability domain to determine which other Manager
components might have a copy of the addressed location in their local cache. The interconnect component uses this
information to determine what other Manager components must be snooped to complete the transaction.

For barrier transactions, a Manager component uses the shareability domain to determine which other Manager
components the barrier is establishing an ordering relationship with. The domain of a barrier transaction can be used
to determine how far a barrier transaction must propagate, and the blocking properties necessary to establish the
required ordering.

The ACE protocol defines the following levels of shareability domain:

Non-shareable

Inner Shareable

Outer Shareable

The domain contains a single Manager component.

The domain can include additional Manager components.

The domain contains at least all Manager components in the Inner domain, but can include
additional Manager components.

### System

The domain includes all Manager components in the system.

Figure D1-3 shows an example set of shareability domains for a system that includes Manager components 0-9:

System

### Figure D1-3 Shareability domains

Although multiple Non-shareable, Inner Shareable, and Outer Shareable domains can exist in a system, there must
be a single consistent definition of the Manager components that are contained in each domain. For example, in
Figure D1-3, because Manager0 has Manager1 in its Inner Shareable domain, then Manager1 must have Manager0
in its Inner Shareable domain.

Domains are defined as non-overlapping. For each Manager component in an Outer Shareable domain, all the other
Manager components in the Inner Shareable domain that includes that Manager component must also be included
in the same Outer Shareable domain.

For transactions that must be visible to all other Manager components in the system, the System domain is used.
Because System domain transactions include Manager components that do not have hardware-coherent caches,
these transactions must not be cached at any level.

In Figure D1-4, from the perspective of Manager0:

- The cache of Manager0 is a local cache.

- The caches of Managers 1-5 are peer caches.
- Caches of Managers 0-2 are in the Inner Shareable domain.
- Caches of Managers 0-5 are in the Outer Shareable domain.
- Cache 1 is a downstream cache.

<table>
 <tr>
  <th rowspan="2">Outer Shareable domain<br/>Inner Shareable domain</th>
 </tr>
 <tr>
 </tr>
 <tr>
  <td>Manager0 Manager1 Manager2 Manager3 Manager4 Manager5</td>
 </tr>
 <tr>
  <td>Interconnect Interconnect</td>
 </tr>
 <tr>
  <td>Outer bi-section boundary Outer bi-section boundary</td>
 </tr>
 <tr>
  <td>Interconnect Subordinate6</td>
 </tr>
 <tr>
  <td rowspan="2">Interconnect Subordinate4 Subordinate5<br/>Subordinate1 Subordinate2 Subordinate3</td>
 </tr>
 <tr>
 </tr>
</table>

### Figure D1-4 Example system using shareability domains

### D1.6.2 Barriers

Barrier transactions provide guarantees about the ordering and observation of transactions in a system. The
following types of barrier transaction are supported:

### Memory barriers

A Manager component issues a memory barrier to guarantee that if another Manager component in
the appropriate domain can observe any transaction after the barrier it must be able to observe every
transaction prior to the barrier.

### Synchronization barriers

A Manager component issues a synchronization barrier to determine when every Manager
component in the appropriate domain can observe all transactions that preceded the barrier
transaction. For System domain synchronization barriers, all transactions that are issued before the
barrier transaction must have reached the destination Subordinate components before the barrier
transaction completes.

A barrier transaction has an address phase and a response, but no data transfer occurs. A Manager component must
issue a barrier transaction on both the read address channel and the write address channel.

Barriers can enforce ordering because a Manager component must not issue any read or write transaction that must
be ordered after the barrier until the Manager component has received a response for the barrier on both read data
and write response channels.

See Chapter D8 Barrier Transactions for more information.

### Distributed Virtual Memory

### D1.6.3

ACE supports Distributed Virtual Memory (DVM) and includes transactions that permit virtual memory system
management. Figure D1-5 shows the basic parts of a virtual memory system.

Manager1 Manager2

Virtual
address

Processor Processor

TLB
MMU

TLB SMMUa
MMU

SMMUa

TLB

TLB

Physical
address

Interconnect

Memory

Memory

Translation tables

a
System Memory Management Unit

### Figure D1-5 Virtual memory system

In Figure D1-5, the System Memory Management Units (SMMUs) translate addresses in the virtual address space
to addresses in the physical address space. Although all components in the system must use a single physical address
space, SMMU components enable different Manager components to operate in their own independent virtual
address or intermediate physical address space.

A typical process in the virtual memory system that is shown in Figure D1-5 might operate as follows:

1. A Manager component operating in a virtual address (VA) space issues a transaction that uses a VA.

2. The SMMU receives the VA, for translation to a physical address (PA):
- If the SMMU has recently performed the requested translation, then it might obtain a cached copy of the translation from its TLB.

Otherwise, the SMMU must perform a translation table walk, accessing translation table in memory
to obtain the required VA to PA translation.

1. The SMMU uses the PA to issue the transaction for the requesting component.

At step 2 of this process, the translation for the required VA might not exist. In this case, the translation table walk
generates a fault, that must be notified to the agent that maintains the translation tables. For the required access to
proceed, that agent must then provide the required VA to PA translation. Typically, it will update the translation
tables with the required information.

Maintaining the translation tables can require changes to translation table entries that are cached in TLBs. To
prevent the use of these entries, a DVM message can be used to issue a TLB invalidate operation.

When the translation tables have been updated, and the required TLB invalidations performed, a DVM Sync
transaction is used to ensure that all required transactions have completed.

See Chapter D13 Distributed Virtual Memory Transactions for more information.

### D1.7 Protocol errors

The protocol defines two categories of protocol errors, a software protocol error and a hardware protocol error.

### D1.7.1 Software protocol error

A software protocol error occurs when multiple accesses to the same location are made with mismatched
shareability or cacheability attributes.

A software protocol error can cause a loss of coherency and result in the corruption of data values. The protocol
requires that the system does not deadlock for a software protocol error, and that transactions always progress
through a system.

A software protocol error for an access in one 4KB memory region must not cause data corruption in a different
4KB memory region.

For locations held in Normal memory, the use of appropriate barriers and software cache maintenance can be used
to return memory locations to a defined state.

When accessing a peripheral device, if Modifiable transactions are used as indicated by AxCACHE[1] = 1, then
the correct operation of the peripheral cannot be guaranteed. The only requirement is that the peripheral continues
to respond to transactions in a protocol-compliant manner. The sequence of events that might be needed to return a
peripheral device, that has been accessed incorrectly, to a known working state is IMPLEMENTATION DEFINED.

### D1.7.2 Hardware protocol error

A hardware protocol error is defined as any protocol error that is not a software protocol error. No support is required
for hardware protocol errors.

If a hardware protocol error occurs, then recovery from the error is not guaranteed. The system might crash, lock
up, or suffer some other non-recoverable failure.

## Chapter D2

### Signal Descriptions

This chapter introduces the additional ACE interface signals. It contains the following sections:

- Changes to existing AXI channels on page D2-170

- Additional channels defined by ACE on page D2-172
- Additional response signals and signaling requirements defined by ACE on page D2-174

Later chapters define the signal parameters and usage.

### D2.1

### D2.1.1

### D2.1.2 Changes to existing AXI channels

The following subsections introduce the additional signals that are defined on the AXI channels:

- Read address channel (AR) signals
- Write address channel (AW) signals
- Read data channel (R) signals on page D2-171

Note

There are no additional signals on the write data channel (W) or the Write response channel (B).

See Chapter A2 Signal Descriptions for the remaining signals on the AXI channels.

### Read address channel (AR) signals

Table D2-1 shows the additional signals on the read address channel. See Read and write address channel signaling
on page D3-176.

Table D2-1 Read address channel signals

| Signal | Source | Description |
| --- | --- | --- |
| ARSNOOP[3:0] | Manager | Indicates the transaction type for Shareable read transactions |
| ARDOMAIN[1:0] | Manager | Indicates the shareability domain of a read transaction |
| ARBAR[1:0] | Manager | Indicates whether a transaction is a read barrier |

### Write address channel (AW) signals

Table D2-2 shows the additional signals on the write address channel. See Read and write address channel signaling
on page D3-176.

Table D2-2 Write address channel signals

| Signal | Source | Description |
| --- | --- | --- |
| AWSNOOP[2:0] | Manager | Indicates the transaction type for Shareable write transactions |
| AWDOMAIN[1:0] | Manager | Indicates the shareability domain of a write transaction |
| AWBAR[1:0] | Manager | Indicates whether a transaction is a write barrier |
| AWUNIQUEa | Manager | Indicates that the data in this transaction is permitted to be held in a |
|  |  | Unique cache state |

a. The AWUNIQUE signal is only required by a component that supports the WriteEvict transaction.

### D2.1.3 Read data channel (R) signals

Table D2-3 shows the additional signals on the read data channel. See Read data channel signaling on page D3-186:

### Table D2-3 Read data channel signals

| Signal | Source | Description |
| --- | --- | --- |
| RRESP[3:2] | Interconnect | Read response, indicates the status of a read transfer |

### D2.2 Additional channels defined by ACE

The following subsections introduce the ACE snoop channels:

- Snoop address channel (AC) signals

- Snoop response channel (CR) signals

- Snoop data channel (CD) signals on page D2-173

### D2.2.1 Snoop address channel (AC) signals

Table D2-4 shows the signals on the snoop address channel. See Snoop address channel signaling on page D3-192.

Table D2-4 Snoop address channel signals

| Signal | Source | Description |
| --- | --- | --- |
| ACVALID | Interconnect | Indicates that the snoop address channel signals are valid |
| ACREADY | Manager | Indicates that a transfer on the snoop address channel can be accepted |
|  | Interconnect | The address of the first transfer in a snoop transaction |
| ACSNOOP[3:0] | Interconnect | Snoop transaction type |
| ACPROT[2:0]b | Interconnect | Protection attributes of a snoop transaction |

1. ac is the width of the snoop address bus.

2. The ACE specification only assigns meaning to ACPROT[1].

### D2.2.2 Snoop response channel (CR) signals

Table D2-5 shows the signals on the snoop response channel. See Snoop response channel signaling on
page D3-195.

Table D2-5 Snoop response channel signals

| Signal | Source | Description |
| --- | --- | --- |
| CRVALID | Manager | Indicates that the snoop response channel signals are valid |
| CRREADY | Interconnect | Indicates that a transfer on the snoop response channel can be accepted |
| CRRESP[4:0] | Manager | Snoop response, indicates the status of a snoop transfer |

### D2.2.3 Snoop data channel (CD) signals

Table D2-6 shows the signals on the snoop data channel. See Snoop data channel signaling on page D3-199.

### Table D2-6 Snoop data channel signals

| Signal | Source | Description |
| --- | --- | --- |
| CDVALID | Manager | Indicates that the snoop data channel signals are valid |
| CDREADY | Interconnect | This signal indicates that the snoop data can be accepted in the current cycle |
|  | Manager | Snoop data |
| CDLAST | Manager | Indicates whether this is the last data transfer in a snoop transaction |

a. cd is the width of the snoop data bus.

### D2.3 Additional response signals and signaling requirements defined by ACE

The following subsections introduce the additional response signals, and an additional signaling requirement,
introduced by ACE:

- Read acknowledge signal
- Write acknowledge signal
- Reset requirements

### D2.3.1 Read acknowledge signal

Table D2-7 shows the additional read acknowledge signal. This signal indicates that a Manager has completed a
read transaction. See Read acknowledge signaling on page D3-189.

Table D2-7 Read acknowledge signal

| Signal | Source | Description |
| --- | --- | --- |
| RACK | Manager | Read acknowledge signal |
| D2-8 | the See | write acknowledge signal. This signal indicates that a Manager has completed a Acknowledge signaling on page D3-191. Table D2-8 Write acknowledge |
| Signal | Source | Description |
| WACK | Manager | Write acknowledge signal |

### D2.3.2 Write acknowledge signal

Table
shows
additional
write transaction.
Write

### D2.3.3 Reset requirements

The ACE protocol uses the AXI single active LOW reset signal ARESETn. See Reset on page A3-40 for the
ARESETn requirements.

During reset, the following interface requirements apply:

- A Manager interface must drive RACK, WACK, CRVALID, and CDVALID LOW.

- An interconnect must drive ACVALID LOW.

The earliest point after reset that the interconnect is permitted to begin driving ACVALID HIGH is at a rising
ACLK edge, after ARESETn is HIGH.

## Chapter D3

### Channel Signaling

This chapter describes the basic channel signaling requirements on an ACE interface. It contains the following
sections:

- Read and write address channel signaling on page D3-176
- Read data channel signaling on page D3-186
- Read acknowledge signaling on page D3-189
- Write response channel signaling on page D3-190
- Write Acknowledge signaling on page D3-191
- Snoop address channel signaling on page D3-192
- Snoop response channel signaling on page D3-195
- Snoop data channel signaling on page D3-199
- Snoop channel dependencies on page D3-201

### D3.1 Read and write address channel signaling

The following sections define the additional signals on the read and write address channels.

### D3.1.1 Shareability domain types

The ACE protocol uses a concept that is called shareability domains. A shareability domain is a set of Managers
that enables a Manager to determine which other Managers to include when issuing coherency or barrier
transactions. See Domains on page D1-165.

Each address channel has its own shareability domain signal. Table D3-1 shows the signal for each address channel:

Table D3-1 Shareability domain signals

| Transaction Channel | Signal | Source | Description |
| --- | --- | --- | --- |
| Read address channel | ARDOMAIN[1:0] | Manager | Indicates shareability domain of a read transaction |
| Write address channel | AWDOMAIN[1:0] | Manager | Indicates shareability domain of a write transaction |

The ACE protocol specifies four levels of shareability domain:

Non-shareable

Inner Shareable

Outer Shareable

The domain contains a single Manager.

The Inner domain can include additional Managers.

The Outer domain contains all Managers in the Inner domain and can include additional
Managers.

System

The System domain includes all Managers in the system.

Use of the Inner Shareable domain is deprecated in ACE5 and ACE5-Lite. See Shareability domain support on
page F5-452 for more details.

### Note

Although multiple Non-shareable, Inner Shareable and Outer Shareable domains can exist in a system, there must
be a single consistent definition of the Managers that are contained in each domain. Figure D1-3 on page D1-165
shows an example set of shareability domains.

In this specification, AxDOMAIN indicates ARDOMAIN or AWDOMAIN.

Table D3-2 shows the AxDOMAIN[1:0] signal encoding.

Table D3-2 Shareability domain encoding

|  | Domain |
| --- | --- |
| 0b00 | Non-shareable |
| 0b01 | Inner Shareable |
| 0b10 | Outer Shareable |
| 0b11 | System |

Restrictions apply to the shareability domain for transactions with different memory types:
- A Device transaction, indicated by AxCACHE[1] equal to zero, must only use domain level System.
- A Cacheable transaction, indicated by AxCACHE[3:2] not equal to zero, must not use domain level System.

Table D3-3 shows all AxCACHE and AxDOMAIN combinations. See AXI4 changes to memory attribute
signaling on page A4-64 for details of the AxCACHE encodings.

### Table D3-3 AxCACHE and AxDOMAIN signal combinations

<table>
 <tr>
  <th>AxCACHE</th>
  <th></th>
  <th>Legal</th>
  <th>Caches accesseda</th>
 </tr>
 <tr>
  <td>Value Attribute Value</td>
  <td>Attribute</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>0b000x Device 0b00</td>
  <td>Non-shareable</td>
  <td>No</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b01</td>
  <td>Inner Shareable</td>
  <td>No</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b10</td>
  <td>Outer</td>
  <td>No</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b11</td>
  <td>System</td>
  <td>Yes</td>
  <td>No caches</td>
 </tr>
 <tr>
  <td>0b001x Non-cacheable 0b00</td>
  <td>Non-shareable</td>
  <td></td>
  <td>No caches</td>
 </tr>
 <tr>
  <td>0b01</td>
  <td>Inner Shareable</td>
  <td></td>
  <td>Inner Shareable peer caches</td>
 </tr>
 <tr>
  <td>0b10</td>
  <td>Outer</td>
  <td></td>
  <td>Outer Shareable peer caches</td>
 </tr>
 <tr>
  <td>0b11</td>
  <td>System</td>
  <td>Yes</td>
  <td>No caches</td>
 </tr>
 <tr>
  <td>0b011x WriteThrough 0b00</td>
  <td>Non-shareable</td>
  <td>Yes</td>
  <td>Downstream caches</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>0b01</td>
  <td>Inner Shareable</td>
  <td>Yes</td>
  <td>Inner Shareable peer caches and</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>downstream caches</td>
 </tr>
 <tr>
  <td>0b10</td>
  <td>Outer</td>
  <td>Yes</td>
  <td>Outer Shareable peer caches and</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>downstream caches</td>
 </tr>
</table>

0b11 System No -

<table>
 <tr>
  <th>a. Shows which caches must be accessed to complete the transaction.</th>
 </tr>
 <tr>
  <th>Note</th>
 </tr>
</table>

Table D3-3 does not include any access that is made to a local cache within the initiating Manager.

The three combinations of AxCACHE and AxDOMAIN that are indicated as Permitted are legal within the
protocol, but not expected. These combinations can be used when a memory location can be cached at a
domain level that requires snooping, but the transaction is deliberately not cached downstream, for example,
in a system level cache.

For transactions where AxCACHE indicates Non-cacheable and AxDOMAIN indicates Inner Shareable or
Outer Shareable it is not required that the data is fetched from the final destination.

When Table D3-3 shows that the caches that are accessed are Outer Shareable peer caches, this includes all
caches that are Inner Shareable peer caches.

A memory location that is indicated as being in the System domain cannot be held in any cache.

### D3.1.2 Read and write barrier transactions

Each address channel has its own barrier transaction signal. Table D3-4 shows the signal for each address channel:

Table D3-4 Barrier transaction signals

Transaction channel

Read address channel

Write address channel

Signal Source Description

ARBAR[1:0] Manager Indicates whether a transaction is a
read barrier.

AWBAR[1:0] Manager Indicates whether a transaction is a
write barrier.

See Barrier transaction signaling on page D8-285.

In this specification, AxBAR indicates ARBAR or AWBAR. Table D3-5 shows the AxBAR[1:0] signal encoding:

Table D3-5 Barrier transaction signal encoding

AxBAR[1:0] Barrier type

| 0b00 | Normal access, respecting barriers |
| --- | --- |
| 0b01 | Memory barrier |
| 0b10 | Normal access, ignoring barriers |
| 0b11 | Synchronization barrier |

### D3.1.3 Read and write Shareable transaction types

Each address channel has its own transaction type signal. Table D3-6 shows the signal for each address channel:

Table D3-6 Shareable transaction type signals

| Transaction channel | Signal | Source | Description |
| --- | --- | --- | --- |
| Read address channel | ARSNOOP[3:0] | Manager | Indicates the transaction type for Shareable |
|  |  |  | read transactions |
| Write address channel | AWSNOOP[2:0] | Manager | Indicates the transaction type for Shareable |
|  |  |  | write transactions |

Transactions on the read and write address channel are categorized into the following groups:

Non-snooping

Coherent

Memory update

Cache maintenance

Barrier

DVM

These transactions must not snoop other Managers.

These transactions are to memory locations that can be held in the cache of other Managers
and require snooping.

These transactions update main memory and must not snoop other Managers.

These transactions are to memory locations that can be held in the cache of other Managers
and require snooping. These transactions might also require to be passed to downstream
caches.

These transactions establish the ordering between other transactions. See Chapter D8
Barrier Transactions.

These transactions pass operations between components that participate in a distributed
virtual memory scheme. See Chapter D13 Distributed Virtual Memory Transactions.

Table D3-7 shows the permitted combinations of ARBAR[0], ARDOMAIN[1:0], and ARSNOOP[3:0] for each
group of read transactions.

All unused ARSNOOP[3:0] encodings are Reserved.

Table D3-7 Permitted read address control signal combinations

| Transaction |  |  | ARSNOOP | Transaction type |
| --- | --- | --- | --- | --- |
| Non-snooping | 0b0 | 0b00 | 0b0000 | ReadNoSnoop |
|  |  | 0b11 |  |  |

<table>
 <tr>
  <th>Coherent 0b0</th>
  <th>0b01 0b0000</th>
  <th>ReadOnce</th>
 </tr>
 <tr>
  <td></td>
  <td>0b10</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>0b0010</td>
  <td>ReadClean</td>
 </tr>
</table>

| 0b0011 | ReadNotSharedDirty |
| --- | --- |
| 0b0111 | ReadUnique |
| 0b1011 | CleanUnique |
| 0b1100 | MakeUnique |
| 0b1000 | CleanShared |
| 0b1001 | CleanInvalid |

Cache maintenance

0b0

Barrier

0b1

0b00
0b01
0b10
0b1101 MakeInvalid

0b00 0b0000 Barrier
0b01
0b10
0b11

0b10

Table D3-8 shows the permitted combinations of AWBAR[0], AWDOMAIN[1:0], and AWSNOOP[2:0] for each
group of write transactions.

All unused AWSNOOP[2:0] encodings are Reserved.

Table D3-8 Permitted write address control signal combinations

<table>
 <tr>
  <th>Transaction group</th>
  <th>AWBAR[0]</th>
  <th>AWDOMAIN</th>
  <th>AWSNOOP</th>
  <th>Transaction type</th>
 </tr>
 <tr>
  <td>Non-snooping</td>
  <td>0b0</td>
  <td>0b00<br/>0b11</td>
  <td>0b000</td>
  <td>WriteNoSnoop</td>
 </tr>
 <tr>
  <td>Coherent</td>
  <td>0b0</td>
  <td>0b01<br/>0b10</td>
  <td>0b000<br/>0b001</td>
  <td>WriteUnique<br/>WriteLineUnique</td>
 </tr>
 <tr>
  <td rowspan="3">Memory update</td>
  <td rowspan="3">0b0</td>
  <td>0b00<br/>0b01<br/>0b10</td>
  <td>0b010<br/>0b011</td>
  <td>WriteClean<br/>WriteBack</td>
 </tr>
 <tr>
  <td>0b01<br/>0b10</td>
  <td>0b100</td>
  <td>Evict</td>
 </tr>
 <tr>
  <td>0b00<br/>0b01<br/>0b10</td>
  <td>0b101</td>
  <td>WriteEvicta</td>
 </tr>
 <tr>
  <td>Barrier</td>
  <td>0b1</td>
  <td>0b00<br/>0b01<br/>0b10<br/>0b11</td>
  <td>0b000</td>
  <td>Barrier</td>
 </tr>
</table>

a. A component that supports the WriteEvict transaction must provide the AWUNIQUE signal.

### Note

A component without a cache only needs to indicate the shareability of a write transaction using AWDOMAIN and
can tie AWSNOOP to zero. As Table D3-8 shows, if the transaction is Non-shareable it is treated as a
WriteNoSnoop transaction and if the transaction is Shareable it is treated as a WriteUnique transaction.

### D3.1.4 AWUNIQUE signal

The AWUNIQUE signal is a write address channel signal that can be used with various write transactions to
improve the operation of lower levels of the cache hierarchy, such as an L3 or system-level cache. Table D3-9 shows
the AWUNIQUE signaling requirements for different write transactions:

Table D3-9 AWUNIQUE signaling requirements for different write transactions

### Transaction type

AWUNIQUE requirement

### Notes

WriteNoSnoop Has no meaning. Can be asserted or -
deasserted.

WriteUnique Can be asserted if the Manager is not -
keeping a copy of the cache line.
Must be deasserted if the Manager issuing
the transaction is keeping a copy of the
cache line.

WriteLineUnique Can be asserted if the Manager is not -
keeping a copy of the cache line.
Must be deasserted if the Manager issuing
the transaction is keeping a copy of the
cache line.

WriteClean

Must be deasserted.

The cache line cannot be held in a Unique
state as the Manager issuing the transaction
is keeping a copy.

| WriteBack | Can be asserted if the cache line was held | It is permitted to deassert the signal |
| --- | --- | --- |
|  | in a Unique state. Must be deasserted if the | alongside a WriteBack transaction even if |
|  | cache line was in a Shared state. | the cache line was held in a Unique state. |

WriteEvict

Must be asserted.

A WriteEvict transaction is only permitted
for a cache line in a UniqueClean state and
therefore the cache line must have been in
a Unique state.

Evict Has no meaning. Can be asserted or -
deasserted.

Barrier Has no meaning. Can be asserted or -
deasserted.

While a WriteBack or WriteEvict transaction is in progress that has the AWUNIQUE signal asserted, the Manager
must not give a snoop response that would allow another copy of the cache line to be created, or an agent to consider
that it has another Unique copy of the cache line.

It is a requirement that a Manager that supports the WriteEvict transaction, supports the AWUNIQUE signal.

A Manager that implements the AWUNIQUE signal can be connected to an interconnect that does not implement
the signal. There is no loss in functionality.

A Manager that does not support the AWUNIQUE signal can be connected to an interconnect that does support the
signal. In this case, the input to the interconnect must be tied low. This is protocol-compliant as all transactions are
permitted to drive AWUNIQUE LOW, with the exception of a WriteEvict transaction.

### D3.1.5 Cache line size restrictions

The cache line size that each ACE Manager can support is determined at design time.

Restrictions apply to the minimum and maximum cache line sizes that can be supported.

The minimum cache line size is 16 bytes.

The maximum cache line size is the smaller of:

- 2048 bytes

- The product of the maximum burst length of 16 and the width

- f the data bus in bytes

### D3.1.6 Transaction constraints

The following sections define the constraints for:

- Cache line size transactions
- ReadOnce and WriteUnique transactions on page D3-184
- WriteBack and WriteClean transactions on page D3-184
- Barrier transactions on page D3-185

### Cache line size transactions

The following transactions must be of cache line size:

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

- CleanUnique

- MakeUnique

- CleanShared

- CleanInvalid

- MakeInvalid

- WriteLineUnique

- WriteEvict

- Evict

Cache line size transactions must comply with the constraints for Regular transactions. See Regular transactions on
page A3-53. Table D3-10 shows the full list of constraints that apply to cache line size transactions.

### Table D3-10 Cache line size transaction constraints

| Attribute | Condition | Constraint |
| --- | --- | --- |
| AxLEN | - | The burst length must be 1, 2, 4, 8 or 16 transfers. See Burst length on |
|  |  | page A3-48. |
| AxSIZE | - | If the burst length is greater than 1, the number of bytes in a transfer must |
|  |  | be equal to the data bus width. See Burst size on page A3-49. |
| AxBURST | INCR | The address must be aligned to the cache line size, which is equal to |
|  |  | (AxLEN x AxSIZE), the total burst length in bytes. See Burst type on |
|  |  | page A3-49. |
|  | WRAP | The address must be aligned to AxSIZE, which is equal to the data bus |
|  |  | width. |
|  | FIXED | Not supported. |

### Table D3-10 Cache line size transaction constraints (continued)

### Attribute Condition Constraint

### AxDOMAIN

All transactions
except:
CleanShared
CleanInvalid
MakeInvalid
or WriteEvict

CleanShared
CleanInvalid
MakeInvalid
and WriteEvict

| AxCACHE | - | Must be Modifiable. |
| --- | --- | --- |
| AxLOCK | - | Must be: |
|  |  | 0b0 If the transaction is ReadNotSharedDirty, ReadUnique, |
|  |  | MakeUnique, CleanShared, CleanInvalid, MakeInvalid, |
|  |  | WriteLineUnique, WriteEvict or Evict. |
|  |  | 0b0 or 0b1 If the transaction is ReadClean, ReadShared, or |
|  |  | CleanUnique. |

The domain must be Inner Shareable or Outer Shareable.

The domain must be Non-shareable, Inner Shareable or Outer Shareable.

### AxBAR -

Must be a normal access.

| AxPROT | - | No constraint, can take any value. |
| --- | --- | --- |
| AxQOS | - | No constraint, can take any value. |

WriteLineUnique and WriteEvict transactions are required to have every write data strobe asserted, that is, sparse
write data strobes are not permitted.

The following transactions must use AxLEN to indicate the correct cache line size, even though these transactions
do not transfer data:

- CleanUnique

- MakeUnique

- CleanShared

- CleanInvalid

- MakeInvalid

- Evict

### ReadOnce and WriteUnique transactions

The ReadOnce and WriteUnique transactions are not constrained to cache line size. This permits legacy components
to operate in a coherent environment by adding an appropriate domain to Modifiable transactions.

Table D3-11 shows the constraints that apply to ReadOnce and WriteUnique transactions.

Table D3-11 ReadOnce and WriteUnique transaction constraints

<table>
 <tr>
  <th>Attribute</th>
  <td>Constraint</td>
 </tr>
 <tr>
  <th>AxDOMAIN</th>
  <td>Must be Inner Shareable or Outer Shareable</td>
 </tr>
 <tr>
  <th>AxBURST</th>
  <td>Must be INCR or WRAP</td>
 </tr>
 <tr>
  <th>AxCACHE</th>
  <td>Must be Modifiable</td>
 </tr>
 <tr>
  <th>AxLOCK</th>
  <td>Must be normal access</td>
 </tr>
 <tr>
  <th>AxPROT</th>
  <td>No constraint, can take any value</td>
 </tr>
 <tr>
  <th>AxQOS</th>
  <td>No constraint, can take any value</td>
 </tr>
</table>

WriteUnique transactions are not required to have every write data strobe asserted, that is, sparse write data strobes
are permitted.

### Note

The FIXED burst type is not supported for ReadOnce and WriteUnique transactions. Any conversion from AXI to
ACE-Lite must provide a translation for a FIXED burst.

<table>
 <tr>
  <th>Attribute</th>
  <td></td>
  <td>Constraint</td>
 </tr>
 <tr>
  <th>AWLEN</th>
  <td>-</td>
  <td>Normal restrictions apply. See Address structure on page A3-48.</td>
 </tr>
 <tr>
  <th>AWSIZE</th>
  <td>-</td>
  <td>Normal restrictions apply. See Address structure on page A3-48.</td>
 </tr>
</table>

### WriteBack and WriteClean transactions

The WriteBack and WriteClean transactions are not constrained to cache line size. A partial update of a cache line
is permitted. However, WriteBack and WriteClean transactions are constrained to updates within a single cache line.

Table D3-12 shows the constraints that apply to WriteBack and WriteClean transactions.

Table D3-12 WriteBack and WriteClean transaction constraints

AWBURST WRAP

The address must be aligned to AxSIZE, which is equal to the data bus
width.
The burst length must be 2, 4, 8 or 16.
AWSIZE x AWLEN must not exceed the cache line size in bytes.

INCR

The burst length must be 16 or less.
The transaction must not cross a cache line boundary. The location of the last
byte in the burst is determined by (AWSIZE × AWLEN) added to the
AWSIZE aligned start address. The location of this last byte must fall within
the same cache line as the first byte in the burst.

FIXED Not supported.

### AWDOMAIN -

AWBAR -

Must not be domain type System.

Must be normal access.

Table D3-12 WriteBack and WriteClean transaction constraints (continued)

<table>
 <tr>
  <th>Attribute</th>
  <td></td>
  <td>Constraint</td>
 </tr>
 <tr>
  <th>AWCACHE</th>
  <td>-</td>
  <td>Must be Modifiable.</td>
 </tr>
 <tr>
  <th>AWLOCK</th>
  <td>-</td>
  <td>Must be normal access.</td>
 </tr>
 <tr>
  <th>AWPROT</th>
  <td>-</td>
  <td>No constraint, can take any value.</td>
 </tr>
 <tr>
  <th>AWQOS</th>
  <td>-</td>
  <td>No constraint, can take any value.</td>
 </tr>
</table>

The WriteBack and WriteClean transactions are permitted to use sparse write data strobes.

Components that support a snoop filter must correctly indicate the shareability domain for all WriteBack,
WriteClean, and Evict transactions. This enables a snoop filter to track the allocation of Inner Shareable and Outer
Shareable transactions.

A snoop filter must not track the allocation of Non-shareable transactions because notification of the eviction of the
associated cache line is not required.

Components that do not support a snoop filter can use any of the following domains for WriteBack or WriteClean
transactions:

- Non-shareable

- Inner Shareable

- Outer Shareable

### Barrier transactions

For a barrier transaction, as indicated by AxBAR[0] equal to 1, constraints apply to the read address and write
address signals. Table D3-13 shows the constraints that apply:

Table D3-13 Barrier transaction constraints

<table>
 <tr>
  <th>Attribute</th>
  <td>Constraint</td>
 </tr>
 <tr>
  <th>AxADDR</th>
  <td>Must be all zeros</td>
 </tr>
 <tr>
  <th>AxBURST</th>
  <td>Must be burst type INCR</td>
 </tr>
 <tr>
  <th>AxLEN</th>
  <td>Must be all zeros</td>
 </tr>
 <tr>
  <th>AxSIZE</th>
  <td>Must be equal to the data bus width</td>
 </tr>
 <tr>
  <th>AxCACHE</th>
  <td>Must be Normal, Non-cacheable</td>
 </tr>
 <tr>
  <th>AxPROT</th>
  <td>No constraint, can take any value</td>
 </tr>
 <tr>
  <th>AxLOCK</th>
  <td>Must be normal access</td>
 </tr>
 <tr>
  <th>AxSNOOP</th>
  <td>Must be all zeros</td>
 </tr>
</table>

Note

A barrier transaction can have any shareability domain. The choice of domain is used to determine the precise
behavior of the barrier with respect to other Managers in the system. See Chapter D8 Barrier Transactions.

### D3.2 Read data channel signaling

The following sections define the additional response and acknowledge signaling and constraints on the read data
channel. See Read and write response structure on page A3-59 for information on the baseline read response
signaling.

### D3.2.1 Read response signaling

Table D3-14 shows the additional read response signals:

### Table D3-14 Additional RRESP read response bits

### Signal Source Name Meaning

RRESP[2] Interconnect PassDirty HIGH

RRESP[3] Interconnect IsShared

LOW

HIGH

LOW

The cache line is Dirty with respect to main memory
and the initiating Manager must ensure that the
cache line is written back to main memory, at some
time. The initiating Manager must either perform the
write, or pass the responsibility to perform the write
to another Manager.

It is not the responsibility of the initiating Manager
to ensure that the cache line is written back to main
memory.

Another copy of the associated data might be held in
another cache and the cache line must be held in a
Shared state.

It is the only cached copy of the associated data and
the cache line can be held in a Unique state.

The IsShared and PassDirty responses have the following restrictions:

- The IsShared and PassDirty responses must be constant for all data transfers within a burst.

The IsShared response must be LOW for the transactions that require all other cached copies to be removed.
The transactions that require all other cached copies to be removed are:
- ReadUnique
- CleanUnique
- MakeUnique
- CleanInvalid
- MakeInvalid

The PassDirty response must be LOW for the transactions that do not permit the passing of Dirty data. The
transactions that do not permit the passing of Dirty data are:
- ReadOnce
- ReadClean
- CleanUnique
- MakeUnique
- CleanShared
- CleanInvalid
- MakeInvalid

The IsShared and PassDirty response must be LOW for the following transactions for because they have no
meaning for those responses:
- ReadNoSnoop
- Barrier transactions
- DVM transactions

The value of RRESP[3:2] must be the same for all data transfers in a burst.

The following transactions have a single read data channel transfer:

- CleanUnique

- MakeUnique

- CleanShared

- CleanInvalid

- MakeInvalid

- Barrier

- DVM

These transactions complete in a single read data channel transfer and must have RLAST asserted. RDATA can
have any value and must be ignored.

The EXOKAY response is only permitted for a ReadNoSnoop, ReadClean, ReadShared or CleanUnique
transaction. See Read and write response structure on page A3-59.

Table D3-15 shows the permitted IsShared and PassDirty responses for each transaction:

### Table D3-15 IsShared and PassDirty permitted responses

<table>
 <tr>
  <th>Transaction</th>
  <th>IsShared</th>
  <th>PassDirty</th>
 </tr>
 <tr>
  <td>ReadNoSnoop</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>ReadOnce</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>0</td>
 </tr>
 <tr>
  <td>ReadClean</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>0</td>
 </tr>
 <tr>
  <td>ReadNotSharedDirty</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>0</td>
 </tr>
 <tr>
  <td>ReadShared</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>1</td>
 </tr>
 <tr>
  <td>ReadUnique</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>CleanUnique</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>MakeUnique</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>CleanShared</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <td></td>
  <td>1</td>
  <td>0</td>
 </tr>
</table>

### Table D3-15 IsShared and PassDirty permitted responses (continued)

<table>
 <tr>
  <th>Transaction</th>
  <td>IsShared PassDirty</td>
 </tr>
 <tr>
  <th>CleanInvalid</th>
  <td>0</td>
 </tr>
 <tr>
  <th>MakeInvalid</th>
  <td>0</td>
 </tr>
 <tr>
  <th>Read Barrier</th>
  <td>0</td>
 </tr>
 <tr>
  <th>DVM Message</th>
  <td>0</td>
 </tr>
 <tr>
  <th>DVM Complete</th>
  <td>0</td>
 </tr>
</table>

Note

Table D3-15 on page D3-187 only shows the permitted responses on RRESP[3:2]. For the permitted responses on
CRRESP, see Snoop response channel signaling on page D3-195.

### D3.3 Read acknowledge signaling

Table D3-16 shows the additional read acknowledge signal. This signal indicates that a Manager has completed a
read transaction.

### Table D3-16 Read acknowledge signaling.

| Signal | Source | Description |
| --- | --- | --- |
| RACK | Manager | Read acknowledge signal |

The RACK signal must be asserted for a single cycle and the interconnect must accept it in a single cycle.

The RACK signal must not be asserted before the cycle after the completion of the associated RVALID/RREADY
handshake of the last read data channel transfer, as indicated by RLAST. The assertion of RACK must not be
delayed to wait for the completion of another transaction. See Handshake process on page A3-41.

Read acknowledge must be sent for all transactions including coherent, barrier, and DVM transactions.

No ordering information is associated with read acknowledge, it is ordered the same as the last read data item and
the associated read responses.

The interconnect must use read acknowledge to ensure that a transaction to a Manager's snoop port is not issued
until any preceding transaction from that Manager to the same address has completed. See Read and Write
Acknowledge on page D6-250.

### D3.4 Write response channel signaling

Write transactions do not have additional response signaling. See Read and write response structure on page A3-59
for information on the baseline write response signaling.

The order that write responses for a single AXI ID are provided is the same as the order that the transactions are
issued on the AW channel. Leading write data does not change the order in which the write responses are provided.

Note

The EXOKAY response is only permitted for a WriteNoSnoop transaction.

### D3.5 Write Acknowledge signaling

Table D3-17 shows the additional write acknowledge signal. This signal indicates that a Manager has completed a
write transaction.

### Table D3-17 Write acknowledge signaling

| Signal | Source | Description |
| --- | --- | --- |
| WACK | Manager | Write acknowledge signal |

The WACK signal is asserted by a Manager for a single cycle and the interconnect must accept the WACK signal
in a single cycle.

The WACK signal must not be asserted before the cycle after the completion of the associated BVALID/BREADY
handshake. The assertion of WACK must not be delayed to wait for the completion of another transaction. See
Handshake process on page A3-41.

Write acknowledge, WACK is asserted for all write transactions, including barrier transactions.

No ordering information is associated with write acknowledge, it is ordered the same as the associated write
responses.

The interconnect must use write acknowledge to ensure that a transaction to a Manager's snoop port is not issued
until any preceding transaction from that Manager to the same address has completed. See Read and Write
Acknowledge on page D6-250.

### D3.6 Snoop address channel signaling

The following sections define the snoop address channel and signals.

### D3.6.1 About the snoop address channel

The snoop address channel (AC channel) is necessary for a Manager that:

- Holds cached copies of shared data

- Supports DVM transactions

The snoop address channel is an input channel to a caching Manager. The snoop address channel passes the snoop
transactions of other components to a caching Manager so that the Manager can determine what actions it must take.
The Manager can respond to the snoop transactions in different ways and its response determines what action the
interconnect must take to complete the snoop process.

### Supplementary information

Control information on the snoop address channel is a subset of the control information on the normal address
channel. It provides sufficient information for the coherency operations, but does not provide unnecessary
information. The snoop address channel does not provide information on the:

- Burst type

- Burst length

- Transaction size

- Modifiable or Shareable nature of the transaction

- Transaction ID

Fundamentally, the snoop address channel provides the same transactions that are issued on the normal read and
write address channels. However, there are a number of exceptions.

The following transactions are not presented on the snoop address channel:

Non-snooping type transactions. These transactions are:
- ReadNoSnoop
- WriteNoSnoop
- WriteBack
- WriteClean
- WriteEvict
- Evict

WriteUnique. Other caching Managers see a transaction, such as CleanInvalid. This ensures that all other
copies of the cache line are cleaned to main memory and removed before the write occurs.

WriteLineUnique. Other caching Managers see a transaction, such as MakeInvalid. This ensures that all other
copies of the cache line are removed before the write occurs.

MakeUnique. Typically, this transaction is converted to a MakeInvalid transaction.

CleanUnique. Typically, this transaction is converted to a CleanInvalid transaction.

Some snoop operations can be fulfilled without snooping every caching Manager in the system. Therefore, the
snoop address channel for a caching Manager might not provide every snoop transaction.

Snoop read transactions can be adapted by the interconnect so that when the required data is obtained, further snoops
to other Managers are not requested.

Transactions that are not required to be a full cache line length are converted to be a full cache line length. These
transactions are:

- ReadOnce

- WriteUnique

### D3.6.2 Snoop address channel signaling

Table D3-18 shows the signals on the snoop address channel.

Table D3-18 Snoop address channel signals

| Signal | Source | Description |
| --- | --- | --- |
| ACVALID | Interconnect | Indicates the snoop address channel signals are valid |
| ACREADY | Manager | Indicates a transfer on the snoop address channel can be accepted |
|  | Interconnect | The address of the first transfer in a snoop transaction |
| ACSNOOP[3:0] | Interconnect | Snoop transaction type. See Table D3-19 |
| ACPROT[2:0] | Interconnect | Protection attributes of a snoop transaction |

a. ac is the width of the snoop address bus.

The standard AXI VALID/READY handshake rules apply. See Handshake process on page A3-41.

When the ACVALID signal is asserted the snoop address and control signals on ACADDR, ACPROT, and
ACSNOOP must not change, until ACREADY is asserted by the Manager. When ACVALID is asserted, it must
remain asserted until ACREADY is asserted.

It is permitted to assert ACREADY before or in the same cycle as ACVALID. If ACREADY is asserted before
ACVALID, then ACREADY can be deasserted without ACVALID being asserted.

ACADDR must be aligned to the data transfer size, which is determined by the width of the snoop data bus in bytes.

ACPROT[1] indicates the Secure or Non-secure nature of the snoop transaction.

For coherency transactions, ACPROT[1] can be considered as defining two address spaces, a Secure address space
and a Non-secure address space, and can be treated as an additional address bit. Any aliasing between the Secure
and Non-secure address spaces must be handled correctly.

Hardware coherency does not manage coherency between Secure and Non-secure address spaces.

ACSNOOP indicates the snoop transaction type. Not all transaction types, observed on the read address channel or
write address channel can be observed on the snoop address channel. Table D3-19 shows the ACSNOOP encodings
for the transactions that can be observed on the snoop address channel. All unused encodings are Reserved.

Table D3-19 ACSNOOP encodings

|  | Transaction |
| --- | --- |
| 0b0000 | ReadOnce |
| 0b0001 | ReadShared |
| 0b0010 | ReadClean |
| 0b0011 | ReadNotSharedDirty |
| 0b0111 | ReadUnique |
| 0b1000 | CleanShared |

0b1001 CleanInvalid

### Table D3-19 ACSNOOP encodings (continued)

|  | Transaction |
| --- | --- |
| 0b1101 | MakeInvalid |
| 0b1110 | DVM Complete |
| 0b1111 | DVM Message |

A snoop transaction of burst length greater than one must be of burst type WRAP. A snoop transaction of burst
length one must be of burst type INCR.

A snoop transaction must be a full cache line in length.

### Note

If the original transaction that caused the snoop process was not a full cache line in length, then the interconnect
must convert it to be a full cache line in length.

A snoop transaction must be the same width as the snoop data channel.

### D3.7 Snoop response channel signaling

Table D3-20 shows the signals on the snoop response channel.

Table D3-20 Snoop response channel signals

| Signal | Source | Meaning | Description |
| --- | --- | --- | --- |
| CRVALID | Manager | Snoop response | Indicates that the snoop response channel signals |
|  |  | valid. | are valid. |
| CRREADY | Interconnect | Snoop response | Indicates that a transfer on the snoop response |
|  |  | ready. | channel can be accepted. |
| CRRESP[4:0] | Manager | Snoop response. | Read response, indicates the status of a snoop |
|  |  |  | transfer. |

The standard AXI VALID/READY handshake rules apply. See Handshake process on page A3-41.

When the CRVALID signal is asserted, the snoop response must not change until the interconnect sets CRREADY
HIGH. When CRVALID is asserted, it must remain asserted until CRREADY is asserted.

It is permitted to assert CRREADY before or in the same cycle as CRVALID. If CRREADY is asserted before
CRVALID, then CRREADY can be deasserted without CRVALID being asserted.

A snoop response is required on the snoop response channel for each snoop address that is presented to a caching
Manager on the snoop address channel.

All snoop transactions are ordered. A response on the snoop response channel must be in the same order as the
addresses on the snoop address channel.

Table D3-20 shows the allocation of each bit of CRRESP[4:0].

Table D3-21 Snoop response bit allocations

| Signal | Name | Meaning |  |
| --- | --- | --- | --- |
| CRRESP[0] |  | HIGH | Indicates that a full cache line of data will be provided on the |
|  |  |  | snoop data channel for this transaction. |
|  |  | LOW | Indicates that no data will be provided on the snoop data |
|  |  |  | channel for this transaction. |
| CRRESP[1] | Error | HIGH | When HIGH, the Error bit indicates that the snooped cache line |
|  |  |  | is in error. Typically, this is caused by a corrupt cache line that |
|  |  |  | has been detected through the use of an Error Correction Code |
|  |  |  | (ECC) system. |
|  |  | LOW | Indicates that no Error condition has been detected. |

CRRESP[2] PassDirty

HIGH

LOW

When HIGH, it indicates that before the snoop process, the
cache line was held in a Dirty state and the responsibility for
writing the cache line back to main memory is being passed to
the initiating Manager or the interconnect.
For all transactions, except MakeInvalid, if the cache line was
held in a Dirty state before the snoop process and a copy is not
being retained by the cache, then the PassDirty bit must be set
HIGH.

Indicates the responsibility for writing the cache line back to
main memory is not being passed.

### Table D3-21 Snoop response bit allocations (continued)

| Signal | Name | Meaning |  |
| --- | --- | --- | --- |
| CRRESP[3] | IsShared | HIGH | Indicates that the snooped cache retains a copy of the cache line |
|  |  |  | after the snoop process has completed. |
|  |  | LOW | Copy of cache line was not retained. |
| CRRESP[4] | WasUnique | HIGH | Indicates that the cache line was held in a Unique state before |
|  |  |  | the snoop process. |
|  |  |  | The WasUnique bit must only be HIGH if it is known that no |
|  |  |  | other cache can have a copy of the cache line. |
|  |  | LOW | No information is provided on whether or not the cache line was |
|  |  |  | held in a Unique state before the snoop process. |

The meaning of the snoop response bits and the limitations of use are as follows:

### DataTransfer bit

The snoop transaction type and the state of the cache line in the snooped cache determine whether
the DataTransfer bit is set HIGH and a data transfer occurs.

For the following transactions, a data transfer occurs if the snoop process has resulted in a cache hit:

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

If the cache line is Clean, it is not mandatory that data transfer occurs. However, this specification
recommends that data transfer still occurs.

For the following transactions, data transfer must occur if the snoop process has resulted in a cache
hit and the cache line is Dirty:

- CleanInvalid

- CleanShared

A MakeInvalid transaction never requires a data transfer.
The DataTransfer bit can be set to 1 and data can be returned on the snoop data channel when it is
not required. For example, a CleanInvalid transaction can return data when it holds the cache line
in a Clean state, and a MakeInvalid transaction can return data. However, this specification does not
recommend this use of the snoop data channel.

Note

The protocol permits the return of data on the snoop data channel when it is not required to enable
a simplified snoop port implementation to handle a MakeInvalid transaction in the same manner as
a ReadUnique or CleanInvalid, and a CleanInvalid transaction to be handled in the same manner as
a ReadUnique.

If an error is detected, the snooped cache can take appropriate action, such as discarding a Clean
cache line. Alternatively, the snooped cache can flag the error by setting the Error bit HIGH and take
no further action.

### PassDirty bit

For the following transactions, the responsibility for writing the Dirty cache line back to main
memory can be passed to the Manager requesting the data:

- ReadNotSharedDirty

- ReadShared

- ReadUnique

In other cases, such as ReadClean, the Dirty cache line must be written back to main memory by the
interconnect.

### IsShared bit

The restrictions on the use of IsShared are:

- For the following transactions, the cache line in the snooped cache must be invalidated and the IsShared response must be LOW:
  - ReadUnique
  - CleanInvalid
  - MakeInvalid

- For the following transactions, the snooped cache can determine if it retains a copy of the cache line after the snoop process has completed, and the snooped cache must use the IsShared bit to signal the outcome:
  - ReadOnce
  - ReadClean
  - ReadNotSharedDirty
  - ReadShared
  - CleanShared

Typically, a snooped cache retains a local copy of the cache line after the snoop process has
completed. However, there are cases when a snooped cache does not retain a local copy, such as
when passing the cache line as unique to another cache in response to a ReadNotSharedDirty snoop
transaction.

### WasUnique bit

A WasUnique response permits the snoop process to be terminated because no other cache can hold
a copy of the cache line.

The protocol permits a cache to not generate a WasUnique response. In this case, the WasUnique bit
must be permanently LOW.

Table D3-22 shows the CRRESP response meanings and transactions for which they are valid.Table D3-22 does
not show the Error bit CRRESP[1], of the response field, because the value of this bit does not affect the meaning
of the other snoop response bits. In this table:

The meaning of the bits in the CRRESP response fields, when asserted, are:
WU, WasUnique The cache line was in Unique state before this snoop.
IS, IsShared The cache is keeping a copy of this cache line after this snoop.
PD, PassDirty The cache line was Dirty before this snoop. This response transfers responsibility for
updating main memory, as well as the data.
DT, DataTransfer The response to the snoop transaction includes a transfer on the snoop data channel.

The snoop transactions are abbreviated as follows:
RO ReadOnce
RC ReadClean
RN ReadNotSharedDirty
RS ReadShared
RU ReadUnique
CI CleanInvalid
MI MakeInvalid
CS CleanShared

Whether a response is permitted, for each transaction, is indicated as follows:
E Expected response
P Permitted response
No Response not permitted

Table D3-22 Response meanings and transactions for which they are valid

The following responses are illegal:

IsShared, CRRESP[3] = 1 for:
- ReadUnique
- CleanInvalid
- MakeInvalid

- PassDirty, CRRESP[2] = 1, and DataTransfer, CRRESP[0] = 0, for any transaction.

### D3.8 Snoop data channel signaling

Table D3-23 shows the signals on the snoop data channel.

### Table D3-23 Snoop data channel signals

| Signal | Source | Description |
| --- | --- | --- |
| CDVALID | Manager | Indicates that the snoop data channel signals are valid . |
| CDREADY | Interconnect | This signal indicates the snoop data can be accepted in the current cycle. |
|  | Manager | Snoop data. |
| CDLAST | Manager | Indicates whether this is the last data transfer in a snoop transaction. |

a. cd is the width of the snoop data bus.

The standard AXI VALID/READY handshake rules apply. See Handshake process on page A3-41.

If the CDVALID signal is asserted, the data value on CDDATA and the last transfer indication on CDLAST, must
not change until CDREADY is asserted to indicate that the information has been accepted by the interconnect.
When CDVALID is asserted, it must remain asserted until CDREADY is asserted.

The assertion of CDREADY is permitted before, or in the same cycle as, CDVALID. If CDREADY is asserted
before CDVALID, then CDREADY can be deasserted without CDVALID being asserted.

The width of the snoop data bus, CDDATA is not required to be the same width as the read data and write data buses.

The snoop data bus can be 32, 64, 128, 256, 512, or 1024 bits wide. However, the following restrictions apply:

- All cache line size transactions must be a full data bus width.
- The burst length must be 1, 2, 4, 8, or 16.

These restrictions determine the minimum and maximum data bus widths that can be supported for a given cache
line size. See Cache line size restrictions on page D3-182.

When CDVALID is asserted, all byte lanes of CDDATA must be valid, as the snoop data bus does not support byte
strobes.

Snoop data is not required for every snoop transaction, it is only provided for a snoop transaction that has a snoop
response with the DataTranfer bit asserted. See Snoop response channel signaling on page D3-195. When snoop
data is required, it must be provided in the same order as the associated snoop addresses were presented on the snoop
address channel.

All snoop transactions of burst length greater than one are defined to be of burst type WRAP. The order in which
data transfers within a snoop burst are provided is the same as for a standard wrapping burst. See Burst type on
page A3-49.

The CDLAST signal must be asserted during the final data transfer associated with a snoop transaction.

The snoop data channel is optional. However, any caching Manager that does not support a snoop data channel must
still support all snoop transaction types on the snoop address channel.

The caching Manager must not be required to return dirty data to complete a snoop transaction, and must never use
a snoop response with DataTransfer asserted. To achieve this, the caching Manager must either:

Not hold dirty data

Perform a WriteBack or WriteClean before responding to any snoop process that must obtain a Dirty cache
line

Note

This option is not compatible with the WriteUnique and WriteLineUnique transactions. See Write
transactions on page D4-222.

### D3.9 Snoop channel dependencies

There are dependencies between the signals on different snoop channels.
In Figure D3-1:

- Single-headed arrows point to signals that can be asserted before or after the signal at the start of the arrow.

- Double-headed arrows point to signals that must be asserted only after assertion of the signal at the start of the arrow.

ACVALID CRVALID CDVALID

ACREADY CRREADY CDREADY

### Figure D3-1 Snoop channel dependencies

Figure D3-1 shows the snoop address, snoop response, and snoop data channel dependencies and shows that:

- The interconnect must not wait for the Manager to assert ACREADY before asserting ACVALID.

- The Manager can wait for ACVALID to be asserted before asserting ACREADY.

- The Manager must wait for both ACVALID and ACREADY to be asserted before asserting CRVALID.

- The Manager must wait for both ACVALID and ACREADY to be asserted before asserting CDVALID.

The Manager must not wait for the interconnect to assert CRREADY or CDREADY before asserting
CRVALID.

If data transfer is required to complete the snoop operation, the Manager must not wait for the interconnect
to assert CRREADY or CDREADY before asserting CDVALID.

The interconnect can wait for CRVALID to be asserted before asserting CRREADY or CDREADY.

If data transfer is required, the interconnect can wait for CDVALID to be asserted before asserting
CRREADY or CDREADY.

## Chapter D4

### Coherency Transactions on the Read Address and Write Address Channels

This chapter describes the transactions that can be issued by an initiating Manager on the read address and write
address channels. The expected channel activity for each transaction group is described, and a brief overview is
given for each transaction. Each transaction has a description of the associated cache line state changes. It contains
the following sections:

- About an initiating Manager on page D4-204
- About snoop filtering on page D4-207
- State changes on different transactions on page D4-208
- State change descriptions on page D4-210
- Read transactions on page D4-211
- Clean transactions on page D4-217
- Make transactions on page D4-220
- Write transactions on page D4-222
- Evict transactions on page D4-227
- Handling overlapping write transactions on page D4-228

#### D4.1 About an initiating Manager

This section describes the behavior of an initiating Manager. Typically, an initiating Manager issues a transaction
to progress an internal action such as a load or store operation.

The internal action requires:

- For a load, the Manager must get the data from either:
- A valid copy of the appropriate cache line
- A transaction that returns valid read data
- For a store, the Manager needs permission to store the cache line from either:
- A copy of the appropriate cache line in a Unique state
- A transaction type that gives the Manager permission to store the cache line

#### D4.1.1 Transaction groups

The following sections describe the expected channel activity for the transaction groups:

- Read transactions
- Clean transactions
- Make transactions on page D4-205
- Write transactions on page D4-205
- Evict transactions on page D4-205

#### Read transactions

The read transaction group is:

- ReadNoSnoop

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

A Read transaction progresses as follows:

1. The address is issued on the read address (AR) channel.

2. The data and response is returned on the read data (R) channel. The number of data beats determined by ARLEN.

3. Completion of a Read transaction is signaled by the Manager asserting RACK.

required is

#### Clean transactions

The clean transaction group is:

- CleanUnique

- CleanShared

- CleanInvalid

A Clean transaction progresses as follows:

1. The address is issued on the AR channel.

2. A single transfer on the R channel returns the response. No data is returned for a Clean transaction.

3. Completion of a Clean transaction is signaled by the Manager asserting RACK.

#### Make transactions

The make transaction group is:

- MakeUnique

- MakeInvalid

For the initiating Manager, a Make transaction progresses as follows:

1. The address is issued on the AR channel.

2. A single transfer on the R channel returns the response. No data is returned for a Make transaction.

3. Completion of a Make transaction is signaled by the Manager asserting RACK.

#### Write transactions

The write transaction group is:

- WriteNoSnoop

- WriteUnique

- WriteLineUnique

- WriteBack

- WriteClean

- WriteEvict

For the initiating Manager, a Write transaction progresses as follows:

1. The address is issued on the AW channel.

2. The data is transferred on the W channel.

3. The response is returned on the B channel.

4. Completion of a Write transaction is signaled by the Manager asserting

#### WACK.

#### Evict transactions

The evict transaction group is, Evict.

For the initiating Manager, an Evict transaction progresses as follows:

1. The address is issued on the AW channel.

2. The response is returned on the B channel. No data is transferred for an Evict transaction.

3. Completion of an Evict transaction is signaled by the Manager asserting WACK.

#### Read barrier transactions

For the Manager initiating the transaction, a Read Barrier transaction progresses as follows:

1. The transaction is issued on the AR channel.

2. A single transfer on the R channel returns the response. No data is returned for a Read Barrier transaction. 3. Completion of a Read Barrier transaction is signaled by the Manager asserting RACK.

See Chapter D8 Barrier Transactions.

#### Write barrier transactions

For the Manager initiating the transaction, a Write Barrier transaction progresses as follows:

1. The transaction is issued on the AW channel.

2. The response is returned on the B channel. No data is transferred for a Write Barrier transaction.

3. Completion of a Write Barrier transaction is signaled by the Manager asserting WACK.

See Chapter D8 Barrier Transactions.

#### DVM transactions

For the Manager initiating the transaction, a DVM transaction progresses as follows:

1. The transaction is issued on the AR channel.

2. A single transfer on the R channel returns the response. No data is returned for a DVM transaction.

3. Completion of a DVM transaction is signaled by the Manager asserting RACK.

See Chapter D13 Distributed Virtual Memory Transactions.

#### D4.2 About snoop filtering

Snoop filtering tracks the cache lines that are allocated in a Manager's cache. To support an external snoop filter, a
caching Manager must be able to broadcast cache lines that are allocated and cache lines that are evicted.

Support for an external snoop filter is optional within the ACE protocol. A Manager component must state in its
data sheet if it provides support. See Chapter D10 Optional External Snoop Filtering for the mechanism the ACE
protocol supports for the construction of an external snoop filter.

For a Manager component that does not support an external snoop filter, the cache line states that are permitted after
a transaction has completed are less strict.

#### D4.3 State changes on different transactions

The state changes that can be associated with a transaction are determined by:

- The transaction type

- The read response for transactions that are issued on the AR channel
- Whether the Manager supports an external snoop filter
- Whether the Manager performs speculative reads

The rules that apply to a Manager are:

If a transaction read response has PassDirty asserted, then the cache line must move to a Dirty state. The
PassDirty response can be asserted for:
- ReadNotSharedDirty
- ReadShared
- ReadUnique

If a transaction read response has IsShared asserted, then the cache line must move to either a Shared state or
the Invalid state. The IsShared response can be asserted for:
- ReadOnce
- ReadClean
- ReadNotSharedDirty
- ReadShared
- CleanShared

A cache line that is in a Unique state is permitted to move to the equivalent Shared state, but this is not
expected behavior.

If an external snoop filter is not supported, a cache line that is in a Clean state can move to the Invalid state.

#### D4.3.1 State changes associated with a load

No cache line state change is required for the internal action of a load.

#### D4.3.2 State changes associated with a coherent store

Before carrying out the internal operation of a store to a cache line in Shareable memory, the Manager must ensure
that it has permission to store. A Manager has permission to store if the cache line is in the UniqueClean or
UniqueDirty state.

If the Manager does not have permission to store then it must either:

Issue a transaction on the AR channel that obtains permission to store, and then perform the store to the cache
line. After the store to a cache line, the Manager must be in the UniqueDirty state. The transactions that obtain
permission to store are:
- ReadUnique
- CleanUnique
- MakeUnique

Issue a transaction on the AW channel that obtains permission to store and also updates main memory. The
transactions that obtain permission to store data and also update main memory are:
- WriteUnique
- WriteLineUnique

#### D4.3.3 State changes associated with a main memory update

An update to main memory can be performed when the cache line is in a Dirty state.

When a Manager is given permission to update main memory, the earliest the associated write transaction can occur
is the cycle after the RVALID/RREADY handshake in which RLAST is asserted for the transaction that gave
permission to update main memory.

An update to main memory is performed using a WriteBack or WriteClean transaction.

After an update to main memory, the cache line must be in a Clean or Invalid state.

If an external snoop filter is supported, then the following restrictions apply:

- After a WriteBack transaction, the cache line must be in the Invalid state.

- After a WriteClean transaction, the cache line must be in a Clean state.

#### State changes associated with cache maintenance operations

#### D4.3.4

The cache maintenance transactions are:

- CleanShared

- CleanInvalid

- MakeInvalid

Before issuing a cache maintenance transaction, the Manager must ensure that:

- For CleanShared, the cache line must be in a Clean or Invalid state.
- For CleanInvalid and MakeInvalid, the cache line must be in the Invalid state.

#### Note

A cache maintenance transaction does not change the cache line state.

#### D4.4 State change descriptions

The cache line state changes associated with a transaction are defined in the following sections:

- Read transactions on page D4-211
- Clean transactions on page D4-217
- Make transactions on page D4-220
- Write transactions on page D4-222
- Evict transactions on page D4-227

For each transaction, the starting state for the transaction and the three possible end state groups are given. The three
possible end state groups are:

- The expected end states, which are also the end states that this specification recommends.

The full list of legal end states for a caching Manager that supports an external snoop filter. This set of end
states takes into account that:
- A cache line in UniqueClean state can always be held in SharedClean state.
- A cache line in UniqueDirty state can always be held in SharedDirty state.

The full list of legal end states for a caching Manager that does not support an external snoop filter. This full
list of legal end states includes the legal end states for external snoop filter support, and takes into account
that a cache line in UniqueClean state, or SharedClean state, can be in the Invalid state.

Some transactions have two tables provided. The first table shows the expected starting states when the transaction
is issued. The second table shows the other permitted starting states for the transaction that is not normally issued.
For example, a ReadShared transaction with a Valid starting state. Typically, the transaction and starting state
combinations in the second table are associated with a speculative read where the Manager issues a transaction
before it has determined the state of the cache line in its local cache.

Any state that is not shown as a starting state in the tables is not a legal starting state.

The starting state is defined as the cache line state just before the transaction response is received by the initiating
Manager. If the initiating Manager receives a snoop transaction to the same cache line between issuing a transaction
and receiving the associated response, then the cache line state changes required by the snoop transaction must be
applied first. See Chapter D5 Snoop Transactions.

The following abbreviations are used for the cache line states:
UC UniqueClean
UD UniqueDirty
SC SharedClean
SD SharedDirty
I Invalid

#### D4.5 Read transactions

This section defines the state changes associated with the Read transaction group that are issued on the AR channel.
The Read transactions are:

- ReadNoSnoop

- ReadOnce on page D4-212

- ReadClean on page D4-212

- ReadNotSharedDirty on page D4-213

- ReadShared on page D4-214
- ReadUnique on page D4-215

#### D4.5.1 ReadNoSnoop

ReadNoSnoop is a read transaction that is used in a region of memory that is not Shareable with other Managers.
The transaction response requirements are:

- The IsShared response must be deasserted.

- The PassDirty response must be deasserted.

Table D4-1 shows the expected cache line state changes for the ReadNoSnoop transaction:

Table D4-1 Expected ReadNoSnoop cache line state changes

| Transaction Start state | PassDirty Start state RRESP[3:2] IsShared/ | RRESP[3:2] IsShared/ Expected end state Legal end state | With Snoop Filter No Snoop Filter Expected end state Legal end state | With Snoop Filter No Snoop Filter |
| --- | --- | --- | --- | --- |
| ReadNoSnoop I | 00 | I, UC | I, UC, SC | I, UC, SC |
| Note A ReadNoSnoop | does not | when the | line is allocated after the | has completed. |
| Table D4-2 shows | other permitted | cache line state D4-2 Other | for the ReadNoSnoop ReadNoSnoop | line state changes |
| Transaction Start | IsShared/ | Expected | state Legal end state |  |
|  | PassDirty |  | With Snoop | No Snoop Filter |
| ReadNoSnoop UC | 00 | I, UC | I, UC, SC | I, UC, SC |
| UD | 00 | UD | UD, SD | UD, SD |
| SC | 00 | I, UC | I, UC, SC | I, UC, SC |
| SD | 00 | UD | UD, SD | UD, SD |

#### D4.5.2 ReadOnce

ReadOnce is a read transaction that is used in a region of memory that is Shareable with other Managers. This
transaction is used when a snapshot of the data is required. The location is not cached locally for future use.

The transaction response requirements are:

- The IsShared response indicates that the cache line is shared or unique.
- The PassDirty response must be deasserted.

Table D4-3 shows the expected cache line state changes for the ReadOnce transaction:

Table D4-3 Expected ReadOnce cache line state changes

| Transaction Start state IsShared/ | Expected | state Legal end |  |
| --- | --- | --- | --- |
| PassDirty |  | With | Filter No Snoop Filter |
| ReadOnce I 00 | I | I | I |
| 10 | I | I | I |
| Table D4-4 shows the other permitted | cache line state Table D4-4 | for the ReadOnce permitted | cache line state |
| Transaction Start state IsShared/ | Expected | state Legal end |  |
| PassDirty |  | With | Filter No Snoop Filter |
| ReadOnce UC 00 | UC | UC, SC | I, UC, SC |
| UD 00 | UD | UD, SD | UD, SD |
| SC 00 | UC | UC, SC | I, UC, SC |
| 10 | SC | SC | I, SC |
| SD 00 | UD | UD, SD | UD, SD |
| 10 | SD | SD | SD |

#### D4.5.3 ReadClean

ReadClean is a read transaction that is used in a region of memory that is Shareable with other Managers. A
ReadClean transaction is guaranteed not to pass responsibility for updating main memory to the initiating Manager.

Typically, a ReadClean transaction is used by a Manager that wants to obtain a Clean copy of a cache line, for
example a Manager with a write-through cache.

The transaction response requirements are:

- The IsShared response indicates that the cache line is shared or unique.

- The PassDirty response must be deasserted.

Table D4-5 shows the expected cache line state changes for the ReadClean transaction:

Table D4-5 Expected ReadClean cache line state changes

| Transaction Start state IsShared/ | Expected | state Legal end |  |
| --- | --- | --- | --- |
| PassDirty |  | With | Filter No Snoop Filter |
| ReadClean I 00 | UC | UC, SC | I, UC, SC |
| 10 | SC | SC | I, SC |
| Table D4-6 shows other permitted | line state Table D4-6 | for the ReadClean permitted | cache line state changes |
| Transaction Start state IsShared/ | Expected | state Legal end |  |
| PassDirty |  | With | Filter No Snoop Filter |
| ReadClean UC 00 | UC | UC, SC | I, UC, SC |
| UD 00 | UD | UD, SD | UD, SD |
| SC 00 | UC | UC, SC | I, UC, SC |
| 10 | SC | SC | I, SC |
| SD 00 | UD | UD, SD | UD, SD |
| 10 | SD | SD | SD |

#### D4.5.4 ReadNotSharedDirty

ReadNotSharedDirty is a read transaction that is used in a region of memory that is Shareable with other Managers.
A ReadNotSharedDirty transaction can complete with any combination of the IsShared and PassDirty responses
except for IsShared and PassDirty asserted.

Typically, the transaction is used by a caching Manager that is carrying out a load operation and can accept the cache
line in any state except the SharedDirty state.

The transaction response requirements are:

- The IsShared response indicates that the cache line is Shared or Unique.

- The PassDirty response indicates that the cache line is Clean or Dirty.

- If the IsShared response indicates that the cache line is Shared, then the PassDirty response the cache line is Clean.

must indicate that

Table D4-7 shows the expected cache line state changes for the ReadNotSharedDirty transaction:

Table D4-7 Expected ReadNotSharedDirty cache line state changes

Transaction

RRESP[3:2]
state

ReadNotSharedDirty I

00

01

10

Expected end state

Legal end state

UC, SC

I, UC, SC

UD, SD

UD, SD

SC

I, SC

UC

UD

SC

Table D4-8 shows other permitted cache line state changes for the ReadNotSharedDirty transaction:

Table D4-8 Other permitted ReadNotSharedDirty cache line state changes

Transaction

#### RRESP[3:2]

state

| ReadNotSharedDirty UC 00 | UC | UC, SC | I, UC, SC |
| --- | --- | --- | --- |
| UD 00 | UD | UD, SD | UD, SD |
| SC 00 | UC | UC, SC | I, UC, SC |
| 01 | UD | UD, SD | UD, SD |
| 10 | SC | SC | I, SC |
| SD 00 | UD | UD, SD | UD, SD |
| 10 | SD | SD | SD |

Expected end state

Legal end state

#### Note

If a cache line starts in the SharedClean state, and the transaction response has PassDirty asserted, the cache line
must move to a Dirty state.

#### D4.5.5 ReadShared

ReadShared is a read transaction that is used in a region of memory that is Shareable with other Managers. A
ReadShared transaction can complete with any combination of the IsShared and PassDirty responses.

Typically, the ReadShared transaction is used by a caching Manager that is carrying out a load operation and can
accept the cache line in any state.

The transaction response requirements are:

- The IsShared response indicates that the cache line is Shared or Unique.

- The PassDirty response indicates that the cache line is Clean or Dirty.

Table D4-9 shows the expected cache line state changes for the ReadShared transaction:

Table D4-9 Expected ReadShared cache line state changes

| Transaction Start state | Expected | state Legal end With | Filter No Snoop Filter |
| --- | --- | --- | --- |
| ReadShared I 00 | UC | UC, SC | I, UC, SC |
| 01 | UD | UD, SD | UD, SD |
| 10 | SC | SC | I, SC |
| 11 | SD | SD | SD |

Table D4-10 shows other permitted state changes for the ReadShared transaction:

Table D4-10 Other permitted ReadShared cache line state changes

| Transaction Start state | Expected | state Legal end With | Filter No Snoop Filter |
| --- | --- | --- | --- |
| ReadShared UC 00 | UC | UC, SC | I, UC, SC |
| UD 00 | UD | UD, SD | UD, SD |
| SC 00 | UC | UC, SC | I, UC, SC |
| 01 | UD | UD, SD | UD, SD |
| 10 | SC | SC | I, SC |
| 11 | SD | SD | SD |
| SD 00 | UD | UD, SD | UD, SD |
| 10 | SD | SD | SD |
| Note |  |  |  |
| If a cache line starts in the must move to a Dirty state. | state, and the | response has | asserted, the cache line |

#### D4.5.6 ReadUnique

A ReadUnique transaction is used in a region of memory that is Shareable with other Managers. The transaction
gets a copy of the data and also ensures that the cache line can be held in a Unique state. This permits the Manager
to carry out a store operation to the cache line.

Typically, a ReadUnique transaction is used when the initiating Manager is carrying out a partial cache line store
and does not have a copy of the cache line.

The transaction response requirements are:

- The IsShared response must be deasserted to indicate that the cache line is Unique.

- The PassDirty response must indicate when the cache line is Clean or Dirty.

#### Note

The cache line state changes associated with the ReadUnique transaction that Table D4-11 and Table D4-12 on
page D4-216 show, do not include the cache line state changes associated with any subsequent store operation by
the Manager when the cache line is in a Unique state.

Table D4-11 shows the expected cache line state changes for the ReadUnique transaction:

Table D4-11 Expected ReadUnique cache line state changes

Transaction Start state RRESP[3:2] Expected end state Legal end state
IsShared/
PassDirty With Snoop Filter

ReadUnique I

00

01

UC

UD

UC, SC

UD, SD

No Snoop Filter

I, UC, SC

UD, SD

Table D4-12 shows other permitted cache line state changes for the ReadUnique transaction:

Table D4-12 Other permitted ReadUnique cache line state changes

| Transaction Start state RRESP[3:2] | PassDirty IsShared/ Transaction Start state RRESP[3:2] | Expected end state Legal end state | With Snoop Filter No Snoop Filter Expected end state Legal end state | With Snoop Filter No Snoop Filter |
| --- | --- | --- | --- | --- |
| ReadUnique UC | 00 | UC | UC, SC | I, UC, SC |
| UD | 00 | UD | UD, SD | UD, SD |
| SC | 00 | UC | UC, SC | I, UC, SC |
|  | 01 | UD | UD, SD | UD, SD |
| SD | 00 | UD | UD, SD | UD, SD |

#### D4.6 Clean transactions

This section defines the state changes associated with the Clean transaction group that are issued on the AR channel.
The Clean transactions are:

- CleanUnique

- CleanShared on page D4-218

- CleanInvalid on page D4-219

#### D4.6.1 CleanUnique

A CleanUnique transaction is used in a region of memory that is Shareable with other Managers. The CleanUnique
transaction ensures that:

The cache line can be held in a Unique state. This permits the Manager to carry out a store operation to the
cache line, but the transaction does not obtain a copy of the data for the Manager.

Data held in another cache in a Dirty state is written to main memory and all other copies of the cache line
are removed.

Typically, a CleanUnique transaction is used before a partial cache line store operation to Shareable memory when
the Manager already has a copy of the data.

The transaction response requirements are:

- The IsShared response must be deasserted to indicate that the cache line is unique.

- The PassDirty response must be deasserted.

#### Note

The cache line state changes associated with the CleanUnique transaction that Table D4-13 and Table D4-14 on
page D4-218 show, do not include the cache line state changes associated with any subsequent store operation by
the Manager when the cache line is in a Unique state.

Table D4-13 shows the expected cache line state changes for the CleanUnique transaction:

Table D4-13 Expected CleanUnique cache line state changes

<table>
 <tr>
  <th>Transaction Start state RRESP[3:2] Expected end state Legal end state</th>
 </tr>
 <tr>
  <th>IsShared/</th>
 </tr>
 <tr>
  <th>PassDirty With Snoop Filter No Snoop Filter</th>
 </tr>
 <tr>
  <th>CleanUnique SC 00 UC UC, SC I, UC, SC</th>
 </tr>
 <tr>
  <th>SD 00 UD UD, SD UD, SD</th>
 </tr>
</table>

Table D4-14 shows other permitted cache line state changes for the CleanUnique transaction:

Table D4-14 Other permitted CleanUnique cache line state changes

| Transaction Start state RRESP[3:2] | PassDirty IsShared/ Transaction Start state RRESP[3:2] | Expected end state Legal end state | With Snoop Filter No Snoop Filter Expected end state Legal end state | With Snoop Filter No Snoop Filter |
| --- | --- | --- | --- | --- |
| CleanUnique I | 00 | I | Ia | I |
| UC | 00 | UC | UC, SC | I, UC, SC |
| UD | 00 | UD | UD, SD | UD, SD |

1. See Snoop filter cache line allocation awareness.

On completing a CleanUnique transaction, the initiating Manager has permission to store to the cache line. If the
cache line was in the Invalid state before the store operation, then the store must be a full cache line size for the
cache line to be allocated in the cache. After the full cache line store, the cache line is in the UniqueDirty state. The
store must occur atomically with the completion of the CleanUnique transaction. Therefore, any snoop that occurs
after the CleanUnique transaction must be delayed until the store is complete.

CleanUnique transactions can be used for Exclusive accesses, see Chapter D9 Exclusive Accesses from ACE
Managers.

#### Snoop filter cache line allocation awareness

A snoop filter regards a cache line as allocated after the completion of a CleanUnique transaction. Therefore, the
snoop filter has the correct information on the allocation of a cache line in the following circumstances:

The cache line was allocated before the CleanUnique transaction and remains allocated after the
CleanUnique transaction completes.

-

-

If the cache line was not allocated before the CleanUnique transaction, or the cache line was invalidated
during the CleanUnique transaction, then when the CleanUnique transaction completes the Manager:

- Performs a full cache line store and the cache line is allocated.
- Performs a WriteBack transaction of either a full or partial cache line store, and indicates to the snoop
filter that the cache line is no longer allocated.

Reissues another transaction, for example a ReadUnique transaction, before performing a full or
partial cache line store and the cache line becomes allocated.

Does not perform a store operation. In this situation, the Manager must issue an Evict transaction to
indicate to the snoop filter that the cache line is no longer allocated.

#### D4.6.2 CleanShared

A CleanShared transaction is a broadcast cache clean operation. It can be used in Shareable and Non-shareable
memory regions.

A CleanShared transaction is used to ensure that all cached copies of a main memory location are Clean.

Note

If the Manager carrying out the cache maintenance operation holds the cache line in a Dirty state, then the Manager
must carry out a WriteBack or WriteClean transaction so that the cache line is in a Clean state before it issues a
CleanShared transaction. While a CleanShared is in progress, the Manager is permitted to write to the line, so it
might become Dirty before the CleanShared completes.

The transaction response requirements are:

- The IsShared response indicates that the cache line is shared or unique.

- The PassDirty response must be deasserted.

Table D4-15 shows the expected cache line state changes for the CleanShared transaction:

Table D4-15 Expected CleanShared cache line state changes

| Transaction Start |  | Expected | state Legal end |  |  |
| --- | --- | --- | --- | --- | --- |
|  |  |  | With | Filter | No Snoop Filter |
| CleanShared I | 00 | I | I |  | I |
|  | 10 | I | I |  | I |
| UC | 00 | UC | UC, SC, | SDa | I, UC, SC, UDa, |
|  |  |  |  |  | SDa |
| SC | 00 | UC | UC, SC |  | I, UC, SC |
|  | 10 | SC | SC |  | I, SC |

a. A line in the UC state might become Dirty as a result of a local write, rather than the response to a CleanShared transaction.

#### D4.6.3 CleanInvalid

A CleanInvalid transaction is a broadcast cache clean and invalidate operation. It can be used in Shareable and
Non-shareable memory regions.

A CleanInvalid transaction is used to ensure that main memory is updated and there are no cached copies of a main
memory location.

#### Note

If the Manager carrying out the cache maintenance operation holds the cache line in a Dirty state, then the Manager
must carry out a WriteBack or WriteClean transaction. Then the Manager must invalidate the cache line, so that the
cache line is in the Invalid state before it issues a CleanInvalid transaction.

The transaction response requirements are:

- The IsShared response must be deasserted.

- The PassDirty response must be deasserted.

Table D4-16 shows the expected cache line state changes for the CleanInvalid transaction:

Table D4-16 Expected CleanInvalid cache line state changes

<table>
 <tr>
  <th>Transaction Start state RRESP[3:2] Expected end state Legal end state</th>
 </tr>
 <tr>
  <th>IsShared/</th>
 </tr>
 <tr>
  <th>PassDirty With Snoop Filter No Snoop Filter</th>
 </tr>
 <tr>
  <th>CleanInvalid I 00 I I I</th>
 </tr>
</table>

#### D4.7 Make transactions

This section defines the state changes associated with the Make transaction group that are issued on the AR channel.
The Make transactions are:

- MakeUnique
- MakeInvalid on page D4-221

#### D4.7.1 MakeUnique

A MakeUnique transaction is used in a region of memory that is Shareable with other Managers. The MakeUnique
transaction ensures that:

The cache line can be held in a Unique state. This permits the Manager to carry out a store operation to the
cache line, but the transaction does not obtain a copy of the data for the Manager.

All other copies of the cache line are removed.

#### Note

A MakeUnique transaction must be used only by an initiating Manager that is carrying out a full cache line store
operation.

The transaction response requirements are:

- The IsShared response must be deasserted indicating that the cache line is unique.
- The PassDirty response must be deasserted.

The expected cache line state changes for a MakeUnique transaction are different from all other transactions
because a MakeUnique transaction must be coupled to a full cache line store operation.

Table D4-17 shows the expected cache line state changes for the MakeUnique transaction with a full cache line store
operation:

Table D4-17 Expected MakeUnique cache line state changes

<table>
 <tr>
  <th>Transaction Start state</th>
  <th>PassDirty IsShared/ RRESP[3:2]</th>
  <th>Expected end state Legal end state</th>
  <th>With Snoop Filter No Snoop Filter Expected end state Legal end state</th>
  <th>With Snoop Filter No Snoop Filter</th>
 </tr>
 <tr>
  <td>MakeUnique with I</td>
  <td>00</td>
  <td>UD</td>
  <td>UD, SD</td>
  <td>UD, SD</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>SC</td>
  <td>00</td>
  <td>UD</td>
  <td>UD, SD</td>
  <td>UD, SD</td>
 </tr>
 <tr>
  <td>SD</td>
  <td>00</td>
  <td>UD</td>
  <td>UD, SD</td>
  <td>UD, SD</td>
 </tr>
</table>

Table D4-18 shows the other permitted cache line state changes for the MakeUnique transaction with a full cache
line store operation:

Table D4-18 Other permitted MakeUnique cache line state changes

<table>
 <tr>
  <th>Transaction Start state RRESP[3:2] Expected end state Legal end state</th>
 </tr>
 <tr>
  <th>IsShared/</th>
 </tr>
 <tr>
  <th>PassDirty With Snoop Filter No Snoop Filter</th>
 </tr>
 <tr>
  <th>MakeUnique with UC 00 UD UD, SD UD, SD</th>
 </tr>
 <tr>
  <th></th>
 </tr>
 <tr>
  <th>UD 00 UD UD, SD UD, SD</th>
 </tr>
</table>

#### D4.7.2 MakeInvalid

A MakeInvalid transaction is a broadcast cache invalidate operation. It can be used in Shareable and Non-shareable
memory regions.

A MakeInvalid transaction is used to ensure that there are no cached copies of a main memory location.

#### Note

If the Manager carrying out the cache maintenance operation holds the cache line in a Valid state, then the Manager
must invalidate the cache line, so that the cache line is in the Invalid state before it issues a MakeInvalid transaction.

The transaction response requirements are:

- The IsShared response must be deasserted.

- The PassDirty response must be deasserted.

Table D4-19 shows the expected cache line state changes for the MakeInvalid transaction:

Table D4-19 Expected MakeInvalid cache line state changes

<table>
 <tr>
  <th>Transaction Start state RRESP[3:2] Expected end state Legal end state</th>
 </tr>
 <tr>
  <th>IsShared/</th>
 </tr>
 <tr>
  <th>PassDirty With Snoop Filter No Snoop Filter</th>
 </tr>
 <tr>
  <th>MakeInvalid I 00 I I I</th>
 </tr>
</table>

#### D4.8 Write transactions

This section defines the state changes associated with the Write transaction group that are issued on the AW channel.
The Write transactions are:

- WriteNoSnoop
- WriteUnique on page D4-223
- WriteLineUnique on page D4-223
- WriteBack on page D4-224
- WriteClean on page D4-224
- WriteEvict on page D4-225
- Restrictions on WriteUnique and WriteLineUnique usage on page D4-226
- Handling overlapping write transactions on page D4-228

#### D4.8.1 WriteNoSnoop

A WriteNoSnoop transaction is used in a region of memory that is not Shareable with other Managers. A
WriteNoSnoop transaction can result from:

- A program action, such as a store operation.

- An update of main memory for a cache line that is in a Non-shareable region of memory.

Table D4-20 shows the expected cache line state changes for the WriteNoSnoop transaction:

Table D4-20 Expected WriteNoSnoop cache line state changes

| Transaction Start | Expected | state Legal end state With Snoop | No Snoop Filter |
| --- | --- | --- | --- |
| WriteNoSnoop I | I | I, UC, SC | I, UC, SC |
| UC | UC | I, UC, SC | I, UC, SC |
| UD | UC | I, UC, SC | I, UC, SC |
| Note A cache line must only move from the | Invalid state to a | state if a full cache line | has been performed. |
| Table D4-21 shows the other | cache line state D4-21 Other | for the WriteNoSnoop WriteNoSnoop | line state |
| Transaction Start | Expected | state Legal end state With Snoop | No Snoop Filter |
| WriteNoSnoop SC | UC | I, UC, SC | I, UC, SC |
| SD | UC | I, UC, SC | I, UC, SC |

#### D4.8.2 WriteUnique

A WriteUnique transaction is used in a region of memory that is Shareable with other Managers. A single write
occurs that is required to propagate to main memory or a downstream cache.

There are restrictions on the use of WriteUnique transactions by caching Managers that can hold Dirty cache lines.
See Restrictions on WriteUnique and WriteLineUnique usage on page D4-226.

Table D4-22 shows the expected cache line state changes for the WriteUnique transaction:

Table D4-22 Expected WriteUnique cache line state changes

| Transaction | Start | Expected | state Legal end With | Filter No Snoop Filter |
| --- | --- | --- | --- | --- |
| WriteUnique | I | I | I | I |
|  | UC | SC | SC | I, SC |
|  | SC | SC | SC | I, SC |

In the case of Manager holding a line in a Clean state while performing a WriteUnique transaction, the cache line
must be updated to the new value when the WriteUnique transaction response is received.

#### D4.8.3 WriteLineUnique

A WriteLineUnique transaction is used in a region of memory that is Shareable with other Managers. A single write
occurs, that is required to propagate to main memory or a downstream cache.

#### Note

A WriteLineUnique transaction must be a full cache line store and all bytes within the cache line must be updated.

There are restrictions on the use of WriteLineUnique transactions by caching Managers that can hold Dirty cache
lines. See Restrictions on WriteUnique and WriteLineUnique usage on page D4-226.

Table D4-23 shows the expected cache line state changes for the WriteLineUnique transaction.

Table D4-23 Expected WriteLineUnique cache line state changes

Start state

Expected end state

Legal end state

With Snoop Filter

No Snoop Filter

I

I

SC

I, SC

SC

I, SC

Transaction

WriteLineUnique I

UC

SC

I

SC

SC

In the case of Manager holding a line in a Clean state while performing a WriteLineUnique transaction, the cache
line must be updated to the new value when the WriteLineUnique transaction response is received.

#### D4.8.4 WriteBack

A WriteBack transaction is a write that can be used in Shareable and Non-shareable regions of memory. A
WriteBack transaction is a write of a Dirty cache line to update main memory or a downstream cache.

The permitted state changes that Table D4-24 and Table D4-25 show, do not take into account a preceding store
operation that makes a cache line Dirty. If a store operation and WriteBack transaction occur as an atomic process,
then the legal cache line state changes can be determined by combining the legal state changes for a store operation.
See State changes associated with a coherent store on page D4-208, followed by the legal state changes for a
WriteBack transaction.

Table D4-24 shows the expected cache line state changes for the WriteBack transaction in a Shareable memory
region.

Table D4-24 Expected WriteBack cache line state changes in a Shareable memory region

Transaction Start state Expected end state Legal end state

WriteBack UD

SD

I

I

#### With Snoop Filter

#### No Snoop Filter

I

I, UC, SC

I

I, SC

Table D4-25 shows the expected cache line state changes for the WriteBack transaction in a Non-shareable memory
region.

Table D4-25 Expected WriteBack cache line state changes in a Non-shareable memory region

Transaction Start state Expected end state Legal end state

WriteBack UD

SD

I

I

With Snoop Filter

#### No Snoop Filter

I, UC, SC

I, UC, SC

I, UC, SC

I, UC, SC

#### D4.8.5 WriteClean

A WriteClean transaction is a write operation that can be used in Shareable and Non-shareable regions of memory.
A WriteClean transaction is a write of a Dirty cache line to update main memory or a downstream cache.

#### Note

The difference between a WriteClean and a WriteBack transaction is the state of the cache line that remains allocated
in the cache for a Shareable region of memory. After a WriteClean transaction, the cache line remains allocated.
After a WriteBack transaction, the cache line is no longer allocated.

The permitted state changes that Table D4-26 on page D4-225 and Table D4-27 on page D4-225 show, do not take
into account any preceding store operation that makes a cache line Dirty. If a store operation and WriteBack
transaction occur as an atomic process, then the legal cache line state changes can be determined by combining the
legal state changes for a store operation. See State changes associated with a coherent store on page D4-208,
followed by the legal state changes for a WriteClean transaction.

Table D4-26 shows the expected cache line state changes for the WriteClean transaction in a Shareable memory
region.

Table D4-26 Expected WriteClean cache line state changes in a Shareable memory region

| Transaction Start | Expected | state Legal end With Snoop | Filter No Snoop Filter |
| --- | --- | --- | --- |
| WriteClean UD | UC | UC, SC | I, UC, SC |
| SD | SC | SC | I, SC |

Table D4-27 shows the expected cache line state changes for the WriteClean transaction in a Non-shareable memory
region.

Table D4-27 Expected WriteClean cache line state changes in a Non-shareable memory region

| Transaction Start | Expected | state Legal end state With Snoop | No Snoop Filter |
| --- | --- | --- | --- |
| WriteClean UD | UC | I, UC, SC | I, UC, SC |
| SD | UC | I, UC, SC | I, UC, SC |

#### D4.8.6 WriteEvict

A WriteEvict transaction can be used when evicting a Clean cache line. This transaction is used to write the line to
a lower level of the cache hierarchy, such as an L3 or system level cache. A WriteEvict transaction is not required
to update main memory.

A WriteEvict transaction must only be used in the following circumstances:

- When the cache line is held in a UniqueClean state.

- When the cache line has not been speculatively fetched from a different shareability domain.

#### Note

It is important that a cache line that could have been speculatively fetched, so that it was located outside of
its shareability domain, could become out-of-date as the cache line is not required to be updated by
subsequent stores to the cache line. If a cache line could be a stale copy, then it must not be written back into
its shareability domain by the use of a WriteEvict transaction.

| A WriteEvict transaction A component can use the Manager must permit the any previous version of to be False. | can be WriteEvict ACE | property to declare if it supports WriteEvict transactions. Any to be disabled to ensure that the Manager operates correctly with If the WriteEvict_Transaction property is not declared, it is considered |
| --- | --- | --- |
|  |  | Table D4-28 Expected WriteEvict cache line state changes |
| Transaction | Start | Expected end state Legal end state With Snoop Filter No Snoop Filter |
| WriteEvict | UC | I I I |

#### D4.8.7 Restrictions on WriteUnique and WriteLineUnique usage

Typically, WriteUnique and WriteLineUnique transactions are used by a non-cached component that is writing to a
Shareable region of memory. However, WriteUnique and WriteLineUnique transactions can be used by a cached
component that meets the requirements.

A cached component must be able to complete any incoming snoop transaction while a WriteUnique or
WriteLineUnique transaction is in progress. A cached component must:

Complete any outstanding WriteBack, WriteClean, WriteEvict, or Evict transactions before issuing a
WriteUnique or WriteLineUnique transaction.

This is necessary, because earlier transactions that also might require earlier snoop transactions to complete, can
prevent WriteUnique and WriteLineUnique transactions from progressing.

These requirements restrict the use of WriteUnique and WriteLineUnique transactions to components that can
either:

Complete all snoop transactions without requiring any data to be supplied, for example write-through caches
that do not keep Dirty cache lines for Shareable data.

Complete snoop transactions by using the snoop data channel, CDDATA.

#### D4.9 Evict transactions

This section defines the state changes associated with the Evict transaction group that are issued on the AW channel.

#### D4.9.1 Evict

An Evict transaction indicates that a cache line has been evicted from a Manager's local cache. There is no data
transfer associated with an Evict transaction. An Evict transaction must be used only in a Shareable memory region.

#### Note

An Evict transaction is only used by a Manager that supports a snoop filter. When used, it is permitted, but not
expected, for a Manager to evict a cache line without issuing an Evict transaction.

Table D4-29 shows the expected cache line state changes for the Evict transaction.

Table D4-29 Expected Evict cache line state changes in a Shareable memory region

<table>
 <tr>
  <th>Transaction Start</th>
  <td>Expected end state Legal end state<br/>With Snoop Filter No Snoop Filter</td>
 </tr>
 <tr>
  <th>Evict UC</th>
  <td>I I Not used</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>I I Not used</td>
 </tr>
</table>

#### D4.10 Handling overlapping write transactions

This section describes the expected behavior when two Managers attempt stores to the same cache line in a
Shareable region of memory at approximately the same time. When this happens, it is the responsibility of the
interconnect to sequence the order that the transactions occur.

The Manager that gets sequenced first proceeds with the transaction as normal. However, the Manager that is
sequenced second sees the transactions that are associated with the first Manager's store on its snoop port while
attempting to carry out a store.

The following sections describe the expected behavior from the standpoint of the Manager that is sequenced second.
For brevity, the Manager that is sequenced first is referred to as Manager1 and the Manager that is sequenced second
is referred to as Manager2.

#### D4.10.1 Overlapping ReadUnique

If Manager2 has issued a ReadUnique transaction because it required a copy of the data, the following occurs:

1. Manager2 issues a ReadUnique transaction.

2. Manager2 then sees one of the following transactions on its snoop port from Manager1 attempting a write to the same line:
- ReadUnique
- CleanInvalid
- MakeInvalid

At this point, Manager2 must invalidate any local copy that it has of the cache line. If Manager2 does not
have a local copy of the cache line, then no action is required.

1. When the ReadUnique completes, it returns with the updated copy of the cache line that includes the store that is performed by Manager1.

2. Manager2 can perform its store.

#### D4.10.2 Overlapping MakeUnique

If Manager2 has issued a MakeUnique transaction because it was performing a full cache line write, the following
occurs:

1. Manager2 issues a MakeUnique transaction.

2. Manager2 sees one of the following transactions on its snoop port from Manager1 attempting a write to the same line:
- ReadUnique
- CleanInvalid
- MakeInvalid

At this point, Manager2 must invalidate any local copy that it has of the cache line. If Manager2 does not
have a local copy of the cache line, then no action is required.

3. When the MakeUnique completes, Manager2 can perform its full cache line store.

#### D4.10.3 Overlapping CleanUnique

If Manager2 has issued a CleanUnique transaction because it was performing a partial line store but it already had
a cached copy of the line, the following occurs:

1. Manager2 issues a CleanUnique transaction.

2. Manager2 sees one of the following transactions on its snoop port from Manager1 attempting a write to the same line:
- ReadUnique
- CleanInvalid
- MakeInvalid

At this point, Manager2 must respond to the snoop appropriately and then invalidate its local copy of the
cache line.

1. When the CleanUnique completes, Manager2 cannot perform its local store because it has lost its local copy of the cache line.

2. Manager2 can issue a new ReadUnique transaction to obtain a copy of the line.

3. Manager2 can perform its store.

A Manager can remove the need to issue a new ReadUnique the transaction, as described in the CleanUnique case,
by initially issuing a ReadUnique transaction instead of a CleanUnique transaction. However, this sometimes results
in a fetch from main memory occurring when it is not required.

Alternatively, a Manager can remove the need to issue a new ReadUnique transaction by performing a partial line
WriteBack to main memory, that only updates the required bytes, when its CleanUnique transaction completes and
the Manager has permission to store to the line. This does mean that the Manager does not retain a copy of the line.

It is acceptable for a Manager to use a CleanUnique transaction when carrying out a full cache line store. In this
case, the Manager does not have to retry the transaction with a ReadUnique. It can simply perform the full cache
line store when the CleanUnique is complete.

## Chapter D5

### Snoop Transactions

This chapter describes the snoop transactions that are seen on the snoop address channel. Both the required and
protocol-recommended snoop transaction behaviors are described. It contains the following sections:

- Mapping coherency operations to snoop operations on page D5-232
- General requirements for snoop transactions on page D5-235
- Snoop transactions on page D5-241

### D5.1 Mapping coherency operations to snoop operations

This section describes the snoop transactions that are seen on the snoop address channel by a caching Manager that
is being snooped by an initiating Manager.

When an initiating Manager issues a transaction, the interconnect is responsible for carrying out any snoop
transactions that are required to complete the original transaction.

Not all transactions that are issued by an initiating Manager are permitted on the snoop address channel. Table D5-1
shows the protocol-recommended mappings between transactions that are issued by the initiating Manager and the
snoop transactions that are seen on the snoop address channel by a caching Manager.

### Table D5-1 Recommended transaction mappings

<table>
 <tr>
  <th>Transaction from<br/>Manager</th>
  <td>Transaction to snooped<br/>Manager</td>
 </tr>
 <tr>
  <th>ReadNoSnoop</th>
  <td>Not snooped</td>
 </tr>
 <tr>
  <th>ReadOnce</th>
  <td>ReadOnce</td>
 </tr>
 <tr>
  <th>ReadClean</th>
  <td>ReadClean</td>
 </tr>
 <tr>
  <th>ReadNotSharedDirty</th>
  <td>ReadNotSharedDirty</td>
 </tr>
 <tr>
  <th>ReadShared</th>
  <td>ReadShared</td>
 </tr>
 <tr>
  <th>ReadUnique</th>
  <td>ReadUnique</td>
 </tr>
 <tr>
  <th>CleanUnique</th>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th>MakeUnique</th>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>CleanShared</th>
  <td>CleanShared</td>
 </tr>
 <tr>
  <th>CleanInvalid</th>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th>MakeInvalid</th>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>WriteNoSnoop</th>
  <td>Not snooped</td>
 </tr>
 <tr>
  <th>WriteUnique</th>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th>WriteLineUnique</th>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>WriteBack</th>
  <td>Not snooped</td>
 </tr>
 <tr>
  <th>WriteClean</th>
  <td>Not snooped</td>
 </tr>
 <tr>
  <th>WriteEvict</th>
  <td>Not snooped</td>
 </tr>
 <tr>
  <th>Evict</th>
  <td>Not snooped</td>
 </tr>
</table>

### Note

The interconnect can use other mappings that force the same cache line state changes in a snooped Manager. See
Alternative snoop transactions on page D5-233.

### Permitted snoop transactions

### D5.1.1

Although the protocol does not require a fixed set of transaction mappings, the protocol does require that only the
following defined subset of transactions is seen on the snoop address channel of a caching Manager:

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

- CleanInvalid

- MakeInvalid

- CleanShared

### Transactions not permitted as snoop transactions

### D5.1.2

The following transactions must not be seen on the snoop address channel of a caching Manager:

- ReadNoSnoop

- CleanUnique

- MakeUnique

- WriteNoSnoop

- WriteUnique

- WriteLineUnique

- WriteBack

- WriteClean

- WriteEvict

- Evict

### Alternative snoop transactions

### D5.1.3

Table D5-2 shows each permitted snoop transaction on the snoop address channel, the required cache line state
change for the transaction, and the alternative snoop transaction that can be used. For completeness, the snoop
transaction option column includes the original snoop transaction.

Table D5-2 Snoop transaction options on the address snoop channel

| Snoop | Required cache line | change Snoop transaction option |
| --- | --- | --- |
| ReadOnce | None | ReadOnce |
|  |  | ReadClean, ReadNotSharedDirty, |
|  |  | ReadShared |
|  |  | ReadUnique, CleanInvalid |
|  |  | CleanShared |
| ReadClean | Shared or Invalid | ReadClean, ReadNotSharedDirty, |
|  |  | ReadShared |
|  |  | ReadUnique, CleanInvalid |
|  | Shared or Invalid | ReadClean, ReadNotSharedDirty, ReadShared |
|  |  | ReadUnique, CleanInvalid |
| ReadShared | Shared or Invalid | ReadClean, ReadNotSharedDirty, |
|  |  | ReadShared |
|  |  | ReadUnique, CleanInvalid |
| ReadUnique | Invalid | ReadUnique, CleanInvalid |

Table D5-2 Snoop transaction options on the address snoop channel (continued)

| Snoop | Required cache line | change Snoop transaction option |
| --- | --- | --- |
| MakeInvalid | Invalid | ReadUnique, CleanInvalid, MakeInvalid |
| CleanInvalid | Invalid | ReadUnique, CleanInvalid |
| CleanShared | Clean or Invalid | ReadUnique, CleanInvalid |
|  |  | CleanShared |

Mapping to different snoop transactions can simplify the design of a snooped Manager. For example, a snooped
Manager can handle all snoop transactions in the same way as a ReadUnique transaction. This is permitted because
a ReadUnique transaction, as Table D5-2 on page D5-233 shows, is an alternative snoop transaction for all other
snoop transactions.

### D5.2 General requirements for snoop transactions

For each snoop transaction, the protocol specifies required and recommended behaviors.
Table D5-3 shows the required behavior for each snoop transaction:
Table D5-3 Required snoop transaction behavior

| Snoop | Must data if | End state Shared or | be End state be Invalid | End state must be Clean or Invalid |
| --- | --- | --- | --- | --- |
| ReadOnce | Yes | - | - | - |
| ReadClean | Yes | Yes | - | - |
|  | Yes | Yes | - | - |
| ReadShared | Yes | Yes | - | - |
| ReadUnique | Yes | - | Yes | - |
| CleanInvalid | Yes | - | Yes | - |
| MakeInvalid | - | - | Yes | - |
| CleanShared | Yes | - | - | Yes |
| Note |  |  |  |  |
| If a cache line is CRRESP[2], the does assert the | the Dirty state cache line can snoop | the associated in the Dirty state. then the cache | does not assert the a cache line is in the must move to a | snoop response, state and the associated cache or Invalid state. |

The cache line end states in Table D5-3 are classified as follows:

Shared or Invalid
The snooped cache must broadcast a transaction before it can perform a store to the cache line. That
is, the snooped cache must consider that another Manager can hold a copy of the cache line.

Invalid

The snooped cache does not hold a copy of the line. This permits another agent to perform a store
to the cache line.

Clean or Invalid
The snooped cache is not holding the cache line in a Dirty state. The snooped cache cannot perform
a memory update, using a WriteBack or WriteClean transaction, until a later store to the cache line
has occurred.

The following state changes must not occur due to a snoop transaction. A cache line must not move from:

- The Invalid state to any Valid state

- A Clean state to a Dirty state

- A Shared state to a Unique state

- The UniqueDirty state to the UniqueClean state

The cache line end state that is permitted as a result of a snoop transaction is dependent on:

- The state of the cache line before the snoop

- The snoop transaction that is issued

Table D5-4 shows the permitted end states for valid combinations of the initial state and the issued snoop
transaction. Combinations of initial state and end state that are not permitted as a result of a snoop transaction are
excluded from Table D5-4.

A WriteBack, WriteClean, WriteEvict, or Evict transaction can occur while a snoop transaction is in progress.
Table D5-4 does not include the state transition that can occur as a result of these write or evict transactions
occurring. To understand such a scenario, the state transition for the WriteBack, WriteClean, WriteEvict, or Evict
transaction must be applied, followed by the snoop transaction state transition that Table D5-4 shows.

The following abbreviations are used for the cache line states:
UC UniqueClean
UD UniqueDirty
SC SharedClean
SD SharedDirty
I Invalid

Table D5-4 Permitted end states for combinations of initial state and snoop transaction

### Cache line state

Permitted for snoop transaction

ReadClean ReadUnique
Initial End ReadOnce ReadNotSharedDirty CleanInvalid Clean Shared
ReadShared MakeInvalid

<table>
 <tr>
  <th></th>
  <td></td>
  <td>Yes</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>UC I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>UC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>UD I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>UD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>SC I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SD I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
 </tr>
 <tr>
  <th>SD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
 </tr>
</table>

The requirements for the IsShared and PassDirty snoop response bits are as follows:

- If the end state of the cache line is any Valid state, the IsShared snoop response bit must be asserted.

- If the cache line moves from a Dirty state to a Clean state, the PassDirty snoop response bit must be asserted.

If the line moves from a Dirty state to the Invalid state as a result of any snoop transaction, except
MakeInvalid, then the PassDirty snoop response bit must be asserted.

If the cache line moves from a Dirty state to the Invalid state as a result of a MakeInvalid snoop transaction,
then the PassDirty snoop response bit can be asserted or deasserted.

The permitted state changes in Table D5-4 on page D5-236 are combined with these requirements in Table D5-5 to
show the permitted state changes and associated snoop response bits.

Table D5-5 Associated snoop responses for combinations of initial state and snoop transaction

Cache line
state

### Permitted for snoop transaction

### Snoop Response

ReadClean ReadUnique
Initial End ReadOnce ReadNotSharedDirty CleanInvalid CleanShared PassDirty IsShared
ReadShared MakeInvalid

<table>
 <tr>
  <th>I I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <th>UC I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <th>UC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
  <td>0</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
  <td>0</td>
  <td>1</td>
 </tr>
 <tr>
  <th>UD I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
  <td>1a</td>
  <td>0</td>
 </tr>
 <tr>
  <th>UD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
  <td>0</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
  <td>1</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
  <td>0</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SC I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
  <td>0</td>
  <td>0</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
  <td>0</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SD I</th>
  <td>Yes</td>
  <td>Yes</td>
  <td>Yes</td>
  <td>1a</td>
  <td>0</td>
 </tr>
 <tr>
  <th>SC</th>
  <td>Yes</td>
  <td>-</td>
  <td>Yes</td>
  <td>1</td>
  <td>1</td>
 </tr>
 <tr>
  <th>SD</th>
  <td>Yes</td>
  <td>-</td>
  <td>-</td>
  <td>0</td>
  <td>1</td>
 </tr>
</table>

a. For a MakeInvalid snoop transaction, these PassDirty responses are also permitted to be 0.

### D5.2.1 Channel activity

The required channel activity is the same for all snoop transactions:

- The address is received on the AC channel.

- The response is returned on the CR channel.

- The data is provided, if required, on the CD channel.

The DataTransfer snoop response bit CRRESP[0], indicates that a data transfer is required.

The snoop response on CR and the snoop data on CD must only be provided after the ACVALID/ACREADY
handshake occurs.

### D5.2.2 Snoop data transfers

A caching Manager can provide the data value of a cache line. The DataTransfer snoop response bit indicates that
the data value of the cache line is to be transferred.

If a caching Manager receives a snoop transaction other than MakeInvalid for a cache line that is in a Dirty state,
then the caching Manager must ensure that the data value is available so that the original transaction can complete.
The caching Manager can ensure that the data value is available by:

- Returning the data when it completes the snoop transaction.

- Carrying out a memory update, using a WriteBack or WriteClean transaction, before responding to the snoop transaction.

Typically, data is transferred for the following read snoop transactions:

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

Table D5-6 shows protocol-recommended data transfer behavior for snoop transactions, assuming that better system
performance and lower power operation are achieved by providing data in response to these snoop transactions. This
behavior is not mandatory, and alternative schemes can be implemented.

Table D5-6 Recommended data transfer behavior for snoop transactions

| Snoop | Data transfer if | line is Clean Data transfer if cache line is Dirty |
| --- | --- | --- |
| ReadOnce | Yes | Yes |
| ReadClean | Yes | Yes |
|  | Yes | Yes |
| ReadShared | Yes | Yes |
| ReadUnique | Yes | Yes |
| CleanInvalid | No | Yes |
| MakeInvalid | No | No |
| CleanShared | No | Yes |

### D5.2.3 Memory update in progress

The protocol ensures that two components cannot update the same area of main memory at the same time.

If a snooped Manager receives a snoop transaction when it is updating main memory using either a WriteBack or
WriteClean transaction, then it is the responsibility of the snooped Manager to ensure that no other Manager can
update the same area of main memory at the same time. The snooped Manager achieves this by one of the following:

Giving a snoop response with PassDirty deasserted and IsShared asserted, which does not pass permission to
store to the line and does not pass responsibility for updating memory.

- Delaying the snoop response until the snooped Manager has completed the update to main memory.

When a snooped Manager is passing the permission to store to a cache line by sending a suitable snoop response,
all write transactions to update main memory must have completed before the cycle in which the snoop response is
given on the CR channel.

Note

If a snoop response is given while a memory update is in progress, the initial cache state must be considered prior
to the memory update completing. This limits certain combinations of snoop response that can be given. For
example, the response to a CleanShared snoop must have PassDirty asserted if the line is in a Dirty state. However,
if it has a memory update in progress from that line, the Manager is not permitted to assert PassDirty. Therefore, the
Manager must wait for the update to complete before responding to a CleanShared snoop.

### WasUnique snoop response

### D5.2.4

The WasUnique snoop response, CRRESP[4] indicates that the snooped cache line was held in a Unique state
before the snoop transaction.

The WasUnique snoop response must be asserted only if the cache line was held in a Unique state. No other cache
can have a copy of the cache line. A WasUnique response indicates that the interconnect does not have to carry out
further snoop transactions to other caching Managers because no other cache can hold a copy of the data.

A caching Manager does not have to generate the WasUnique response. The protocol permits CRRESP[4] to be
fixed as deasserted. However, always deasserting WasUnique in this way can result in the cache line being provided
to the initiating Manager as Shared, when it could have been provided as Unique. This might result in additional
caches being snooped unnecessarily.

### Non-blocking requirements for a snooped Manager

### D5.2.5

The protocol defines rules for snooped Managers and the interconnect to ensure transactions always progress
through a system. The rules stipulate which transactions must always progress and which transactions can wait for
others to complete.

The rules for the interconnect are defined in Chapter D6 Interconnect Requirements. See Non-blocking requirements
on page D6-260.

The rules that apply to a caching Manager are:

A Manager must complete any snoop transaction, to any address, before any of the following transactions,
issued by the Manager, can be guaranteed to complete:

- Any transaction, to any address, issued on the AR channel.
- A WriteUnique or WriteLineUnique transaction, to any address, issued on the AW channel.
See also Restrictions on WriteUnique and WriteLineUnique usage on page D4-226.

A Manager is permitted to wait for the following transactions to complete, to any address, before completing
a snoop transaction:
- WriteNoSnoop
- WriteBack
- WriteClean
- WriteEvict
- Evict

If the response to a snoop transaction could result in the interconnect generating a write to main memory, or
another Manager being given permission to write the cache line, then the Manager being snooped must
complete any WriteBack, WriteClean, or WriteEvict transaction that is in progress for the cache line before
it provides a response to the snoop transaction.

A Manager must not wait for a WriteUnique or WriteLineUnique transaction to complete before completing
a snoop transaction. If a snoop transaction is received by a Manager and a WriteUnique or WriteLineUnique
transaction is in progress then the snoop transaction must be completed without the use of the AW and W
channels.

### Note

This requirement means that if a Manager has a WriteUnique or WriteLineUnique transaction in progress for
any cache line that is in a Dirty state, and it receives a snoop transaction other than a MakeInvalid transaction,
then it must return the data on the CD channel.

Figure D5-1 shows the non-blocking requirements.

<table>
 <tr>
  <th>AW</th>
  <th>AR</th>
  <th>AC</th>
 </tr>
 <tr>
  <td colspan="3"></td>
 </tr>
</table>

In summary, the requirements are:

### Figure D5-1 Required transaction channel ordering

- Any transaction on the AR channel can be stalled waiting for a transaction on the AC channel.

Any snoop transaction on the AC channel can be stalled waiting for a write transaction on the AW channel,
except for a WriteUnique or WriteLineUnique transaction.

### D5.3 Snoop transactions

This section describes each of the snoop transactions and provides information on the recommended behavior where
options exist.

The following abbreviations are used for the cache line states:
UC UniqueClean
UD UniqueDirty
SC SharedClean
SD SharedDirty
I Invalid

### D5.3.1 ReadOnce

Table D5-7 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for the ReadOnce snoop transaction.

Table D5-7 ReadOnce permitted cache line state changes

| Cache line initial state Cache line | state Snoop PassDirty, | IsShared, CRRESP[3] |
| --- | --- | --- |
| I |  |  |
| UC I | 0 | 0 |
| UC | 0 | 1 |
| SC | 0 | 1 |
| UD I | 1 | 0 |
| UD | 0 | 1 |
| SC | 1 | 1 |
| SD | 0 | 1 |
| SC I | 0 | 0 |
| SC | 0 | 1 |
| SD I | 1 | 0 |
| SC | 1 | 1 |
| SD | 0 | 1 |

A ReadOnce snoop transaction is received by a snooped Manager when the initiating Manager indicates that it is
not going to keep a cached copy of the cache line it is accessing. The ReadOnce snoop transaction enables the
snooped Manager to:

- Keep the cache line in a Unique state.

- Carry out a later store to the cache line without issuing a transaction to obtain permission to store.

If the snooped Manager has a copy of the cache line, then this specification recommends that data is transferred. If
the snooped Manager has the cache line in a Dirty state, then data must be transferred.

This specification recommends that the cache line is passed as Clean. Although it is permitted to pass the cache line
as Dirty, this requires the interconnect to write the cache line back to main memory and the cache line to move to
either the SharedClean or Invalid state.

Note

The IsShared snoop response must be asserted if the snooped Manager is retaining a copy of the cache line, even if
the retained copy is in a Unique state.

### D5.3.2 ReadClean, ReadShared, and ReadNotSharedDirty

The ReadClean, ReadShared, and ReadNotSharedDirty snoop transactions have the same requirements, but differ
in the behavior that this specification recommends.

Table D5-8 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for these snoop transactions.

Table D5-8 ReadClean, ReadShared, and ReadNotSharedDirty permitted cache line state changes

| Initial | End | Snoop PassDirty, | IsShared, CRRESP[3] |
| --- | --- | --- | --- |
| I |  |  | 0 |
| UC | I | 0 | 0 |
|  | SC | 0 | 1 |
| UD | I | 1 | 0 |
|  | SC | 1 | 1 |
|  | SD | 0 | 1 |
| SC | I | 0 | 0 |
|  | SC | 0 | 1 |
| SD | I | 1 | 0 |
|  | SC | 1 | 1 |
|  | SD | 0 | 1 |

If the cached line being snooped is part of an exclusive sequence, then the cache line must remain valid in the
snooped Manager.

If data is available, this specification recommends that the data is transferred.

### ReadClean

For a ReadClean snoop transaction, if the responsibility for writing the cache line back to main memory is being
passed to the interconnect, as indicated by the PassDirty snoop response being asserted, the cache line is written
back to main memory immediately. This specification recommends that the cache line remains Dirty in the snooped
cache.

### ReadShared

For a ReadShared snoop transaction, if the responsibility for writing the cache line back to main memory is being
passed to the initiating Manager, then it is accepted by the Manager. The decision to pass responsibility for writing
the cache line that is Dirty back to main memory depends on which Manager accesses the cache line next:

If the snooped Manager is likely to be the next Manager to store to the cache line, then this specification
recommends that the cache line remains Dirty in the snooped cache but is passed as Clean to the initiating
Manager.

-

-

If the initiating Manager is likely to be the next Manager to store to the cache line, then this specification
recommends that the cache line is passed to the initiating Manager as Dirty. In this case:

If it is likely that the initiating Manager carries out a store before the snooped Manager next loads from
the cache line, then this specification recommends that the snooped Manager does not retain a cached
copy.

If it is likely that the snooped cache loads from the cache line before the initiating Manager performs
a store, then this specification recommends that the snooped Manager does retain a copy of the cache
line.

If it is not known whether the initiating Manager or the snooped Manager is the next to store to the cache line,
then this specification recommends that the cache line is held as Dirty in the cache that is least likely to evict
the cache line. Typically, this would be the initiating Manager, because this is the Manager that has most
recently accessed the cache line.

- If the snooped Manager does not support all five cache states, then fewer options are available.

If information on the access patterns for a cache line is not available, then this specification recommends that the
cache line is passed as Dirty to the initiating Manager and moves to the SharedClean state in the snooped cache.

### ReadNotSharedDirty

If responsibility for updating main memory is passed to the initiating Manager, it is only accepted if the cache line
moves to the Invalid state in the snooped cache. The decision to pass responsibility for writing the cache line back
to main memory depends on which Manager accesses the cache line next:

If the snooped Manager is likely to be the next Manager to store to the cache line, then this specification
recommends that the cache line remains Dirty in the snooped cache but is passed as Clean to the initiating
Manager.

If the initiating Manager is likely to be the next Manager to store to the cache line, then this specification
recommends that the cache line is passed to the initiating Manager as Dirty and the cache line is removed
from the snooped cache.

If it is not known which Manager accesses the cache line next, then no recommendations are provided by this
specification.

### D5.3.3 ReadUnique

Table D5-9 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for the ReadUnique snoop transaction.

Table D5-9 ReadUnique permitted cache line state changes

| Initial | End | Snoop PassDirty, | IsShared, CRRESP[3] |
| --- | --- | --- | --- |
| I |  |  | 0 |
| UC | I | 0 | 0 |
| UD | I | 1 | 0 |
| SC | I | 0 | 0 |
| SD | I | 1 | 0 |

For a ReadUnique transaction, if the snooped cache holds a copy of the cache line in a Dirty state, then the data must
be transferred.

This specification recommends that data is also transferred if the cache line is in a Clean state.

### D5.3.4 CleanInvalid

Table D5-10 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for the CleanInvalid snoop transaction.

Table D5-10 CleanInvalid permitted cache line state changes

| Initial | End | Snoop PassDirty, | IsShared, CRRESP[3] |
| --- | --- | --- | --- |
| I |  |  | 0 |
| UC | I | 0 | 0 |
| UD | I | 1 | 0 |
| SC | I | 0 | 0 |
| SD | I | 1 | 0 |

For a CleanInvalid transaction, if the snooped cache holds a copy of the cache line in a Dirty state, then the data
must be transferred.

This specification recommends that data is not transferred if the cache line is in a Clean state.

### D5.3.5 MakeInvalid

Table D5-11 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for the MakeInvalid snoop transaction.

Table D5-11 MakeInvalid permitted cache line state changes

<table>
 <tr>
  <th>Initial state</th>
  <th>End state Snoop response<br/>PassDirty,</th>
  <th>IsShared, CRRESP[3]</th>
 </tr>
 <tr>
  <td>I</td>
  <td>I0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>UC</td>
  <td>I 0</td>
  <td>0</td>
 </tr>
 <tr>
  <td rowspan="2">UD</td>
  <td>I 0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>1</td>
  <td>0</td>
 </tr>
 <tr>
  <td>SC</td>
  <td>I 0</td>
  <td>0</td>
 </tr>
 <tr>
  <td rowspan="2">SD</td>
  <td>I 0</td>
  <td>0</td>
 </tr>
 <tr>
  <td>1</td>
  <td>0</td>
 </tr>
</table>

For a MakeInvalid transaction, this specification recommends that the data is not transferred.

### Note

If data is not transferred, as indicated by the DataTransfer snoop response, CRRESP[0] being deasserted, then the
PassDirty snoop response bit must also be deasserted.

### D5.3.6 CleanShared

Table D5-12 shows all the permitted cache line state changes and the associated PassDirty and IsShared snoop
responses for the CleanShared snoop transaction.

Table D5-12 CleanShared permitted cache line state changes

| Initial | End | Snoop PassDirty, | IsShared, CRRESP[3] |
| --- | --- | --- | --- |
| I |  |  | 0 |
| UC | I | 0 | 0 |
|  | UC | 0 | 1 |
|  | SC | 0 | 1 |
| UD | I | 1 | 0 |
|  | SC | 1 | 1 |
| SC | I | 0 | 0 |
|  | SC | 0 | 1 |
| SD | I | 1 | 0 |
|  | SC | 1 | 1 |

For a CleanShared transaction, if the snooped cache holds a copy of the cache line in a Dirty state, then the data
must be transferred.

This specification recommends that the data is not transferred if the cache line is in a Clean state.

### Note

The IsShared snoop response must be asserted if the snooped Manager is retaining a copy of the cache line, even if
the retained copy is in a Unique state.

## Chapter D6

### Interconnect Requirements

This chapter describes the interconnect requirements for ACE. It contains the following sections:

- About the interconnect requirements on page D6-248
- Sequencing transactions on page D6-249
- Issuing snoop transactions on page D6-252
- Transaction responses from the interconnect on page D6-255
- Interactions with main memory on page D6-257
- Other requirements on page D6-260
- Interoperability considerations on page D6-262

This chapter does not describe the interconnect requirements for barriers or DVM operations. See Chapter D8
Barrier Transactions and Chapter D13 Distributed Virtual Memory Transactions for these requirements.

### D6.1 About the interconnect requirements

It is the responsibility of the interconnect to:

- Receive transactions from an initiating Manager.

- Determine the order of transactions when multiple transactions are received at the same time.

- Issue snoop transactions, as required, for each transaction from an initiating Manager.

- Receive snoop responses and data, when data is provided, from a snooped Manager.

- Generate the response for the initiating Manager.

- Carry out any required access to main memory.

### D6.2 Sequencing transactions

Many Managers might issue transactions at the same time. The protocol permits each Manager to make multiple
outstanding requests, and to receive multiple outstanding snoop transactions.

It is the responsibility of the interconnect to ensure that there is a defined order in which transactions to the same
cache line can occur, and that the defined order is the same for all components. In the case of two Managers issuing
transactions to the same cache line at approximately the same time, then the interconnect determines which of the
transactions is sequenced first. The arbitration method that is used by the interconnect is not defined by the protocol.

The interconnect indicates the order of transactions to the same cache line by sequencing transaction responses and
snoop transactions to the Managers. The ordering rules are:

If a Manager issues a Coherent or Cache Maintenance transaction to a cache line and it receives a snoop
transaction to the same cache line before it receives a response to the transaction it has issued, then the snoop
transaction is defined as ordered first.

If a Manager issues a Coherent or Cache Maintenance transaction to a cache line and it receives a response
to the transaction before it receives a snoop transaction to the same cache line, then the transaction that is
issued by the Manager is defined as ordered first.

### Note

The relative ordering of transaction responses and snoop transactions only applies to transactions to the same cache
line.

The interconnect must ensure the following:

If the interconnect provides a Manager with a response to a Coherent or Cache Maintenance transaction, it
must not send that Manager a snoop transaction to the same cache line before it has received the associated
RACK or WACK response from that Manager.

If the interconnect sends a snoop transaction to a Manager, it must not provide that Manager with a response
to a Coherent or Cache Maintenance transaction to the same cache line before it has received the associated
CRRESP response from that Manager.

Figure D6-1 shows that from the point that a Manager starts to receive a transaction response, it is guaranteed not
to receive a snoop transaction to the same cache line until it has asserted the acknowledge signal, indicating that the
transaction has completed.

<table>
 <tr>
  <th>AR</th>
  <td>R0 R1 R2 R3</td>
 </tr>
</table>

ACLK

RLAST

RACK

Manager does not observe a snoop to the same line during a transaction response

### Figure D6-1 Transaction response before a snoop transaction

The diagram in Figure D6-2 shows that if a Manager receives a snoop transaction to a cache line to which it has
issued a transaction, but has not yet received a transaction response, then it is guaranteed not to see a transaction
response until it has provided a snoop response.

<table>
 <tr>
  <th colspan="3">ACLK</th>
 </tr>
 <tr>
  <th>AR<br/>RLAST<br/>RACK</th>
  <td>AC<br/>CR</td>
  <td>R0 R1 R2 R3</td>
 </tr>
 <tr>
  <th colspan="3">Manager does not receive a transaction response while<br/>a snoop operation to the same cache line is in progress</th>
 </tr>
</table>

### Figure D6-2 Snoop transaction before a transaction response

### Read and Write Acknowledge

### D6.2.1

The read and write acknowledge signals are required to ensure correct operation where there is a delay between an
interconnect and the Manager completing a transaction. For example, this can occur when a register or clock domain
boundary exists between the interconnect and the Manager.

The Manager provides the read acknowledge signal RACK and the write acknowledge signal WACK to guarantee
that the interconnect can determine when a transaction has completed at the Manager.

The Manager sends the RACK and WACK signals for all transactions, not only Shareable transactions. This
permits the signals to be generated using only the handshake signals on the read data channel or write response
channel respectively.

The Manager must only send a read acknowledge after the last read data transfer in which RLAST is asserted. See
Read acknowledge signaling on page D3-189.

The Manager must only send a write acknowledge after the write response handshake has occurred. See Write
Acknowledge signaling on page D3-191.

There is no mechanism to stall the RACK or WACK signal. The interconnect is required to accept the acknowledge
in the same cycle as the Manager asserted the read or write acknowledge.

### Continuous read data return

### D6.2.2

To specify that a system provides continuous read data return, a Continuous_Cache_Line_Read_Data property is
defined that can be True or False for an ACE interconnect.
True An ACE interconnect is declared as having property Continuous_Cache_Line_Read_Data.
False Interconnect does not support the Continuous_Cache_Line_Read_Data property. If not declared,
the property is considered to be False.

A Manager is defined as requiring this property if it requires that when the first data beat of a cache line read is
returned, then all subsequent data transfers for that cache line are returned without requiring progress on any snoop
transaction.

Note

A Manager that requires the Continuous_Cache_Line_Read_Data property is not required to make forward progress
on new snoop transactions between the return of the first and last read data beats for a cache line transaction it has
issued. However, if the Manager has already started responding to a snoop transaction, and has returned at least one
beat of snoop data, then it must return all the remaining beats of snoop data for a single snoop transaction that it is
responding to.

An interconnect is defined as supporting this property if it is guaranteed that once the first data beat of a cache line
read is returned, then all subsequent data transfers for that cache line are returned without requiring forward progress
on any snoop transaction.

This property is only required for transaction types that are precisely a cache line size:

- All ReadClean, ReadShared, ReadUnique, and ReadNotSharedDirty transactions.

- ReadOnce transactions that are precisely a cache line size.

ReadNoSnoop transactions that are Non-shareable, WriteThrough or WriteBack Cacheable, and are precisely
a cache line size.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>This specification recommends this behavior for all new designs.</td>
 </tr>
</table>

### D6.3 Issuing snoop transactions

It is the responsibility of the interconnect to generate the snoop transactions that are required to progress a
transaction from an initiating Manager.

The transaction from the initiating Manager determines which caching Managers in the shareability domain must
be snooped:

The following transactions do not cause a snoop of any caching Managers:
- ReadNoSnoop
- WriteNoSnoop
- WriteBack
- WriteClean
- WriteEvict
- Evict

The following transactions must cause a snoop of the caching Managers that can hold a copy of the cache line:
- ReadOnce
- ReadClean
- ReadNotSharedDirty
- ReadShared

Snooping of the caching Managers must continue until any one of the following occurs:
- A copy of the line is obtained.
- A snoop response is received with WasUnique, CRRESP[4], asserted.
- All caches have been snooped.

The CleanShared transaction must cause a snoop of the caching Managers that can hold a copy of the cache
line until any one of the following occurs:

A Dirty copy of the line is obtained, as indicated by snoop response PassDirty, CRRESP[2], being
asserted.

-

- A snoop response is received with WasUnique, CRRESP[4], asserted.
- All caches have been snooped.

The following transactions must cause a snoop of the caching Managers that can hold a copy of the cache line:
- ReadUnique
- CleanUnique
- MakeUnique
- CleanInvalid
- MakeInvalid
- WriteUnique
- WriteLineUnique

Snooping of the caching Managers must continue until either of the following occurs:
- A snoop response is received with WasUnique, CRRESP[4], asserted.
- All caches have been snooped.

### Note

The interconnect must not issue a snoop transaction to the initiating Manager.

Table D6-1 on page D6-253 shows for each transaction that is issued by the initiating Manager:

- The snooped cache line state change that must be ensured by the interconnect.

- The snoop transaction that this specification recommends the interconnect to use.

- The optional snoop transactions that the interconnect can use.

In Table D6-1, the snoop transaction that this specification recommends is also included as an optional snoop
transaction.

Table D6-1 Interconnect snoop requirements

<table>
 <tr>
  <th>Transaction</th>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>initiating</th>
  <td></td>
  <td></td>
  <td>Optional Snoop transaction</td>
 </tr>
 <tr>
  <th>Manager</th>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>ReadNoSnoop</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>ReadOnce</th>
  <td>None</td>
  <td>ReadOnce</td>
  <td>ReadOnce, ReadClean,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>ReadNotSharedDirty, ReadShared,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>ReadUnique, CleanInvalid,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>CleanShared</td>
 </tr>
 <tr>
  <th>ReadClean</th>
  <td>Shared or</td>
  <td>ReadClean</td>
  <td>ReadClean, ReadNotSharedDirty,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>ReadShared, ReadUnique,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td>Shared or</td>
  <td></td>
  <td>ReadClean, ReadNotSharedDirty,<br/>ReadShared, ReadUnique,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th>ReadShared</th>
  <td>Shared or</td>
  <td>ReadShared</td>
  <td>ReadClean, ReadNotSharedDirty,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>ReadShared, ReadUnique,</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>CleanInvalid</td>
 </tr>
 <tr>
  <th>ReadUnique</th>
  <td>Invalid</td>
  <td>ReadUnique</td>
  <td>ReadUnique, CleanInvalida</td>
 </tr>
 <tr>
  <th>CleanUnique</th>
  <td>Invalid</td>
  <td>CleanInvalid</td>
  <td>ReadUnique, CleanInvalida</td>
 </tr>
 <tr>
  <th>MakeUnique</th>
  <td>Invalid</td>
  <td>MakeInvalid</td>
  <td>ReadUnique, CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>CleanShared</th>
  <td>Clean or Invalid</td>
  <td>CleanShared</td>
  <td>ReadUnique, CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>CleanShared</td>
 </tr>
 <tr>
  <th>CleanInvalid</th>
  <td>Invalid</td>
  <td>CleanInvalid</td>
  <td>ReadUnique, CleanInvalida</td>
 </tr>
 <tr>
  <th>MakeInvalid</th>
  <td>Invalid</td>
  <td>MakeInvalid</td>
  <td>ReadUnique, CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>WriteNoSnoop</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WriteUnique</th>
  <td>Invalid</td>
  <td>CleanInvalid</td>
  <td>ReadUnique, CleanInvalida</td>
 </tr>
 <tr>
  <th>WriteLineUnique</th>
  <td>Invalid</td>
  <td>MakeInvalid</td>
  <td>ReadUnique, CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>MakeInvalid</td>
 </tr>
 <tr>
  <th>WriteBack</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WriteClean</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WriteEvict</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>Evict</th>
  <td>None</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>a. Other<br/>snooped at<br/>The interconnect</th>
  <td>snoop transactions can<br/>same time.<br/>not required to snoop</td>
  <td>used if the caching<br/>all caches at the same</td>
  <td>in the same shareability domain are not all<br/>caches can be snooped sequentially.</td>
 </tr>
</table>

When the interconnect is snooping multiple caching Managers, it is not required to snoop all the caching Managers
in an identical manner.

If the interconnect is carrying out the snoop transactions sequentially, issuing some snoop transactions after other
snoop transactions for the same cache line have completed, then after a snoop response is received with PassDirty
asserted, it is permitted to use the MakeInvalid snoop transaction for the remaining caching Managers that are still
to be snooped. The transactions that can benefit from this use of the MakeInvalid snoop transaction are:

- WriteUnique

- ReadUnique

- CleanUnique

- CleanInvalid

### D6.4 Transaction responses from the interconnect

The interconnect must provide a response for all transactions from an initiating Manager.
Table D6-2 shows the permitted response from the interconnect for a transaction that is issued on the AR channel.
Table D6-2 Permitted interconnect response for a transaction on the AR channel

<table>
 <tr>
  <th>Transaction from initiating Manager</th>
  <td>Permitted response from the interconnect<br/>IsShared, RRESP[3] PassDirty, RRESP[2]</td>
 </tr>
 <tr>
  <th>ReadNoSnoop</th>
  <td>0 0</td>
 </tr>
 <tr>
  <th>ReadOnce</th>
  <td>0 0<br/>1 0</td>
 </tr>
 <tr>
  <th>ReadClean</th>
  <td>0 0<br/>1 0</td>
 </tr>
 <tr>
  <th>ReadNotSharedDirty</th>
  <td>0 0<br/>0 1<br/>1 0</td>
 </tr>
 <tr>
  <th rowspan="2">ReadShared</th>
  <td>0 0<br/>0 1</td>
 </tr>
 <tr>
  <td>1 0<br/>1 1</td>
 </tr>
 <tr>
  <th>ReadUnique</th>
  <td>0 0<br/>0 1</td>
 </tr>
 <tr>
  <th>CleanUnique</th>
  <td>0 0</td>
 </tr>
 <tr>
  <th>MakeUnique</th>
  <td>0 0</td>
 </tr>
 <tr>
  <th>CleanShared</th>
  <td>0 0<br/>1 0</td>
 </tr>
 <tr>
  <th>CleanInvalid</th>
  <td>0 0</td>
 </tr>
 <tr>
  <th>MakeInvalid</th>
  <td>0 0</td>
 </tr>
</table>

The

interconnect must determine the IsShared

response for the following transactions

from the initiating Manager:

ReadOnce

ReadClean

ReadNotSharedDirty

ReadShared

CleanShared

After snooping all the required caching Managers, the IsShared response to the initiating Manager for these
transactions is determined as follows:

If WasUnique was asserted for any snoop response received by the interconnect then:
- If IsShared was asserted for that snoop response then, IsShared must be asserted in the transaction
response to the initiating Manager.

If IsShared was deasserted for that snoop response then, this specification recommends that IsShared
is deasserted in the transaction response to the initiating Manager. However, it is permitted to assert
IsShared in the transaction response to the initiating Manager.

-

-

-

If WasUnique was not asserted for any snoop response received by the interconnect then:
- If any snoop responses had IsShared asserted then, IsShared must be asserted in the transaction
response to the initiating Manager.

If all snoop responses received by the interconnect had IsShared and DataTransfer deasserted then,
IsShared must be deasserted in the transaction response to the initiating Manager.

If all snoop responses received by the interconnect had IsShared deasserted and any snoop response
had DataTransfer asserted then, this specification recommends that IsShared is deasserted in the
transaction response to the initiating Manager. However, it is permitted to assert IsShared in the
transaction response to the initiating Manager.

The interconnect must determine the PassDirty response to the initiating Manager for the following transactions:

- ReadNotSharedDirty

- ReadShared

- ReadUnique

After snooping all the required caching Managers, the PassDirty response to the initiating Manager for these
transactions is determined as follows:

If PassDirty was asserted for any snoop response that is received by the interconnect, and the interconnect
has not generated a write transaction to update main memory, then PassDirty must be asserted in the
transaction response to the initiating Manager.

### Note

Only transactions that are initiated on the AR channel have additional response bits returned with the transaction
response to the initiating Manager on the R channel.

Write transactions do not have additional response bits. The response from the transaction that passes through the
interconnect can be returned directly to the initiating Manager. The write transactions are:

- WriteNoSnoop

- WriteUnique

- WriteLineUnique

- WriteBack

- WriteClean

- WriteEvict

An Evict transaction does not propagate downstream and the interconnect is required to generate an OKAY,
BRESP[1:0] = 0b00 write response.

### D6.5 Interactions with main memory

This section describes the circumstances in which the interconnect:

- Must read or update main memory directly.

- Can pass permission to update main memory to a Manager.

It contains to following sections:

- Interconnect read from main memory or peripheral device

- Main memory update that is generated by the interconnect on page
- Permission to update main memory on page D6-259

### D6.5.1 Interconnect read from main memory or peripheral device

The interconnect must always read from main memory, or the appropriate peripheral device, for a ReadNoSnoop
transaction.

If the interconnect has not obtained the required data from a snoop transaction, the interconnect must read from main
memory to complete the following transactions:

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

- ReadUnique

An interconnect is permitted to read from main memory before all snoop transactions have completed. However,
the following rules apply:

Data obtained from main memory must not be used if any cache in the shareability domain of the Manager
is holding a Dirty copy of the cache line. Therefore, if the cache line is provided by a snoop transaction, then
data that is obtained from main memory must not be used.

### Note

The snoop response does not indicate if a cache is holding a Dirty copy of the cache line. It only indicates
that the responsibility for updating main memory is being passed.

Data read from main memory must not be used if it is possible that the data read is different to the data that
would be read after all associated snoop transactions have completed. For example, if a WriteBack or
WriteClean transaction to the cache line did not complete before the read from main memory was issued, then
the data that is obtained from main memory must not be used. A new read from main memory must be issued
to obtain the correct data.

### Main memory update that is generated by the interconnect

### D6.5.2

The following transactions are passed through the interconnect to the appropriate main memory or peripheral
device:

- WriteNoSnoop

- WriteBack

- WriteClean

For the WriteUnique and WriteLineUnique transactions, the interconnect must carry out the required snoop
transactions as described in Issuing snoop transactions on page D6-252. If a snoop response is received with
PassDirty asserted, then the final value in memory must be the same as if the memory is updated with the original
Dirty cache line first and then the write data that is part of the WriteUnique or WriteLineUnique transactions.

Examples of how this can be achieved are:

The order in which data is written is:

1. The Dirty cache line that is obtained from the snoop is written to main memory.
2. The write data that is part of the WriteUnique or WriteLineUnique transaction is written to main
memory.

The write data that is part of the WriteUnique or WriteLineUnique transaction must be merged with the data
that is obtained from the Dirty cache line. The valid bytes of the WriteUnique or WriteLineUnique transaction
must overwrite the associated bytes of the Dirty cache line. A single write to main memory is then performed
of the merged data.

When a snoop response has the PassDirty response asserted, and the interconnect does not assert the PassDirty
transaction response for the initiating Manager, the interconnect must generate a write transaction to update main
memory. This occurs when:

The transaction from the initiating Manager does not permit the assertion of the PassDirty response bit. This
is true for the following transactions:
- ReadOnce
- ReadClean
- CleanUnique
- CleanShared
- CleanInvalid
- ReadNotSharedDirty, if the IsShared response is asserted

The interconnect has provided a read response to an initiating Manager before it has received all the snoop
responses and a later snoop response has PassDirty asserted.

The interconnect is permitted to carry out a write transaction to update main memory when it receives a snoop
response with the PassDirty response asserted. In this case, it must not assert the PassDirty transaction response for
the initiating Manager.

If it does not receive a snoop response with the PassDirty response asserted, then the interconnect must not carry
out a write to update main memory.

This specification recommends that the interconnect does not carry out a write transaction to update main memory,
unless required by the combination of the initiating Manager transaction type and the received snoop response.

### D6.5.3 Permission to update main memory

The interconnect must ensure that all updates to main memory, both from caching Managers and the interconnect
itself, are performed in the correct order. The interconnect must only give a caching Manager permission to update
main memory when it is guaranteed that any earlier updates to main memory are ordered.

Permission to update main memory is given to a Manager by either:

- Giving a transaction response to the Manager with the PassDirty response asserted.

Giving a transaction response to the Manager with the IsShared response deasserted. This gives the Manager
permission to store to the cache line and therefore permission to carry out a write to update main memory.

When a Manager is given permission to update main memory, the first point at which the Manager can start the
associated write transaction is the cycle after the RVALID/RREADY handshake in which RLAST is asserted for
the transaction that gave permission to update main memory.

### D6.6 Other requirements

This section describes other requirements that apply to the interconnect. It contains the following sections:

- Non-blocking requirements
- Permitted transaction modifications on page D6-261
- Speculative reads on page D6-261

### D6.6.1 Non-blocking requirements

To ensure transactions always progress through a system, the protocol defines rules for snooped Managers and the
interconnect. The rules stipulate which transactions must always progress and which transactions can wait for others
to complete.

The rules for snooped Managers are defined in Chapter D5 Snoop Transactions. See Non-blocking requirements for
a snooped Manager on page D5-239.

To ensure transactions always progress through a system, the following rules apply for an interconnect:

The following transactions must progress to any address without requiring any pending snoop transactions
to progress:
- WriteNoSnoop
- WriteBack
- WriteClean
- WriteEvict
- Evict

### Note

None of these transactions require an associated snoop transaction.

An interconnect is permitted to wait for a snoop transaction to complete before it progresses the following
transactions:

- Any transaction to any address issued on the AR channel
- WriteUnique or WriteLineUnique transactions to any address issued on the AW channel

### Note

See also Restrictions on WriteUnique and WriteLineUnique usage on page D4-226.

The diagram in Figure D6-3 shows the non-blocking requirements.

<table>
 <tr>
  <th></th>
  <th>AC</th>
 </tr>
 <tr>
  <td colspan="2">AW AR</td>
 </tr>
</table>

In summary, the requirements are:

### Figure D6-3 Required non-blocking transaction channel ordering

- Any transaction on the AR channel can be stalled waiting for a transaction on the AC channel.

Any snoop transaction on the AC channel can be stalled waiting for a write transaction on the AW channel,
except for a WriteUnique or WriteLineUnique transaction.

### D6.6.2 Permitted transaction modifications

An interconnect is permitted to modify transactions as defined by the Modifiable attribute, AxCACHE[1], in
Modifiable transactions on page A4-65:

- A transaction can be broken into multiple transactions.

- Multiple transactions can be merged into a single transaction.

- A read transaction can fetch more data than required.

A write transaction can access a larger address range than required, making use of Write strobes to ensure
that only the required memory locations are updated.

In each generated transaction, the following signals can be modified:
- The transfer address, AxADDR
- The burst size, AxSIZE
- The burst length, AxLEN
- The burst type, AxBURST

Note

A modification to a transaction by the interconnect is not seen by any Manager in the system.

### D6.6.3 Speculative reads

A Manager in the ACE protocol is permitted to carry out a read of a cache line that it already holds in its cache. This
is referred to as a Speculative Read.

A Manager issuing a speculative read must ensure that:

- The transaction uses the correct shareability and cacheability attributes for the address location.

- It uses its cached version of the data and not the data that is returned by the speculative read.

### Note

It is required that a Manager uses its cached version because this could be in the Dirty state and therefore no
other valid copies of the cache line exist.

An interconnect must consider that a Manager might be carrying out a speculative read, as it is not explicit in the
transaction. The interconnect must ensure that it does not use data that is obtained by a speculative read to service
another transaction.

### D6.7

### D6.7.1 Interoperability considerations

A system wide coherency protocol has to work correctly with components that might have:

- Different structures for caching and storing data

- Different cache line sizes

- Different physical address space sizes

### Cache Line size conversions

Maximum performance and efficiency is usually achieved when all components use the same cache line size. For
systems where this is not possible, it is the responsibility of the interconnect to convert between the different cache
line sizes.

Note

The supported cache line sizes and maximum physical address space size are defined at design time.

### Narrow to wide conversion

When the Manager initiating a transaction has a narrow cache line, the following conversion is required:

A read transaction can be converted to a wider cache line size. The transactions that can be converted are:
- ReadOnce
- ReadClean
- ReadNotSharedDirty
- ReadShared
- ReadUnique

The converted transaction fetches the data that is required to complete the original transaction together with
data that is not required. The excess data must be written back to main memory if it is Dirty, but can be
discarded if it is Clean.

A clean transaction can be converted to a wider cache line size. The transactions that can be converted are:
- CleanUnique
- CleanShared
- CleanInvalid

Dirty data obtained as a result of the clean transaction must be written back to main memory.

The MakeUnique or MakeInvalid transactions require special consideration. A cache line that is wider than
that requested by a Manager with a narrow cache line cannot be invalidated. When converting a MakeUnique
or MakeInvalid transaction to a wider cache line size, it must be converted to a CleanInvalid transaction. This
ensures that all dirty data is written back to main memory before the wider line is invalidated.

### Note

Similar consideration is required for the WriteUnique or WriteLineUnique transaction.

### Wide to narrow conversion

When the Manager initiating a transaction has a wide cache line, the transaction can be broken into multiple narrow
transactions.

Each of these narrow transactions can be responded to by different caching Managers during the snoop process and
some of the narrow transactions might require access to main memory.

It is the responsibility of the interconnect to:

- Assemble the transaction response sent to the originating Manager.
- Ensure that the multiple narrow transactions are sequenced correctly, that is, as a contiguous block with
respect to other snoop transactions.

If any part of the wide cache line is shared, then the whole cache line must be considered as shared. If any part of
the wide cache line is Dirty, then the whole cache line must be considered to be Dirty.

The passing of dirty data from a snooped Manager is optional for the following transactions:

- ReadOnce

- ReadClean

- ReadNotSharedDirty

- ReadShared

It is the responsibility of the interconnect to ensure that no parts of the cache line can be Dirty in more than one
cache.

### Additional Cache Line conversion considerations

### D6.7.2

The following transactions, issued by a Manager, are not required to be a full cache line size:

- ReadNoSnoop

- ReadOnce

- WriteNoSnoop

- WriteUnique

- WriteBack

- WriteClean

All other transactions are required to be a full cache line size and must use the full width of the data bus.

As a snoop transaction is required to be a full cache line size, it is the responsibility of the interconnect to carry out
the required size translation. Size translation is required for:

- A ReadOnce transaction that is converted into a ReadOnce snoop.

- A WriteUnique transaction that is converted into a CleanInvalid snoop.

### D6.7.3 Address space size

The protocol supports communication between components that have different physical address space sizes.

Components with different physical address space sizes must communicate as follows:

The component with the smaller physical address space must be positioned within an aligned window in the
larger physical address space. Typically, the window is located at the bottom of the larger physical address
space. However, it is acceptable for the component with the smaller physical address space to be positioned
in an offset window within the larger physical address space.

- An outgoing transaction must have the required additional higher-order bits added to the transaction address.

An incoming transaction must be examined so that:
- A transaction that is within the address window has the higher-order address bits removed and is
passed through.
- A transaction that does not have the required higher-order address bits is suppressed.

### Note

It is the responsibility of the interconnect to provide the required functionality.

## Chapter D7

### Cache Maintenance

This chapter describes cache maintenance operations (CMOs) that assist with software cache management.

It contains the following sections:

- Cache Maintenance Operations on page D7-266

- CMO transactions on page D7-267
- Actions on receiving a CMO on page D7-268
- Cache maintenance transaction attributes on page D7-269
- Cache maintenance propagation on page D7-270
- CMO signaling on page D7-271
- Cache maintenance for Persistence on page D7-273
- Write with cache maintenance on page D7-277
- ACE Managers and CMOs on page D7-280

### D7.1 Cache Maintenance Operations

There are two general types of CMO:

### Cache cleaning

Ensures that a store to a cache line is made visible to non-coherent agents by updating main memory
with the value that is held in a Dirty cache line.

### Cache invalidation

Ensures that a subsequent load from a location does not use a cached copy. Any accesses to that
location will be to main memory. After a line is invalidated from all caches, it can be updated by
coherent or non-coherent agents.

### D7.2 CMO transactions

The specification supports the following transactions for cache maintenance:
CleanShared When completed, all cached copies of the addressed line in the specified domain are Clean and any
associated writes are observable.

When completed, all cached copies of the addressed line in the specified domain are invalidated,
having been written to memory if they were Dirty. Any associated writes are observable.

### CleanInvalid

### MakeInvalid

When completed, all cached copies of the addressed line in the specified domain are invalidated.
Dirty data might have been discarded.

### D7.3 Actions on receiving a CMO

When a component receives a CMO, it must do the following:

1. If the component is a cache and the CMO is cacheable, it must look up the line.

2. If the component is a coherent interconnect and the CMO is Inner or Outer Shareable, a CMO snoop must be sent to any cache that might have the line:
- Allocated, for an Invalidate CMO
- Dirty, for a Clean CMO

3. Write back any dirty data that is found in the cache or peer caches. This specification recommends that Write-Through No-Allocate is used for writes to memory which will be followed by a CMO to the same line. This ensures that the line will be looked up in any downstream cache but will not be allocated.

4. Wait for all snoops and associated writes to receive a response.

5. If the CMO does not need to be sent downstream, the component can issue a response to the CMO.

6. If the CMO does need to be sent downstream, the CMO must be sent and the response that is returned must be propagated when it is received from downstream.

### D7.4 Cache maintenance transaction attributes

The following rules apply to CMO transactions:

- CMOs must be cache line sized and Regular. See Regular transactions on page A3-53 for more details.
- The domain can be Non-shareable, Inner Shareable or Outer Shareable.
- Inner Shareable is supported for legacy reasons and is not recommended for new designs.
- System Shareable is not permitted, which means that CMO transactions must be Normal rather than
Device.

Table D7-1 is a summary of which caches must action CMOs, based on the AxCACHE and AxDOMAIN
attributes:

### Table D7-1 Caches that must action CMOs

| AxCACHE | AxDOMAIN | CMO applies to |
| --- | --- | --- |
| Device | System Shareable | N/A (not legal for CMOs) |
| Non-cacheable | Non-shareable | No caches |
|  | Inner Shareable | Inner-domain peer caches |
|  | Outer Shareable | Inner and outer-domain peer caches |
| Cacheable | Non-shareable | In-line caches |
|  | Inner Shareable | Inner-domain peer caches, in-line caches |
|  | Outer Shareable | Inner and outer-domain peer caches, in-line caches |

To maintain coherency, the following recommendations apply to CMOs and non-CMOs:

- If a location is cacheable for non-CMO transactions, it should be cacheable for CMO transactions.

If a location is in the Inner or Outer Shareable domain for non-CMO transactions, it should be in the same
domain for CMO transactions.

If a location is in the Non-shareable domain for non-CMO transactions, it can be in the Non-shareable, Inner
Shareable, or Outer Shareable domain for CMO transactions.

A Manager should not issue a read request that permits it to allocate a line, while there is an outstanding CMO
to that line.

Allocation hints, such as AxCACHE[3:2], are not required to match between CMO and non-CMO
transactions to the same cache line.

### D7.5 Cache maintenance propagation

The propagation of CMOs downstream of components, depends on the system topology. A CMO must be
propagated downstream if the CMO is cacheable and there is a downstream cache which might have allocated the
line and there is an observer downstream of that cache.

The mechanism for controlling whether a component propagates CMOs is IMPLEMENTATION DEFINED, options
include:

- Using the interface control signals that are described in Chapter D12 Interface Control.

Changing interface properties, where these are configurable. For example, a cache Subordinate interface can
be configured to accept CMOs, but the Manager interface might be configured to not issue CMOs.

### D7.6 CMO signaling

CMOs can be transported on either the read or write channels.
Two properties are used to determine which channels are used:

- CMO_On_Read

- CMO_On_Write

Transporting CMOs on read channels is included in this specification to support legacy components. This
specification recommends that new designs transmit CMOs on the write channels.

### D7.6.1 Cache maintenance on read channels

The CMO_On_Read property is used to indicate whether an interface supports CMOs on the read channels:

### True

CMOs are supported on the AR and R channels. This is consistent with this specification up to and
including Issue F.

If CMO_On_Read is not declared, it is considered True.

### False

CMOs are not supported on the AR and R channels. In this case, they are either signaled on the write
channels or not used by this interface.

The CMO_On_Read property can be set True for the following interfaces:

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

A CMO transaction on the read channels consists of a request on the AR channel and a single beat response on the
R channel. The response indicates that the CMO is observed, and all cache lines have been cleaned and invalidated
if necessary.

Table D7-2 shows the ARSNOOP encodings that are used to signal CMO requests on the AR channel.

### Table D7-2 ARSNOOP encodings

| ARSNOOP | Operation |
| --- | --- |
| 0b1000 | CleanShared |
| 0b1001 | CleanInvalid |
| 0b1101 | MakeInvalid |

### D7.6.2 Cache maintenance on write channels

The CMO_On_Write property is used to indicate whether an interface supports CMOs on the write channels:

True

CMOs are supported on the AW and B channels.

### False

CMOs are not supported on the AW and B channels. In this case, they are either signaled on the read
channels or not used by this interface.

If CMO_On_Write is not declared, it is considered False.

The CMO_On_Write property can be set True for the following interfaces:

- ACE5-Lite

- ACE5-LiteDVM

The following CMOs can be sent on write channels:

- CleanInvalid

- CleanShared

MakeInvalid is not supported on the write channels.

Table D7-3 shows AWSNOOP encoding permissible when the CMO_On_Write property is True.

Table D7-3 AWSNOOP encoding

| AWSNOOP | Operation | Property |
| --- | --- | --- |
| 0b0110 | CMO | CMO_On_Write |

Table D7-4 shows the signal that is added to the AW channel when CMO_On_Write is True.

Table D7-4 Signal added to AW channel when CMO_On_Write is True

<table>
 <tr>
  <th>Signal</th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>AWCMO[1:0]</th>
  <td>Write<br/>When<br/>which is<br/>0b00</td>
  <td>channel CMO indicator.<br/>is CMO, this signal indicates the type of CMO<br/>signaled:<br/>CleanInvalid</td>
 </tr>
 <tr>
  <th></th>
  <td>0b01<br/>When</td>
  <td>CleanShared<br/>is not CMO, this signal must be 0b00.</td>
 </tr>
</table>

Other encodings of AWCMO are used to signal CMOs for persistence. See Table D7-7 on page D7-274 for a full
list of encodings.

A CMO transaction on the write channels consists of a request on the AW channel and a response on the B channel.
There are no transfers on the W channel in a CMO transaction.

The write response to the CMOs CleanInvalid and CleanShared have a single response beat on the B channel. This
indicates that all caches are Clean and/or invalid within the specified domain and any associated writes are
observable.

### D7.7 Cache maintenance for Persistence

Additional cache maintenance operations are introduced that are used to provide a cache clean to the Point of
Persistence or Point of Deep Persistence. These operations are used to ensure that a store operation, which might be
held in a Dirty cache line, is moved downstream to persistent memory.

The Persist_CMO property is used to indicate whether a component supports cache maintenance for Persistence:

True Persistent CMOs are supported.

False Persistent CMOs are not supported.
If Persist_CMO is not declared, it is considered False.

Persistent CMOs can be transmitted on either read or write channels, according to the CMO_On_Read and
CMO_On_Write properties.

If CMO_On_Read and CMO_On_Write are both False, Persist_CMO must be False.

The Persist_CMO property can be set True for the following interfaces:

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

### D7.7.1 Point of Persistence and Deep Persistence

In systems with non-volatile memory, each memory location has a point in the hierarchy at which data can be relied
upon to be persistent when power is removed. This is known as the Point of Persistence (PoP).

Some systems require multiple levels of guarantee regarding the persistence of data. For example, some data might
need the guarantee that it is preserved on power failure and also backup battery failure. To support such a
requirement, this specification also defines the Point of Deep Persistence (PoDP).

Systems might have different points for the PoP and PoDP, or they might be the same.

### D7.7.2 Persistent CMO (PCMO) transactions

The specification supports the following PCMO transactions:

### CleanSharedPersist

When this completes, all cached copies of the addressed line in the specified domain are Clean and
any associated writes are observable and have reached the Point of Persistence.

### CleanSharedDeepPersist

When this completes, all cached copies of the addressed line in the specified domain are Clean and
any associated writes are observable and have reached the Point of Deep Persistence.

When a component receives a PCMO, it is processed in the same way as a CleanShared transaction. If a snoop is
required, a CleanShared snoop transaction is used.

### D7.7.3 PCMO propagation

The propagation of PCMOs downstream of components, depends on the system topology. A PCMO must be
propagated downstream in the following circumstances:

1. If the PCMO is cacheable and there is a downstream cache which might have allocated the cache line and there is an observer downstream of that cache.

2. If there is a PoP downstream of the component.

3. If the PCMO is a CleanSharedDeepPersist and there is a PoDP downstream of the component.

If (1) applies, but not (2) or (3), then a CleanSharedPersist or CleanSharedDeepPersist can be changed to a
CleanShared before being sent downstream.

If the PCMO is changed to a CleanShared, the Persist response must be sent by the component doing the
transformation.

### D7.7.4 PCMOs on read channels

If using read channels to transport cache maintenance operations, only the CleanSharedPersist transaction is
supported.

Table D7-5 shows how the request is signaled on the AR channel using the following encoding of ARSNOOP.

Table D7-5 Encoding of ARSNOOP for PCMOs on read channels

| ARSNOOP | Operation |
| --- | --- |
| 0b1010 | CleanSharedPersist |

CleanSharedDeepPersist is not supported on read channels.

A CleanSharedPersist transaction on the read channels has a single response beat on the R channel. This indicates
that the request is observed, and all cache lines have been cleaned to the PoP.

### D7.7.5 PCMOs on write channels

When using write channels to transport cache maintenance operations, CleanSharedPersist and
CleanSharedDeepPersist are both supported.

### PCMO request on the AW channel

Table D7-6 shows how PCMO requests are signaled using a combination of the AWSNOOP and AWCMO signals.

Table D7-6 Encoding of AWSNOOP on write channels

| AWSNOOP | Operation |
| --- | --- |
| 0b0110 | CMO |

Table D7-7 shows that when AWSNOOP indicates CMO, the AWCMO signal indicates the type of operation being
requested.

Table D7-7 AWCMO operation types

Signal Description

AWCMO[1:0] 0b00: CleanInvalid
0b01: CleanShared
0b10: CleanSharedPersist
0b11: CleanSharedDeepPersist

When Persist_CMO is False, AWCMO must not indicate CleanSharedPersist or CleanSharedDeepPersist.

### PCMO response on the B channel

Table D7-8 shows the signals that are added to the write response channel when CMO_On_Write and Persist_CMO
are both True.

### Table D7-8 Signals added to write response channel with CMO_On_Write and Persist_CMO

| Signal | Description |
| --- | --- |
| BCOMP | Response flag that indicates that a write is observable. |
|  | If BCOMP is present on an interface, it must be asserted for one |
|  | beat of the write response for all write transactions. |
| BPERSIST | Response flag that indicates that write data is updated in persistent |
|  | memory. |
|  | This must be asserted for one beat of a response to a |
|  | CleanSharePersist or CleanSharedDeepPersist. It must be |
|  | deasserted for all other responses. |

CleanSharedPersist and CleanSharedDeepPersist transactions on the AW channel have two responses, known as a
Completion response and Persist response.

Having separate responses enables system tracking resources to be freed up early, in the case that committing data
to the PoP/PoDP takes a long time. The Completion and Persist responses can occur in any order and can be
separated by responses from other transactions.

The Completion response indicates that all caches are Clean, and any associated writes are observable. It has the
following rules:

- BCOMP is asserted and BPERSIST is deasserted.
- BID is driven with the same value as AWID.
- If loopback signaling is supported, BLOOP is driven from AWLOOP.
- If AWIDUNQ was asserted, the ID can be reused when this response is received.
- BRESP can be OKAY, SLVERR or DECERR.
- The Completion response must follow normal response ordering rules.

The Persist response indicates that the data has reached the PoP or PoDP. It has the following rules:

- BCOMP is deasserted and BPERSIST is asserted.
- BID is driven from AWID.
- BLOOP can take any value, it is not required to be driven from AWLOOP.
- BRESP can be OKAY, SLVERR or DECERR.
- The Persist response has no ordering requirements, it can overtake or be overtaken by other response beats.

A Subordinate can optionally combine the two responses into a single beat. The following rules apply:

- BCOMP and BPERSIST are both asserted.
- BID is driven from AWID.
- If loopback signaling is supported, BLOOP is driven from AWLOOP.
- BRESP can be OKAY, SLVERR or DECERR.
- The combined response must follow normal response ordering rules.
- If AWIDUNQ was asserted, the ID can be reused when this response is received.

A Manager can count the number of responses returned with BPERSIST asserted, allowing it to determine when it
has no outstanding persistent operations.

### Example PCMO using write channels

Figure D7-1 shows an example of an ACE-Lite Manager issuing a CleanSharedPersist transaction. The last-level
cache is at the PoS, so can send an OKAY response once the request has been serialized with transactions to that
line from other Managers. In this example, the Non-volatile Memory sends a combined Completion and Persist
response, so the cache must deassert BCOMP when it propagates the response upstream.

Cache line is
observable

ACE-Lite
Manager

CSP (AW)

Interconnect

Last-level Cache

Non-volatile Memory

CSP (AW)

Clean is
complete

CSP (AW)

long
period

Data is
persistent

Cache line is
persistent

Cache must
deassert BCOMP

### Figure D7-1 Example CMO transactions

OKAY with
BCOMP(B)

OKAY with
BCOMP(B)

OKAY with
BCOMP &
BPERSIST (B)

OKAY with
BPERSIST (B)

OKAY with
BPERSIST (B)

### D7.8 Write with cache maintenance

Cache maintenance operations are often used in conjunction with a write to memory. For example:

- A write from an I/O agent which must be made visible to observers which are downstream of caches.

- A write to persistent memory that must ensure that all copies of the line are also cleaned to the point of persistence.

- A CMO that causes a write back of dirty data, which must be followed by the CMO.

Write with cache maintenance adds new opcodes that combine a write with a CMO in order to improve the
efficiency of this type of scenario. It is expected that some Managers will natively generate a write with CMO. In
other cases, a cache or interconnect will combine a CMO with a write before propagating them downstream.

### D7.8.1 Write with CMO configuration

The Write_Plus_CMO property is used to indicate whether a component supports combined write and CMOs on the
write channels.
True Write with CMO operations are supported on the write request channel.
False Write with CMO operations are not supported on the write request channel.

If Write_Plus_CMO is not declared, it is considered False.

The Write_Plus_CMO property can be set True for the following interface types:

- ACE5-Lite

- ACE5-LiteDVM

If the Write_Plus_CMO property is True, the CMO_On_Write property must also be True.

### D7.8.2 Write with CMO operations

A combined write and CMO is supported using previously reserved encodings of AWSNOOP. For these new
encodings, the AWCMO signal indicates which CMO type is combined with the write. The following CMOs are
supported:

- CleanInvalid (CI)

- CleanShared (CS)

- CleanSharedPersist (CSP)

- CleanSharedDeepPersist (CSDP)

Table D7-9 shows valid combinations of AWSNOOP, AWDOMAIN, and AWCMO for the new operations:

Table D7-9 Valid combinations of AWSNOOP, AWDOMAIN, and AWCMO

|  | Operation | AWDOMAIN |  | Options | Size restrictions |
| --- | --- | --- | --- | --- | --- |
| 0b1010 | WritePtlCMO | Non-shareable, | CI, CS, | CSDP | Less than or equal to |
|  |  | Inner Shareable, |  |  | one cache line. |
|  |  | Outer Shareable |  |  |  |
| 0b1011 | WriteFullCMO | Non-shareable, | CI, CS, | CSDP | Cache line sized. |
|  |  | Inner Shareable, |  |  | transaction. |
|  |  | Outer Shareable |  |  |  |
| This | recommends that | designs use Outer | in | to | Inner Shareable. |

Many combinations of write, domain, and CMO are possible. Some example operations with use-case and action
are shown in the following table:

Table D7-10 Combinations of write, domain, and CM

| Operation | Primary use-case | Action |
| --- | --- | --- |
| Outer Shareable | An I/O agent writing less than a cache | All in-line and peer caches must look up the |
| WritePtlCMO | line to a Shareable region, where the | line and write back any dirty data. Data from |
| with CS | data must be visible to observers | a Dirty cache line can be merged with the |
|  | downstream of a cache. | partial write to form a WriteFullCMO with CS |
|  |  | to go downstream. |

Outer Shareable
WriteFullCMO
with CSP

An I/O agent writing a cache line to a
Shareable region, where the data must
reach the Point of Persistence.

The coherent interconnect issues a
MakeInvalid snoop to Outer Shareable peer
caches. In-line caches look up the line and
either update or invalidate any copies.
The write and CSP must be propagated if
there is a Point of Persistence downstream.

<table>
 <tr>
  <th>Non-shareable</th>
  <td>Issued by a cache when a CleanInvalid</td>
  <td>All in-line cache entries must be cleaned and</td>
 </tr>
 <tr>
  <th>WriteFullCMO</th>
  <td>CMO has hit a Dirty line and caused a</td>
  <td>invalidated. The write and CI must be</td>
 </tr>
 <tr>
  <th>with CI</th>
  <td>write to memory.</td>
  <td>propagated if there are observers downstream.</td>
 </tr>
</table>

### D7.8.3 Attributes for write with CMO

A write with CMO has the following attribute constraints:

- AWDOMAIN is Non-shareable, Inner Shareable, or Outer Shareable.

- AWCACHE[1] is asserted, the transaction must be Modifiable.
- AWLOCK is deasserted, Normal access.

A WriteFullCMO must be cache line sized and Regular, see Regular transactions on page A3-53.

A WritePtlCMO must be cache line sized or smaller and not cross a cache line boundary. The associated CMO
applies to the whole of the addressed cache line. AWBURST must not be FIXED.

The cache maintenance part of the write with CMO is always treated as cacheable and Shareable, irrespective of
AWCACHE and AWDOMAIN.

### D7.8.4 Propagation of write with CMO

Propagation of a write with CMO follows the same rules as the propagation of a CMO. It is possible to split a write
with CMO into separate write and CMO transactions for propagation downstream. In that case, either:

- The write is issued first, followed by the CMO on the write request channel with the same ID as the write.

The write is issued first. When the write response is received, the CMO can be issued on the write or read
channel.

When splitting a write and CMO, if AWDOMAIN is Inner Shareable or Outer Shareable, then:

- WritePtlCMO becomes WriteUniquePtl

- WriteFullCMO becomes WriteUniqueFull

If AWDOMAIN is Non-shareable, then the write becomes WriteNoSnoop.

The CMO is sent as cacheable. If there is a downstream cache in the shareable domain, the CMO is sent as
Shareable.

If there is no cache downstream that requires management by cache maintenance, the CMO part of the transaction
can be discarded. If the discarded CMO is a CSP or CSDP, the BCOMP and BPERSIST signals must be set on the
write response.

### D7.8.5 Response to write with CMOs

Responses to writes with CMOs follow the same rules as CMOs on the write channel.

A write with CleanInvalid or CleanShared has a single response beat which indicates that the write and CMO are
both observable.

A write with a CleanSharedPersist or CleanSharedDeepPersist, has one response that indicates that the write and is
observable and one response that indicates that the write has reached the PoP / PoDP.

As with a standalone CSP/CSDP, a Subordinate can optionally combine the two responses into a single beat.

A write with CMO is not permitted to use the MTE Match opcode, so a write response that is combined with Persist
and Match responses is not necessary.

### D7.8.6 Example flow

This figure shows an I/O Coherent Manager issuing an Outer Shareable CleanSharedPersist on the AW channel.
The resulting snoop hits dirty data in the coherent cache. The cache then issues a Non-shareable WriteFullCMO
with CleanSharedPersist. The Subordinate sends a single, combined response on the B channel.

### Figure D7-2 Example write with CMO

HIT (CR/CD)

OKAY with
BCOMP &
BPERSIST (B)

OKAY with
BCOMP &
BPERSIST (B)

OKAY with
BCOMP &
BPERSIST (B)

### D7.9 ACE Managers and CMOs

An ACE Manager issuing a broadcast cache maintenance operation has to co-ordinate the following:

- Appropriate action for local cache maintenance.

- Appropriate action for peer and downstream cache maintenance.

Issuing a broadcast cache maintenance transaction performs the required action on peer caches and causes the
interconnect to generate a downstream cache maintenance transaction to other levels of cache.

The downstream cache maintenance transaction must be correctly ordered with respect to other transactions to the
same cache line. The Manager carrying out the cache maintenance, must follow the sequence:

1. The Manager must complete any outstanding Shareable transactions, which permits the line to be allocated, to a cache line before it issues a cache maintenance transaction to the same cache line.

a. For CleanShared and CleanInvalid operations:
If the Manager holds the cache line in a Dirty state, it must issue a WriteBack or WriteClean
transaction, that must complete, before issuing the cache maintenance transaction.
If the cache line is initially Clean, but there are outstanding Cacheable transactions to the line, then the
Manager must ensure that the line is not Dirty after the completion of all outstanding transactions to
the cache line.

b. For CleanInvalid and MakeInvalid transactions:
The Manager must invalidate the cache line before issuing the cache maintenance transaction after all
outstanding transactions and required WriteBack or WriteClean transactions are complete.

2. The Manager issues the appropriate cache maintenance transaction, after all required outstanding
transactions and required WriteBack or WriteClean transactions are complete.

For CleanShared operations, the Manager is permitted to issue either an Evict or WriteEvict transaction at any point
during the sequence. It is also permitted to perform a local write to the line, if it is in a Unique state.

The Manager must not issue any further Shareable transactions, that permits the line to be allocated, to the same
cache line until the broadcast cache maintenance sequence is complete.

All Managers that support an external snoop filter must ensure that the information that is provided enables the
snoop filter to correctly track the allocation of cache lines. Typically, this is ensured by the correct use of WriteBack
and WriteClean transactions and the appropriate snoop responses. See Chapter D10 Optional External Snoop
Filtering.

For a given memory location, cache maintenance operations are permitted to use different shareability and
cacheability attributes to those that the translation table attributes assign for any non-cache maintenance transaction
to that location. This possible mismatch of attributes means that an interconnect cannot correctly determine the
cacheability attributes to use for any interconnect-generated transactions that result from the cache maintenance
operation, that is required if a snooped cache provides dirty data on the CD channel in response to a snoop
transaction for the cache maintenance operation.

### D7.9.1 Requirements for a snooped Manager

There are no additional requirements for a snooped Manager during a cache maintenance operation. All
requirements are as specified in Chapter D5 Snoop Transactions.

### D7.9.2 Processor cache maintenance instructions

The cache maintenance protocol requires that the cache maintenance operations use the AxCACHE and
AxDOMAIN signals to identify the caches on which the cache maintenance operations must operate.

For a processor that has cache maintenance instructions that are required to operate on a different number of caches
than are defined by the AxCACHE and AxDOMAIN values, the cacheability and shareability of the transaction
must be adapted to meet the requirements of the processor.

For example, if a processor instruction performing a cache maintenance operation on a location with Device
memory attributes is required to operate on all caches within the system, then the Manager must issue a cache
maintenance transaction as Outer Shareable, since this is the most pervasive of the cache maintenance operations
and operates on all the required caches.

### D7.9.3 Unpredictable behavior with software cache maintenance

Cache maintenance can be used to reliably communicate shared memory data structures between a coherent group
of Managers and non-coherent agents. This process must follow a particular sequence to reliably make the data
structures visible as required.

When using cache maintenance to make the writes of a non-coherent agent visible to a coherent group of Managers,
there are periods of time when writing and reading the data structures gives UNPREDICTABLE results and can cause
a loss of coherency.

The observation of a line that is being updated by a non-coherent agent is UNPREDICTABLE during the period
between the clean transaction that starts the sequence and the invalidate transaction that completes it. During this
period, it is permissible to see multiple transitions of a cache line that is being updated by a non-coherent agent.

Figure D7-3 shows the required sequence of communication between a coherent domain and a non-coherent agent.

| Coherent domain | Coherent domain | Non-coherent | Coherent domain | Coherent domain |
| --- | --- | --- | --- | --- |
| access | clean | agent access | invalidate | access |
| 1 | 2 | 3 | 4 | 5 |

### Figure D7-3 Required sequence of communication between coherent and non-coherent domains

The five stage sequence that Figure D7-3 shows is:

1. The coherent domain has access. The coherent domain has full read and write access to the appropriate memory locations during this stage. This stage finishes when all required writes from the coherent domain are complete within the coherent domain.

2. The coherent domain is cleaned. A cache clean operation is required for all the address locations that are undergoing software cache maintenance during this stage. The coherent domain clean forces all previous writes to be visible to the non-coherent agent. This stage finishes when all required writes are complete and therefore visible to the non-coherent agent.

3. The non-coherent agent has access. The non-coherent agent has both read and write access to the defined memory locations during this stage. This stage finishes when all required writes from the non-coherent agent are complete.

4. The coherent domain is invalidated. A cache invalidate operation is required for all the address locations that are undergoing software cache maintenance during this stage. This coherent domain invalidate stage removes all cached copies of the defined locations ensuring that any subsequent access from the coherent domain observes the writes from the non-coherent agent. This stage finishes when all the required invalidations are complete.

5. The coherent domain has full access to the defined memory locations.

Table D7-11 shows when accesses from the coherent domain or the non-coherent agent are permitted. The
remaining accesses can have UNPREDICTABLE results, with possible loss of coherency.

Table D7-11 Permitted accesses from the Coherent domain and Non-coherent agent

| Phase | Description Read | domain Write | Read | agent Write |
| --- | --- | --- | --- | --- |
| 1 | Coherent domain access |  | - | - |
| 2 | Coherent domain clean - | - | - | - |
| 3 | External agent access - | - |  | Permitted |
| 4 | Coherent domain invalidate- | - | - | - |
| 5 | Coherent domain access |  | - | - |

## Chapter D8

### Barrier Transactions

This chapter describes ACE barrier transactions. It contains the following sections:

- About barrier transactions on page D8-284
- Barrier transaction signaling on page D8-285
- Barrier responses and domain boundaries on page D8-287
- Barrier requirements on page D8-290

### D8.1 About barrier transactions

Barrier transactions provide guarantees about the ordering and observation of transactions in a system. Barrier
transactions are not supported in ACE5 and ACE5-Lite variant interfaces. See Barrier transaction support on
page F5-453 for further details.

ACE supports memory barriers and synchronization barriers:

A memory barrier is issued by a Manager to guarantee that if another Manager in the appropriate domain can
observe any transaction issued after the barrier it must be able to observe every transaction issued before the
barrier.

A synchronization barrier is issued by a Manager to guarantee that all transactions that are issued before the
barrier are observable by every Manager in the appropriate domain when the barrier completes. System
domain synchronization barriers have the additional requirement that all transactions that are issued before
the barrier transaction must have reached the endpoint Subordinates they are destined for before the barrier
completes.

A memory barrier is used for memory-based communication. For example, when writing an array of data to
memory, a Manager component can issue a memory barrier before setting a memory flag to indicate that the array
is available. Any other Manager component that can observe the flag must observe all transactions that write to the
array.

### Note

It is not necessary for all Manager components in the domain to observe the updated array at the same time. It is a
requirement for each Manager in the domain that can observe the flag, to be guaranteed to observe the updated array.

A synchronization barrier is used with various forms of sideband signaling communication. For example, when
writing an array of data to memory, a Manager component can use a synchronization barrier before generating an
interrupt to indicate that the array is available. When the synchronization barrier completes, the updated array is
guaranteed to be observable by all Manager components in the domain.

Barrier transactions can be read or write transactions, and are defined as follows:

### Read barrier transactions

A Manager component issues a read barrier transaction on the read address channel and a response
is returned on the read data channel. No data transfer occurs.

### Write barrier transactions

A Manager component issues a write barrier on the write address channel and a response is returned
on the write response channel. No data transfer occurs.

A Manager component must issue barrier transactions as a barrier pair, with a barrier transaction on both the read
address channel and the write address channel. For each address channel, any transaction that is issued on the
channel, before the barrier transaction, is defined to be before the barrier, even if it is issued after the corresponding
barrier on the other address channel. A transaction is defined to be after the barrier if it is issued after both the read
barrier response and write barrier response are received.

### D8.2 Barrier transaction signaling

This section describes the read address channel and write address channel signaling associated with barrier
transactions.

To permit interworking between barrier transactions and QoS, the following types of non-barrier transactions exist:

- Transactions that are affected by barrier transactions.

- Transactions that are not affected by barrier transactions.

This specification recommends that, by default, all transactions are affected by barrier transactions. The only
transaction streams that can be signaled so that they are not affected by barrier transactions are transactions that do
not require ordering with respect to other streams, such as those related to real-time data flows.

### D8.2.1 AxBAR signaling

AxBAR is used to differentiate between barrier transactions and normal transactions. For normal transactions,
AxBAR also indicates that the associated transaction must respect barriers or if the ordering requirements of any
barrier transactions can be ignored. For barrier transactions, AxBAR also indicates that the transaction is a memory
barrier or a synchronization barrier. See Read and write barrier transactions on page D3-178 for more information
about AxBAR encoding.

Table D3-13 on page D3-185 shows the constraints that apply to barrier transactions.

### D8.2.2 AxDOMAIN signaling

The AxDOMAIN signal determines the level of propagation of a barrier transaction, defining the domains within
a system that the barrier transaction accesses. See Shareability domain types on page D3-176. Table D8-1 shows the
different levels of barrier applicability for each domain type.

### Table D8-1 Domain barrier applicability

|  | Domain | Barrier Applicability |
| --- | --- | --- |
| 00 | Non-shareable | Acts as a barrier to other transactions in the current transaction stream. When |
|  |  | two or more transaction streams are combined, no ordering is required with |
|  |  | respect to the newly combined transaction stream. |
| 01 | Inner Shareable | Ordering must be established with respect to other transactions from all |
|  |  | Managers in the same Inner Shareable domain. |
| 10 | Outer | Ordering must be established with respect to other transactions from all Managers in the same Outer Shareable domain. |
| 11 | System | Ordering must be established with respect to all other transactions. For a |
|  |  | Synchronization barrier, a response must only be given when all transactions |
|  |  | from the issuing Manager, which are ahead of the barrier, have reached their |
|  |  | endpoint. |

### D8.2.3 Response signaling

All barrier transactions must complete with a response, as follows:

- Responses for barrier transactions issued on the read address channel are signaled on the read data channel.

Responses for barrier transactions issued on the write address channel are signaled on the write response
channel.

The response must have a matching AXI ID to the barrier transaction and OKAY is the only permitted response for
a barrier transaction. Table D8-2 shows the constraints for barrier transaction response signaling.

Table D8-2 Barrier response transaction constraints

<table>
 <tr>
  <th>Attribute</th>
  <td>Constraint</td>
 </tr>
 <tr>
  <th>RID, BID</th>
  <td>Must match barrier transaction ID.</td>
 </tr>
 <tr>
  <th>RRESP</th>
  <td>Must be all zeros.</td>
 </tr>
 <tr>
  <th>RLAST</th>
  <td>Must be HIGH.</td>
 </tr>
 <tr>
  <th>RDATA</th>
  <td>No constraint, can take any value. Must be ignored.</td>
 </tr>
 <tr>
  <th>BRESP</th>
  <td>Must be all zeros.</td>
 </tr>
</table>

### Note

User-defined signals, such as ARUSER, AWUSER, RUSER, WUSER, and BUSER, cannot be reliably
transported alongside barrier transactions. It is therefore recommended that user-defined signals are all zeros for
barrier transactions.

### D8.3 Barrier responses and domain boundaries

The location of an interconnect in relation to the domain boundaries within a system influences the ability of the
interconnect to issue responses to barrier transactions. In general, a system can contain domain boundaries and
bi-section boundaries, where:

- A domain boundary is an interface downstream from all Manager components in the domain.
- A bi-section boundary is downstream of a subset of Manager components in the domain, but not all of them.

Figure D8-1 shows the domain boundaries in an example system.

<table>
 <tr>
  <th rowspan="2">Outer Shareable domain<br/>Inner Shareable domain</th>
 </tr>
 <tr>
 </tr>
 <tr>
  <td>Manager0 Manager1 Manager2 Manager3 Manager4 Manager5</td>
 </tr>
 <tr>
  <td>Interconnect Interconnect</td>
 </tr>
 <tr>
  <td>Inner domain boundary Outer domain bounda</td>
 </tr>
 <tr>
  <td>Interconnect Subordinate6</td>
 </tr>
 <tr>
  <td>Outer domain boundary Outer domain boundary</td>
 </tr>
 <tr>
  <td rowspan="2">Interconnect Subordinate4 Subordinate5<br/>Subordinate1 Subordinate2 Subordinate3</td>
 </tr>
 <tr>
 </tr>
</table>

### Figure D8-1 Domain boundaries

### Note

The interface to Subordinate6 is an outer domain boundary. Subordinate6 cannot be accessed by Manager0,
Manager1, and Manager2, and therefore it cannot be considered relative to these Manager components. It is
downstream of all Manager components in the outer domain that can access it.

<table>
 <tr>
  <th colspan="4">Figure D8-2 shows the bi-section boundary locations for the same system.</th>
 </tr>
 <tr>
  <td rowspan="8"></td>
  <td colspan="3">Outer Shareable domain</td>
 </tr>
 <tr>
  <td></td>
  <td colspan="2">Inner Shareable domain</td>
 </tr>
 <tr>
  <td colspan="2"></td>
  <td>Manager1 Manager2 Manager3 Manager4 Manager5</td>
 </tr>
 <tr>
  <td colspan="3">Interconnect Interconnect</td>
 </tr>
 <tr>
  <td colspan="3">Outer bi-section boundary Outer bi-section boundary</td>
 </tr>
 <tr>
  <td colspan="3">Interconnect Subordinate6</td>
 </tr>
 <tr>
  <td colspan="3">Interconnect Subordinate4 Subordinate5</td>
 </tr>
 <tr>
  <td colspan="3">Subordinate1 Subordinate2 Subordinate3</td>
 </tr>
</table>

### Figure D8-2 Bi-section boundaries

For an interconnect to issue a response to a barrier transaction, certain conditions apply. The main consideration
influencing the ability of an interconnect to issue responses to barrier transactions is the location of the interconnect
in relation to the domain boundaries within a system.

A system can contain the following types of boundary:

### Domain boundary

A domain boundary is an interface downstream from all Manager components in the domain.
For an interface to be a domain boundary, all of the following must apply:

- The set of addresses that pass across the interface is identical for all Managers in the domain.

- All accesses from any Manager in the domain to those addresses pass across the interface.

### Bi-section boundary

A bi-section boundary is an interface downstream of a subset of Manager components in the
domain, but not all of them.

For an interface to be a bi-section boundary, all of the following must apply:

- The set of addresses that pass across the interface is identical for a subset of Manager
components in the domain.

All accesses from any Manager component in that subset to those addresses pass across the
interface.

No accesses from a Manager component that is in the domain but is not in the subset passes
across the interface.

Considering in turn each Manager component not in the subset, then all addresses that are
accessed by both that Manager and the Managers in the subset must be accessed by the
Managers in the subset across the same interface.

### Note

Informally, an interface is a bi-section boundary if all communication between a subset of
Managers and the other Managers not in the subset pass across the same interface.

In the definition of a bi-section boundary, the subset of Managers is permitted to be all
Managers in the domain and this makes the bi-section boundary definition the same as the
domain boundary definition.

See Barrier responses and domain boundaries on page D8-287 for more information.

An interconnect can provide a response to a barrier transaction in certain circumstances. The following rules apply:

For memory barrier transactions, an interconnect can respond provided it is at the appropriate bi-section
boundary or domain boundary, or beyond the domain boundary.

- For any synchronization barrier transaction that applies to a Non-shareable, Inner Shareable or Outer Shareable domain, an interconnect can respond provided the interconnect is at or beyond the appropriate domain boundary.

For any synchronization barrier transaction that applies to a System domain, an interconnect can respond
provided all transactions before the barrier have reached the endpoint Subordinates they are destined for.

When responding to a barrier transaction, an interconnect must ensure that all transactions that pass across the
interface before the barrier are observable to every transaction after the barrier. Some techniques that can be used
to achieve this are:

Blocking all transactions and sending barrier

The interconnect blocks all transactions received after the barrier transactions and issues a barrier
transaction downstream. The block is removed after a response has been received on both the read
data and write response channels for the downstream issued barrier transactions.

### Blocking all transactions and waiting for completion

The interconnect blocks all transactions after the barrier transactions and waits for transactions
before the barrier to provide a response. The block is removed when all transactions before the
barrier have provided a response. To use this technique, it is required that all transactions must have
attributes that ensure the response originates from a location that is observable by all Managers in
the required barrier domain.

### Hazard-checking transactions

The interconnect blocks all transactions after the barrier transactions until transactions before the
barrier to the same or overlapping addresses have provided a response.

### D8.4 Barrier requirements

This section describes the formal requirements for barrier transactions.

### D8.4.1 Manager requirements

For a Manager component issuing a barrier transaction, the following rules apply:

- Both transactions in a barrier pair must have the same AxID, AxBAR, AxDOMAIN, and AxPROT values.

If the ARID and AWID signals have different widths, the narrower version must be zero-extended to match
the wider version.

Barrier pairs must be issued in the same sequence on the read address and write address channels.

A Manager interface is not required to issue barrier transactions on the read address and write address
channels in the same cycle.

A Manager interface is permitted to issue multiple outstanding barriers, meaning that additional barrier
transactions can be issued before responses to earlier barrier transactions are received. However:

- An ACE-Lite Manager interface can issue outstanding barrier transactions without restriction.
- An ACE Manager interface must not issue more than 256 outstanding barrier transactions.

On each address channel, any transaction issued before the barrier on that channel is defined to be before the barrier,
even if it is issued after the corresponding barrier on the other address channel.

Figure D8-3 shows pre-barrier and post-barrier transactions, with respect to barriers being issued on the address
channels and responses being received:

<table>
 <tr>
  <th>R1† Barrier R2</th>
  <th>R3 R4 R5 R6 R7</th>
  <th>R8‡</th>
 </tr>
 <tr>
  <td>W1† W2† W3†</td>
  <td>Barrier W4 W5 W6 W7</td>
  <td>W8‡</td>
 </tr>
 <tr>
  <td></td>
  <td>Resp</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>Resp</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

Read address
channel
Write address
channel
Read data
channel
Write response
channel

### Figure D8-3 Barrier transaction timing

In Figure D8-3 on page D8-290:

- Transactions R1, W1, W2, and W3 are before the barrier.
- Transactions R8 and W8 are after the barrier.
- Transactions R2, R3, R4, R5, R6, R7, W4, W5, W6, and W7

have no relationship to the barrier.

The following rules apply to Manager components issuing barrier transactions, and relate to non-barrier
transactions:

A Manager must not issue any transaction, either read or write, that must be after the barrier until the Manager
has received a response for the barrier on both the read data and write response channels.

A Manager is permitted to issue transactions between issuing a barrier transaction on the address channel and
receiving the read and write barrier responses. Such transactions have no ordering guarantees with respect to
the barrier. On the address channel, these transactions are permitted to remain after the barrier transaction or
they are permitted to overtake the barrier transaction.

A Manager interface that has issued a read barrier on the read address channel must issue the corresponding
write barrier on the write address channel, in a timely manner, if all other transactions on the write address
channel are progressed. The Manager interface must not require either handshaking or a response to the read
barrier or any read transaction after the read barrier before issuing the corresponding write barrier.

A Manager interface that has issued a write barrier on the write address channel, must issue the corresponding
read barrier on the read address channel, in a timely manner, if all other transactions on the read address
channel are progressed. The Manager interface must not require either handshaking or a response to the write
barrier or any write transaction after the write barrier before issuing the corresponding read barrier.

A barrier must not be issued on the read address channel if subsequent read transactions are required for
either:
- Issuing the corresponding barrier on the write address channel
- Issuing any write transactions that must be before the barrier

For example, a read barrier must not be issued if, after issuing the read barrier, it is necessary to perform
translation table walks to issue write transactions that must be before the corresponding write barrier.

For an ACE-Lite interface, a barrier must not be issued on the write address channel if subsequent write
transactions are required for either:
- Issuing the corresponding barrier on the read address channel
- Issuing any read transactions that must be before the barrier

For an ACE interface, a barrier must not be issued on the write address channel if subsequent write
transactions that must be ordered with respect to the barrier, must be issued for either:
- Issuing the corresponding barrier on the read address channel
- Issuing any read transactions that must be before the barrier

An ACE interface is permitted to issue a write barrier, followed by any of the following transactions that are
required for snoop transactions to that Manager to complete:
- WriteBack
- WriteClean
- WriteEvict
- Evict

The following rules apply to ACE Manager components and the interaction of barriers and local cache accesses:

A Manager must not perform a store that must be ordered with respect to the barrier, to a Shareable location
in its local cache until after the barrier response is received on both read data and write response channels.
This rule applies even if there is no requirement for a transaction to be issued because the cache line is in a
Unique state.

A Manager must not perform a load that must be ordered with respect to the barrier, from a Shareable location
in its local cache until after the barrier response is received on both read data and write response channels.
This applies even if there is no requirement for a transaction to be issued because the cache line is in a Valid
state.

A Manager must be capable of issuing write transactions to complete snoop transactions, even if the read
address channel is stalled.

Issuing a barrier transaction must not prevent any of the following transactions, that are required for snoop
transactions, being issued and completed:
- WriteBack
- WriteClean
- WriteEvict
- Evict

### D8.4.2 Subordinate requirements

The following rules apply to a Subordinate component that is handling barrier transactions:

On receipt of a barrier transaction, an ACE-Lite Subordinate interface is permitted to either:
- Stall the read address channel until it receives the corresponding barrier transaction on the write
address channel.

- Stall the write address channel until it receives the corresponding barrier transaction on the read
address channel.

An ACE Subordinate interface must be able to accept 256 barrier transactions on the write address channel
without blocking the progress of subsequent transactions. It is required that the write address channel is
available and that write transactions can progress.

On receipt of a read barrier, an ACE Subordinate interface is permitted, but not required, to stall the read
address channel.

### D8.4.3 Interconnect requirements

The following rules apply to interconnect processing barrier transactions:

The interconnect topology must not permit transactions with overlapping destination addresses to have a
common start point and end point but have different paths through the interconnect.

When merging two streams of transactions, an interconnect must ensure that barrier pairs are issued on the
read and write channels in the same sequence. Barriers pairs must not be interleaved.

Any interconnect component that has multiple ACE Subordinate ports must be capable of meeting the ACE
Subordinate interface requirements in Subordinate requirements, for all ports simultaneously.

An interconnect must not permit a barrier transaction to overtake any transaction that respects barriers.

A barrier must apply to any transaction that the component issuing the barrier observed before issuing the
barrier.

An interconnect that has not responded to a barrier can permit any non-barrier transaction to overtake that
barrier.

### Note

This specification recommends that ACE interconnect components stall a read barrier until:

- The corresponding write barrier is received.

- All transactions before the read barrier and write barrier have been snooped as required, and all write transactions that must be before the barrier have been issued.

### D8.4.4 Barriers and Device transaction ordering

Barrier transactions ensure ordering between Device transactions to a single peripheral device, regardless of the
addresses within the peripheral being accessed. This means that any hazard-checking that an interconnect performs
when responding to a barrier must be extended to the entire address space of the peripheral, and must not consider
only overlapping transactions. If an interconnect is unable to determine the address range of a particular peripheral,
it must ensure ordering between all accesses that could be addressing that peripheral.

### D8.4.5 Multi-copy atomicity requirements for Shareable locations

For Inner Shareable and Outer Shareable locations, multi-copy atomicity is required. This means that a snoop
response to a write is issued only when all observers in the required shareability domain have observed the write.
Also, on the cycle that a snoop response is received, the associated Manager must have already observed the write.
The point of observation is defined as the handshake on the snoop response channel. The snoop data channel is not
used in defining the point of observation. This means that there is no requirement for barriers on the snoop address
channel.

## Chapter D9

### Exclusive Accesses from ACE Managers

This chapter describes Exclusive accesses from ACE Managers. It contains the following sections:

- About Exclusive accesses from ACE Managers on page D9-296
- Role of the Manager on page D9-297
- Role of the interconnect on page D9-299
- Multiple Exclusive Threads on page D9-302
- Exclusive Accesses from AXI components on page D9-303
- Transaction requirements on page D9-304

### D9.1 About Exclusive accesses from ACE Managers

The principles of Exclusive accesses are that a Manager performing an Exclusive sequence does the following:

- Performs an Exclusive Load from a location

- Calculates a value to store to that location

- Performs an Exclusive Store to the location:
  - The Exclusive Store fails if another Manager has performed a store to the location since the Exclusive Load. In this case, the Exclusive Store does not occur and the Manager does not change the value that is held at the location.
  - The Exclusive Store can pass if no other Manager has performed a store to the location since the Exclusive Load. In this case, the store can occur and the Manager can change the value that is held at the location.

Note

An Exclusive Load by a processor is caused by the execution of an instruction such as LDREX. An Exclusive Store
by a processor is caused by the execution of an instruction such as STREX.

In the ACE protocol, correct execution of an Exclusive sequence places requirements on both the Manager
performing the Exclusive sequence and the interconnect.

For Non-shareable and System Shareable locations, the behavior is identical to the behavior specified in AXI.

For Inner Shareable and Outer Shareable locations, the following requirements apply:

The Manager is responsible for ensuring that it only updates the location if no other Manager can have
performed a store to the location since the Manager performed the Exclusive Load. The term Manager
exclusive monitor describes the monitor that must exist within the Manager component to meet this
requirement.

The interconnect is responsible for ensuring that if two Managers attempt an Exclusive Store transaction to
the same location and it is possible that the second Manager will have its copy of the location invalidated
before its Exclusive Store transaction completes, then the interconnect must fail the Exclusive Store
transaction from the second Manager. The term PoS exclusive monitor describes the monitor that must exist
within the interconnect, at the point of serialization, to meet this requirement.

The term Exclusive Store is used to describe the action of a Manager executing an appropriate program instruction.
When an Exclusive Store passes, this indicates an update to the data value at the address location. When an
Exclusive Store fails, this indicates that the store has not changed the data value at the address location, and the
Exclusive sequence must be restarted.

The term Exclusive Store transaction is used to describe the transaction that is issued on the ACE interface of a
Manager. Not every Exclusive Store requires an Exclusive Store transaction. An Exclusive Store transaction can
pass or fail and this result is made known to the Manager using the transaction response. When an Exclusive Store
transaction passes, this indicates that the transaction has been propagated to other Managers, but it does not indicate
whether the Exclusive Store passes or fails. When an Exclusive Store transaction fails, this indicates that the
transaction has not been propagated to other Managers and therefore the associated Exclusive Store cannot pass.

All Managers that attempt an Exclusive access to the same location must be using the same shareability for the
location. If the location for the Exclusive access is Shareable, then all Managers must be able to participate in the
coherency protocol.

When first obtaining a copy of the exclusive location, it is important that the line is not removed from another cache
that is also performing an Exclusive sequence to the same cache line. For this reason, ReadClean or ReadShared
must be used rather than ReadNotSharedDirty or ReadUnique.

A Load Exclusive, Store Exclusive sequence (LDREX, STREX) must use an Exclusive sequence. An atomic update, such
as a swap operation or a read-modify-write atomic operation, is not required to use an Exclusive sequence. For such
atomic updates, it is permitted to use a ReadUnique transaction that is not marked as Exclusive, if it can be
guaranteed to successfully complete the atomic update with no other external action.

### D9.2 Role of the Manager

The Manager must implement a Manager exclusive monitor, that is used to monitor the location that is used by an
Exclusive sequence. This Manager exclusive monitor is used to determine if another Manager could have performed
a store to the location during the Exclusive sequence by monitoring the snoop transaction that it receives.

When the Manager performs an Exclusive Load, the Manager exclusive monitor is set. The Manager exclusive
monitor is reset when a snoop transaction is observed that indicates another Manager could perform a store to the
location.

### D9.2.1 Exclusive Load

The Manager starts an Exclusive sequence with an Exclusive Load. The start of the Exclusive sequence must set the
Manager exclusive monitor.

If the Manager does not hold a copy of the cache line, then it must obtain a copy of the line using either a ReadClean
or a ReadShared transaction.

An Exclusive Load transaction is a ReadClean or ReadShared transaction with the ARLOCK signal asserted. This
indicates to the PoS exclusive monitor that the Manager is starting an Exclusive sequence.

It is recommended, but not required, that a Manager use an Exclusive Load transaction, with ARLOCK asserted,
if it is issuing a transaction at the start of Exclusive sequence. If a Manager does not use an Exclusive Load
transaction, it is permitted to use a ReadClean or ReadShared transaction with ARLOCK deasserted.

If the Manager holds a copy of the line in a Unique state, then issuing a transaction for the Exclusive Load is
permitted but not recommended.

An Exclusive Load is expected to receive an EXOKAY response, which indicates that Exclusive accesses are
supported at the address of the transaction. If Exclusive accesses are not supported, then the transaction will receive
an OKAY response.

### D9.2.2 Exclusive Load to Exclusive Store

After the execution of an Exclusive Load a Manager will typically calculate a new value to store to the location
before it attempts the Exclusive Store.

It is not required that a Manager always completes an Exclusive sequence. For example, the value that is obtained
by the Exclusive Load can indicate that a semaphore is held by another Manager and therefore the value cannot be
changed until the semaphore is released by the other Manager. Therefore, the Exclusive sequence can be restarted
with no attempt to complete the current Exclusive sequence.

During the time between the Exclusive Load and the Exclusive Store, the Manager exclusive monitor must monitor
the location to determine whether another Manager might have performed a store to the location.

### D9.2.3 Exclusive Store

A Manager must not permit an Exclusive Store transaction to be in progress at the same time as any transaction that
registers that it is performing an Exclusive sequence. The Manager must wait for any such transaction to complete
before issuing an Exclusive Store transaction. The transactions that register that a Manager is performing an
Exclusive sequence are Exclusive Load transactions to any location, and Exclusive Store transactions to any
location. These transactions are:

- ReadClean with ARLOCK asserted

- ReadShared with ARLOCK asserted
- CleanUnique with ARLOCK asserted

When a Manager executes an Exclusive Store, the following behavior is required:

If the Manager exclusive monitor has been reset, the Exclusive Store must fail and the Manager must not
issue an Exclusive Store transaction. The Manager must restart the Exclusive sequence.

### Note

In this case, not issuing an Exclusive Store transaction avoids unnecessarily invalidating other copies of the
line by preventing the issue of a transaction that will eventually fail.

If the line is held in a Unique state and the Manager exclusive monitor is set, then the Exclusive Store has
passed and the Manager can execute the Exclusive Store without issuing a transaction.

If the line is held in a Shared state and the Manager exclusive monitor is set, then the Manager must issue a
transaction to perform the Exclusive Store. This check of the Manager exclusive monitor must only occur
after any other transactions that register a Manager is performing an Exclusive sequence have completed. A
CleanUnique transaction with ARLOCK asserted must be used. The Manager exclusive monitor must
continue to operate during this transaction. The transaction will respond with an OKAY or EXOKAY
response.

If the transaction receives an EXOKAY response, then it indicates that the transaction has passed and been
propagated to invalidate all other copies of the line. After an Exclusive transaction completes with an EXOKAY
response, the Manager must again check the Manager exclusive monitor:

- If the Manager exclusive monitor is set, then the Exclusive Store has passed and the store is performed.

If the Manager exclusive monitor has been reset, it indicates that a non-Exclusive Store has occurred to the
cache between the point that the Exclusive Store transaction was issued and the point that it completed. The
Exclusive Store must fail and the Exclusive sequence must be restarted.

If the Manager has not been able to track the exclusive nature of the cache line, because the line has been
evicted, then the Exclusive Store must fail and the Exclusive sequence must be restarted.

If the transaction receives an OKAY response, then it indicates that another Manager has been permitted to progress
a transaction that is associated with an Exclusive Store. The transaction that is associated with the Exclusive Store
from this Manager has failed and has not propagated to other Managers in the system. When an Exclusive
transaction completes with an OKAY response the following options exist:

The Manager can fail the Exclusive Store and restart the Exclusive sequence without checking the state of
the line when the access completed.

The Manager can check the Manager exclusive monitor:
- If the Manager exclusive monitor has been reset, then the Manager must fail the Exclusive Store and
restart the Exclusive sequence.

If the Manager exclusive monitor is set, then the Manager can repeat the Exclusive Store transaction.

-

### D9.3 Role of the interconnect

The interconnect can pass or fail an Exclusive Store transaction. A pass indicates that the transaction has been
propagated to other cacheable Managers. A fail indicates that the transaction has not been propagated to other
Managers and therefore the Exclusive Store cannot pass.

The interconnect is required to have a monitor that is used to ensure that an Exclusive Store transaction from a
Manager is only successful if that Manager could not have received a snoop transaction relating to an Exclusive
Store to the same address from another Manager after it issued its own Exclusive Store transaction. This monitor is
referred to as the PoS exclusive monitor and it exists within the interconnect at the point of serialization.

### D9.3.1 Minimum PoS Exclusive Monitor

The minimum requirement of PoS exclusive monitor is to record when any Manager performs a Shareable
transaction that is related to an Exclusive sequence. The Shareable transactions that are related to an Exclusive
sequence are:

- ReadClean with ARLOCK asserted
- ReadShared with ARLOCK asserted
- CleanUnique with ARLOCK asserted

If a Manager has performed a transaction that is related to an Exclusive sequence and it then performs an Exclusive
Store transaction before a successful Exclusive Store transaction from another Manager is scheduled, then the
Exclusive Store transaction must be successful.

The monitor must support the parallel monitoring of all Exclusive-capable Managers in the system.

When the interconnect receives a transaction that is associated with an Exclusive Load or an Exclusive Store, the
monitor registers that the Manager is attempting an Exclusive sequence. If an Exclusive Store fails, indicated by an
OKAY response, the attempt must be recorded. If the Exclusive Store transaction is successful it is recommended,
but not required, that the monitor registers that the Manager is attempting an Exclusive sequence.

If an Exclusive Store transaction from one Manager passes, the registered attempts of all other Managers are reset.
The other Managers can only register a new Exclusive sequence when it is guaranteed that outstanding Exclusive
Stores can complete without the line being invalidated by later Exclusive Stores. This can be achieved by observing
the RACK from the Exclusive Store or through address hazarding in the interconnect.

When the interconnect receives an Exclusive Store transaction:

If the PoS exclusive monitor has registered that the Manager is performing an Exclusive sequence, that is, it
has not been reset by another Manager's Exclusive Store transaction, then the Exclusive Store transaction is
successful and is allowed to proceed. An EXOKAY response is returned to the issuing Manager.

If the PoS exclusive monitor has not registered that the Manager is performing an Exclusive sequence, that
is, it has been reset by another Manager's Exclusive Store transaction, then the Exclusive Store transaction
is failed and is not allowed to proceed. An OKAY response is returned to the issuing Manager.

### Note

A successful Exclusive Store transaction from a Manager does not have to reset that the Manager is performing an
Exclusive sequence. The Manager can continue to perform a sequence of Exclusive Store transactions that will all
be successful, until another Manager performs a successful Exclusive Store transaction.

From reset, the first Manager to perform an Exclusive Store transaction can be successful, but is not required to be.
At that point, all other Managers must then register the start of their Exclusive sequence for their Exclusive Store
transaction to be successful.

### D9.3.2 Additional address comparison

The interconnect monitor can be enhanced to include some address comparison. A full address comparison is not
required and it is permitted to only record a subset of address bits. This approach reduces the chances of an
Exclusive Store transaction failing because of another Manager's Exclusive Store transaction to a different address
location. The number of bits of address comparison that is used is an implementation choice.

Where additional address comparison monitor is used, the monitored address bits are recorded at the start of an
Exclusive sequence on either a Load Exclusive or Store Exclusive transaction. It is reset by a successful Store
Exclusive transaction from another Manager to a matching address.

A monitor with additional address comparison must include a minimum monitor of a single bit for every
Exclusive-capable Manager to ensure progress.

An Exclusive Store transaction is allowed to progress if one of the following occurs:

The address monitor has registered an Exclusive sequence for a matching address from the same Manager
and has not been reset by an Exclusive Store transaction from a different Manager with a matching address.

The minimum single bit monitor has registered an Exclusive sequence from the same Manager, and it has not
been reset by an Exclusive Store transaction from a different Manager to any address.

### Note

In the above description, the term matching address is used to describe where a monitor only records a subset of
address bits. A matching address is where the address bits that are recorded are identical, but the address bits that
are not recorded can be different.

An implementation does not require address monitor for each Exclusive-capable Manager. Because the address
monitor provides a performance enhancement, it is acceptable to have fewer address monitors and for the use of
these to be IMPLEMENTATION DEFINED. Examples of how the additional address monitors can be used include:

- Use on a first-come first-served basis

- Allocation to particular Managers

- A more complex algorithm

Additional PoS Exclusive Monitor functionality can be provided to prevent interference, or denial of service, caused
by one agent in the system issuing a large number of Exclusive access transactions. This specification recommends
that Secure exclusive accesses are permitted to make progress independently of the progress of Non-secure
exclusive accesses.

### D9.3.3 Multiple interconnect PoS monitors

When the interconnect contains multiple points of serialization, as the serialization for different address ranges is
done at different points within the interconnect, then a PoS exclusive monitor can be at each point of serialization.

### D9.3.4 PoS Exclusive Monitor behavior

The following terms can be used to describe the behavior of a PoS exclusive monitor:

### True pass

### True fail

Describes the case where an Exclusive Store transaction is permitted to progress and when the
transaction completes the Exclusive Store will also pass, permitting the Manager to make forward
progress.

Describes the case where an Exclusive Store transaction is failed because another Manager has
already performed a successful Exclusive Store transaction to the same address location, so at least
one agent has made forward progress.

### False pass

Can occur for an Exclusive Store transaction, for which the Exclusive Store will eventually fail. This
can only occur when a non-exclusive store transaction from another agent to the same location has
occurred. This non-exclusive store transaction from another agent is considered as progress for that
other agent.

#### False fail

Can occur for an Exclusive Store transaction in the following circumstances:

- No transaction was issued for the Load Exclusive. This is resolved by re-issuing the
Exclusive Store.

An Exclusive Store transaction from another agent to a different location has been successful
between the point that the Exclusive sequence is first registered and the point that the
Exclusive Store transaction is scheduled. This is resolved by re-issuing the Exclusive Store.

An Exclusive Store transaction from another agent to the same location has been successful,
but that other agent is destined to eventually fail because a third party has performed a
non-exclusive store transaction. This non-exclusive store transaction from the third party is
considered as progress for that third party.

### D9.4 Multiple Exclusive Threads

The protocol can support more than one Exclusive-capable Manager for each interface. This permits multiple
Managers to use the same interface for Exclusive accesses. In this scenario, the interconnect must be able to use the
AXI ID values to differentiate between the different Managers using the same interface.

### D9.5 Exclusive Accesses from AXI components

An important consideration for the conversion of legacy AXI components for use in an ACE environment is the
handling of Exclusive accesses. In a coherent environment, a monitor, which is associated with each Manager, is
used for Shareable transactions to track whether another component has performed a store to an address that is being
monitored for exclusivity. For non-cacheable transactions, a monitor that is remote from the Manager issuing an
Exclusive access, is used to track all access to a location that is being monitored for exclusivity and this monitor can
return a pass or fail response as part of the write response.

Therefore conversion of legacy AXI components for use in an ACE environment requires a monitor that is
associated with the Manager interface that is being converted if the interface is capable of performing Exclusive
accesses to Shareable locations.

### D9.6 Transaction requirements

This section summarizes the requirements of transactions that are associated with Exclusive accesses.
The existing AXI rules apply for all transactions with AxDOMAIN set to Non-shareable or System Shareable.
For transactions with ARDOMAIN set to Inner Shareable or Outer Shareable:

- An Exclusive Load transaction must assert ARLOCK.

- An Exclusive Load transaction must use either ReadClean or ReadShared transaction type.

An Exclusive Store transaction must assert ARLOCK.

An Exclusive Store transaction must be a CleanUnique transaction.

An Exclusive Store transaction response can be either EXOKAY or OKAY.

Matching Exclusive Load transactions and Exclusive Store transactions are not required.

When multiple Exclusive-capable threads use a single interface:

- Transactions must use an AXI ID value that permits the Exclusive-capable thread to be identified.

The bits of the AXI ID signal that are used to identify the Exclusive-capable thread must be the same for all
Exclusive transactions from the same Exclusive-capable thread.

A single Exclusive-capable thread must not have an Exclusive Store transaction in progress at the same time as any
transaction that registers that a Manager is performing an Exclusive sequence.

## Chapter D10

### Optional External Snoop Filtering

This chapter describes using an external snoop filter with an existing Manager component. It contains the following
sections:

- About external snoop filtering on page D10-306

- Manager requirements to support snoop filters on page D10-308

- External snoop filter requirements on page D10-309

### D10.1 About external snoop filtering

The ACE protocol supports a mechanism for constructing an optional external snoop filter that operates with an
existing caching Manager component.

### Note

External snoop filtering is optional. If a Manager component supports external snoop filtering, it must declare this
in its data sheet.

To support the addition of a snoop filter, a caching Manager must ensure that it broadcasts sufficient information to
permit a snoop filter to track Shareable allocations and evictions for cache lines that the Manager maintains. This
ensures that a snoop filter can:

- Reduce the number of snoop transactions that are required to be passed to the Manager, which reduces cache intrusion.

- In certain circumstances, provide a faster response to snoop transactions.

For correct operation, a snoop filter must observe any transactions being issued by a Manager that could result in
that Manager allocating a cache line in its local cache. The snoop filter must also observe activity that indicates an
eviction from the local cache of that Manager. This includes:

- Local cache line evictions.

- WriteBack of cache lines to memory.

- Snoop transactions that cause an eviction.

A snoop filter can consider that a cache line is no longer allocated following a WriteEvict transaction.

Whether a transaction causes a cache line to be allocated depends on the transaction. A snoop filter can determine
the expected allocation state of a particular cache line by observing the transactions that are issued by a Manager
component. Table D10-1 shows the expected allocation state for both cache maintenance transactions and normal
transactions. If the actual allocation for a cache line is different from what the filter expects, then an associated Evict
operation must be performed to ensure that the snoop filter can correctly track the allocated cache line.

### Table D10-1 External snoop filter expected cache line allocation states

| Transaction | Expected cache line allocation |
| --- | --- |
| ReadOnce | Allocation does not change |
| ReadClean | Allocated |
|  | Allocated |
| ReadShared | Allocated |
| ReadUnique | Allocated |
| CleanUnique | Allocated |
| MakeUnique | Allocated |
| CleanShared | Allocation does not change |
| CleanInvalid | Evicted |
| MakeInvalid | Evicted |
| WriteUnique | Allocation does not change |
| WriteLineUnique | Allocation does not change |

WriteClean

Allocation does not change

Table D10-1 External snoop filter expected cache line allocation states (continued)

<table>
 <tr>
  <th>Transaction</th>
  <td>Expected cache line allocation</td>
 </tr>
 <tr>
  <th>WriteBack</th>
  <td>Evicted</td>
 </tr>
 <tr>
  <th>WriteEvict</th>
  <td>Evicted</td>
 </tr>
 <tr>
  <th>Evict</th>
  <td>Evicted</td>
 </tr>
</table>

An error response to a transaction does not change the allocation behavior of a snoop filter. Any Manager that
changes its allocation behavior when a transaction receives an error response must take appropriate action to ensure
that the snoop filter is kept up to date.

### D10.2 Manager requirements to support snoop filters

The snoop filter monitors the snoop address and the snoop response channels to determine the effect of snoop
transactions on the allocation of particular cache lines, and the IsShared response is used to determine if a cache line
remains allocated in a cache after a snoop. A Manager component that is implementing snoop filter functionality
must therefore provide an accurate IsShared response. See Read response signaling on page D3-186.

A Manager component must ensure that the transactions issued never indicate to the external snoop filter that a
cache line is not allocated when the Manager still holds a copy of the cache line. A Manager component can ensure
that the snoop filter always has correct allocation information using the following techniques.

This specification recommends that a Manager component must not:

Issue a transaction that indicates that the cache line is to become allocated, while a transaction that indicates
the same cache line is to be evicted is in progress.

Issue a transaction that indicates that a cache line is to be evicted, while a transaction that indicates the same
cache line is to be allocated is in progress.

If a Manager component does overlap allocating and evicting transactions, then the following must apply:

From the first cycle that there is an overlapping allocating transaction and evicting transaction for the same
cache line, the caching Manager must not have the line that is allocated.

- The line must remain de-allocated until a non-overlapping allocating transaction has completed.

When the overlapping allocating and evicting transactions have all completed the allocation status of the line
must be resolved, by issuing either:
- An allocating transaction, to indicate that the line is allocated
- An evicting transaction, to indicate that the line is de-allocated

### D10.3 External snoop filter requirements

The snoop filter must ensure that it does not cause a capacity overflow by considering cache lines that are accessed
using ReadNoSnoop and WriteNoSnoop transactions to be allocated. Such cache lines are Non-shareable locations,
and Manager components are not required to issue Evict transactions to these locations.

Snoop filters must consider speculative reads. For example, a snoop filter cannot rely on an allocating transaction
to determine whether it must add a cache line to its list of allocated cache lines. It must check the current list of
allocated lines so that it does not hold two copies of the same line, potentially overflowing its resources.

The snoop filter must be able to track the allocation of all cache lines that could be allocated in the associated cache.
Typically, the storage within a snoop filter will match the structure of the cache for which it is filtering snoops, in
terms of:

- Associativity

- Size of the cache tags

- Total number of cache lines being tracked

Transactions in progress, and other caching structures within a Manager, can cause a situation where the snoop filter
is required to track additional cache lines. A snoop filter can include additional storage to enable it to track these
additional cache lines.

To avoid snoop filter overflow, where the tracking requirements exceed the total capabilities of the snoop filter, the
snoop filter is permitted to issue snoop transactions. Transactions, such as CleanInvalid, are used to remove cache
lines from the associated cache. Use of this technique ensures that the snoop filter can continue to correctly track
all allocated cache lines.

## Chapter D11

### AMBA ACE-Lite

This chapter describes the ACE-Lite interface. It contains the following sections:

- About ACE-Lite on page D11-312
- ACE-Lite signal requirements on page D11-313

### D11.1 About ACE-Lite

ACE-Lite is used by Manager components that do not have hardware coherent caches, but are required to:

- Indicate if issued transactions could be held in the hardware coherent caches of other Managers.
- Issue barrier transactions.
- Issue broadcast cache maintenance operations.

ACE-Lite consists of an AXI4 interface with additional signals on the read address channel and write address
channel. See Read address channel (AR) signals on page D2-170 and Write address channel (AW) signals on
page D2-170 for more information.

ACE-Lite does not include:

- A snoop address channel

- A snoop response channel

- A snoop data channel

- A read acknowledge signal

- A write acknowledge signal

- The ACE-specific read response bits

### D11.2 ACE-Lite signal requirements

An ACE-Lite interface can issue all Non-shareable transactions, but can only use a restricted set of Shareable
transaction types.

Table D11-1 shows the permitted combinations of ARSNOOP[3:0], ARBAR[0], and ARDOMAIN[1:0] for each
permitted category of Shareable read transaction.

Table D11-1 ACE-Lite permitted read address control signal combinations

| Transaction |  |  |  | Transaction |
| --- | --- | --- | --- | --- |
| Non-snooping | 0b0000 | 0b0 | 0b00 | ReadNoSnoop |
|  |  |  | 0b11 |  |
| Coherent | 0b0000 | 0b0 | 0b01 | ReadOnce |
|  |  |  | 0b10 |  |
| Cache | 0b1000 | 0b0 | 0b00 | CleanShared |
|  |  |  | 0b01 |  |
|  |  |  | 0b10 |  |
| Cache | 0b1001 | 0b0 | 0b00 | CleanInvalid |
|  |  |  | 0b01 |  |
|  |  |  | 0b10 |  |
| Cache | 0b1101 | 0b0 | 0b00 | MakeInvalid |
|  |  |  | 0b01 |  |
|  |  |  | 0b10 |  |
| Barrier | 0b0000 | 0b1 | 0b00 | Barrier |
|  |  |  | 0b01 |  |
|  |  |  | 0b10 |  |
|  |  |  | 0b11 |  |
| Table D11-2 shows the category of Shareable | transaction. Table D11-2 | of | and write address | for each permitted signal combinations |
| Transaction |  |  |  | Transaction |
| Non-snooping | 0b000 | 0b0 | 0b00 | WriteNoSnoop |
|  |  |  | 0b11 |  |
| Coherent | 0b000 | 0b0 | 0b01 | WriteUnique |
|  |  |  | 0b10 |  |
| Coherent | 0b001 | 0b0 | 0b01 | WriteLineUnique |
|  |  |  | 0b10 |  |
| Barrier | 0b000 | 0b1 | 0b00 | Barrier |
|  |  |  | 0b01 |  |
|  |  |  | 0b10 |  |
|  |  |  | 0b11 |  |

## Chapter D12

### Interface Control

This chapter describes the optional signals that can be used to configure the behavior of the ACE interface. It
contains the following section:

- About the interface control signals on page D12-316

### D12.1 About the interface control signals

This section lists the signals that are available to configure interface behavior in components that support flexible
interfaces.

### Note

The signals in this section are optional, and are not part of the AMBA ACE protocol. However, if used, it is an
architectural requirement that all interface control signals are stable, and remain static, on reset.

The AMBA ACE configuration signals are:

### BROADCASTINNER

Tie-off input to control whether a Manager issues Inner Shareable transactions. If this signal is
asserted, BROADCASTOUTER must also be asserted.

### BROADCASTOUTER

Tie-off input to control whether a Manager issues Outer Shareable transactions.

### BROADCASTCACHEMAINT

Tie-off input to control whether a Manager issues cache maintenance operations.
This signal controls the broadcast of cache maintenance operations and is asserted whenever a
downstream cache exists below the coherent interconnect. Asserting this signal results in
CleanShared, CleanInvalid, and MakeInvalid transactions that must be observed by a downstream
cache being broadcast.

When this signal is deasserted, whether cache maintenance operations are broadcast depends on:

- Their shareability domain

- BROADCASTINNER and BROADCASTOUTER settings

Table D12-1 shows the valid combinations of the interface control signals and the corresponding transactions that
are broadcast.

Table D12-1 Interface control signals

<table>
 <tr>
  <th>Signal</th>
  <th></th>
  <th></th>
  <th>broadcast</th>
 </tr>
 <tr>
  <td>BROADCASTINNER</td>
  <td>BROADCASTOUTER</td>
  <td>BROADCASTCACHEMAINT</td>
  <td></td>
 </tr>
 <tr>
  <td>0</td>
  <td>0</td>
  <td>0</td>
  <td></td>
 </tr>
 <tr>
  <td>0</td>
  <td>1</td>
  <td>0</td>
  <td>Shareable</td>
 </tr>
 <tr>
  <td>1</td>
  <td>1</td>
  <td>0 - </td>
  <td>Inner Shareable</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Outer Shareable</td>
 </tr>
 <tr>
  <td>0</td>
  <td>0</td>
  <td>1</td>
  <td>maintenance</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>0</td>
  <td>1</td>
  <td>1 - </td>
  <td>Outer Shareable</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Cache maintenance</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>operations</td>
 </tr>
 <tr>
  <td>1</td>
  <td>1</td>
  <td>1 - </td>
  <td>Inner Shareable</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Outer Shareable</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Cache maintenance</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>operations</td>
 </tr>
</table>

## Chapter D13

### Distributed Virtual Memory Transactions

This chapter describes Distributed Virtual Memory (DVM) messages and the transactions that are used to pass them
between components of a virtual memory system. It contains the following sections:

- About DVM transactions on page D13-318
- DVM transactions on page D13-319
- DVM messages on page D13-323
- DVM Complete on page D13-336

### D13.1 About DVM transactions

DVM transactions are used to pass messages that support the maintenance of a virtual memory system.
There are two types of DVM transactions: DVM message and DVM Complete.
A DVM message supports the following operations:

- TLB Invalidate

- Branch Predictor Invalidate

- Physical Instruction Cache Invalidate

- Virtual Instruction Cache Invalidate

- Synchronization

- Hint

A DVM Complete transaction is issued in response to a DVM Synchronization message to indicate that all required
operations and any associated transactions have completed.

DVM transactions are optionally supported on ACE, ACE5, and ACE5-LiteDVM interfaces, which can be designed
to operate in one of the following ways:

- Initiate and receive DVM messages

- Only receive DVM messages

The DVM_Message_Support property is used to describe the types of messages that are supported by an interface.
It can take one of the following values:

Bidirectional DVM transactions are supported in both directions on the interface. This requires the use of the
AR/R and AC/CR channels.

### Receiver

DVM message and Synchronization transactions are supported from Subordinate to Manager
interfaces on the AC/CR channels.

DVM Complete transactions are supported from Manager to Subordinate interfaces on the AR/R
channels.

DVM transactions are not supported.

### False

For ACE, ACE5, and ACE5-LiteDVM interfaces, if DVM_Message_Support is not declared, it is considered to be
Bidirectional.

DVM_Message_Support must be False or not declared for other interface types.

Interfaces with an address width smaller than 32 bits cannot support DVM messages, the DVM_Message_Support
property must be False.

Table D13-1 describes the capability of Manager and Subordinate interfaces with each value of
DVM_Message_Support.

Table D13-1 Capability of Manager and Subordinate interfaces

|  | Manager | Subordinate |
| --- | --- | --- |
| Bidirectional | - Initiate DVM requests on AR - Receive DVM Complete requests on AC - Receive DVM requests on AC - Issue DVM Complete requests on AR | - Receive DVM requests on AR - Issue DVM Complete requests on AC - Issue DVM requests on AC - Receive DVM Complete requests on AR |
| Receiver | - Receive DVM requests on AC - Issue DVM Complete requests on AR | - Issue DVM requests on AC - Receive DVM Complete requests on AR |
| False | No DVM requests can be issued or received. | No DVM requests can be issued or received. |

### D13.2 DVM transactions

A DVM transaction can be either a DVM message or DVM Complete.

### D13.2.1 DVM message transactions

A DVM message can be sent in one or two transactions. Messages that include an address are sent using two
transactions.

A one-part DVM message has one request transfer and one response transfer. The message is sent by the initiator
Manager on the AR channel and is propagated to participating Managers on the AC channel. Managers can use the
Coherency Connection signaling to opt into receiving messages at runtime, see Coherency Connection signaling on
page E1-364.

The flow of a DVM message is:

1. The originating Manager component issues the DVM message request on its read address channel.

2. The interconnect component distributes the request to participating components using the appropriate snoop address channel.

3. The request is not sent to the same component that issued the transaction.

4. Each participating component acknowledges receipt of the message using the snoop response channel. For ACE5-LiteDVM interfaces, this response must not be dependent on the forward progress of any transactions on the AR or AW channels.

5. The interconnect component collects the acknowledgements and responds to the original DVM request using the read data channel of the originating Manager component.

Figure D13-1 shows the flow when a Manager issues a DVM message to two other Managers.

<table>
 <tr>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
 </tr>
</table>

<table>
 <tr>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

AC

DVM message

CR

response

### Figure D13-1 One-part DVM message flow

A two-part DVM message has two request transfers and two response transfers. Each transaction of a two-part DVM
message has a response, both on the snoop response and read data channels. Figure D13-2 shows a two-part DVM
message flow.

<table>
 <tr>
  <th colspan="2">Initiating</th>
  <td colspan="3">Receiving</td>
 </tr>
 <tr>
  <th>Manager</th>
  <td></td>
  <td>Interconnect</td>
  <td></td>
  <td>Manager</td>
 </tr>
 <tr>
  <th>AR</th>
  <td></td>
  <td></td>
  <td></td>
  <td>AC</td>
 </tr>
 <tr>
  <th></th>
  <td>msg pt2</td>
  <td>msg pt1 msg pt2</td>
  <td>msg pt1</td>
  <td></td>
 </tr>
 <tr>
  <th>R</th>
  <td></td>
  <td></td>
  <td></td>
  <td>CR</td>
 </tr>
 <tr>
  <th></th>
  <td>resp pt1</td>
  <td>resp pt2 resp pt1</td>
  <td>resp pt2</td>
  <td></td>
 </tr>
</table>

The following rules apply to two-part DVM messages:

### Figure D13-2 Two part DVM message flow

- The requests are always sent as successive transfers, with no other transaction requests between them.

- Each transaction of a two-part DVM message must use the same AXI ID.

A Manager issuing a two-part DVM message must be able to issue the latter parts of the message without
requiring any other external actions.

An interconnect component issuing a two-part DVM message on the snoop address channel must be able to
issue the second part of the message without requiring a response to the first part of the message.

### D13.2.2 DVM Synchronization and DVM Complete transactions

A DVM Synchronization message (Sync) has a response but also causes a DVM Complete transaction that indicates
that the synchronization process is complete. The process is:

1. The initiating Manager issues the DVM Sync on its read address channel.

2. The interconnect component distributes the DVM Sync to participating Managers using the appropriate snoop address channel. The transaction is not sent to the initiating Manager.

3. Each participating Manager acknowledges receipt of the DVM Sync using the snoop response channel. For ACE5-LiteDVM interfaces, this response must not be dependent on the forward progress of any transactions on the AR or AW channels.

4. The interconnect component collects the acknowledgements and responds to the original DVM Sync using the read data channel of the initiating Manager component.

5. Each receiving Manager must issue a DVM Complete when it has completed all the necessary actions, see DVM Complete on page D13-336. The DVM Complete is issued on the read address channel after the handshake of the associated DVM Sync on the snoop address channel of the same Manager.

6. The interconnect component can respond immediately to the DVM Complete transaction using the read data channel of the component that issued the DVM Complete.

7. When the interconnect component has received a DVM Complete from each participating component, it issues a DVM Complete using the snoop address channel of the initiating Manager.

8. The initiating Manager acknowledges the receipt of the DVM Complete using the snoop response channel.

Figure D13-3 shows the synchronization flow between an initiating Manager and one receiving Manager.

Interconnect

Receiving
Manager

Figure D13-3 Synchronization flow between initiating Manager and receiving Manager

### D13.2.3 DVM request attributes

Table D13-2 shows the constraints on AR and AC signals for DVM requests. If a signal is not listed, it is
unconstrained.

Table D13-2 DVM transaction constraints

Attribute Constraint

| ARADDR | Must be zero for DVM Complete. |
| --- | --- |
| ARSNOOP | Must be either: |
|  | - 0b1111 for a DVM Message |
|  | - 0b1110 for a DVM Complete |

### ARBURST

ARLEN

### ARSIZE

### ARCACHE

### ARCHUNKEN

ARMMUATST

ARMMUFLOW

ARTAGOP

ARLOCK

ARDOMAIN

Burst type must be INCR.

The burst length must be 1, which means ARLEN[7:0] must be 0x00. See Address
structure on page A3-48 for more information.

The number of bytes in a transfer must be equal to the data bus width. See Burst size on
page A3-49.

Must be Modifiable and Non-cacheable, which means ARCACHE[3:0] must be 0b0010.
See Table A4-4 on page A4-68 for more information.

Must be zero

Must be zero

Must be 0b00

Must be 0b00

Must be a normal access, which means ARLOCK must be zero.

The domain must be Inner Shareable or Outer Shareable.

### Table D13-2 DVM transaction constraints (continued)

### Attribute Constraint

### ARBAR

| ACADDR | Must be zero for DVM Complete. |
| --- | --- |
| ACSNOOP | Must be either: |
|  | - 0b1111 for a DVM Message |
|  | - 0b1110 for a DVM Complete |

Must be a normal access, which means AxBAR[0] must be zero.

### ACPROT

Not used for DVM messages, can take any value.

### D13.2.4 DVM ID values

All the following rules apply to ARID/RID values for DVM transactions:

DVM messages and non-DVM transactions on the read channels can use the same AXI ID value, if one
transaction has fully completed before the other is issued.

DVM messages are permitted to use the same AXI ID value as a transaction issued on the AW channel.

Different DVM transactions can use either the same AXI ID, or different AXI IDs.

If different AXI IDs are used for DVM requests, then the order of arrival of the different messages at the
recipient of the message is not guaranteed.

All DVM operations must be correctly ordered with respect to a DVM Sync from the same issuing Manager
component, even if different AXI IDs are used.

Each transaction of a two-part DVM message must use the same AXI ID.

### D13.2.5 DVM responses

When a component receives a DVM request, it must respond as follows:

- If the component can perform the requested action, then it must respond by setting CRRESP to 0b00000.

If the component is unable to perform the requested action, then it must respond by setting CRRESP to
0b00010. Typically, this response indicates an unsupported message.

- A component is not permitted to set CRRESP to 0b00010 in response to a DVM Sync or a DVM Complete.

- The interconnect component gathers all response values and responds to the originator as follows:

- If CRRESP is 0b00000 for all responses, then the interconnect component sets RRESP to 0b0000.

If CRRESP is 0b00010 for any responses:
- The interconnect component sets RRESP to 0b0010. This response can be sent before all CR responses
have been received.

This specification recommends that the interconnect component provides a fault log to record which
components are unable to perform requested actions.

-

Other rules for DVM responses:

- No data transfer is associated with DVM transactions.

- For two-part DVM messages, the response to each transaction must be the same.

The response to a DVM request must not be dependent on the forward progress of any transactions on the
AR or AW channels.

### D13.3 DVM messages

The following DVM messages are supported by the protocol:

- TLB Invalidate

- Branch Predictor Invalidate

- Physical Instruction Cache Invalidate

- Virtual Instruction Cache Invalidate

- Synchronization

- Hint

DVM messages are signaled using ARSNOOP or ACSNOOP set to 0b1111.

DVM messages can require multiple transactions to convey the required information. In this case, the first
transaction provides sufficient information to determine whether another transaction is required.

DVM transactions only operate on read-only structures, such as Instruction cache, Branch Predictor, and TLB, and
therefore only invalidation operations are required. The concept of cleaning does not apply to a read-only structure.
This means that it is functionally correct to invalidate more entries than the DVM message requires, although the
extra invalidations can affect performance.

### D13.3.1 DVM message versions

DVM messages were introduced in the Armv7 architecture and were extended in Armv8, Armv8.1 and Armv8.4
architectures. It is essential that interfaces initiating and receiving DVM messages support the same architecture
versions.

The following properties define the version that is supported by an interface:

- DVM_v8

- DVM_v8.1

- DVM_v8.4 (ACE5-LiteDVM interfaces only)

Each property can take the values: True or False. If a property is not declared, then it is considered False.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>The only ACE interface that supports DVM_v8.4 is ACE5-LiteDVM</td>
 </tr>
</table>

Table D13-3 shows which message versions are supported, depending on the property values. A component that
supports DVM messages from a specific version must also support earlier architecture versions.

### Table D13-3 DVM message versions

| DVM property | Architecture support |
| --- | --- |
| DVM_v8.4 DVM_v8.1 DVM_v8 | Armv8.4 Armv8.1 Armv8 Armv7 |
| True Tuer o F alse Trueo | Y Y Y |
| False True True or False | - Y Y Y |
| False False True | - - Y Y |
| False False False | - - - Y |

In a system with heterogeneous components, it is the responsibility of the system configuration to determine the
lowest common DVM specification that is supported in the system. The interconnect must have the knowledge of
this lowest common denominator value by means of configuration, straps, parameterization, or some other
IMPLEMENTATION DEFINED method.

To avoid deadlocks or denial of service the interconnect must detect unsupported DVM operations and suppress
their propagation and respond in a protocol compliant manner. Error indication in such a response is optional.

### D13.3.2 Addresses in DVM messages

DVM messages that require an address are transported using two transactions.

Table D13-4 shows the physical and virtual address space sizes that are supported.

Table D13-4 Supported physical and virtual address spaces

| DVM version | Physical | space Virtual address space |
| --- | --- | --- |
| All versions | 32-bit | 32-bit |
|  | 40-bit | 32-bit |
| v8 and above | 40-bit | 41-bit |
|  | 44-bit | 49-bit |
|  | 48-bit | 57-bit |

If the physical address space exceeds the virtual address space, then virtual address operations might receive
additional address information in a DVM message. In this case, any additional address information must be ignored
and operations that are performed using only the supported address bits.

If a component supports a larger virtual address space than its physical address space, then a minimum
ADDR_WIDTH is required to support the virtual address space size. The component must take appropriate action
regarding the additional physical address bits. See Address space size on page D6-263 for more details.

Table D13-5 and Table D13-6 on page D13-325 show the allocation of address fields for the first and second parts
of an invalidation by VA or IPA. The encodings are dependent on the physical and virtual address sizes. The address
fields apply to the ARADDR and ACADDR signals.

Table D13-5 Address fields for the first of a two-part invalidation by VA or IPA

<table>
 <tr>
  <th>Address size<br/>Physical Virtual</th>
  <th>DVM version</th>
  <th>First transaction address field mapping<br/>[47:44] [43:40] [39:32] [31:24] [23:16]</th>
 </tr>
 <tr>
  <td>32-bit 32-bit</td>
  <td>All versions</td>
  <td>- - - VMID[7:0] ASID[7:0]</td>
 </tr>
 <tr>
  <td rowspan="2">40-bit 32-bit<br/>41-bit</td>
  <td>All versions</td>
  <td>- - SBZ VMID[7:0] ASID[7:0]</td>
 </tr>
 <tr>
  <td>v8 and above</td>
  <td>- - ASID[15:8] VMID[7:0] ASID[7:0]</td>
 </tr>
 <tr>
  <td>44-bit 49-bit</td>
  <td>v8 and above</td>
  <td>- VA[48:45] ASID[15:8] VMID[7:0] ASID[7:0]</td>
 </tr>
 <tr>
  <td>48-bit 57-bit</td>
  <td>v8 and above</td>
  <td>VA[56:53] VA[48:45] ASID[15:8] VMID[7:0] ASID[7:0]</td>
 </tr>
</table>

Table D13-6 Address fields for the second of a two-part invalidation by VA or IPA

| Address size DVM version Physical Virtual |  | address field mapping [39:32] [31:12] [11:4] [3] |
| --- | --- | --- |
| 32-bit 32-bit All versions - | - | - VA[31:12] VA[11:4] SBZ |
| 40-bit 32-bit All versions - | - | SBZ VA[31:12] VA[11:4] SBZ |
| 41-bit v8 and above - | - | VA[39:32] VA[31:12] VA[11:4] VA[40] |
| 44-bit 49-bit v8 and above - |  | VA[39:32] VA[31:12] VA[11:4] VA[40] |
| 48-bit 57-bit v8 and above |  | VA[39:32] VA[31:12] VA[11:4] VA[40] |

### Note

The bit positions for some higher-order address bits are both shifted by a single bit and also split between the first
and second parts of a two-part DVM transaction. This bit position allocation might appear irregular, but is used to
ease the translation between implementations with different physical address sizes.

For a message operating on a physical address, the first part contains the Virtual Address for Virtually Indexed
Physically Tagged (VIPT) caches. Table D13-7 shows the first transaction, which contains the Virtual Address for
VIPT caches.

Table D13-7 First transaction address mapping for any DVM operation, operating on a physical address

<table>
 <tr>
  <th>Physical</th>
  <td>size DVM version First transaction address field mapping<br/>[47:44] [43:40] [39:32] [31:24] [23:16]</td>
 </tr>
 <tr>
  <th>32-bit</th>
  <td>All versions - - - VA[27:20] VA[19:12]</td>
 </tr>
 <tr>
  <th>40-bit</th>
  <td>All versions - - SBZ VA[27:20] VA[19:12]</td>
 </tr>
 <tr>
  <th>44-bit</th>
  <td>v8 and above - SBZ SBZ VA[27:20] VA[19:12]</td>
 </tr>
 <tr>
  <th>48-bit</th>
  <td>v8 and above SBZ SBZ SBZ VA[27:20] VA[19:12]</td>
 </tr>
 <tr>
  <th>Table D13-8<br/>D13-8 Second</th>
  <td>the second transaction, which contains the physical address.<br/>address mapping for any DVM operation, operating on a physical address</td>
 </tr>
 <tr>
  <th>Physical</th>
  <td>size DVM version Second transaction address field mapping<br/>[47:44] [43:40] [39:32] [31:12] [11:4]</td>
 </tr>
 <tr>
  <th>32-bit</th>
  <td>All versions - - - PA[31:12] PA[11:4]</td>
 </tr>
 <tr>
  <th>40-bit</th>
  <td>All versions - - PA[39:32] PA[31:12] PA[11:4]</td>
 </tr>
 <tr>
  <th>44-bit</th>
  <td>v8 and above - PA[43:40] PA[39:32] PA[31:12] PA[11:4]</td>
 </tr>
 <tr>
  <th>48-bit</th>
  <td>v8 and above PA[47:44] PA[43:40] PA[39:32] PA[31:12] PA[11:4]</td>
 </tr>
</table>

Table
transaction

### D13.3.3 Support for 16-bit ASID

DVM_v8 and above support both 8-bit and 16-bit ASID. It cannot be determined from a DVM message whether
the message uses an 8-bit or 16-bit VMID. All 8-bit ASID messages are required to set the ASID[15:8] field to zero.

It is expected that most systems will use a single ASID size across the entire system, either 8-bit ASID or 16-bit
ASID.

In a system that contains a mix of 8-bit ASID and 16-bit ASID components, it is expected that all maintenance is
done by an agent that uses 16-bit ASID. This ensures that the agent can perform maintenance on both the 8-bit ASID
and 16-bit ASID components.

The interoperability requirements are:

For an 8-bit ASID agent sending a message to a 16-bit ASID agent, a message appears as a 16-bit ASID with
the upper 8 bits set to zero.

For a 16-bit ASID agent sending a message to an 8-bit VMID agent:
- If the upper 8 bits are zero, the message was received correctly.
- If the upper 8 bits are nonzero, then over-invalidation will occur, since the 8-bit ASID agent ignores
the upper 8 bits.

### D13.3.4 Support for 16-bit VMID

DVM_v8.1 and above support both 8-bit and 16-bit VMIDs. It cannot be determined from a DVM message whether
the message uses an 8-bit or 16-bit VMID. All 8-bit VMID messages are required to set the VMID[15:8] field to
zero.

It is expected that most systems use a single VMID size across the entire system, either 8-bit VMID or 16-bit VMID.

In a system that contains a mix of 8-bit VMID and 16-bit VMID components, it is expected that all maintenance is
done by an agent that uses 16-bit VMID. This ensures that the agent can perform maintenance on both the 8-bit
VMID and 16-bit VMID components.

The interoperability requirements are:

For an 8-bit VMID agent sending a message to a 16-bit VMID agent, a message appears as a 16-bit VMID
with the upper 8 bits set to zero.

For a 16-bit VMID agent sending a message to an 8-bit VMID agent:
- If the upper 8 bits are zero, the message was received correctly.
- If the upper 8 bits are nonzero, then over-invalidation will occur, since the 8-bit VMID agent ignores
the upper 8 bits.

| Signal | Source Width Description | Signal presence property condition |
| --- | --- | --- |
|  | Manager 4 Extension for 16-bit on read address channel. | DVM_v8.1 and DVM_Message_Support is Bidirectional |
|  | Manager 4 Extension for 16-bit on snoop address channel. | DVM_v8.1 and DVM_Message_Support is not False |
|  | using a 16-bit VMID, for a one-part message: VMID[11:8] is transported using AxVMIDEXT[3:0] |  |
|  | VMID[15:12] is transported using AxADDR[43:40] |  |

- The following signals are defined for transporting the additional VMID bits:

Table D13-9 Signals for transporting the additional VMID bits

When using a 16-bit VMID, for a two-part message::

- VMID[11:8] is transported using AxVMIDEXT[3:0] in the first part

- VMID[15:12] is transported using AxVMIDEXT[3:0] in the second part

### D13.3.5 DVM message encoding, first part

DVM message information is transported using ARADDR/ARVMIDEXT and ACADDR/ACVMIDEXT.

Table D13-10 shows how information is encoded for a one-part message or the first of a two-part message.

Table D13-10 Encoding for a one-part message or the first of a two-part message

<table>
 <tr>
  <th></th>
  <th></th>
  <th></th>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>[47:44]</td>
  <td>Virtual Address</td>
  <td>VA[56:53]a</td>
 </tr>
 <tr>
  <td>[43:40]</td>
  <td>Virtual Address</td>
  <td>VA[48:45]a or VMID[15:12]b</td>
 </tr>
 <tr>
  <td></td>
  <td>or VMID</td>
  <td></td>
 </tr>
 <tr>
  <td>[39:32]</td>
  <td>ASID upper byte</td>
  <td>ASID[15:8]a</td>
 </tr>
 <tr>
  <td>[31:24]</td>
  <td>VMID or Virtual</td>
  <td>VMID[7:0] or VA[27:20]</td>
 </tr>
 <tr>
  <td></td>
  <td>Index</td>
  <td></td>
 </tr>
 <tr>
  <td>[23:16]</td>
  <td>ASID or Virtual</td>
  <td>ASID[7:0] or VA[19:12]</td>
 </tr>
 <tr>
  <td></td>
  <td>Index</td>
  <td></td>
 </tr>
 <tr>
  <td>[15]</td>
  <td>Completion</td>
  <td>0b0 DVM Complete transaction is not required</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>0b1 DVM Complete transaction is required</td>
 </tr>
</table>

| [14:12] | Message type | 0b000 | TLB Invalidate |
| --- | --- | --- | --- |
|  |  | 0b001 | Branch Predictor Invalidate |
|  |  | 0b010 | Physical Instruction Cache Invalidate |
|  |  | 0b011 | Virtual Instruction Cache Invalidate |
|  |  | 0b100 | Synchronization |
|  |  | 0b101 | Reserved |
|  |  | 0b110 | Hint |
|  |  | 0b111 | Reserved |

| [11:10] Exception Level 0b00 | Applies to Hypervisor and all Guest OS |
| --- | --- |
| 0b01 | Applies to EL3a |
| 0b10 | Applies to Guest OS |
| 0b11 | Applies to Hypervisor |
| [9:8] Security 0b00 | Applies to Secure and Non-secure |
| 0b01 | Applies to a Non-secure address from a Secure contextc |
| 0b10 | Applies to Secure only |
| 0b11 | Applies to Non-secure only |
| [7] SBZ or Rangec 0b0 | Message does not include address range information |
| 0b1 | Message includes address range information |

1. [6] VMID or VA 0b0 AxADDR[31:24] and AxVMIDEXT[3:0] must be zero, Vali d except for Hint operations. AxADDR[31:24] and AxVMIDEXT[3:0] contains VMID or VA information.

0b1

Table D13-10 Encoding for a one-part message or the first of a two-part message (continued)

AxADDR
bits

<table>
 <tr>
  <th>Name</th>
  <th>Function</th>
  <th></th>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>[5] ASID or VA</td>
  <td>0b0</td>
  <td>AxADDR[23:16] must be zero, except for Hint</td>
 </tr>
 <tr>
  <td>Valid</td>
  <td></td>
  <td>operations.</td>
 </tr>
 <tr>
  <td></td>
  <td>0b1</td>
  <td>Message includes ASID or VA information in</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>AxADDR[23:16].</td>
 </tr>
 <tr>
  <td>[4] Leaf</td>
  <td>0b0</td>
  <td>Invalidate all associated translations.</td>
 </tr>
 <tr>
  <td></td>
  <td>0b1</td>
  <td>Invalidate Leaf Entry only, that is the entry that is returned</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>from the last level of the translation table walk.a</td>
 </tr>
 <tr>
  <td>[3:2] Stage</td>
  <td>0b00</td>
  <td>DVM_v7: Stage of invalidation varies with invalidation</td>
 </tr>
</table>

| [3:2] Stage | 0b00 | DVM_v7: Stage of invalidation varies with invalidation |
| --- | --- | --- |
|  |  | type. |
|  |  | DVM_v8 and above: Stage 1 and Stage 2 invalidation |
|  | 0b01 | Stage 1 only invalidationa |
|  | 0b10 | Stage 2 only invalidationa |
|  | 0b11 | Reserved |

| [1] | - |  | SBZ |
| --- | --- | --- | --- |
| [0] | Addr | 0b0 | The message does not require an address and has one part |
|  |  | 0b1 | The message includes an address and has two parts |

1. DVM_v8 and above

2. DVM_v8.1 and above

3. DVM_v8.4 and above

Address bits that are not used for a particular message must be driven to zero.

### D13.3.6 DVM message encoding, second part

Table D13-11 shows how information is encoded for the second part of a two-part message.

Table D13-11 Information encoding for the second part of a two-part message

| AxADDR | Description |
| --- | --- |
| [47:44] | VA[52:49] or PA[47:44] |
| [43:40] | VA[44:41] or PA[43:40] |
| [39:12] | VA[39:12] or PA[39:12] |
| [11:10] | VA[11:10] or PA[11:10] or TGa |
| [9:8] | VA[9:8] or PA[9:8] or TTLa |
| [7:6] | VA[7:6] or PA[7:6] or SCALEa |
| [5:4] | VA[5:4] or PA[5:4] or NUM[4:3]a |
| [3] | VA[40] |
| [2:0] | NUM[2:0]a |

a. DVM_v8.4 and above

Address bits that are not used for a particular message must be driven to zero.

### D13.3.7 TLB Invalidate operations in DVM v8.4

When the DVM_v8.4 property is True, the first and second part of a TLB Invalidate by IPA or VA contains
additional information.

Table D13-12 shows DVM v8.4 additional information in the first part of a TLB Invalidate by IPA or VA.

Table D13-12 First part of a TLB Invalidate by IPA or VA

| AxADDR bits | Name |  |  |
| --- | --- | --- | --- |
| [7] | Range | 0b0 | Message does not include address range information |
|  |  | 0b1 | Message includes address range information. |
| Table D13-13 | DVM v8.4 | Table | in the second part of a TLB Invalidate by IPA or VA. Second part of a TLB Invalidate by IPA or |
| AxADDR bits | Name |  |  |

| AxADDR bits | Name | Encoding |  |
| --- | --- | --- | --- |
| [11:10] | Transaction granule, | 0b00 | No granule information |
|  | TG | 0b01 | Transaction_Granule_Size is 4KB |
|  |  | 0b10 | Transaction_Granule_Size is 16KB |
|  |  | 0b11 | Transaction_Granule_Size is 64KB |

| [9:8] | Transaction table 0b00 | No level hint information |
| --- | --- | --- |
|  | level, TTL 0b01 | The leaf entry is on level 1 of the page table walk |
|  | 0b10 | The leaf entry is on level 2 of the page table walk |
|  | 0b11 | The leaf entry is on level 3 of the page table walk |

| [7:6] | SCALE | A constant used in the address range exponent calculation. |
| --- | --- | --- |
| [5:4] | NUM[4:3] | A constant used as a multiplication factor in the range calculation |
| [2:0] | NUM[2:0] | A constant used as a multiplication factor in the range calculation |

If the DVM_v8.4 property is True and the message type is not TLB Invalidate by IPA or VA, the TG, TTL, SCALE
and NUM bits must be zero.

The Range bit must be zero if either:

- DVM_v8.4 is not supported.

- The message type is not TLB Invalidate by IPA

- r VA.

The SCALE and NUM bits must be zero if the Range bit is deasserted.

When the Range bit is asserted, the range of addresses that are invalidated is determined by the following formula:

BaseADDR <= VA < BaseADDR + ( (NUM+1)*2(5*SCALE+1) * Translation_Granule_Size)

Where:

- BaseADDR: base address of the range, shifted based on the Transaction Granule (TG): 4K BaseADDR is VA[48:12] 16K BaseADDR is VA[50:14] 64K BaseADDR is VA[52:16]

- SCALE is a constant, it can take any value from 0-3.

- NUM is a constant, it can take any value from 0-31.

### D13.3.8 TLB Invalidate

This section lists the TLB Invalidate (TLBI) operations that the DVM message supports.

Table D13-14 shows the fixed values for the TLBI message fields.

Table D13-14 Fixed values for the TLBI fields

| AxADDR | Name | Value | Status |
| --- | --- | --- | --- |
| [15] |  | 0b0 | Completion not required |
| [14:12] | Message | 0b000 | TLB Invalidate opcode |
| [1] | - | 0b0 | Reserved |
| Table D13-15 shows the TLBI |  |  |  |
|  |  |  | Table D13-15 TLBI |

### Operation

<table>
 <tr>
  <th>EL3 TLBI alla</th>
  <td>0b01</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>EL3 TLBI by VAa</th>
  <td>0b01</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>EL3 TLBI by VA, Leaf onlya</th>
  <td>0b01</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by Non-secure IPAb</th>
  <td>0b10</td>
  <td>0b01</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by Non-secure IPA, Leaf onlyb</th>
  <td>0b10</td>
  <td>0b01</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure TLBI all</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Secure TLBI by VA</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure TLBI by VA, Leaf onlya</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure TLBI by ASID</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Secure TLBI by ASID and VA</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure TLBI by ASID and VA, Leaf onlya</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI allb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by VAb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI all, Stage 1 onlyb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b01</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by Secure IPAb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by VA, Leaf onlyb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by Secure IPA, Leaf onlyb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by ASIDb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by ASID and VAb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <th>Secure Guest OS TLBI by ASID and VA, Leaf onlyb</th>
  <td>0b10</td>
  <td>0b10</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
</table>

AxADDR bit

[11:10] [9:8] [6]

H'visor Secure VMID

[5]

### ASID

[4] [3:2] [0]

Leaf Stage Addr

D13-330 Copyright © 2003-2021 Arm Limited or its affiliates. All rights reserved. ARM IHI 0022H.c
Non-Confidential ID012621

#### Operation

<table>
 <tr>
  <th>All OS TLBI all</th>
  <th>0b10</th>
  <th>0b11</th>
  <th>0b0</th>
  <th>0b0</th>
  <th>0b0</th>
  <th>0b00</th>
  <th>0b0</th>
 </tr>
 <tr>
  <td>Guest OS TLBI all, Stage 1 and 2</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by VA</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Guest OS TLBI all, Stage 1 onlya</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b01</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by IPAa</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by VA, Leaf onlya</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by IPA, Leaf onlya</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b10</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by ASID</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by ASID and VA</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Guest OS TLBI by ASID and VA, Leaf onlya</td>
  <td>0b10</td>
  <td>0b11</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI allb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI by VAb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI by VA, Leaf onlyb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI by ASIDb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI by ASID and VAb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Secure Hypervisor TLBI by ASID and VA, Leaf onlyb</td>
  <td>0b11</td>
  <td>0b10</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI all</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI by VA</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI by VA, Leaf onlya</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI by ASIDc</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b0</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI by ASID and VAc</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b0</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
 <tr>
  <td>Hypervisor TLBI by ASID and VA, Leaf onlyc</td>
  <td>0b11</td>
  <td>0b11</td>
  <td>0b0</td>
  <td>0b1</td>
  <td>0b1</td>
  <td>0b00</td>
  <td>0b1</td>
 </tr>
</table>

1. DVM_v8 and above

2. DVM_v8.4 and above

3. DVM_v8.1 and above

Table D13-15 TLBI messages (continued)

AxADDR bit

[11:10] [9:8] [6]

H'visor Secure VMID

### [5] ASID

[4]

### Leaf

[3:2]

Stage

[0]
Addr

### D13.3.9 Branch Predictor Invalidate

This section lists the Branch Predictor Invalidate operations that the DVM message supports.

Table D13-16 shows the fixed values for the Branch Predictor Invalidate message fields.

Table D13-16 Fixed values for the Branch Predictor Invalidate message fields

| AxADDR | Value | Status |
| --- | --- | --- |
| [15] | 0b0 | Completion not required |
| [14:12] | 0b001 | Branch Predictor Invalidate opcode |
| [11:10] | 0b00 | Applies to all Guest OS and Hypervisor |
| [7] | 0b0 | No address range information |
| [6] | 0b0 | VMID field not valid |
| [5] | 0b0 | ASID field not valid |
| [4:1] | 0b0000 | Reserved |

Table D13-17 shows the Branch Predictor Invalidate messages.

Table D13-17 Branch Predictor Invalidate messages

<table>
 <tr>
  <th>Operation</th>
  <td>AxADDR [0]</td>
 </tr>
 <tr>
  <th>Branch Predictor Invalidate all</th>
  <td>0b0</td>
 </tr>
 <tr>
  <th>Branch Predictor Invalidate by VA</th>
  <td>0b1</td>
 </tr>
</table>

### D13.3.10 Instruction cache invalidations

Instruction caches can use either a physical address or a virtual address to tag the data they contain. A system might
contain a mixture of both forms of cache.

The DVM protocol includes instruction cache invalidation operations that use physical addresses and operations
that use virtual addresses. A component that receives DVM messages must support both forms of message,
independent of the style of instruction cache implemented. It might be necessary to over-invalidate in the case where
a message is received in a format that is not native to the cache type.

### Physical Instruction Cache Invalidate

This section lists the Physical Instruction Cache Invalidate (PICI) operations that the DVM message supports. This
message type is also used for Instruction Caches which are Virtually Indexed Physically Tagged (VIPT).

Table D13-18 shows the fixed values for the PICI message fields.

Table D13-18 Fixed values for the PICI message fields

| AxADDR | Value | Description |
| --- | --- | --- |
| [15] | 0b0 | Completion not required |

[14:12] 0b010 Physical Instruction Cache Invalidate opcode

Table D13-18 Fixed values for the PICI message fields (continued)

| AxADDR | Value | Description |
| --- | --- | --- |
| [11:10] | 0b00 | Applies to all Guest OS and Hypervisor |
| [7] | 0b0 | No address range information |
| [4:1] | 0b0000 | Reserved |
| D13-19 | the PICI | Table D13-19 PICI messages |

Table
shows
messages.

| Operation |  | AxADDR bit |  |
| --- | --- | --- | --- |
|  | [9:8] | [6:5] | [0] |
|  | Secure | Virtual Index | Addr |

| PICI all, Secure only | 0b10 | 0b00 | 0b0 |
| --- | --- | --- | --- |
| PICI by PA without Virtual Index, Secure only | 0b10 | 0b00 | 0b1 |
| PICI by PA with Virtual Index, Secure only | 0b10 | 0b11 | 0b1 |
| PICI all, Non-secure only | 0b11 | 0b00 | 0b0 |
| PICI by PA without Virtual Index, Non-secure | 0b11 | 0b00 | 0b1 |
| PICI by PA with Virtual Index, Non-secure only | 0b11 | 0b11 | 0b1 |

When Virtual Index is 0b11, then Virtual Index VA[27:12] at AxADDR[29:14] is used as part of the Physical
Address.

### Virtual Instruction Cache Invalidate

This section lists the Virtual Instruction Cache Invalidate (VICI) operations that the DVM message supports.

Table D13-20 shows the fixed values for the VICI message fields.

### Table D13-20 Fixed values for VICI message fields

| AxADDR bits | Value | Description |
| --- | --- | --- |
| [15] | 0b0 | Completion not required |
| [14:12] | 0b011 | Virtual Instruction Cache Invalidate opcode |
| [7] | 0b0 | No address range information |
| [4:1] | 0b0000 | Reserved |

Table D13-21 shows the VICI messages.

### Operation

| Hypervisor and all Guest OS VICI all, Secure and | 0b00 | 0b00 | 0b0 | 0b0 |
| --- | --- | --- | --- | --- |
| Hypervisor and all Guest OS VICI all, Non-secure only | 0b00 | 0b11 | 0b0 | 0b0 |
| All Guest OS VICI by ASID and VA, Secure only | 0b10 | 0b10 | 0b0 | 0b1 |
| All Guest OS VICI by VMID, Secure onlya | 0b10 | 0b10 | 0b1 | 0b0 |
| All Guest OS VICI by ASID, VA and VMID, Secure | 0b10 | 0b10 | 0b1 | 0b1 |
| All Guest OS VICI by VMID, Non-secure only | 0b10 | 0b11 | 0b1 | 0b0 |
| All Guest OS VICI by ASID, VA and VMID, Non-secure | 0b10 | 0b11 | 0b1 | 0b1 |
| Hypervisor VICI by VA, Non-secure only | 0b11 | 0b11 | 0b0 | 0b0 |
| Hypervisor VICI by ASID and VA, Non-secure onlyb | 0b11 | 0b11 | 0b0 | 0b1 |

1. DVM_v8.4 and above

2. DVM_v8.1 and above

Table D13-21 VICI messages

AxADDR bit

[11:10] [9:8] [6] [5] [0]

Level Secure VMID ASID Addr

### D13.3.11 Synchronization

This section lists the Synchronization operation that the DVM message supports.

Table D13-22 shows the values for the Synchronization message fields.

### Table D13-22 Values for Synchronization message fields

| AxADDR | Value | Status |
| --- | --- | --- |
| [15] | 0b1 | Completion required |
| [14:12] | 0b100 | Synchronization opcode |
| [11:10] | 0b00 | Applies to all Guest OS and Hypervisor |
| [9:8] | 0b00 | Applies to Secure and Non-secure |
| [7] | 0b0 | No address range information |
| [6] | 0b0 | VMID field not valid |
| [5] | 0b0 | ASID field not valid |
| [4:1] | 0b0000 | Reserved |
| [0] | 0b0 | No address specified in this message |

### D13.3.12 Hint

A reserved message address space is provided for future Hint messages.

Table D13-23 shows the fixed values for the Hint message fields.

### Table D13-23 Hint message fields

| AxADDR | Value | Status |
| --- | --- | --- |
| [15] | 0b0 | Completion not required |
| [14:12] | 0b110 | Hint opcode |

Hint messages must have a response with CRRESP set to 0b00000.

### D13.4 DVM Complete

A DVM Complete transaction is sent when a component has received a DVM Sync message and all preceding
invalidation operations are complete. The following rules apply in determining when an operation is complete:

### TLB Invalidate

Complete when a Manager can no longer use an invalidated translation and all previous transactions
that could have used an invalidated translation are complete.

### Branch Predictor Invalidate

Complete when cached copies of predicted instruction fetches have been invalidated and can no
longer be accessed by the associated Manager. The invalidated cached copies might be from any
virtual address or from a specified virtual address.

### Instruction Cache Invalidate

Complete when cached instructions have been invalidated and can no longer be accessed by the
associated Manager.

A component must have only one outstanding DVM Sync transaction. A component must receive a DVM Complete
transaction before it issues another DVM Sync transaction.

Components must be able to accept DVM Sync messages and continue processing snoop transactions while waiting
for earlier transactions to complete. This processing might be needed before a DVM Complete message can be sent.
The maximum number of outstanding DVM Sync messages that a Manager must be able to accept is 256.

A DVM Sync must complete in a timely manner, even if the component continues to receive more DVM
invalidation operations and more DVM Sync messages.

Support for multiple outstanding DVM Sync messages only requires the component to be aware of the number of
DVM Complete responses required. No additional information about the individual DVM Sync messages is
necessary.

A component that has issued a DVM Sync and also received a DVM Sync from another component is not permitted
to wait for the DVM Complete to its DVM Sync before providing a DVM Complete response for the other
component.

## Chapter D14

### Manager Design Recommendations

This chapter presents a set of recommendations for the design of Manager components that improve the ability to
bridge the Manager to different protocol interfaces. It contains the following sections:

- Recommended design restrictions on page D14-338

### D14.1 Recommended design restrictions

This specification recommends that all new Manager components are designed to meet the following restrictions:

- A single cache line size of 64 bytes.

- A constrained number of WriteBack, WriteClean, WriteEvict, and WriteNoSnoop transactions in progress:
  - The total number of data bytes within each transaction must be considered as well as the total number of transactions.
  - There is no fixed limit, it is only required that the limit is specified. This permits a buffer to be designed which can accept the maximum number of transactions.

A snoop transaction must make forward progress unless there is an outstanding WriteBack, WriteClean, or
WriteEvict transaction to the same line.

Any address hazard that prevents forward progress of a snoop transaction while a WriteBack, WriteClean, or
WriteEvict transaction is in progress must be precise to cache line granularity:

It is not permitted to prevent forward progress of a snoop transaction while a WriteBack, WriteClean,
or WriteEvict transaction is in progress to a different cache line and there is no WriteBack, WriteClean,
or WriteEvict transaction in progress to the same cache line.

-

The use of the CD channel to respond to snoops must be supported if the cache holds dirty cache lines:
- This is required to permit the forward progress of a snoop transaction when the maximum number of
WriteBack, WriteClean, WriteEvict, and WriteNoSnoop transactions have been reached and these
transactions are not guaranteed to complete before the snoop must complete.

Partial dirty cache lines cannot be supported because the CD channel does not support the use of byte
strobes.

-

All WriteBack, WriteClean, WriteEvict, and Evict transactions in progress must use a unique AXI ID
transaction identifier. This allows the interconnect to respond to WriteBack, WriteClean, WriteEvict, and
Evict transactions in any order.

The single-copy atomicity guarantee for a Device transaction is no greater than the number of bytes in a
single data transfer, as defined by AxSIZE.

This set of restrictions is sufficient to permit a Manager component to be bridged to a protocol that does not support
the free-flowing write channel that ACE provides.

This set of restrictions has no impact on the compatibility of the Manager with different revisions of the
specification.
