# Part E

AMBA 5 Protocol Features

## Chapter E1

### Additional Features in AMBA 5

This chapter describes features that can be used with AMBA 5 interfaces:

- Atomic transactions on page E1-342
- Cache stashing on page E1-351
- Deallocating transactions on page E1-355
- Trace signals on page E1-357
- User Loopback signaling on page E1-359
- QoS Accept signaling on page E1-360
- Wake-up Signaling on page E1-362
- Coherency Connection signaling on page E1-364
- Untranslated transactions on page E1-369
- Non-secure access identifiers on page E1-376
- Read data chunking on page E1-378
- Read interleaving property on page E1-382
- Unique ID indicator on page E1-383
- Memory Partitioning and Monitoring (MPAM) on page E1-385
- Memory tagging on page E1-387
- Prefetch request and response on page E1-396
- Write zero with no data on page E1-398
- Additional interface properties on page E1-399
- Signal width properties on page E1-403

All these features are optional.Table G3-1 on page G3-472 shows which features can be included on which interface
type.

### E1.1 Atomic transactions

AMBA 5 introduces Atomic transactions, which perform more than just a single access and have an operation that
is associated with the transaction. Atomic transactions enable sending the operation to the data, permitting the
operation to be performed closer to where the data is located. Atomic transactions are suited to situations where the
data is located a significant distance from the agent that must perform the operation.

Compared with using Exclusive Accesses, this approach reduces the amount of time during which the data must be
made inaccessible to other agents in the system.

The Atomic_Transactions property is used to indicate whether a component supports Atomic transactions:
True Atomic transactions are supported.
False Atomic transactions are not supported. If not declared, Atomic_Transactions property is considered
False.

The Atomic_Transactions extension is supported in the following interfaces:

- AXI5

- ACE5-Lite

- ACE5-LiteDVM

If a Subordinate or interconnect component declares that it supports Atomic transaction, then it must support all
operation types, sizes, and endianness.

This specification does not support the use of Atomic transactions by ACE5 Managers.

### E1.1.1 Overview

In an atomic transaction, the Manager sends an address, control information, and outbound data. The Subordinate
sends inbound data (except for AtomicStore) and a response. This specification supports four forms of Atomic
transaction:

### AtomicStore

### AtomicLoad

### AtomicSwap

- Sends a single data value with an address and the atomic operation to be performed.
- The target performs the operation using the sent data and value at the addressed

location as operands.

- The result is stored in the address location.

- A single response is given without data.
- Outbound data size is 1, 2, 4, or 8 bytes.

-
- The original data value at the addressed location is returned.

- The target performs the operation using the sent data and value at location as operands.

- The result is stored in the address location.

- Outbound data size is 1, 2, 4, or 8 bytes.

- Inbound data size is the same as the outbound data size.

- Sends a single data value with an address and the atomic operation to be performed.

- the addressed

- Sends a single data value with an address.

- The target swaps the value at the addressed location with the data value that is supplied in the transaction.

- The original data value at the addressed location is returned.

- Outbound data size is 1, 2, 4, or 8 bytes.
- Inbound data size is the same as the outbound data size.

AtomicCompare
- Sends two data values, the compare value and the swap value, to the addressed
location. The compare and swap values are of equal size.

The data value at the addressed location is checked against the compare value:
- If the values match, the swap value is written to the addressed location.
- If the values do not match, the swap value is not written to the addressed
location.

- The original data value at the addressed location is returned.

- Outbound data size is 2, 4, 8, 16, or 32 bytes.

- Inbound data size is half of the outbound data size because the outbound data contains both compare and swap values, whereas the inbound data has only the original data value.

### E1.1.2 Atomic transaction operations

This specification supports eight different operations which can be used with AtomicStore and AtomicLoad
transaction. Table E1-1 shows the operators.

### Table E1-1 Atomic transaction operators

| Operator | Description |
| --- | --- |
| ADD | The value in memory is added to the sent data and the result stored in memory. |
| CLR | Every set bit in the sent data clears the corresponding bit of the data in memory. |
| EOR | Bitwise exclusive OR of the sent data and value in memory. |
| SET | Every set bit in the sent data sets the corresponding bit of the data in memory. |
| SMAX | The value stored in memory is the maximum of the existing value and sent data. This |
|  | operation assumes signed data. |
| SMIN | The value stored in memory is the minimum of the existing value and sent data. This |
|  | operation assumes signed data. |
| UMAX | The value stored in memory is the maximum of the existing value and sent data. This |
|  | operation assumes unsigned data. |
| UMIN | The value stored in memory is the minimum of the existing value and sent data. This |
|  | operation assumes unsigned data. |

### E1.1.3 Atomic transactions attributes

Rules for atomic transactions:

AWLEN and AWSIZE specifies the number of bytes of write data in the transaction. For AtomicCompare,
the number of bytes must include both the compare and swap values.

If AWLEN indicates a burst length greater than one, AWSIZE is required to be the full data bus width.

Write strobes that are not within the data window, as specified by AWADDR and AWSIZE, must be
deasserted.

- Write strobes within the data window must be asserted.

For AtomicStore, AtomicLoad, and AtomicSwap:

- The write data is 1, 2, 4, or 8 bytes and read data is 1, 2, 4, or 8 bytes respectively.

- AWADDR must be aligned to the data size.

- AWBURST must be INCR.

For AtomicCompare:

- The write data is 2, 4, 8, 16, or 32 bytes and read data is 1, 2, 4, 8, or 16 bytes.

- AWADDR must be aligned to a single write data value, half the total write data size.
- If AWADDR points to the lower half of the transaction:
  - The compare value is sent first. The compare value is in the lower bytes of a single-beat transaction, or in the first beats of a multi-beat transaction.
  - AWBURST must be INCR.
- If AWADDR points to the upper half of the transaction:
  - The swap value is sent first. The swap value is in the lower bytes of a single-beat transaction, or in the first beats of a multi-beat transaction.
  - AWBURST must be WRAP.

For AtomicCompare transactions, there are relaxations to the usual rules for transactions of type WRAP:

- A burst of length 1 is permitted, AWLEN=0

- AWADDR is not required to be aligned to the transfer size

Example E1-1 shows some permitted combinations of attributes for a 64-bit data bus and the location of the
Compare and Swap data values.

### Example E1-1 Location of the Compare and Swap data values

<table>
 <tr>
  <th></th>
  <td>AWADDR AWSIZE AWLEN AWBURST 7 6 5 4 3 2 1 0<br/>0x00 1 (2B) 0 INCR - - - - - - S C<br/>0x01 1 (2B) 0 WRAP - - - - - - C S<br/>0x04 2 (4B) 0 INCR S S C C - - - -<br/>0x06 2 (4B) 0 WRAP C C S S - - - -<br/>0x00 3 (8B) 0 INCR S S S S C C C C<br/>0x04 3 (8B) 0 WRAP C C C C S S S S<br/>C C C C C C C C 1st Beat<br/>0x00 3 (8B) 1 INCR<br/>S S S S S S S S 2nd Beat<br/>S S S S S S S S 1st Beat<br/>0x08 3 (8B) 1 WRAP<br/>C C C C C C C C 2nd Beat</td>
  <td></td>
 </tr>
 <tr>
  <th colspan="3">E1.1.4 ID use for Atomic transactions<br/>A single AXI ID is used for an Atomic transaction. The same AXI ID is used for the request, write response, and<br/>the read data. This requirement means that the Manager must only use ID values that can be signaled on both AWID<br/>and RID signals.</th>
 </tr>
</table>

Atomic transactions must not use AXI ID values that are used by Non-atomic transactions that are outstanding at
the same time. This rule applies to transactions on either the AR or AW channel. This rule ensures that there are no
ordering constraints between Atomic transactions and Non-atomic transactions.

If one transaction has fully completed before the other is issued, Atomic transactions and Non-atomic transactions
can use the same AXI ID value.

Multiple Atomic transactions that are outstanding at the same time must not use the same AXI ID value.

### E1.1.5 Request attributes for Atomic transactions

For Atomic transactions, the following restrictions apply for request attributes:

AWCACHE and AWDOMAIN are permitted to be any combination valid for the interface type. See
Table D3-3 on page D3-177.

- AWSNOOP must be set to all zeros.

- AWLOCK must be 0b0, Normal access.

### E1.1.6 Atomic transaction signaling

An extra signal is added to the interface to support Atomic transactions.

The signal is AW Atomic Operation, AWATOP. Table E1-2 and Table E1-3 on page E1-346 show the AWATOP
encodings.

### Table E1-2 AWATOP encodings

|  | Description |
| --- | --- |
| 0b000000 | Non-atomic operation |
| 0b01exxx | AtomicStore |
| 0b10exxx | AtomicLoad |
| 0b110000 | AtomicSwap |
| 0b110001 | AtomicCompare |

For AtomicStore and AtomicLoad transactions AWATOP[3] indicates the endianness that is required for the atomic
operation:

- When deasserted, this bit indicates that the operation is little-endian.

- When asserted, this bit indicates that the operation is big-endian.

The value of AWATOP[3] applies to arithmetic operations only and is ignored for bitwise logical operations.

For AtomicStore and AtomicLoad transactions, Table E1-3 shows the encodings for the operations on the
lower-order AWATOP[2:0] signals.

### Table E1-3 Lower-order AWATOP[2:0] encodings

|  |  | Description |
| --- | --- | --- |
| 0b000 | ADD | Add |
| 0b001 | CLR | Bit clear |
| 0b010 | EOR | Exclusive OR |
| 0b011 | SET | Bit set |
| 0b100 | SMAX | Signed maximum |
| 0b101 | SMIN | Signed minimum |
| 0b110 | UMAX | Unsigned maximum |
| 0b111 | UMIN | Unsigned minimum |

### E1.1.7 Transaction structure

For AtomicLoad, AtomicSwap, and AtomicCompare transactions, the transaction structure is as follows:

- The request is issued on the AW channel.

- The associated transaction data is sent on the W channel.

- The number of write data transfers required on the W channel is determined by the AWLEN signal.
- The relative timing of the Atomic transaction request and the Atomic transaction write data is not specified.
- The Subordinate returns the original data value using the R channel.
- The number of read data transfers is determined from both AWLEN and the AWATOP signals.

### Note

For the AtomicCompare operation, if AWLEN indicates a burst length greater than 1, then the number of
read data transfers is half that specified by AWLEN.

- A Subordinate is permitted to wait for all write data before sending read data. A Manager must be able to send all write data without receiving any read data.

- A Subordinate is permitted to send all read data before accepting any write data. A Manager must be able to accept all read data without any write data being accepted.

- A single write response is returned on the B channel. The write response must be given by the Subordinate only after it has received all write data transfers and the result of the atomic transaction is observable.

Figure E1-1 shows the flow of information and data for AtomicLoad, AtomicSwap, and AtomicCompare
transactions.

<table>
 <tr>
  <th colspan="3">Manager Subordinate</th>
 </tr>
 <tr>
  <th rowspan="2">AW<br/>W<br/>B</th>
  <td>AtomicLoad</td>
  <td rowspan="2"></td>
 </tr>
 <tr>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th colspan="3"></th>
 </tr>
</table>

### Figure E1-1 AtomicLoad, AtomicSwap, or AtomicCompare transaction

For AtomicStore transactions, the transaction structure is as follows:

- The request is issued on the AW channel.

- The associated transaction data is sent on the W channel.

- The number of write data transfers required on the W channel is determined by the AWLEN signal.
- The relative timing of the Atomic transaction request and the Atomic transaction write data is not specified.
- A single write response is returned on the B channel. The write response must be given only by the Subordinate after it has received all write data transfers and the result of the atomic transaction is observable.

Figure E1-2 shows the flow of information and data for AtomicStore transactions.

<table>
 <tr>
  <th colspan="2">Manager</th>
 </tr>
 <tr>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
 </tr>
</table>

Manager Subordinate

### Figure E1-2 AtomicStore transaction

### E1.1.8 Response signaling

An Atomic transaction requires a write response. The write response indicates that the transaction is visible to all
required observers.

Atomic transactions that include a read response are visible to all required observers from the point of receiving the
first item of read data.

### Note

Both the read response and write response indicate that a transaction is visible to all required observers. It is
permitted for a Manager to use either response.

There is no concept of an error that is associated with the operation, such as overflow. An operation is fully specified
for all input combinations.

For transactions, such as AtomicCompare, where there are multiple outcomes for the transaction, no indication is
provided on the outcome of the transaction. To determine if a Compare and Swap instruction has updated the
memory location, it is necessary to inspect the original data value that is returned as part of the transaction.

It is permitted to give an error response to an Atomic transaction when the transaction reaches a component that
does not support Atomic transactions. For AtomicLoad, AtomicSwap and AtomicCompare transactions:

- A Subordinate must send the correct number of read data beats, even if the write response is DECERR or SLVERR.

- A Manager might ignore the write response and only use the response that comes with read data.

### E1.1.9 Atomic transaction dependencies

For AtomicLoad, AtomicSwap, and AtomicCompare transactions, Figure E1-3 on page E1-349 shows the
following Atomic transaction handshake signal dependencies:

The Manager must not wait for the Subordinate to assert AWREADY or WREADY before asserting
AWVALID or WVALID.

The Subordinate can wait for AWVALID or WVALID, or both, before asserting AWREADY.

The Subordinate can assert AWREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate can wait for AWVALID or WVALID, or both, before asserting WREADY.

The Subordinate can assert WREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate must wait for AWVALID, AWREADY, WVALID, and WREADY to be asserted before
asserting BVALID.

The Subordinate must also wait for WLAST to be asserted before asserting BVALID, because the write
response BRESP, must be signaled only after the last data transfer of a write transaction.

The Subordinate must not wait for the Manager to assert BREADY before asserting BVALID.

The Manager can wait for BVALID before asserting BREADY.

The Manager can assert BREADY before BVALID is asserted.

The Subordinate must wait for both AWVALID and AWREADY to be asserted before it asserts RVALID
to indicate that valid data is available.

The Subordinate must not wait for the Manager to assert RREADY before asserting RVALID.

The Manager can wait for RVALID to be asserted before it asserts RREADY.

The Manager can assert RREADY before RVALID is asserted.

The Manager must not wait for the Subordinate to assert RVALID before asserting WVALID.

The Subordinate can wait for WVALID to be asserted, for all write data transfers, before it asserts RVALID.

The Manager can assert WVALID before RVALID is asserted.

In the dependency diagram that Figure E1-3 shows:

- A single-headed arrow points to a signal that can be asserted before or after the signal at the start of the arrow.

A double-headed arrow points to a signal that must be asserted only after assertion of the signal at the start
of the arrow.

AWVALID WVALID BVALID RVALID

### AWREADY WREADY BREADY RREADY

### Figure E1-3 Atomic transaction handshake dependencies

### E1.1.10 Support for Atomic transactions

### Manager support

Atomic transactions are not supported for ACE Managers. An ACE Manager is able to perform an atomic operation
to a Cacheable location by obtaining a unique copy of the cache line and performing the atomic operation locally
within its own cache. An ACE Manager cannot support Atomic transactions to Non-cacheable or Device locations.
No specific support for Atomic transactions is required on the Snoop channel and therefore an ACE Manager needs
no added functionality to be compatible with Atomic transactions that are performed by other components.

A Manager component that supports Atomic transactions is required to support a mechanism to suppress the
generation of Atomic transactions to ensure compatibility in systems where Atomic transactions are not supported.
An optional BROADCASTATOMIC pin is specified. When the pin is tied HIGH, the interface is permitted to
generate Atomic transactions. When tied LOW, the interface must not generate Atomic transactions.

### Subordinate support

It is optional for a Subordinate component to support Atomic transactions.

If a Subordinate component only supports Atomic transactions for particular memory types, or for particular address
regions, then the Subordinate must give an appropriate error response for the Atomic transactions that it does not
support.

### Interconnect support

It is optional for an interconnect to support Atomic transactions.

If an interconnect does not support Atomic transactions, all attached Manager components must be configured to
not generate Atomic transactions. The BROADCASTATOMIC pin can be used for this purpose.

Atomic transactions, can be supported at any point within an interconnect that supports them, including passing
Atomic transactions downstream to Subordinate components.

Atomic transactions are not required to be supported for every address location. If Atomic transactions are not
supported for a given address location, then an appropriate error response can be given for the transaction. See
Response signaling on page E1-347.

For Device transactions, the Atomic transaction must be passed to the endpoint Subordinate. If the Subordinate is
configured to indicate that it does not support Atomic transactions, then the interconnect must give an error response
for the transaction. An Atomic transaction must not be passed to a component that does not support Atomic
transactions.

For Cacheable transactions, the interconnect can either:

Perform the atomic operation within the interconnect. This method requires that the interconnect performs
the appropriate read, write, and snoop transactions to complete the operation.

If the appropriate endpoint Subordinate is configured to indicate that it does support atomic operations, then
the interconnect can pass the atomic operation to the Subordinate.

### E1.2 Cache stashing

Cache stashing enables one component to indicate that a particular cache line should be placed in the cache of
another component in the system. This technique can be used to ensure that data is located close to its point of use,
potentially improving the performance of the overall system.

The Cache_Stash_Transactions property is used to indicate whether an interface supports cache stashing:
True Cache stashing is supported.
False Cache stashing is not supported and associated signals are omitted. If Cache_Stash_Transactions is
not declared, it is considered False.

The Cache_Stash_Transactions extension is supported in the following interfaces:

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

This specification does not support the use of cache stashing by, or into, ACE5 Managers. ACE5-Lite Managers can
cause data to be stashed in fully coherent Managers with AMBA CHI interfaces. For more information on stashing
into a CHI Manager, see AMBA 5 CHI Architecture Specification.

An identification mechanism is required with the transaction to use cache stashing. The identification indicates the
specific cache in the system that is the intended target for the stash operation. This specification does not define the
precise details of this identification mechanism. It is expected that any agent that is performing a stash operation
knows the identifier to use for a given stash transaction.

This specification does define two levels of identification, one to identify the physical interface that the cache stash
should be sent to, and one to identify a functional unit that is associated with that physical interface. For example,
a stash transaction can specify a processor cluster interface and specific cache within that cluster.

### E1.2.1 Stash transaction types

This specification defines four stash transaction types:

### WriteUniquePtlStash

A write to memory which also indicates that the data should be allocated into a particular
cache. For a WriteUniquePtlStash transaction, any number of bytes within the cache line are
written, including all bytes or zero bytes.

### WriteUniqueFullStash

A write to memory which also indicates that the data should be allocated into a particular
cache. For a WriteUniqueFullStash transaction, it is required that all bytes within the cache
line are written.

### StashOnceShared

### StashOnceUnique

A data-less transaction which indicates that a cache line should be fetched into a particular
cache. For a StashOnceShared transaction, it is required that existing cached copies of the
cache line are not invalidated.

A data-less transaction which indicates that a cache line should be fetched into a particular
cache. For a StashOnceUnique transaction, this specification recommends that the cache
line is stashed in Unique state. Stashing in a Unique state permits a store to the cache line to
occur with no further action.

### Note

A StashOnceUnique transaction can cause the invalidation of a cached copy of a cache line and care must be taken
to ensure that such transactions do not interfere with Exclusive access sequences.

For an interface that supports the Untranslated_Transactions feature, an extra stash transaction is supported. The
StashTranslation transaction is used to indicate to a System Memory Management Unit (SMMU) that a translation
should be obtained for the address that is supplied with the StashTranslation transaction. See StashTranslation on
page E1-374.

### E1.2.2 Stash transaction signaling

An additional set of signaling is provided on the ACE5-Lite interface to support the use of cache stashing. This
includes the extension of the AWSNOOP signal to 4 bits.

A stash transaction is sent using the AW channel, with or without an associated transfer on the W channel. The
permitted combinations of control signals for stash requests is shown in Table E1-4. WriteUniqueStash and
StashOnce transactions must not cross a cache line boundary.

Table E1-4 Permitted Stash transaction write address control signal combinations

<table>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>AWLOCK</td>
  <td></td>
  <td></td>
  <td>AWSIZE</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>0b0</td>
  <td>0b01, 0b10</td>
  <td>0b1</td>
  <td>Cache line or</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>smaller</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>0b0</td>
  <td>0b01, 0b10</td>
  <td>0b1</td>
  <td>Cache line sized</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>and Regular</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>0b0</td>
  <td>0b00, 0b01, 0b10</td>
  <td>0b1</td>
  <td>Cache line sized</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>and Regular</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>0b0</td>
  <td>0b00, 0b01, 0b10</td>
  <td>0b1</td>
  <td>Cache line sized</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>and Regular</td>
 </tr>
 <tr>
  <th>E1-5 shows the</th>
  <td></td>
  <td>signals</td>
  <td>are required</td>
  <td>on the AW<br/>Table E1-5</td>
  <td>to support stash<br/>AW</td>
  <td></td>
 </tr>
 <tr>
  <th>Signal</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>AWSTASHNID[10:0]</th>
  <td></td>
  <td>Node</td>
  <td>of the target</td>
  <td>a stash</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>AWSTASHNIDEN</th>
  <td></td>
  <td>Indicates</td>
  <td>the</td>
  <td>signal is</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>Logical</td>
  <td>Identifier</td>
  <td>the target</td>
  <td>a stash operation</td>
  <td></td>
 </tr>
 <tr>
  <th>AWSTASHLPIDEN</th>
  <td></td>
  <td>Indicates</td>
  <td>the</td>
  <td>signal</td>
  <td>valid</td>
  <td></td>
 </tr>
</table>

Stash transaction

WriteUniquePtlStash 0b1000

WriteUniqueFullStash 0b1001

StashOnceShared 0b1100

StashOnceUnique 0b1101

The following rules apply to the AW channel signaling associated with the Cache_Stash_Transactions property:

- AWSTASHNID and AWSTASHNIDEN must either be both present or both absent.
- AWSTASHLPID and AWSTASHLPIDEN must either be both present or both absent.
- AWSTASHNID[10:0] must be driven to all zeros when AWSTASHNIDEN is deasserted.
- AWSTASHLPIDEN must be driven to all zeros when AWSTASHLPIDEN is deasserted.

It is permitted, but not recommended, to send a stash transaction with a stash target that indicates a component that
does not support cache stashing. The indication of a stash target within a stash transaction does not affect which
components are permitted to access and cache a given cache line.

Table E1-6 shows the permitted combinations of the enable signals associated with the Node and Logical Processor
identifiers.

### Table E1-6 Permitted combinations of the enable signals

| AWSTASHNIDEN |  | Permitted behavior |
| --- | --- | --- |
| 0 | 0 | Required value for any transaction that is not a |
|  |  | WriteUniqueStash or StashOnce transaction. |
|  |  | Permitted for a WriteUniqueStash or StashOnce transaction. |
| 1 | 0 | Permitted for a WriteUniqueStash or StashOnce transaction. |
|  |  | Only the physical interface that is the target for the stash |
|  |  | operation is provided. |
| 0 | 1 | Permitted for a WriteUniqueStash or StashOnce transaction. |
|  |  | This combination is only expected to be used on an |
|  |  | ACE5-LiteACP interface, where the Node ID is not required. |
|  |  | See Chapter F4 ACE5-LiteACP. |
| 1 | 1 | Permitted for a WriteUniqueStash or StashOnce transaction. |

### E1.2.3 Rules and recommendations

It is permitted to send a stash transaction without a stash target. In this situation, this specification recommends the
following behavior for each of the different types of stash transaction:

- For WriteUniquePtlStash and WriteUniqueFullStash transactions:
- If the interconnect is able to determine that the cache line is held in a single cache before the write
occurs, then stash the cache line back to that cache.

If the cache line is not held in any cache before the write occurs, then stash the cache line in a shared
system cache.

-

For StashOnceShared and StashOnceUnique transactions, if the interconnect is able to determine that the
cache line is not in any cache, then stash the cache line in a shared system cache.

|  | Note |
| --- | --- |
|  | For StashOnceShared or StashOnceUnique transactions, care is required to avoid any action that could result |
|  | in the deallocation of the cache line from the cache where it is expected to be used. |
|  | A common use of StashOnce without a stash target is for a component to prefetch a cache line to a |
|  | downstream cache for its own use. |

### E1.2.4 Transaction structure

A WriteUniqueStash has the same transaction structure as other WriteUnique transactions.

A StashOnce transaction has no data transfers. The address and control information is provided on the AW channel,
and a single response is provided on the B channel. The response must be provided only after the address has been
accepted.

### E1.2.5 ID use for stash transactions

WriteUniquePtlStash and WriteUniqueFullStash transactions impose no additional constraints on the use of AXI ID
values.

StashOnceShared and StashOnceUnique can be referred to as StashOnce transactions. StashOnce transactions must
not use the same AXI ID values that are used by non-StashOnce transactions that are outstanding at the same time.
This rule ensures that there are no ordering constraints between StashOnce transactions and other transactions. Both
StashOnce transactions and non-StashOnce transactions are permitted to use the same AXI ID value, provided that
the same ID value is not used by both a StashOnce transaction and a non-StashOnce at the same time. There can be
multiple outstanding StashOnce transactions with the same ID. There can be multiple outstanding non-StashOnce
transactions with the same ID.

### E1.2.6 Support for stash transactions

The Cache_Stash_Transactions property is used to indicate whether a component supports stash transactions.

Table E1-7 shows the conversion of transactions between components that issue stash transactions and components
that do not support them.

### Table E1-7 Conversion between Stash and Non-stash transactions

<table>
 <tr>
  <th>Stash transaction</th>
  <td>Action</td>
 </tr>
 <tr>
  <th>WriteUniquePtlStash</th>
  <td>Convert to WriteUnique, optionally named WriteUniquePtl.</td>
 </tr>
 <tr>
  <th>WriteUniqueFullStash</th>
  <td>Convert to WriteLineUnique, optionally named WriteUniqueFull.</td>
 </tr>
 <tr>
  <th>StashOnceShared</th>
  <td>Do not propagate and give an immediate response.</td>
 </tr>
 <tr>
  <th>StashOnceUnique</th>
  <td>Do not propagate and give an immediate response.</td>
 </tr>
 <tr>
  <th>Note</th>
  <td></td>
 </tr>
 <tr>
  <th>See Full and partial cache line<br/>WriteUniquePtl.</th>
  <td>transaction naming on page G1-458 for a description of WriteUniqueFull and</td>
 </tr>
</table>

### E1.3 Deallocating transactions

The primary use of a deallocating transaction is to deallocate the associated cache lines when it is known that these
cache lines are no longer required. This mechanism helps to ensure better availability of the cache resources for
other address locations.

The DeAllocation_Transactions property is used to indicate whether a component supports deallocating
transactions:

### True

Deallocating transactions are supported.

Deallocating transactions are not supported. If the DeAllocation_Transactions property is not
declared, it is considered False.

False

The Deallocation_Transactions extension is supported in the following interfaces:

- ACE5-Lite

- ACE5-LiteDVM

This specification does not support the use of deallocating transactions by ACE5 Managers.

Interoperability between a component that issues deallocating transactions and a component that does not support
them can be performed by converting the transaction to a ReadOnce transaction.

### E1.3.1 Deallocating transaction types

This specification defines two deallocating transactions:

### ReadOnceCleanInvalid (ROCI)

This transaction reads a snapshot of the current value of the cache line. This specification
recommends, but does not require, that any cached copy of the cache line is deallocated. If a Dirty
copy of the cache line exists, and the cache line is deallocated, then the Dirty copy must be written
back to main memory.

### ReadOnceMakeInvalid (ROMI)

This transaction reads a snapshot of the current value of the cache line. This specification
recommends, but does not require, that any cached copy of the cache line is deallocated. It is
permitted, but not required, that a Dirty copy of the cache line is discarded. The Dirty copy of the
cache line does not need to be written back to main memory.

### E1.3.2 Rules and recommendations

Deallocating transactions are only permitted to access one cache line at a time. Accessing less than a cache line is
permitted, but it is not permitted to cross a cache line boundary.

### Note

Use of a ReadOnceMakeInvalid transaction to access less than a cache line can result in the invalidation of the entire
cache line.

For a ReadOnceMakeInvalid transaction, it is required that the invalidation of the cache line is committed before
the return of the first item of read data for the transaction. The invalidation of the cache line is not required to have
completed at this point. However, it must be ensured that any later write transaction from any agent that starts after
this point, is guaranteed not to be invalidated by this transaction.

The following considerations apply to the use of these transactions:

Caution is needed when deallocating transactions are issued to the same cache line that other agents are using
for Exclusive accesses. This is because the deallocation can cause an exclusive sequence to fail.

Apart from the interaction with Exclusive accesses, the ReadOnceCleanInvalid transaction only provides a
hint for deallocation of a cache line and has no other impact on the correctness of a system.

The use of the ReadOnceMakeInvalid transaction can cause the loss of a Dirty cache line. The use of this
transaction must be strictly limited to scenarios when it is known that it is safe to do so.

These transactions do not guarantee the invalidation of cache lines and cannot be used to ensure the visibility
of downstream caches.

### Note

This specification permits the use of ReadOnceCleanInvalid and ReadOnceMakeInvalid transactions to access less
than a cache line. However, some implementations might not support the deallocation behavior for transactions that
are less than a cache line and instead convert the transaction to ReadOnce in such cases.

### E1.3.3 Deallocating transaction signaling

A deallocating transaction is sent using the AR channel. A deallocating transaction is indicated using the extended
ARSNOOP encodings that are shown in Table E1-8.

### Table E1-8 ARSNOOP encodings

|  | Transaction |
| --- | --- |
| 0b0100 | ReadOnceCleanInvalid |
| 0b0101 | ReadOnceMakeInvalid |

These transactions are only supported for transactions to the Inner or Outer Shareable domain.

The permitted response and permitted cache line state changes for these transactions is identical to the permitted
response and permitted cache line state changes for ReadOnce transactions.

There is no snoop channel equivalent of these transactions. An interconnect is permitted to use any appropriate
snoop transaction to obtain the required data and deallocate the cache line.

Conversion between a component that issues deallocation transactions and one that does not support them can be
performed by simply converting the transaction to a ReadOnce transaction.

### E1.4 Trace signals

An optional Trace signal can be associated with each channel to support the debugging, tracing, and performance
measurement of systems.

The Trace_Signals property is used to indicate whether a component supports Trace signals:
True Trace_Signals are supported.
False Trace_Signals are not supported. If Trace_Signals is not declared, it is considered False.

The Trace_Signals extension is supported in the following interfaces:

- AXI5

- AXI5-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

Table E1-9 shows the Trace signal that is associated with each channel.

Table E1-9 Trace signal associated with each channel

<table>
 <tr>
  <th>Trace signal</th>
  <td></td>
  <td>Description</td>
 </tr>
 <tr>
  <th>ARTRACE</th>
  <td>AR</td>
  <td>Associated with the Read Address channel</td>
 </tr>
 <tr>
  <th>RTRACE</th>
  <td>R</td>
  <td>Associated with the Read Data channel</td>
 </tr>
 <tr>
  <th>AWTRACE</th>
  <td>AW</td>
  <td>Associated with the Write Address channel</td>
 </tr>
 <tr>
  <th>WTRACE</th>
  <td>W</td>
  <td>Associated with the Write Data channel.</td>
 </tr>
 <tr>
  <th>BTRACE</th>
  <td>B</td>
  <td>Associated with the Write Response channel</td>
 </tr>
 <tr>
  <th>ACTRACEa</th>
  <td>AC</td>
  <td>Associated with the Snoop Address channel</td>
 </tr>
 <tr>
  <th>CRTRACEa</th>
  <td>CR</td>
  <td>Associated with the Snoop Response channel</td>
 </tr>
 <tr>
  <th>CDTRACEb</th>
  <td>CD</td>
  <td>Associated with the Snoop Data channel</td>
 </tr>
</table>

1. ACE5 and ACE5-LiteDVM only.

2. ACE5 only.

If the Trace_Signals property is True, then the appropriate Trace signal must be present for all channels that are
present.

The expected use of the Trace signal is as follows:

A component, such as a Manager or an interconnect, can assert the Trace signal along with the address of a
transaction that should be tracked through the system.

This specification expects that any component that provides a response to a transaction with the Trace signal
asserted in the request provides a response with the Trace signal asserted.

For transactions that have the Trace signal asserted and which generate extra related transactions, such as
snoop transactions, this specification recommends asserting the Trace signal for the related transactions:

- Any related transaction using the same address, such as a snoop transaction, has the Trace signal
propagated to it.

- For other transactions, which might have an unrelated address, it is IMPLEMENTATION DEFINED
whether the Trace signal is propagated.

It is permitted for an interconnect or Subordinate component to use Trace signals.

It is permitted for a component to assert the Trace signal of a transaction response for a transaction that did not have
the Trace signal asserted in the request. In this case, it is not required that the Trace signal is asserted for all responses
of the same transaction.

This specification recommends that all behavior relating to the propagation of the Trace signaling is adopted, but
this recommendation is not a requirement. Therefore, any component that uses the Trace signaling must not always
require the correct propagation of the Trace signaling.

This specification expects that the use of Trace signaling is coordinated across the entire system and only one use
of the Trace signaling occurs at a given time.

For Write transactions the following behavior is recommended:

A Subordinate that receives a write request with AWTRACE asserted should assert the BTRACE signal
alongside the write response.

WTRACE should be propagated through interconnect components.

For Atomic transactions that require a response on the read channel, the RTRACE signal should be asserted
if AWTRACE was asserted.

For Read transactions the following behavior is recommended:

A Subordinate that receives a read request with the ARTRACE signal asserted should assert the RTRACE
signal alongside every beat of the read response.

For Snoop transactions the following behavior is recommended:

A Manager that receives a snoop request with the ACTRACE signal asserted should assert the CRTRACE
signal alongside the snoop response.The Manager should also assert CDTRACE alongside every data beat
of the snoop data that is associated with the snoop transaction.

### E1.5 User Loopback signaling

User Loopback signaling permits an agent that is issuing transactions to store information that is related to the
transaction in an indexed table. The response to the transaction can then use a fast table index to obtain the required
information, rather than requiring a more complex lookup that uses the transaction AxID.

The Loopback_Signals property is used to indicate whether a component supports User Loopback signals:
True Loopback signals are supported.
False Loopback signals are not supported. If Loopback_Signals is not declared, it is considered False.

The Loopback_Signals extension is supported in the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

Table E1-10 shows the User Loopback signals.

### Table E1-10 User Loopback signals

| Signal | Width | Description |
| --- | --- | --- |
| ARLOOP | LOOP_R_WIDTH | Loopback value for a read transaction |
| AWLOOP | LOOP_W_WIDTH | Loopback value for a write transaction |
| RLOOP | LOOP_R_WIDTH | Returns the value that is provided on ARLOOP |
| BLOOP | LOOP_W_WIDTH | Returns the value provided on AWLOOP |

If the Loopback_Signals property is True, then all loopback signals must be present. See Table E1-10.

The usage rules and recommendations are:

- LOOP_R_WIDTH and LOOP_W_WIDTH are recommended to be configurable up to 8 bits wide.

- The value of RLOOP must be identical to the value that was presented on the ARLOOP signal.

- The value of BLOOP must be identical to the value that was presented on the AWLOOP signal.

- If an interface includes BCOMP, BLOOP can take any value for responses with BCOMP deasserted.

- For Atomic transactions that require a response on the read channel, the value of RLOOP must be identical to the value that was presented on the AWLOOP signal. This requirement means that Manager must use loop values that can be signaled on both AWLOOP and RLOOP signals.

This specification does not require that the loopback value is unique. Multiple outstanding transactions from the
same Manager are permitted to use the same value.

This specification does not require that the loopback value is preserved as a transaction progresses through a system.
An intermediate component is permitted to store the loopback value of a transaction it receives and use its own
loopback value for a transaction that it propagates downstream. When the component receives a response to the
downstream transaction, it can retrieve the loopback value that is required for the response to the original
transaction.

Loopback signaling is not supported on the snoop channels. All snoop transaction responses are required to be in
order, which simplifies the process of associating a response with a request.

### E1.6 QoS Accept signaling

AXI4 introduced two interface signals to indicate the QoS value of a transaction. AMBA 5 introduced two
additional interface signals that enable a Subordinate to indicate the minimum QoS value of transactions that it
accepts. The QoS_Accept property is used to indicate whether an interface includes these signals:
True The interface includes both VARQOSACCEPT and VAWQOSACCEPT signals.
False The interface does not include VARQOSACCEPT or VAWQOSACCEPT. If QoS_Accept is not
declared, it is considered False.

The QoS_Accept extension is applicable to the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

QoS Accept signaling is intended for Subordinate components that have different resources available for different
QoS levels, which is typically the case with memory controllers. The Subordinate can indicate that it only accepts
transactions at a certain QoS level or above when the resources available to lower QoS levels are in use.

QoS Accept signaling can be used as an input to a Manager interface that might have several different transactions
to select from. This permits the Manager interface to only issue transactions that are likely to be accepted, which
avoids unnecessary blocking of the interface. By preventing the issue of transactions that might be stalled for a
significant period, the interface remains available for the issue of higher priority transactions that might arrive at a
later point in time. The two signals are shown in Table E1-11:

### Table E1-11 QoS Accept signals

| Signal | Description |
| --- | --- |
| VARQOSACCEPT[3:0] | QoS acceptance level for read transactions |
| VAWQOSACCEPT[3:0] | QoS acceptance level for write transactions. |

Each signal is an output from a Subordinate and an input to a Manager that indicates the QoS value for which the
Subordinate accepts transactions. Any transactions at this QoS level or higher are accepted by the Subordinate. Any
transaction below this QoS level might be stalled for a significant time.

### Note

This specification does not define a time period during which the Subordinate is required to accept a transaction at,
or above, the QoS level indicated. However, it is expected that for a given Subordinate there will be a deterministic
maximum number of clock cycles taken to accept a transaction, after taking into account implementation aspects
such as clock domain crossing ratios.

<table>
 <tr>
  <th>In<br/>It is</th>
  <td>specification, the term VAxQOSACCEPT refers collectively to the VARQOSACCEPT and<br/>signals.<br/>permitted for a Manager interface to issue a transaction that is below the QoS level indicated by the<br/>such a transaction be stalled for a time.</td>
 </tr>
 <tr>
  <th>It is</th>
  <td>permitted for a Subordinate interface to accept a transaction that is below the QoS level indicated by the<br/>signal, but it is expected that the transaction might be subject to a significant delay.</td>
 </tr>
 <tr>
  <th>a<br/>- </th>
  <td>this specification recommends that such a transaction is not delayed indefinitely. There are several reasons for<br/>transaction to be issued on the interface, for example:<br/>A delay between a change in the QoS Acceptance value and the ability of the component to adapt to that</td>
 </tr>
 <tr>
  <th></th>
  <td>change.</td>
 </tr>
 <tr>
  <th></th>
  <td>A requirement to make progress on a transaction that is Head-of-Line Blocking a higher priority transaction.</td>
 </tr>
 <tr>
  <th></th>
  <td>A requirement to make progress on a transaction for reasons of starvation prevention.</td>
 </tr>
</table>

The VAxQOSACCEPT signal is synchronous to the interface, but it is unrelated to any other AXI channel.

The default value for the VAxQOSACCEPT signals is zero.

### E1.7

### E1.7.1 Wake-up Signaling

The wake-up signals are used to indicate that there is activity associated with the interface. These are:

- AWAKEUP

- ACWAKEUP

The Wakeup_Signals property is used to indicate whether a component supports wake-up signaling:
True Wake-up signals are supported.
False Wake-up signals are not supported. If Wakeup_Signals is not declared, it is considered False.

The signals can be routed to a clock controller, or similar component, to enable power and clocks to the connected
components. The wake-up signals must be glitch-free and generated directly from a register. They are synchronous
to the interface that it relates to, but are appropriate for crossing clock domains to a controller.

Wake-up signals must be asserted to guarantee that a transaction can be accepted, but once the transaction is in
progress the assertion or deassertion of the wake-up signal is IMPLEMENTATION DEFINED. This specification
recommends, but does not require, that the wake-up signal be deasserted when no further transactions are required.

### AWAKEUP rules and recommendations

The AWAKEUP signal is applicable to interfaces:

- AXI5

- AXI5-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

AWAKEUP is an output signal from a Manager interface and is asserted at the start of a transaction to indicate that
there is a transaction to be processed:

-

-

This specification recommends that AWAKEUP is asserted at least one cycle before the assertion of
ARVALID, AWVALID, or WVALID to prevent the acceptance of a new transaction being delayed.

It is permitted for AWAKEUP to be asserted at any point before or after the assertion of ARVALID,
AWVALID, or WVALID.

A Subordinate is permitted to wait for AWAKEUP to be asserted before asserting ARREADY,
AWREADY, or WREADY.

If AWAKEUP is asserted in a cycle where AWVALID is asserted and AWREADY is deasserted, then
AWAKEUP must remain asserted until AWREADY is asserted.

If AWAKEUP is asserted in a cycle when ARVALID is asserted and ARREADY is deasserted, then
AWAKEUP must remain asserted until ARREADY is asserted.

After theARVALID, ARREADY handshake, or the AWVALID, AWREADY handshake, the interconnect
must remain active until the transaction has completed.

It is required that the AWAKEUP signal is asserted to guarantee progress of a transition on the Coherency
Connection signaling. See Coherency Connection signaling on page E1-364:

It is permitted for AWAKEUP to be asserted at any point before or after the assertion of SYSCOREQ.
However, it is required to be asserted to guarantee the corresponding assertion of SYSCOACK. When
AWAKEUP is asserted with SYSCOREQ asserted and SYSCOACK deasserted, it must remain
asserted until SYSCOACK is asserted.

It is permitted for AWAKEUP to be asserted at any point before or after the deassertion of
SYSCOREQ. However, it is required to be asserted to guarantee the corresponding deassertion of
SYSCOACK. When AWAKEUP is asserted with SYSCOREQ deasserted and SYSCOACK
asserted, it must remain asserted until SYSCOACK is deasserted.

It is permitted, but not recommended, to assert AWAKEUP then deassert it without a transaction taking
place.

### Note

There is no requirement relating to the assertion of AWAKEUP relative to WVALID. However, for components
that can assert WVALID before AWVALID, the assertion of AWAKEUP at least one cycle before WVALID can
prevent the acceptance of a new transaction being delayed.

If a Subordinate has an AWAKEUP input, but the attached Manager does not have an AWAKEUP output, then
either:

- Tie AWAKEUP high, however this might prevent the Subordinate interface from using low-power states.

Derive AWAKEUP from AxVALID and SYSCOREQ/ACK. This method enables the Subordinate to use
low-power states, but might introduce latency while the clock is enabled.

### E1.7.2 ACWAKEUP rules and recommendations

The ACWAKEUP signal is only applicable to:

- ACE5

- ACE5-LiteDVM

ACWAKEUP is an output signal from an interconnect interface and is asserted at the start of a snoop transaction
to indicate that there is a transaction to be processed. This rule applies to either a normal coherency snoop
transaction or a DVM snoop transaction:

This specification recommends that ACWAKEUP is asserted at least one cycle before the assertion of
ACVALID to prevent the acceptance of a new snoop transaction being delayed unnecessary.

ACWAKEUP must remain asserted until the associated ACVALID / ACREADY handshake to ensure
progress of the snoop transaction.

After the ACVALID / ACREADY handshake, the Manager must remain active until the snoop transaction
has completed.

It is permitted for ACWAKEUP to be asserted at any point before or after the assertion of ACVALID.

It is permitted, but not recommended, to assert ACWAKEUP and then deassert it without ACVALID being
asserted.

### E1.8 Coherency Connection signaling

A four-phase Coherency Connection signaling scheme is added, which can safely cross clock domains. These
signals are used by a Manager to connect and disconnect from a coherency domain. When a Manager is connected
to the coherency domain, it might receive snoop requests or DVM messages on the AC channel. When
disconnected, no snoop requests or DVM messages are received.

The Coherency_Connection_Signals property is used to indicate whether a component supports the additional
signals:
True Coherency Connection signaling is supported.
False Coherency Connection signaling is not supported. If not declared, Coherency_Connection_Signals
property is considered False.

Coherency Connection signaling is only applicable to

- ACE5

- ACE5-LiteDVM

A Manager must be connected to a coherency domain before it can cache locations that must be kept
hardware-coherent. A Manager can disconnect from a coherency domain when it no longer holds cache lines that
must be kept hardware-coherent. When disconnected from a coherency domain, the Manager does not receive snoop
transactions and therefore does not need to provide any snoop responses. Disconnecting from a coherency domain
is typically used before entering a low-power state in which snoop transactions cannot be processed.

The connection to, or disconnection from, a coherency domain includes both normal coherency transactions, and
DVM transactions that are sent on the snoop channel. Throughout the rest of this section, the connection to, or
disconnection from, a coherency domain applies to whichever of these transaction types are applicable to the
component.

The following two signals are used for coherency connect and disconnect signaling:
SYSCOREQ Coherency connect request.
SYSCOACK Coherency connect acknowledge.

The usage rules are:

- SYSCOREQ and SYSCOACK must either be both present or both absent.
- No default signaling is associated with SYSCOREQ and SYSCOACK signaling.

When disconnected from coherency, a Manager must not issue allocating transactions to Shareable memory. The
following transactions are permitted:

- IO Coherent transactions:
- ReadOnce
- WriteUnique

Cache Maintenance Operation transactions:
- CleanShared
- CleanSharedPersist
- CleanInvalid
- MakeInvalid

- All Non-shareable transactions

Note

RACK and WACK signaling is still used when a component is disconnected from coherency.

### E1.8.1 Coherency Connection Handshake

SYSCOREQ and SYSCOACK must be deasserted when ARESETn is asserted. When not in reset, the following
requests are permitted:

A Manager requests to be connected to system coherency by asserting SYSCOREQ HIGH. The interconnect
indicates that coherency is enabled by asserting SYSCOACK HIGH.

The Manager requests disconnection from system coherency by deasserting SYSCOREQ LOW. The
interconnect indicates that coherency is disabled by deasserting SYSCOACK LOW.

Requests to enter and exit coherency are always initiated by the Manager.

Figure E1-4 shows the system coherency interface handshake timing:

<table>
 <tr>
  <th colspan="6">ACLK</th>
 </tr>
 <tr>
  <th rowspan="3">SYSCOREQ<br/>SYSCOACK</th>
  <td></td>
  <td rowspan="3">Coherency<br/>Connect</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>Coherency<br/>Disabled</td>
  <td>Coherency<br/>Enabled</td>
  <td>Coherency<br/>Disconnect</td>
  <td>Coherency<br/>Disabled</td>
 </tr>
</table>

### Figure E1-4 System coherency interface handshake timing

The interface signaling obeys the four-phase handshake rules:

- A Manager can only change SYSCOREQ when SYSCOACK is at the same level.

- An interconnect can only change SYSCOACK when SYSCOREQ is at the opposite level.

### Manager rules

A Manager:

- Must be able to respond to snoop transactions when it asserts SYSCOREQ HIGH.
- Must not issue a transaction that permits it to cache a coherent location until it observes SYSCOACK HIGH.

- Must not hold any cached copies of a coherent location when it deasserts SYSCOREQ LOW. A snoop that is received by the Manager, after it has deasserted SYSCOREQ, must give a snoop response indicating that the cache line is invalid.

- Must be able to respond to snoop transactions until it observes SYSCOACK LOW.

### Interconnect rules

An interconnect:

- Must be able to service transactions to a coherent location when it asserts SYSCOACK HIGH.
- Must have completed all snoop transactions to this interface before it deasserts SYSCOACK LOW.

The transactions that would permit a coherent location to be cached are:

- ReadUnique

- ReadClean

- ReadNotSharedDirty

- ReadShared

- CleanUnique

- MakeUnique

### E1.8.2 Coherency Connection signaling states

Figure E1-5 shows the state diagram for the Coherency Connection signaling.

ARESETn = 0

<table>
 <tr>
  <th>SYSCOREQ</th>
  <th>= 0</th>
  <th></th>
  <th>SYSCOREQ = 0</th>
 </tr>
 <tr>
  <td>SYSCOACK</td>
  <td>= 0</td>
  <td></td>
  <td>SYSCOACK = 1</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>SYSCOACK = 0</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>SYSCOREQ = 1</td>
  <td>SYSCOREQ</td>
  <td>= 0</td>
 </tr>
 <tr>
  <td>SYSCOREQ</td>
  <td>= 1</td>
  <td></td>
  <td>SYSCOREQ = 1</td>
 </tr>
 <tr>
  <td>SYSCOACK</td>
  <td>= 0</td>
  <td></td>
  <td>SYSCOACK = 1</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>SYSCOACK = 1</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

### Figure E1-5 Coherency Connection signaling state diagram

Table E1-12 shows a summary of the states that are associated with the system coherency interface and the
requirements for the Manager and the interconnect.

### Table E1-12 Coherency Connection signaling states

<table>
 <tr>
  <th>State SYSCOREQ SYSCOACK</th>
  <td></td>
 </tr>
 <tr>
  <th>Disabled 0 0<br/>- </th>
  <td>Must not hold any cached copies of coherent locations.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must not issue transactions that allow a coherent location</td>
 </tr>
 <tr>
  <th></th>
  <td>to be cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Not required to respond to snoop transactions.</td>
 </tr>
 <tr>
  <th></th>
  <td>Not to service transactions that allow a coherent</td>
 </tr>
 <tr>
  <th></th>
  <td>location to be cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must not issue snoop transactions.</td>
 </tr>
 <tr>
  <th>Connect 1 0<br/>- </th>
  <td>Must not issue transactions that allow a coherent location</td>
 </tr>
 <tr>
  <th></th>
  <td>to be cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must respond to snoop transactions.</td>
 </tr>
 <tr>
  <th></th>
  <td>Not required to service transactions to a coherent location.</td>
 </tr>
 <tr>
  <th>Enabled 1 1<br/>- </th>
  <td>Can issue transactions that allow a coherent location to be</td>
 </tr>
 <tr>
  <th></th>
  <td>cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must respond to snoop transactions.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must service transactions to a coherent location.</td>
 </tr>
 <tr>
  <th></th>
  <td>Can issue snoop transactions.</td>
 </tr>
 <tr>
  <th>Disconnect 0 1<br/>- </th>
  <td>Must not hold any cached copies of coherent locations.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must not issue transactions that allow a coherent location</td>
 </tr>
 <tr>
  <th></th>
  <td>to be cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Must respond to snoop transactions.</td>
 </tr>
 <tr>
  <th></th>
  <td>Not required to service transactions that allow a coherent</td>
 </tr>
 <tr>
  <th></th>
  <td>location to be cached.</td>
 </tr>
 <tr>
  <th></th>
  <td>Can complete all required snoop transactions.</td>
 </tr>
 <tr>
  <th>E1.8.3 Coherency Connection signaling and DVM<br/>A Manager that supports DVM can:</th>
  <td></td>
 </tr>
 <tr>
  <th>- Issue DVM messages on its AR channel.</th>
  <td></td>
 </tr>
 <tr>
  <th>- Receive DVM messages on its AC channel.<br/>- Issue a DVM Complete message on its AR</th>
  <td>in response to a DVM Sync received on its AC channel.</td>
 </tr>
 <tr>
  <th>A Manager must not issue any DVM messages,<br/>SYSCOREQ.</th>
  <td>DVM Complete, on its AR channel after it has deasserted</td>
 </tr>
 <tr>
  <th>is permitted to deassert SYSCOACK when all<br/>the second part of a 2-part message.</th>
  <td>requests on the AC snoop channel have completed, including</td>
 </tr>
</table>

### E1.8.4

If an interconnect has sent a DVM Sync message that requires a DVM Complete message on the AR channel, then
the interconnect is permitted to deassert SYSCOACK when all DVM requests on the AC snoop channel have
completed. The Manager is still required to send the DVM Complete transaction on the AR channel, even when
coherency is fully disconnected.

### Incompatible support for Coherency Connection signaling

Coherency Connection signaling does not have a default set of values that can be used. If one side of an interface
supports Coherency Connection signaling and the other side does not, then a third-party component, such as a power
controller, must be connected to the Coherency Connection signaling. This component is required to coordinate the
Coherency Connection signaling and it must ensure that the requirements of the signaling are met.

### E1.9 Untranslated transactions

AMBA 5 extends support of an SMMU by providing a means to identify untranslated transactions.
The Untranslated_Transactions property is used to indicate whether a component supports the required signals.
v2 The required signals are supported for version 2 of untranslated transactions.
v1 The required signals are supported for version 1.
True The required signals are supported for version 1.
False The required signals are not supported.
If Untranslated_Transactions is not declared, it is considered False.

The Untranslated Transactions version 1 extension is applicable to the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

The Untranslated Transactions version 2 extension is applicable to the following interfaces:

- AXI5

- ACE5-Lite

Support in ACE5 is for version 1 only, and has additional restrictions. See Use of Untranslated Transactions with
ACE5 on page E1-372.

Address translation is the process of translating an input address to an output address based on address mapping and
memory attribute information that is held in translation tables. This process permits agents in the system to use their
own virtual address space, but ensures that the addresses for all transactions are eventually translated to a single
physical address space for the entire system.

The use of a single physical address space is required for the correct operation of hardware coherency and therefore
the SMMU functionality is typically located before a coherent interconnect.

The additional signals that are specified in this section provide sufficient information for an SMMU to determine
the translation that is required for a particular transaction and permit different transactions on the same interface to
use different translation schemes.

All signals in the Untranslated Transactions extension are prefixed with ARMMU for read transactions and
AWMMU for write transactions.

In this specification, AxMMU indicates ARMMU or AWMMU.

### E1.9.1 Untranslated Transaction signaling

Table E1-13 shows the signals that support Untranslated Transactions.

Table E1-13 Write address channel signals that support untranslated transactions

| Signal | Width | Description |
| --- | --- | --- |
| AxMMUSECSID | 1 | Secure Stream Identifier. |
|  |  | - When deasserted indicates a Non-secure stream. |
|  |  | - When asserted indicates a Secure stream. |
|  |  | This is an optional signal, the default value is 0. |

### AxMMUSID

### AxMMUSSIDV

### AxMMUSSID

### AxMMUATST

SID_WIDTH Stream Identifier. Secure and Non-secure streams use different
name-spaces, qualified with AxMMUSECSID, so they can use the
same stream identifier values.
This is an optional signal, the default value is 0.

1

Substream Identifier Valid. Indicates that the transaction has an
substream identifier.

- When deasserted, this signal indicates that the transaction does not have a substream identifier.

- When asserted, this signal indicates that the transaction has a substream identifier.

This is an optional signal, the default value is 0.

SSID_WIDTH Substream Identifier. This signal is only valid if AxMMUSSIDV is
asserted. For a single stream, the stream with substream 0 is a
different stream from the stream with no valid substream.
This is an optional signal, the default value is 0.

1

Address Translated. Indicates that the transaction has already
undergone PCIe ATS translation. This translation might be a full or
partial translation in cases where two stages of translation are
supported.

- When deasserted, this signal indicates that the transaction has not been translated.

- When asserted, this signal indicates that the transaction has been translated.

This signal is optional for Untranslated Transactions v1, it is not
present for Untranslated Transactions v2. If not present the default
value is 0.
AxMMUATST is equivalent to AxMMUFLOW[0] when
AxMMUFLOW[1] is deasserted.

Table E1-13 Write address channel signals that support untranslated transactions (continued)

| Signal | Width | Description |
| --- | --- | --- |
| AxMMUFLOW | 2 | Indicates the SMMU flow for managing translation faults for this |
|  |  | transaction. Encoded as: |
|  |  | 0b00 Stall |
|  |  | 0b01 ATST |
|  |  | 0b10 No stall |
|  |  | 0b11 PRI |
|  |  | This signal is optional for Untranslated Transactions v2, it is not |
|  |  | present for Untranslated Transactions v1. If not present the default is |
|  |  | 0b00. |

### RRESP

3

When Untranslated_Transactions is v2, RRESP extended to 3-bits
to accommodate the signaling of an additional response.
The following response is permitted when using untranslated
transactions v2:
0b101 TRANSFAULT. Transaction was terminated
because of a translation fault which might be
resolved by a PRI request. Read data is not valid.

### BRESP

3

When Untranslated_Transactions is v2, BRESP extended to 3-bits
to accommodate the signaling of an additional response.The
following response is permitted when using untranslated
transactions v2:
0b101 TRANSFAULT. Transaction was terminated
because of a translation fault which might be
resolved by a PRI request.

### Optional signals and default values

### E1.9.2

During the building of a system, it is possible that the stream identifiers for a given component have some ID bits
provided by the component and some ID bits that are tied off for that component. This fixes the range of values in
the stream identifier name space that can be used by that component. Typically, the low-order bits are provided by
the component and the high-order bits are tied off.

Any additional identifier field bits for AxMMUSID or AxMMUSSID, that are not supplied by the component or
hard coded by the interconnect, must be tied LOW.

All signals are optional with defined default values, with the restrictions:

- ARMMUSSID and ARMMUSSIDV must either be both present or both absent.
- AWMMUSSID and AWMMUSSIDV must either be both present or both absent.

### E1.9.3 PCIe considerations

When the Untranslated_Transactions signaling is used for interfacing to PCIe Root Complex, the following
considerations apply:

- All PCIe transactions must be Non-secure. - AxMMUSECSID must either not be present, or must be tied LOW.

- For PCIe transactions:
  - AxMMUSID corresponds to the PCIe Requester ID.
  - AxMMUSSID corresponds to the PCIe PASID.
  - AxMMUSSIDV is asserted if the transaction had a PASID

prefix, otherwise it is deasserted.

### E1.9.4 Use of Untranslated Transactions with ACE5

It is possible to use address translation on untranslated transactions from an ACE5 Manager. There are restrictions,
however, depending on the type of transaction being translated.

In general, the translation process:

- Must not convert Shareable transactions into Non-shareable transactions, since this can break coherency.

Must not convert Allocating Shareable transactions into Non-allocating Shareable transactions, since this can
mislead a downstream snoop filter.

Must ensure that when converting write transactions from Non-shareable to Shareable transactions, a
WriteUnique or WriteLineUnique transaction is not outstanding at the same time as a WriteBack,
WriteClean, or WriteEvict transaction.

For transactions that are IO Coherent or Non-shareable, the following rules apply:

- The translation process is used for protection checking and can also be used for address translation.

Protection checks can result in any combination of permissions. Both read and write transactions must be
checked.

The Manager must not permit a snoop to hit a cache line that has been fetched using an IO Coherent or
Non-shareable transaction.

Transactions within this group are:
- ReadNoSnoop
- WriteNoSoop
- ReadOnce
- ReadOnceMakeInvalid
- ReadOnceCleanInvalid
- WriteUnique
- WriteLineUnique
- WriteBack to Non-shareable locations
- WriteClean N to on-shareable locations
- WriteEvict to Non-shareable locations

For transactions that are Allocating Coherent, the following rules apply:

The translation process can be used for protection checking, but must always result in either full read and
write access or no access. Read-only or write-only permissions are not supported.

The translation process must result in the same address after translation as before translation.

Shareable WriteBack, WriteClean, WriteEvict, and Evict transactions are permitted, but do not need to be
checked. They can only occur after the successful permission check of a transaction that permits the cache
line to be allocated in the cache.

A transaction that results in an error response must not be allocated in the cache.

Transactions within this group are:
- ReadShared
- ReadClean
- ReadNotSharedDirty
- ReadUnique
- CleanUnique
- MakeUnique
- WriteBack to Shareable locations
- WriteClean S tohareable locations
- WriteEvict to Shareable locations
- Evict

### E1.9.5 SMMU flows

This section describes the different SMMU flows for managing translation faults.

### Stall flow

When the Stall flow is used, software can configure the SMMU to take one of the following actions when a
translation fault occurs:

- Terminate the transaction with a SLVERR response.

- Terminate the transaction with an OKAY response, data is RAZ/WI.

Stall the translation and inform software that the translation is stalled. Software can then instruct the SMMU
to terminate the transaction, or update the page tables and retry the translation. The Manager is not aware of
the stall.

This flow enables software to manage translation faults and demand paging without the Manager being aware.
However, it has some limitations:

- The Manager can see very long transaction latency, potentially triggering timeouts.

Due to the dependence of software activity, the Stall flow can cause deadlocks in some systems.
For example, it is not recommended for use with PCIe, because of dependencies between outgoing
transactions to PCIe from a CPU, and incoming transactions from PCIe through the SMMU.

Enabling the Stall flow does not necessarily cause a stall when a translation fault occurs. Stalls only occur when
enabled by software. Software does not normally enable stalling for PCIe endpoints.

### ATST flow

The Address Translation Service Translated (ATST) flow indicates that the transaction has already been translated
by ATS. It is only used by PCIe Root Ports.

The ATST flow is indicated when AxMMUATST is asserted or AxMMUFLOW is 0b01.

### E1.9.6

### E1.9.7

When the flow is ATST, the transaction might still undergo some translation, depending on the configuration of the
SMMU. For more information on the SMMUv3 architecture, see Arm System Memory Management Unit
Architecture Specification. If a translation fault occurs, the transaction must be terminated with a SLVERR response.

When the flow is ATST, the following constraints apply:

- AxMMUSECSID must be LOW. Secure translated transactions are not supported.
- AxMMUSSIDV must be LOW. Substream IDs for translated transactions are not supported.

### NoStall flow

The NoStall flow is used by a Manager that is not able to be stalled, it is indicated when AxMMUFLOW is 0b10.

If a translation fault occurs when using this flow, the Subordinate must terminate the transaction with a SLVERR or
OKAY response, even if software has configured the device to be stalled when a translation fault occurs.

This flow is recommended for Managers such as PCIe Root Ports which might deadlock if stalling is enabled by
software.

### PRI flow

The PRI flow is designed for use with a PCIe integrated endpoint. It is indicated when AxMMUFLOW is 0b11. The
Manager uses the PRI flow to enable software to respond to translation faults without risking deadlock.

When the flow is PRI and a translation fault occurs, the transaction is terminated with a TRANSFAULT response
on BRESP or RRESP. The Manager can then use a separate mechanism to request that the page is made available,
before retrying the transaction. This mechanism is normally PCIe PRI.

When this flow is used, software enables ATS but no ATS features are required in hardware.

A transaction that uses this flow might still be terminated by the SMMU with a SLVERR, if the translation failed
for a reason which cannot be resolved by a PRI request, for example because the SMMU is incorrectly configured.

### Protocol rules

The following rules apply to Untranslated Transactions signals.

- For transactions that do not specify a substream ID, as indicated by AxMMUSSIDV deasserted. AxMMUSSID must be driven to all zeros.
- For transactions that are in a Non-secure stream, as indicated by AxMMUSECSID deasserted, AxPROT[1] must be HIGH, which indicates a Non-secure transaction.
- A TRANSFAULT is indicated using a value of 0b101 for RRESP and BRESP.

- If AWMMUFLOW is not PRI, BRESP must not be TRANSFAULT.
- If ARMMUFLOW is not PRI, RRESP must not be TRANSFAULT.
- If TRANSFAULT is used for one response beat, it must be used for all response beats of a transaction.

### StashTranslation

The Untranslated Transactions extension also supports a StashTranslation transaction. This indicates that the
translation for the given transaction address should be cached, since it is likely to be needed.

The StashTranslation transaction must be supported in any of the following cases::

- Untranslated_Transactions is True and Cache_Stash_Transactions is True

- Untranslated_Transactions is v1

- Untranslated_Transactions is v2

A StashTranslation transaction has no data transfers. The address and control information is provided on the AW
channel, and a single response is provided on the B channel. The response must be provided only after the address
has been accepted.

The following restrictions apply for the StashTranslation transaction:

No stash target is supported. If present, AWSTASHNID[10:0], AWSTASHNIDEN, AWSTASHLPID[4:0],
and AWSTASHLPIDEN must be driven LOW.

Any legal combination of AxCACHE and AxDOMAIN values is permitted. See AxCACHE and
AxDOMAIN signal combinations on page D3-177.

StashTranslation transactions must not use the same AXI ID values that are used by non-StashTranslation
transactions that are outstanding at the same time. This rule ensures that there are no ordering constraints
between StashTranslation transactions and other transactions, so a Subordinate that does not stash
translations can respond immediately.

### E1.10

### E1.10.1 Non-secure access identifiers

To support the storage and processing of protected data, AMBA 5 provides a set of signals that enable access to
particular Non-secure memory locations to be controlled. The signals supply a Non-secure Access Identifier
(NSAID) alongside the transaction request. The NSAID can be checked to permit or deny access to a memory
location.

The NSAccess_Identifiers property is used to indicate whether a component supports these additional signals:
True NSAID signaling is present on the interface.
False NSAID signaling is not present on the interface. If NSAccess_Identifiers is not declared, it is
considered False.

The non-secure access identifiers extension is applicable to the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

### NSAID signaling

Table E1-14 shows the signals that are associated with each channel.

Table E1-14 NSAID signals associated with each channel

| Signal | Source | Description |
| --- | --- | --- |
| AWNSAID[3:0] | Manager | Non-secure Access Identifier for a write transaction. |
| ARNSAID[3:0] | Manager | Non-secure Access Identifier for a read transaction. |
| CRNSAID[3:0]a | Manager | Non-secure Access Identifier for a snoop response. |

1. Implemented in ACE5 only.

If the NSAccess_Identifiers property is True, then AWNSAID and ARNSAID must both be present on the
interface. CRNSAID can only be included on ACE5 interfaces and is optional when NSAccess_identifiers is True.

AWNSAID and ARNSAID are provided alongside write and read transaction requests, respectively. CRNSAID is
supplied alongside a snoop response and is used to indicate the NSAID value that was originally used to fetch data
that is held in the cache of a coherent Manager. CRNSAID is only used for ACE5 Managers that can provide data
in response to a snoop transaction.

A 4-bit NSAID value supports up to 16 unique identifiers. For each NSAID there is a set of access permission that
is defined which determine how locations in memory are permitted to be accessed.

The access permissions can be:

- No access

- Read-only access

- Write-only access

- Read/write access

The mechanism that is used to define the access permissions for each NSAID is IMPLEMENTATION DEFINED.
However, this mechanism is typically implemented using some form of Memory Protection Unit (MPU).

It is permitted for transactions with different NSAID values to have access to overlapping locations in memory. It
is permitted for transactions with different NSAID values to have any combination of access permissions for a given
location in memory.

A default NSAID value of zero is supported. Typically, Managers use a default NSAID value of zero when accessing
data that is not protected, or when they do not have an assigned NSAID value.

If a Manager is required to use a single NSAID value, then it is permitted for NSAID signals to be tied to a fixed
value.

The NSAID signals are only used for Non-secure transactions.

For Secure transactions, as indicated by AxPROT[1] = 0, a value of zero must be used for NSAID.

### E1.10.2 Caching and NSAID

Where caching and system coherency is performed upstream of permission checking, accesses with different
NSAID values that pass data between them must be subjected to permission checks. The rules that are associated
with NSAID use and coherency are as follows:

When an agent caches a line of data that has been fetched using a particular NSAID value, it must ensure that
any subsequent write to main memory or any response to a snoop uses the same NSAID value. This rule
ensures that a Manager cannot move a cache line of data from one protected region to another.

For a read request with a given NSAID value, if a snoop is used to obtain the data:
- If the NSAID value of the snoop response matches the read request then data can be provided directly.
- If the NSAID value of the snoop response does not match the read request, then the cache line must
first be written to memory using the NSAID value obtained via the snoop response, and then read from
memory using the NSAID value of the original request.

### Note

The write and subsequent read are only required to reach a point at which permission checking has
occurred.

Snoop transactions that invalidate cached copies, such as MakeInvalid, must not be used if memory
protection is used. All such snoop transactions must be replaced with transactions that also clean the cache
line to main memory, such as CleanInvalid.

Any interconnect-generated write to main memory that occurs as the result of a snoop must use the NSAID
value that is obtained from the snoop response.

-

-

If a single Manager can issue transactions with multiple NSAID values, it must ensure that internal accesses
to cached copies use the NSAID value that was used to fetch the cache line initially:

An access that has a cache line hit with the same address, but a different NSAID value, must clean and
invalidate the cache line before refetching the cache line with the appropriate NSAID value. This
process ensures that a protection check is performed.

If it is guaranteed that the Manager never accesses the same cache line with a different NSAID value,
clean and invalidation operations are not necessary.
This guarantee can be by design or be assured by using appropriate cache maintenance operations.

Appropriate cache maintenance must be performed when changing the access permissions for NSAID
values.

### Note

It is permitted for a Manager to write to a cache line when that agent does not have write permission to the location.
It is also permitted for the updated cache line to be passed to other Managers using the same NSAID value.
However, it is not permitted for the update to propagate to main memory or to an access using a different NSAID
value.

### E1.11 Read data chunking

The read data chunking option enables a Subordinate interface to send read data for a transaction in any order using
a 128 bit granule. The start address might be used as a hint to determine which chunk to send first, but the
Subordinate is permitted to return data in any order.

The property Read_Data_Chunking is used to indicate whether an interface supports the return of read data in
reorderable chunks:

True Read data reordering is supported; the interface includes the chunking signals.

Read data reordering is not supported; the interface does not include the chunking signals and read
data must be sent in-order.

False

If Read_Data_Chunking is not declared, it is considered False.

The Read_Data_Chunking property is supported in the following interfaces:

- AXI5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

To enable read data chunking, signals are added to the read address and data channel.

Table E1-15 Signals that enable read data chunking

| Signal | Source Width | Description |
| --- | --- | --- |
| ARCHUNKEN | Manager 1 | Read data chunking enable. |
|  |  | If asserted, read data for this transaction can be |
|  |  | returned out of order in 128 bit chunks. |
| RCHUNKV | Subordinate 1 | Indicates the validity of RCHUNKNUM and |
|  |  | RCHUNKSTRB. |
|  | Subordinate 8 (128-bit read data) 7 (256-bit read data) | Read data chunk number. Indicates the chunk number being transferred. |
|  | 6 (512-bit read data) | Chunks are numbered incrementally from zero, |
|  | 5 read | according to the data width and base address of the |
|  |  | transaction. |
|  |  | For read data widths of 64 bits or smaller, this signal |
|  |  | can be 1 bit wide or omitted. |
|  | Subordinate 2 (256-bit read data) 4 (512-bit read data) | Read data chunk strobe. Indicates the read data chunks that are valid for this |
|  | 8 (1024-bit read data) | transfer. |
|  |  | Each bit corresponds to 128 bits of data. The least |
|  |  | significant bit of RCHUNKSTRB corresponds to |
|  |  | the least significant 128 bits of RDATA. |
|  |  | For read data widths of 128 bits or smaller, this |
|  |  | signal can be 1 bit wide or omitted. |
| E1.11.1 Read data In the read - - - - | protocol rules chunking protocol, all the following rules must only be asserted for ARSIZE is equal to the data bus width or ARSIZE is 128 bits or larger. ARADDR is aligned to 16 bytes. | apply: with the following attributes: is one beat. |

- ARBURST is INCR or WRAP.
- ARSNOOP is ReadNoSnoop, ReadOnce, ReadOnceCleanInvalid or ReadOnceMakeInvalid.

The ID value must be unique-in-flight, which means:
- ARCHUNKEN can only be asserted if there are no outstanding read transactions using the same
ARID value.

The Manager must not issue a request on the read channel with the same ARID as an outstanding
request that had ARCHUNKEN asserted.

-

If present on the interface, ARIDUNQ must be asserted.

-

If ARCHUNKEN is deasserted, RCHUNKV must be deasserted for all response beats of the transaction.

If ARCHUNKEN is asserted, RCHUNKV can be asserted for response beats of the transaction.

RCHUNKV must be the same for every response beat of a transaction.

When RVALID and RCHUNKV are asserted, RCHUNKNUM must be between zero and ARLEN.

When RVALID and RCHUNKV are asserted, RCHUNKSTRB must not be zero.

When RVALID and RCHUNKV are asserted, RLAST must only be asserted for the final response beat of
the transaction, irrespective of RCHUNKNUM and RCHUNKSTRB.

When RVALID is asserted and RCHUNKV is deasserted, RCHUNKNUM and RCHUNKSTRB can take
any value.

The number of data chunks transferred must be consistent with ARLEN and ARSIZE, the number of bytes
transferred in a burst is the same whether chunking is enabled or not. For unaligned transactions, chunks at
addresses lower than ARADDR are not transferred.

### E1.11.2 Interoperability

If a Manager supports read data chunking, then downstream interconnect and Subordinates can reduce their
buffering if they also support chunking. An interconnect which connects to components with a mixture of chunking
support can drive ARCHUNKEN and RCHUNKV according to the capabilities of the attached components.

When connecting interfaces with different values for the Read_Data_Chunking property, the following rules apply:

Table E1-16 Connecting interfaces with different values for Read_Data_Chunking

|  | Subordinate: False | Subordinate: True |
| --- | --- | --- |
| Manager: False | ARCHUNKEN is not present. RCHUNKV is not present. RCHUNKNUM is not present. RCHUNKSTRB is not present. Full data beats are sent in natural order. | Subordinate ARCHUNKEN input is tied low. Subordinate RCHUNKV output is unconnected. Subordinate RCHUNKNUM output is unconnected. Subordinate RCHUNKSTRB output is unconnected. Full data beats are sent in natural order. |
| Manager: True | Manager ARCHUNKEN output is unconnected. Manager RCHUNKV input is tied low. Manager RCHUNKNUM input is tied. Manager RCHUNKSTRB input is tied. Full data beats are sent in natural order. | Chunking signals are connected. Read data can be reordered and sent in chunks. |

### E1.11.3 Chunking examples

In these examples, each row in the figure represents a transfer and the shaded cells indicate bytes that are not
transferred.

Figure E1-6 shows a transaction on a 256-bit width read data bus, where:

- ARADDR is 0x00.

- ARLEN is 2 beats.

- ARSIZE is 256 bits.

- ARBURST is INCR.

- st 1 transfer

- nd 2 transfer

- rd 3 transfer

- th 4 transfer

<table>
 <tr>
  <th>255 128</th>
  <td>127 0</td>
 </tr>
 <tr>
  <th></th>
  <td>0x20</td>
 </tr>
 <tr>
  <th>0x10</th>
  <td></td>
 </tr>
 <tr>
  <th>0x30</th>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td>0x00</td>
 </tr>
</table>

- RCHUNKNUM = 1; RCHUNKSTRB = 0b01; RLAST = 0

- RCHUNKNUM = 0; RCHUNKSTRB = 0b10; RLAST = 0

- RCHUNKNUM = 1; RCHUNKSTRB = 0b10; RLAST = 0

- RCHUNKNUM = 0; RCHUNKSTRB = 0b01; RLAST = 1

- RDATA

- Figure E1-6 Example of read data returned in 128 bit chunks

Figure E1-7 shows transactions on a 256-bit width data read bus, where:

- ARADDR is 0x10.
- ARLEN is 2 beats.
- ARSIZE is 256 bits.
- ARBURST is INCR.

| 255 128 | 127 0 |
| --- | --- |
| 0x10 |  |
| 0x30 | 0x20 |

1st transfer

2nd transfer

RCHUNKNUM = 0; RCHUNKSTRB = 0b10; RLAST = 0

RCHUNKNUM = 1; RCHUNKSTRB = 0b11; RLAST = 1

RDATA

Figure E1-7 Example with an unaligned address and a mixture of 128-bit and 256-bit chunks

Figure E1-8 shows transactions on a 128-bit width data read bus, where:

- ARADDR is 0x10.

- ARLEN is 4 beats.

- ARSIZE is 128 bits.

- ARBURST is WRAP.

- RCHUNKSTRB is not present.

The Subordinate uses the start address as a hint and sends the chunk at 0x10 first.

RCHUNKNUM numbering is not dependent on whether the burst is INCR or WRAP.

<table>
 <tr>
  <th></th>
  <td>127</td>
  <td>0</td>
  <td></td>
 </tr>
 <tr>
  <th>1st transfer</th>
  <td>0x10</td>
  <td></td>
  <td>RCHUNKNUM = 1; RLAST = 0</td>
 </tr>
 <tr>
  <th>2nd transfer</th>
  <td>0x30</td>
  <td></td>
  <td>RCHUNKNUM = 3; RLAST = 0</td>
 </tr>
 <tr>
  <th>3rd transfer</th>
  <td>0x00</td>
  <td></td>
  <td>RCHUNKNUM = 0; RLAST = 0</td>
 </tr>
 <tr>
  <th>4th transfer</th>
  <td>0x20</td>
  <td></td>
  <td>RCHUNKNUM = 2; RLAST = 1</td>
 </tr>
 <tr>
  <th></th>
  <td>RDATA</td>
  <td></td>
  <td></td>
 </tr>
</table>

### Figure E1-8 Example of a wrapping burst

### E1.12 Read interleaving property

Read data from transactions with different ARID values can be interleaved within the AXI ordering model.
Some AXI Manager and interconnect components can be more efficiently designed if it is determined at design-time
whether the attached Subordinate interface will interleave read data from different transactions.

The property Read_Interleaving_Disabled is used to indicate whether an interface supports the interleaving of read
data beats from different transactions.

For Manager interfaces, Read_Interleaving_Disabled indicates:
True The Manager is not capable of receiving read data that is interleaved. The connected Subordinate
must have the property as True.
False The Manager can receive read data that is interleaved. This is legacy AXI-compliant behavior.

For Subordinate interfaces, Read_Interleaving_Disabled indicates:
True The Subordinate is guaranteed not to interleave read data.
False The Subordinate might interleave data from read transactions with different
connected Manager must have the property as False.

ARID values. The

If the Read_Interleaving_Disabled property is not declared, it is considered to be False.

For some interfaces, this property can be used as a configuration control, for others it is a capability indicator. All
Managers that issue bursts with different IDs must be designed to accept interleaved data. Managers might use a
configuration option to disable interleaving as an optimization, when the attached Subordinate supports the
disabling of interleaving.

The Read_Interleaving_Disabled property is supported in the following interfaces:

- AXI5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

### E1.13 Unique ID indicator

The unique ID indicator is an optional flag that indicates when a request on the read and write address channels is
using an AXI identifier that is unique for in-flight transactions. A corresponding signal is also on the read and write
response channels to indicate that a transaction is using a unique ID.

The unique ID indicator can be used downstream of the AXI Manager to determine when a transaction needs to be
ordered with respect to other transactions from that Manager. Transactions that do not require ordering might not
require tracking in downstream components. Responses with the indicator set are not required to look up in the
trackers.

The Unique_ID_Support property is used to indicate if an interface supports the Unique ID Indicator:

True

The interface has the unique ID indicator on read and write address and response channels.

### False

The interface does not have unique ID indicator signals.
If the Unique_ID_Support property is not declared, it is considered to be False.

The Unique ID Indicator is supported in the following interfaces:

- AXI5

- AXI5-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

Table E1-17 shows the signals that are added to provide unique ID indication.

Table E1-17 Signals for unique ID indication

| Signal | Source | Description |
| --- | --- | --- |
| ARIDUNQ | Manager | Read address channel unique ID indicator, active HIGH. |
| RIDUNQ | Subordinate | Read data channel unique ID indicator, active HIGH. |
| AWIDUNQ | Manager | Write address channel unique ID indicator, active HIGH. |
| BIDUNQ | Subordinate | Write response channel unique ID indicator, active HIGH. |

The following rules apply to the unique ID indicator:

When ARIDUNQ is asserted, there must be no outstanding read transactions from this Manager with the
same ARID value.

A Manager must not issue a read request with the same ARID as an outstanding read transaction that had
ARIDUNQ asserted.

If ARIDUNQ is deasserted for a request, the corresponding RIDUNQ signals must be deasserted for all
response beats for that transaction.

If ARIDUNQ is asserted for a request, the corresponding RIDUNQ signals must be asserted for all response
beats for that transaction.

When AWIDUNQ is asserted, there must be no outstanding write transactions from this Manager with the
same AWID value.

A Manager must not issue a write request with the same AWID as an outstanding write transaction that had
AWIDUNQ asserted.

If AW DUNQ is deasserted for a request, the corresponding BIDUNQ signal must be deasserted for all
response beats for that transaction.

If AW DUNQ is asserted for a request, the corresponding BIDUNQ signal must be asserted for all response
beats for that transaction.

A transaction is outstanding from the cycle that had AxVALID asserted until the cycle when the final response
transfer is accepted by the Manager. If an interface includes BCOMP, the transaction is considered to be
outstanding until a response is received with BCOMP asserted.

An Atomic transaction is outstanding until both write and read responses are accepted by the Manager.

Some transaction types specify that AxIDUNQ is required to be asserted, if present. If not specified, asserting
AxIDUNQ is optional, even if there are no outstanding transactions using the same AxID.

### E1.14 Memory Partitioning and Monitoring (MPAM)

MPAM is a technology for partitioning and monitoring memory system resources for physical and virtual machines.
The full MPAM architecture is described in the Armv8.4 extensions.

Each MPAM-enabled Manager adds MPAM information to its read and write requests. The MPAM information is
propagated through the system to memory components, where it can be used to influence resource allocation
decisions. Monitoring memory usage based on MPAM information can also enable the tuning of performance and
accurate costing between machines.

The MPAM_Support property is used to indicate whether an interface supports MPAM:

MPAM_9_1 The interface is enabled for partitioning and monitoring, it must include the MPAM signal on all
address channels. The width of PARTID is 9 and PMG is 1.

### False

The interface is not MPAM-enabled. No MPAM signals are present on the interface.
If the MPAM_Support property is not declared, it is considered to be False.

The MPAM extension is supported in the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

### E1.14.1 MPAM signaling

When MPAM_Support is MPAM_9_1, the MPAM signaling is shown in Table E1-18.

Table E1-18 MPAM signaling

| Signal |  | Source | Description |  |
| --- | --- | --- | --- | --- |
|  |  | Manager | Read address | MPAM information |
|  |  | Manager | Write address | MPAM information |
| The MPAM |  | has three | They are mapped | the MPAM signals is shown in Table E1-19. Table E1-19 MPAM |
| Field |  |  | Width | Default Mapping |
| MPAM_NS |  | indicator | 1 | AxPROT[1] AxMPAM[0] |
| PARTID |  | identifier | 9 | 0x000 AxMPAM[9:1] |
| PMG |  | monitor | 1 | 0b0 AxMPAM[10] |

For details on how to use MPAM information, refer to the MPAM architecture document.

For DVM operations, MPAM values do not apply and the ARMPAM signal can take any value.

### E1.14.2 MPAM component interactions

Implementation of MPAM technology has impacts on:

- Manager components

- Interconnect components

- Subordinate components

### Manager components

Manager components that are MPAM-enabled must drive MPAM signals when the corresponding AxVALID is
asserted. Values used are IMPLEMENTATION DEFINED for all transaction types. It is expected, but not required,
that a Manager use the same sets of values for read and write requests. A Manager might not use all the PARTID or
PMG values that can be signaled on the AXI interface.

If a Manager component is included in an MPAM-enabled system, but does not support MPAM signaling, then the
system must add the MPAM information. Default values are shown in Table E1-19 on page E1-385. If a Manager
is required to drive MPAM_NS differently to AxPROT[1], it must include AxMPAM signals.

### Interconnect components

MPAM identifiers have global scope. There is no requirement for interconnect components to make MPAM
identifiers unique. When an interconnect Manager interface is connected to an MPAM-enabled Subordinate, it can
use propagated values or IMPLEMENTATION DEFINED values.

### Subordinate components

A Subordinate component that is MPAM-enabled can use the MPAM information for memory partitioning and
monitoring. MPAM signals are sampled when the corresponding AxVALID is asserted.

If an attached Manager does not support MPAM, the system must supply a value for the MPAM information
required for the interface. Values used are IMPLEMENTATION DEFINED.

### E1.15 Memory tagging

The Memory Tagging Extension (MTE) provides a mechanism that can be used to detect memory safety violations.
When a region of memory is allocated for a particular use, it is given an Allocation Tag value. When the memory
is subsequently accessed, a Physical Tag value is provided that corresponds to the physical address of the access. If
the Physical Tag does not match the Allocation Tag, a warning is generated.

Allocation Tags are stored in the memory system and can be cached in the same way as data. Each tag is 4 bits and
is associated with a 16-byte aligned address location.

The following operations are supported:

Updating the Allocation Tag value using a write transaction, with or without updating the associated data
value.

Reading of data with associated Allocation tag. The Requestor can then perform the check of Physical Tag
against the Allocation Tag.

Writing to memory with a Physical Tag to be compared with the Allocation Tag. The result is indicated in the
transaction response.

When memory tagging is supported in a system, it is not required that every transaction uses memory tagging. It is
also not required that every component in the system supports memory tagging.

The Memory Tagging Extension architecture is described as part of the Architecture Reference Manual v8.5.

### E1.15.1 MTE support

The MTE_Support property is used to indicate that a component supports the Memory Tagging Extension.

### Standard

Memory tagging is supported on the interface, all MTE signals are present.

### Basic

Memory tagging is supported on the interface at a basic level. A limited set of tag operations are
permitted. BTAGMATCH is not present. BCOMP is not required.

### False

Memory tagging is not supported on the interface and no MTE signals are present. If MTE_Support
is not declared, it is considered False.

The MTE_Support property can be set for the following interface types:

- ACE5-Lite

- ACE5-LiteDVM (Basic only)

- AXI5

MTE_Support must be False on interfaces with a data width smaller than 32 bits.

Table E1-20 shows compatibility between Manager and Subordinate interfaces, according to the values of the
MTE_Support property.

Table E1-20 MTE_Support

Manager: False

Manager: Basic

<table>
 <tr>
  <th></th>
  <th>Not compatible.</th>
  <th>Compatible.</th>
 </tr>
 <tr>
  <td></td>
  <td>If the Manager uses</td>
  <td></td>
 </tr>
 <tr>
  <td>Standard</td>
  <td>the Match</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>response will not be</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>protocol-compliant.</td>
  <td></td>
 </tr>
</table>

Subordinate: Subordinate: Subordinate:
False Basic Standard

Compatible. Compatible. Compatible.

Protocol compliant.
The Subordinate
ignores AxTAGOP,
so write tag values
are lost and read tag
values are static.

Compatible. Compatible.

### E1.15.2 MTE signaling

Table E1-21 shows the signals that are required to support MTE.

Table E1-21 MTE Signaling

| Signal | Width | Description |
| --- | --- | --- |
| ARTAGOP | 2 | Read request tag operation, encoded as: |
|  |  | 0b00 Invalid |
|  |  | 0b01 Transfer |
|  |  | 0b10 Reserved |
|  |  | 0b11 Fetch |

RTAG ceil(DATA_WIDTH/128)*4 The tag that is associated with read data.
There is a 4-bit tag per 128 bits of data, with a minimum
of 4 bits.
RTAG[4n-1:4(n-1)] corresponds to
RDATA[128n-1:128(n-1)].
RTAG has the same validity rules as RDATA.

| AWTAGOP | 2 | Write request tag operation, encoded as: |
| --- | --- | --- |
|  |  | 0b00 Invalid |
|  |  | 0b01 Transfer |
|  |  | 0b10 Update |
|  |  | 0b11 Match |

WTAG ceil(DATA_WIDTH/128)*4 The tag that is associated with write data.
There is a 4-bit tag per 128 bits of data, with a minimum
of 4 bits.
WTAG[4n-1:4(n-1)] corresponds to
WDATA[128n-1:128(n-1)].
WTAG has the same validity rules as WDATA.

### Signal Width

WTAGUPDATE ceil(DATA_WIDTH/128)

| BTAGMATCH | 2 | Indicates the result of a tag comparison on a write |
| --- | --- | --- |
|  |  | transaction: |
|  |  | 0b00 Not a match transaction |
|  |  | 0b01 Match result in separate response |
|  |  | 0b10 Fail |
|  |  | 0b11 Pass |

### BCOMP 1

### Table E1-21 MTE Signaling (continued)

### Description

Indicates which tags must be written to memory in an
Update operation.

- If a bit is asserted, then the corresponding tags must be written to memory.

- If a bit is deasserted, then the corresponding tags are invalid.

There is 1 bit per 4 bits of tag.
WTAGUPDATE[n] corresponds to WTAG[4n+3:4n].
WTAGUPDATE bits outside of the transaction
container must be deasserted.
For operations other than Update, WTAGUPDATE
must be deasserted. It can be asserted or deasserted for
Update operations.

Indicates that the write is observable.
This signal is also required for persistent CMOs on the
write channels.

### E1.15.3 Caching tags

Allocation Tags that are cached must be kept hardware-coherent. The coherence mechanism is the same as data
coherence.

Applicable tag cached states are: Invalid, Clean, and Dirty. A line that is either Clean or Dirty is Valid.

Constraints on the combination of data cache state and tag cache state are:

- Tags can be Valid only when data is Valid.

- Tags can be Invalid when data is Valid.

- When a cached line is evicted and tags are Dirty, then it is permitted to treat clean data that is evicted as dirty.

- When Dirty tags are evicted from a cache, they must be either written back to memory or passed dirty to another cache.

- When Clean tags are evicted from a cache, they can be sent to other caches or dropped silently.

- A CMO which hits a line with Valid tags applies to the data and the tag.

- When a MakeInvalid or ROMI transaction hits a line with dirty tags, the tags must be written back to memory.

### E1.15.4 Transporting tags

Tag values are transported using the RTAG signal when ARTAGOP is not Invalid.

Tag values are transported using the WTAG signal when AWTAGOP is not Invalid.

When transporting tags, the following rules apply in addition to other constraints based on the transaction type:

- The transaction must be cache-line-sized or smaller.

- AxBURST must be INCR or WRAP, not FIXED.

The transaction must be to Normal Write-Back memory, which means:
- AxCACHE[3:2] is not 0b00
- AxCACHE[1:0] is 0b11

-

-

-

The ID value must be unique-in-flight, which means:
- A read with tag Transfer or Fetch can only be issued if there are no outstanding read transactions using
the same ARID value.

A Manager must not issue a request on the read channel with the same ARID as an outstanding read
with tag Transfer or Fetch.

- If present, ARIDUNQ must be asserted for a read with tag Transfer or Fetch.
- A write with tag Transfer, Update or Match can only be issued if there are no outstanding write
transactions using the same AWID value.

A Manager must not issue a request on the write channel with the same AWID as an outstanding write
with tag Transfer, Update, or Match.

If present, AWIDUNQ must be asserted for a write with tag operations Transfer, Update, or Match.

For data widths wider than 128 bits, the tag signal carries multiple tags. The tags are driven appropriate to
the data being transported, with the least significant tag bits used to transport the tag for the least significant
128 bits of data.

For read transactions that use read data chunking, only tags which correspond to valid chunk strobes are
required to be valid.

For write transactions where multiple beats address the same tag, WTAG and WTAGUPDATE values must
be consistent for each 4-bit tag that is accessed by the transaction.

### E1.15.5 Reads with tags

A read can request that Allocation Tags are returned along with data, which is determined by the value of
ARTAGOP. Table E1-22 shows reads with tags operations.

### Table E1-22 Reads with tags operations

<table>
 <tr>
  <th></th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Invalid</th>
  <td>0b00</td>
  <td>Tags are not required to be returned with the data.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>In the response to this request, RTAG is invalid and must be zero.</td>
 </tr>
 <tr>
  <th>Transfer</th>
  <td>0b01</td>
  <td>Each beat of read data must have a valid tag value.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>Tags must be sent for every 16-byte granule that is accessed, even if</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>the address is not aligned to 16 bytes.</td>
 </tr>
 <tr>
  <th>-</th>
  <td>0b10</td>
  <td>Reserved.</td>
 </tr>
 <tr>
  <th>Fetch</th>
  <td>0b11</td>
  <td>Only tags are required to be fetched. Data is not required to be valid</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>and must not be used by the Manager. Transactions using Fetch must</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>be cache line sized.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>Tags must be sent for every 16-byte granule that is accessed.</td>
 </tr>
 <tr>
  <th>Table E1-23 on</th>
  <td>E1-391</td>
  <td>tag operations that are legal for read transactions.</td>
 </tr>
</table>

Transactions that can only be signaled on ACE interfaces are not included in the table because MTE_Support cannot
be enabled for ACE interfaces.

### Table E1-23 Legal tag operations for read transactions

<table>
 <tr>
  <th>Transaction</th>
  <td>MTE_Support = Basic<br/>Invalid Transfer Fetch</td>
  <td>MTE_Support = Standard<br/>Invalid Transfer Fetch</td>
 </tr>
 <tr>
  <th>ReadNoSnoop</th>
  <td>Y Y -</td>
  <td>Y Y Y</td>
 </tr>
 <tr>
  <th>ReadOnce</th>
  <td>Y Y -</td>
  <td>Y Y -</td>
 </tr>
 <tr>
  <th>ReadOnceCleanInvalid</th>
  <td>Y - -</td>
  <td>Y - -</td>
 </tr>
 <tr>
  <th>ReadOnceMakeInvalid</th>
  <td>Y - -</td>
  <td>Y - -</td>
 </tr>
 <tr>
  <th>CleanInvalid / MakeInvalid</th>
  <td>Y - -</td>
  <td>Y - -</td>
 </tr>
 <tr>
  <th>CleanShared / CleanSharedPersist</th>
  <td>Y - -</td>
  <td>Y - -</td>
 </tr>
 <tr>
  <th>DVM Message / Complete</th>
  <td>Y - -</td>
  <td>Y - -</td>
 </tr>
</table>

### E1.15.6 Writes with tags

Table E1-24 shows the write tag operations that are defined.

Table E1-24 Writes with tag operations

<table>
 <tr>
  <th></th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Operation</th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Invalid</th>
  <td>0b00</td>
  <td>The tags in the write are not valid; no tag updating or checking is</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>required. WTAGUPDATE must be deasserted.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>WTAG must be zero.</td>
 </tr>
 <tr>
  <th>Transfer</th>
  <td>0b01</td>
  <td>The tags are Clean. Tag check does not need to be performed. The</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>of the write can cache the if it is the data in</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>its cache.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>WTAGUPDATE must be deasserted.</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>WTAG bits must be valid for every byte in the transaction container.</td>
 </tr>
</table>

Update

Match

0b10

0b11

Tag values have been updated and are dirty; the tags in memory must
be updated, according to WTAGUPDATE.
WTAGUPDATE can have any number of bits asserted, including
none.
Tags that are only partially addressed in the transaction must have
WTAGUPDATE deasserted.
WriteUniqueFull and WriteFullCMO with Update must have all
associated WTAGUPDATE bits asserted.
WTAG must be valid for every associated WTAGUPDATE bit that
is asserted.

The tags in the write must be checked against the Allocation Tag
values that are obtained from memory. The Match operation must be
performed for all tags where any corresponding write data strobes
are asserted. It is required to update memory with the data, even if
the match fails.
WTAGUPDATE must be deasserted.
WTAG bits must be valid for byte lanes that are enabled by
WSTRB.
For interfaces with more than 4 bits of tags, the Match operation is
performed only on those tags that correspond to active byte lanes.

Table E1-25 indicates which tag operations are legal for which write transactions. The asterisk (*) indicates all
variants of the transaction.

Table E1-25 Legal tag operations for write transactions

<table>
 <tr>
  <th>Transaction</th>
  <td>MTE_Support = Basic<br/>Invalid Transfer Update Match</td>
  <td>MTE_Support = Standard<br/>Invalid Transfer Update Match</td>
 </tr>
 <tr>
  <th>WriteNoSnoop</th>
  <td>Y - Y -</td>
  <td>Y Y Y Y</td>
 </tr>
 <tr>
  <th>WriteUnique*</th>
  <td>Y - Y -</td>
  <td>Y - Y -</td>
 </tr>
 <tr>
  <th>Atomic transaction</th>
  <td>Y - - -</td>
  <td>Y - - Y</td>
 </tr>
 <tr>
  <th>CMO</th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Write*CMO</th>
  <td>Y - - -</td>
  <td>Y Y Y -</td>
 </tr>
</table>

### Table E1-25 Legal tag operations for write transactions (continued)

<table>
 <tr>
  <th>Transaction</th>
  <td>MTE_Support = Basic<br/>Invalid Transfer Update Match</td>
  <td>MTE_Support = Standard<br/>Invalid Transfer Update Match</td>
 </tr>
 <tr>
  <th>WriteZ ro</th>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>WriteUniqueStash*</th>
  <td>Y - - -</td>
  <td>Y - - -</td>
 </tr>
 <tr>
  <th>StashOnce*</th>
  <td>Y - - -</td>
  <td>Y - - -</td>
 </tr>
 <tr>
  <th>StashTranslation</th>
  <td>Y - - -</td>
  <td>Y - - -</td>
 </tr>
 <tr>
  <th>Prefetch</th>
  <td>Y - - -</td>
  <td>Y Y - -</td>
 </tr>
</table>

Write transactions with a tag Match operation (AWTAGOP is 0b11) have two parts to the response:

- A Completion response, which indicates that the write is observable.
- A Match response, which indicates whether the tag comparison passes or fails.

A two-part response enables components with separate data and tag storage parts to respond independently. The two
parts can be optionally combined into a single response beat.

Response beats can be sent in any order.

### Completion response

The Completion response indicates that the write is observable. It has the following rules:

- BCOMP must be asserted.

- BTAGMATCH must be 0b01 (Match result in separate response).

- BID must have the same value as AWID.
- If loopback signaling is supported, BLOOP must have the same value as AWLOOP.
- BRESP can be OKAY, EXOKAY, SLVERR, or DECERR.
- The Completion response must follow normal response ordering rules.
- The ID value can be reused when this response is received.

### Match response

The Match response indicates the result of the tag comparison on a write.

- If the tags match for every beat of the entire transaction, then the response is Pass.
- If any bits of any tags in the transaction do not match those already stored, then the response is Fail.

A Match response has the following rules:

- BCOMP must be deasserted.
- BTAGMATCH must be 0b11 (Pass) or 0b10 (Fail).

- BID must have the same value as AWID.

- BLOOP can take any value, it is not required to have

- BRESP can be OKAY, SLVERR, or DECERR.

- The Match response has no ordering requirements, it can beats.

the same value as AWLOOP.

overtake or be overtaken by any other response

### Combined response

A Subordinate can optionally combine the two responses into a single beat. The following rules apply:

- BCOMP must be asserted.
- BTAGMATCH must be 0b11 (Pass) or 0b10 (Fail).

- BID must have the same value as AWID.

- If loopback signaling is supported, BLOOP must have the same value as AWLOOP.

- BRESP can be OKAY, EXOKAY, SLVERR, or DECERR.

- The combined response must follow normal response ordering rules.

- The ID value can be reused when this response is received.

Table E1-26 summarizes possible responses to a Match operation:

### Table E1-26 Possible responses to a Match operation

|  | BCOMP | Description |
| --- | --- | --- |
| 0b00 | 0 | Not legal |
| 0b00 | 1 | Not legal |
| 0b01 | 0 | Not legal |
| 0b01 | 1 | Completion response, part of a two-part response |
| 0b10 | 0 | Match Fail, part of a two-part response |
| 0b10 | 1 | Match Fail or MTE Match not supported, one-part response |
| 0b11 | 0 | Match Pass, part of a two-part response |
| 0b11 | 1 | Match Pass, one-part response |

### E1.15.7 MTE and Atomic transactions

An Atomic transaction to a location that is protected with memory tagging can use a write Match operation. Atomic
transactions cannot be used with Transfer or Update operations.

For AtomicCompare transactions of 32 bytes, the same tag value must be used for tag bits associated with the
compare and swap bytes.

AtomicCompare transactions with Match can be 16 bytes or 32 bytes. If the transaction is 32 bytes, the same tag
value must be used for tag bits associated with the compare and swap bytes.

Read data that is returned within an Atomic Transaction does not have valid RTAG values, so RTAG is
recommended to be zero.

### E1.15.8 MTE and Prefetch transactions

A Prefetch transaction with AWTAGOP of Transfer indicates that the data should be prefetched with tags if
possible. A Prefetch transaction has no write data, so no tag Transfer operation occurs within the transaction.

### E1.15.9 MTE and Poison

There is no poison signaling directly associated with Allocation Tags. When writing a tag with poisoned data, the
stored tag might be marked as poisoned. The exact mechanism for this is IMPLEMENTATION DEFINED.

### E1.15.10 Memory tagging interoperability

When an MTE operation is performed to a memory location that does not support memory tagging, the resultant
data must be the same as if a non-MTE operation was performed to that location.

- For a read with Transfer or Fetch, RTAG is recommended to be zero.

- For a write with Transfer or Update, the data must be written normally. The tag is discarded.

For a write with Match, the data must be written normally and a single Combined response is given.
BTAGMATCH must be 0b10 (Fail).

A Subordinate is expected to give an OKAY response to an MTE operation, unless it would have given a different
response to an equivalent non-MTE operation.

### E1.16 Prefetch request and response

When a Manager has indication that it might need data for an address but does not want to commit to reading it yet,
it can send a request to the system that it might be advantageous to prepare the location for reading. This request to
the system can cause reading the data into a downstream cache or from off-chip memory before the Manager makes
the actual read request.

When, for example, a CPU within a shareable domain issues a Prefetch request, it is routed directly to the memory
controller, bypassing any coherency checks. The CPU accompanies this with a coherent request to the same address
which will be routed through the coherency logic. If the snoop lookup misses, then the request will be propagated
to memory, where it might hit on the prefetched data.

The PREFETCHED response indicates that a read transaction has hit upon prefetched data. The Manager can use
this as part of a heuristic to determine if it will continue issuing Prefetch requests.

### E1.16.1 Prefetch transaction

A Prefetch is a data-less transaction. The transaction indicates that a Manager might read data from a specified
location at a later time.

The Prefetch_Transaction property is used to indicate whether a component supports prefetching.
True The Prefetch transaction is supported. The RRESP signal is extended to 3 bits.
False The Prefetch transaction is not supported.
If Prefetch_Transaction is not declared, it is considered False.

The Prefetch_Transaction property can be set True for the following interface types:

- ACE5-Lite

- ACE5-LiteDVM

The rules for Prefetch transactions are:

The Prefetch transaction consists of a request on the AW channel and a single response beat on the B channel,
there is no data.

The Prefetch request indicates that the request is a prefetch and the Subordinate can choose to move data from
a long-latency store, such as DRAM, into a low-latency store, such as an on-chip RAM or buffer.

A Prefetch request is signaled using the AWSNOOP opcode of 0b1111.

A Prefetch request must be cache line sized with the following constraints:
- The transaction is Regular, see Regular transactions on page A3-53.
- AWCACHE[1] is asserted, that is a Normal transaction.
- AWDOMAIN is Non-shareable, Inner Sharable or Outer Shareable.
- AWLOCK is Normal access.

-

-

The ID value must be unique-in-flight, which means:
- A Prefetch transaction can only be issued if there are no outstanding write transactions using the same
AWID.

The Manager must not issue a request on the write channel with the same AWID as an outstanding
Prefetch request.

If present on the interface, AWIDUNQ must be asserted for Prefetch transactions.

The Manager may or may not follow a Prefetch request with a non-Prefetch request to the same address.

A Subordinate interface at any level can chose to propagate or respond to a prefetch request.

It is permitted to respond to a Prefetch request with OKAY, DECERR or SLVERR. An OKAY response can
be sent irrespective of whether the Subordinate acts on the Prefetch request.

### E1.16.2 Response for prefetched data

If a read request hits on data which has been prepared due to a previous Prefetch request, the Subordinate may return
a PREFETCHED response. This can be used by the Manager to determine the success rate of its Prefetch requests.

When an interface supports prefetching, RRESP is extended to 3-bits to enable the signaling of a PREFETCHED
response. The PREFETCHED response uses the RRESP opcode of 0b100; it has the following rules and
recommendations:

- PREFETCHED indicates that read data is valid and has come from a prefetched source.

PREFETCHED can be used for a response to the following transaction types:
- ReadNoSnoop
- ReadOnce
- ReadOnceCleanInvalid
- ReadOnceMakeInvalid

A PREFETCHED response cannot be sent for an exclusive read.

This specification recommends that PREFETCHED is signaled for all beats or no beats of a response.

A PREFETCHED response can only be sent if the Prefetch_Transaction property is True for the interface.

A PREFETCHED response can be sent to a Manager even if the Manager has not sent a Prefetch request to
that location. For example, if a Manager happens to read data which was prefetched by another Manager.

### E1.17 Write zero with no data

Many writes in a system, particularly from a CPU have data set to zero. For example while initializing or allocating
memory. These writes with a zero value consume write data bandwidth and interconnect power that can be saved
by using a data-less request.

The WriteZero transaction is used to zero a cache-line-sized data location. The transaction consists of a write request
and write response but has no associated write data transfer. It is functionally equivalent to a regular write to the
same location with fully populated data lanes where all data has a value of zero.

### E1.17.1 WriteZero transaction configuration

The WriteZero_Transaction property is used to indicate whether an interface supports the WriteZero transaction.
True The WriteZero transaction is supported.
False The WriteZero transaction is not supported.

If WriteZero_Transaction is not declared, it is considered False.

The WriteZero_Transaction property can be set True for the following interface types:

- ACE5-Lite

- ACE5-LiteDVM

### E1.17.2 WriteZero transaction

The rules for a WriteZero transaction are:

A WriteZero request indicates that the data at the locations indicated by address, size and length attributes
must be set to zero.

A WriteZero transaction consists of a request on the AW channel and a single response on the B channel.

A WriteZero transaction is cache line sized and Regular, see Regular transactions on page A3-53.

AWSNOOP must be 0b0111.

AWLOCK must be normal access.

AWTAGOP must be Invalid.

AWID must be unique-in-flight, which means:
- A WriteZero transaction can only be issued if there are no outstanding write transactions using the
same AWID value.

- A Manager must not issue a request on the write channel with the same AWID as an outstanding
WriteZero transaction.

- If present, AWIDUNQ must be asserted for a WriteZero transaction.

AWDOMAIN can take any value. If AWDOMAIN is InnerShareable or Outer Shareable, a WriteZero acts
as a WriteUniqueFull with zeros as data.

### E1.17.3 Interoperability

A Manager that issues WriteZero requests cannot be connected to a Subordinate that does not support WriteZero.

When the Subordinate does not support WriteZero, the Manager must be configured to issue write transactions that
include write data beats of zero value, rather than WriteZero requests.

### E1.18 Additional interface properties

There are many different implementations of components that use interfaces from the AXI family of specifications.
Additional interface properties are defined that can help define interface capability or act as means for configuring
interfaces.

### E1.18.1 Exclusive accesses

Exclusive accesses are used for semaphore type accesses and tend to be used only by a limited subset of Managers
and Subordinate components.

The Exclusive_Accesses property is used to define whether a Manager issues exclusive accesses or whether a
Subordinate supports them:
True Exclusive accesses are supported. ARLOCK and AWLOCK are present on the interface.
False Exclusive accesses are not supported. ARLOCK and AWLOCK are not present on the interface.

If Exclusive_Accesses is not declared, it is considered:
False For AXI4-Lite, AXI5-Lite, and ACE5-LiteACP interfaces
True For other interface types

The Exclusive_Accesses property can be True for the following interfaces:

- AXI3

- AXI4

- AXI5

- ACE

- ACE-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

Table E1-27 provides guidance that applies when connecting Manager and Subordinate components with different
property values:

Table E1-27 Exclusive_Accesses interoperability

<table>
 <tr>
  <th></th>
  <th>Subordinate: False</th>
  <th>Subordinate: True</th>
 </tr>
 <tr>
  <td>Manager:</td>
  <td>Compatible.</td>
  <td>Compatible. ARLOCK and AWLOCK are</td>
 </tr>
 <tr>
  <td>False</td>
  <td></td>
  <td>tied LOW.</td>
 </tr>
 <tr>
  <td></td>
  <td>Exclusive Accesses will</td>
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
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>deadlock.</td>
  <td></td>
 </tr>
</table>

### E1.18.2 Shareable transactions

Inner Shareable and Outer Shareable transactions are used when accessing locations that might be stored in the
caches of Managers which are not downstream of the transaction issuer. Some interfaces are not required to identify
Shareable transactions, for example if they are downstream of all caches.

The Shareable_Transactions property is used to define whether a Manager issues Inner Shareable or Outer
Shareable transactions and whether a Subordinate supports them:

True

False

Shareable and Non-shareable transactions are supported. ARDOMAIN and AWDOMAIN are
present on the interface.

Inner Shareable and Outer Shareable transactions are not supported. ARDOMAIN and
AWDOMAIN are not present on the interface.

If Shareable_Transactions is not declared, it is considered:
False For AXI3, AXI4, AXI4-Lite, AXI5, and AXI5-Lite interfaces
True For ACE, ACE-Lite, ACE5, ACE5-Lite, ACE5-LiteDVM, and

ACE5-LiteACP interfaces

The Shareable_Transactions property can be True for the following interfaces:

- ACE

- ACE-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

Table E1-28 gives guidance that applies when connecting Manager and Subordinate components with different
property values:

### Table E1-28 Shareable_Transactions interoperability

|  | Subordinate: False | Subordinate: True |
| --- | --- | --- |
| Manager: False | Compatible. | Compatible. AxDOMAIN inputs are tied to {~AxCACHE[1], ~AxCACHE[1]}. |
| Manager: True | Compatible. AxDOMAIN outputs are unconnected. | Compatible. |

### E1.18.3 Maximum transaction size and boundary

The maximum size of a transaction is 4KB and transactions are not permitted to cross a 4KB boundary. However,
many Managers generate transactions which are guaranteed to be smaller than this.

A Subordinate or interconnect might benefit from this information. For example, a Subordinate might be able to
optimize away some decode logic. An interconnect striping at a granule smaller than 4KB might be able to avoid
burst splitting if it knows that transactions will not cross the stripe boundary.

The property Max_Transaction_Bytes defines the maximum size of a transaction in bytes. It can take the following
values:

- 64

- 128

- 256

- 512

- 1024

- 2048

- 4096

If Max_Transaction_Bytes is not declared, it is considered to be 4096.

The Max_Transaction_Bytes property can be declared for a Manager and Subordinate interface:

A Manager is guaranteed to not issue transactions larger than Max_Transaction_Bytes and transactions do
not cross a Max_Transaction_Bytes boundary.

A Subordinate is guaranteed to accept transactions up to Max_Transaction_Bytes in size.

The Max_Transaction_Bytes property is supported in all interface types.

Table E1-29 gives guidance that applies for connecting Manager and Subordinate components with different
property values:

### Table E1-29 Max_Transaction_Bytes interoperability

<table>
 <tr>
  <th>&lt;</th>
  <td>=</td>
  <td>&gt;</td>
 </tr>
 <tr>
  <th>Subordinate</th>
  <td>Subordinate</td>
  <td>Subordinate</td>
 </tr>
 <tr>
  <th>Compatible</th>
  <td>Compatible</td>
  <td>Not compatible</td>
 </tr>
</table>

### E1.18.4 Consistent DECERR response

Read transactions have multiple beats of data. The value of RRESP is not constrained within a transaction, so each
beat can take any legal value. A response of DECERR is generally used when there is a problem accessing a
Subordinate, and in this case DECERR is signaled consistently in every beat of read data. There may be a benefit if
a Manager can inspect just one beat of read data to determine whether a DECERR has occurred.

The Consistent_DECERR property is used to define whether a Subordinate signals DECERR consistently within a
transaction:

### True

DECERR is signaled for every beat of read data, or no beats of read data within each cache line of
data. For example, a transaction which crosses a cache line boundary can receive a DECERR
response for every read data beat on one cache line and no data beats on the next cache line.

False

DECERR may be signaled on any number of read data beats.

If Consistent_DECERR is not declared, it is considered to be:

True

For AXI4-Lite and AXI5-Lite interfaces, since they do not support multiple beats of data.

False For all other interfaces.

The Consistent_DECERR property can be True for the following interfaces:

- AXI3

- AXI4

- ACE

- ACE-Lite

- ACE5

- ACE5- LiteDVM

- ACE5- Lite

- ACE5- LiteACP

- AXI5

A Subordinate interface that does not use the DECERR response can set the Consistent_DECERR property to True.

Setting this property to True can be helpful when bridging between AXI and CHI, where DECERR translates to a
non-data error.

A Manager with Consistent_DECERR set True can inspect a single beat of data to determine whether a DECERR
has occurred.

Table E1-30 shows interoperability guidance when connecting Manager and Subordinate components with different
property values:

Table E1-30 Consistent_DECERR interoperability

|  | Subordinate: False | Subordinate: True |
| --- | --- | --- |
| Manager: False | Compatible. | Compatible. |
| Manager: True | Not compatible. A DECERR response might be missed by the Manager. | Compatible. |

### E1.19 Signal width properties

Properties are added to define the width of signals where the width is not fixed by the specification.
If a property is zero, then the associated signals are not present on the interface.
The maximum values are for guidance only, in order to set a reasonable maximum for configurable interfaces.

Table E1-31 Signal width properties

| Name | Min | Max | Applies to Constraints |
| --- | --- | --- | --- |
| ADDR_WIDTH | 1 | 64 | AWADDR, |
|  |  |  | ARADDR, |
|  |  |  | ACADDR |
| DATA_WIDTH | 8 | 1024 | WDATA, - 32 or 64 for AXI4-Lite. |
|  |  |  | RDATA, - 128 for ACE5-LiteACP. |
|  |  |  | CDDATA - 8, 16, 32, 64, 128, 256, 512, |
|  |  |  | 1024 for other interfaces. |
| ID_R_WIDTH | 0 | 32 | ARID, RID |
| ID_W_WIDTH | 0 | 32 | AWID, BID |
| LOOP_R_WIDTH | 0 | 8 | ARLOOP, |
|  |  |  | RLOOP |
| LOOP_W_WIDTH | 0 | 8 | AWLOOP, |
|  |  |  | BLOOP |
| SID_WIDTH | 0 | 32 | AWMMUSID, |
|  |  |  | ARMMUSID |
| SSID_WIDTH | 0 | 20 | AWMMUSSID, |
|  |  |  | ARMMUSSID |
| USER_REQ_WIDTH | 0 | 128 | AWUSER, |
|  |  |  | ARUSER |
|  | 0 |  | WUSER, RUSER |
|  | 0 | 16 | BUSER, |
|  |  |  | RUSER |

## Chapter E2

### Interface and data protection

This chapter specifies schemes for the protection of data and interfaces using poison and parity signaling:

- Poison on page E2-406

- Parity use in AMBA on page E2-407

- Configuration of interface protection on page E2-408
- Byte parity check signals on page E2-409
- Error detection behavior on page E2-410
- Parity check signals on page E2-411

### E2.1 Poison

Poison signaling is used to indicate that a set of data bytes have been previously corrupted. Passing the Poison
signaling alongside the data permits any future user of the data to be notified that the data might be corrupt. Poison
signaling is supported at the granularity of 1 bit for every 64 bits of data.

The Poison property is used to indicate whether a component supports Poison signaling:
True Poison signaling is supported.
False Poison signaling is not supported. If the Poison property is not declared, it is considered

to be False.

The Poison extension is supported in the following interfaces:

- AXI5

- AXI5-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

When the Poison signal is asserted, it indicates that the associated 64-bit data granule is corrupt.

Table E2-1 shows the Poison signaling.

### Table E2-1 Poison signaling

| Signal | Source | Width | Description |
| --- | --- | --- | --- |
| RPOISON | Subordinate | ceil(DATA_WIDTH/64) | Indicates that the read data in this transfer |
|  |  |  | has been corrupted. |
| WPOISON | Manager | ceil(DATA_WIDTH/64) | Indicates that the write data in this transfer |
|  |  |  | has been corrupted. |
| CDPOISON | ACE Manager | ceil(DATA_WIDTH/64) | Indicates that the snoop data in this transfer |
|  |  |  | has been corrupted. |

If the Poison property is True, then the appropriate Poison signal must be present for all data channels that are
present on that interface.

The validity of the Poison signaling is identical to the validity of the associated data.

Poison signaling is independent of error response signaling:

- It is permitted to signal an error with no Poison violation.

- It is permitted to signal a Poison violation without signaling an error response.

A 64-bit granule is defined to be an 8-byte address range that is aligned to an 8-byte boundary.

Where the transaction size, as indicated by AxSIZE, is less than 64-bits then it is permitted for the Poison bit to be
different on each data beat. In this situation the receiving component must examine all data beats to determine if the

64-bit granule is poisoned.

Poison bits can be set for data lanes that are invalid for a transfer. For example, a 64-bit transfer on a 128-bit bus
can have both Poison bits set.

### E2.2 Parity use in AMBA

For safety-critical applications it is necessary to detect and possibly correct, transient and functional errors on
individual wires within an SoC.

An error in a system component can propagate and cause multiple errors within connected components. Error
detection and correction (EDC) is required to operate end-to-end, covering all logic and wires from source to
destination.

One way to implement end-to-end protection, is to employ customized EDC schemes in components and implement
a simple error detection scheme between components. Between these components there is no logic and single bit
errors do not propagate to multi-bit errors. This section describes a parity scheme for detecting single-bit errors on
the AMBA interface between components. Multi-bit errors can be detected if they occur in different parity signal
groups. Figure E2-1 shows locations where parity can be used in AMBA.

<table>
 <tr>
  <th>distance</th>
  <td></td>
 </tr>
 <tr>
  <th>and routing logic</th>
  <td>Short distance wiring</td>
 </tr>
 <tr>
  <th>AMBA</th>
  <td>AMBA</td>
 </tr>
 <tr>
  <th>Source</th>
  <td>Destination</td>
 </tr>
 <tr>
  <th>Parity EDC</th>
  <td>code Parity</td>
 </tr>
 <tr>
  <th>Parity generation check and EDC</th>
  <td>EDC check and Parity check</td>
 </tr>
 <tr>
  <th>generation</th>
  <td>generation</td>
 </tr>
</table>

### Figure E2-1 Parity use in AMBA

### E2.3 Configuration of interface protection

The protection scheme employed on an interface is defined by the property Check_Type. The following
Check_Type values are defined:

### False

No checking signals on the interface. If the Check_Type property is not declared, it is considered to
be False.

### Odd_Parity_Byte_Data

Odd parity checking included for data signals with names that end in DATA. Each bit of the parity
signal covers exactly 8 bits.

### Odd_Parity_Byte_All

Odd parity checking included for all signals. Each bit of the parity signal generally covers up to 8
bits. However, a parity bit can cover more than 8 bits if the configuration requires it.

Interface protection is supported in the following interfaces:

- AXI5

- AXI5-Lite

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

### E2.4 Byte parity check signals

The following attributes are common to all the check signals added for byte parity interface protection:

- Odd parity is used. Odd parity means that check signals are added to groups of signals on the interface and driven such that there is always an odd number of asserted bits in that group.

Parity signals covering data and payload are defined such that in most cases, there are no more than 8 bits per
group.

This limitation assumes that there is a maximum of 3 logic levels available in the timing budget for generating
each parity bit.

Parity signals covering critical control signals, which are likely to have a smaller timing budget available, are
defined with a single odd parity bit. This single odd parity bit is the inversion of the original critical control
signal.

For a check signal that is wider than 1 bit:
- Check bit [n] corresponds to bits [(8n+7):8n] in the payload.
- If the payload is not an integer number of bytes, the most significant bit of the check signal covers
fewer than 8-bits in the most significant portion of the payload.

Check signals must be driven correctly in every cycle that the Check Enable term is True, see Table E2-2 on
page E2-411.

Parity signals must be driven appropriate to all the bits in the associated payload, irrespective of whether
those bits are actively used in the transfer. For example, all bits of WDATACHK must be driven correctly
when WVALID is asserted, even if some byte lanes are not being used.

If none of the signals covered by a check signal are present on an interface, then the check signal is omitted
from the interface.

If some of the signals covered by a check signal are not present on an interface, then the missing signals are
assumed to be LOW.

### E2.5 Error detection behavior

This specification is not prescriptive regarding component or system behavior when a parity error is detected.
Depending on the system and affected signals, a flipped bit can have a wide range of effects. It might be harmless,
cause performance issues, cause data corruption, cause security violations, or deadlock. The transaction response is
independent of parity error detection.

When an error is detected, the receiver can to do any of the following:

- Terminate or propagate the transaction. Termination might or might not be protocol compliant.
- Correct the parity check signal or propagate the signal in error.
- Update its memory or leave untouched. The location might be marked as poisoned.

- Signal an error response through other means, for example with an interrupt.

### E2.6 Parity check signals

All of the following check signals are synchronous to ACLK and must be driven correctly every cycle that the
Check Enable signal is HIGH.

Table E2-2 Parity check signals

<table>
 <tr>
  <th>Check signal</th>
  <th>Signals</th>
  <th>Check signal</th>
  <th>Granularity Check enable</th>
 </tr>
 <tr>
  <td>AWVALIDCHK</td>
  <td>AWVALID</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>AWREADYCHK</td>
  <td>AWREADY</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>AWIDCHK</td>
  <td>Packed as</td>
  <td></td>
  <td>1-8 AWVALID</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>if AWIDUNQ is</td>
  <td>not present:</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWADDRCHK</td>
  <td>AWADDR</td>
  <td></td>
  <td>1-8 AWVALID</td>
 </tr>
 <tr>
  <td>AWLENCHK</td>
  <td>AWLEN</td>
  <td>1</td>
  <td>8AWVLID</td>
 </tr>
 <tr>
  <td>AWCTLCHK0</td>
  <td>AWSIZE,</td>
  <td>1</td>
  <td>1-9AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td>AWBURST,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWLOCK,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWPROT</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWCTLCHK1</td>
  <td>AWREGION,</td>
  <td>1</td>
  <td>4-12AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td>AWCACHE,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWQOS</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWCTLCHK2</td>
  <td>AWDOMAIN,</td>
  <td>1</td>
  <td>2-9AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td>AWSNOOP,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWUNIQUE,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWBAR</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWCTLCHK3</td>
  <td>AWATOP,</td>
  <td>1</td>
  <td>2-10AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td>AWCMO,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWTAGOP</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWNSAIDCHK</td>
  <td>AWNSAID</td>
  <td>1</td>
  <td>4AWVLID</td>
 </tr>
 <tr>
  <td>AWUSERCHK</td>
  <td>AWUSER</td>
  <td></td>
  <td>1-8 AWVALID</td>
 </tr>
 <tr>
  <td>AWSTASHNIDCHK</td>
  <td>AWSTASHNID,</td>
  <td>1</td>
  <td>12AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWSTASHLPIDCHK</td>
  <td>AWSTASHLPID,</td>
  <td>1</td>
  <td>6AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWTRACECHK</td>
  <td>AWTRACE</td>
  <td>1</td>
  <td>1AWVLID</td>
 </tr>
 <tr>
  <td>AWLOOPCHK</td>
  <td>AWLOOP</td>
  <td>1</td>
  <td>1-8AWVLID</td>
 </tr>
 <tr>
  <td>AWMMUCHK</td>
  <td>AWMMUATST,</td>
  <td>1</td>
  <td>3-4AWVLID</td>
 </tr>
 <tr>
  <td></td>
  <td>AWMMUFLOW,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>AWMMUSSIDV</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWMMUSIDCHK</td>
  <td>AWMMUSID</td>
  <td></td>
  <td>1-8 AWVALID</td>
 </tr>
 <tr>
  <td>AWMMUSSIDCHK</td>
  <td>AWMMUSSID</td>
  <td></td>
  <td>1-8 AWVALID</td>
 </tr>
 <tr>
  <td>AWMPAMCHK</td>
  <td>AWMPAM</td>
  <td>1</td>
  <td>1AWVLID</td>
 </tr>
</table>

Table E2-2 Parity check signals (continued)

<table>
 <tr>
  <th>Check signal</th>
  <td>Signals</td>
  <td>Check signal</td>
  <td></td>
  <td></td>
  <td>Check enable</td>
 </tr>
 <tr>
  <th>WVALIDCHK</th>
  <td>WVALID</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>WREADYCHK</th>
  <td>WREADY</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>WDATACHK</th>
  <td>WDATA</td>
  <td></td>
  <td></td>
  <td>8</td>
  <td>WVALID</td>
 </tr>
 <tr>
  <th>WSTRBCHK</th>
  <td>WSTRB</td>
  <td></td>
  <td></td>
  <td>1-8</td>
  <td>WVALID</td>
 </tr>
</table>

WTAGCHK

WTAG,
WTAGUPDATE

ceil(DATA_WIDTH/128)

WTAGCHK[n] is the parity
of {WTAGUPDATE[n],
WTAG[4n+3:4n]}

<table>
 <tr>
  <th>WLASTCHK</th>
  <th>WLAST</th>
  <th>1</th>
  <th>1WVALID</th>
 </tr>
 <tr>
  <td>WUSERCHK</td>
  <td>WUSER</td>
  <td></td>
  <td>1-8 WVALID</td>
 </tr>
 <tr>
  <td>WPOISONCHK</td>
  <td>WPOISON</td>
  <td></td>
  <td>1-8 WVALID</td>
 </tr>
 <tr>
  <td>WTRACECHK</td>
  <td>WTRACE</td>
  <td>1</td>
  <td>1WVALID</td>
 </tr>
 <tr>
  <td>BVALIDCHK</td>
  <td>BVALID</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>BREADYCHK</td>
  <td>BREADY</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>BIDCHK</td>
  <td>Packed as</td>
  <td></td>
  <td>1-8 BVALID</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>if BIDUNQ is</td>
  <td>present:</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>BRESPCHK</td>
  <td>BRESP,</td>
  <td>1</td>
  <td>2-7BVALID</td>
 </tr>
 <tr>
  <td></td>
  <td>BPERSIST,</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>BTAGMATCH</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>BUSERCHK</td>
  <td>BUSER</td>
  <td></td>
  <td>1-8 BVALID</td>
 </tr>
 <tr>
  <td>BTRACECHK</td>
  <td>BTRACE</td>
  <td>1</td>
  <td>1BVALID</td>
 </tr>
 <tr>
  <td>BLOOPCHK</td>
  <td>BLOOP</td>
  <td>1</td>
  <td>1-8BVALID</td>
 </tr>
 <tr>
  <td>ARVALIDCHK</td>
  <td>ARVALID</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>ARREADYCHK</td>
  <td>ARREADY</td>
  <td>1</td>
  <td>1ARESETn</td>
 </tr>
 <tr>
  <td>ARIDCHK</td>
  <td>Packed as</td>
  <td></td>
  <td>1-8 ARVALID</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>if ARIDUNQ is</td>
  <td>present:</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ARADDRCHK</td>
  <td>ARADDR</td>
  <td></td>
  <td>1-8 ARVALID</td>
 </tr>
 <tr>
  <td>ARLENCHK</td>
  <td>ARLEN</td>
  <td>1</td>
  <td>8ARVLID</td>
 </tr>
</table>

5 WVALID

ARCTLCHK0 ARSIZE, 1 1-9ARVLID
ARBURST,
ARLOCK,
ARPROT

ARCTLCHK1 ARREGION, 1 4-12ARVLID

### ARCACHE, ARQOS

Table E2-2 Parity check signals (continued)

| Check signal | Signals covered | Check signal | Granularity Check enable |
| --- | --- | --- | --- |
| ARCTLCHK2 | ARDOMAIN, | 1 | 2-8ARVLID |
|  | ARSNOOP, |  |  |
|  | ARBAR |  |  |
| ARCTLCHK3 | ARVMIDEXT, | 1 | 1-7ARVLID |
|  | ARCHUNKEN, |  |  |
|  | ARTAGOP |  |  |
| ARNSAIDCHK | ARNSAID | 1 | 4ARVLID |
| ARUSERCHK | ARUSER |  | 1-8 ARVALID |
| ARTRACECHK | ARTRACE | 1 | 1ARVLID |
| ARLOOPCHK | ARLOOP | 1 | 1-8ARVLID |

ARMMUCHK ARMMUATST, 1 3-4ARVLID
ARMMUFLOW,
ARMMUSECSID,
ARMMUSSIDV

<table>
 <tr>
  <th>ARMMUSIDCHK</th>
  <td>ARMMUSID</td>
  <td></td>
  <td></td>
  <td>1-8</td>
  <td>ARVALID</td>
 </tr>
 <tr>
  <th>ARMMUSSIDCHK</th>
  <td>ARMMUSSID</td>
  <td></td>
  <td></td>
  <td>1-8</td>
  <td>ARVALID</td>
 </tr>
 <tr>
  <th>ARMPAMCHK</th>
  <td>ARMPAM</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RVALIDCHK</th>
  <td>RVALID</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RREADYCHK</th>
  <td>RREADY</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RIDCHK</th>
  <td>Packed as</td>
  <td></td>
  <td></td>
  <td>1-8</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>if RIDUNQ is</td>
  <td>present:</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RDATACHK</th>
  <td>RDATA</td>
  <td></td>
  <td></td>
  <td>8</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th>RTAGCHK</th>
  <td>RTAG</td>
  <td></td>
  <td></td>
  <td>4</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>RTAGCHK[n]</td>
  <td>the parity</td>
  <td>of</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>RTAG[4n+3:4n]</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RRESPCHK</th>
  <td>RRESP</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RLASTCHK</th>
  <td>RLAST</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RUSERCHK</th>
  <td>RUSER</td>
  <td></td>
  <td></td>
  <td>+ 1-8</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RPOISONCHK</th>
  <td>RPOISON</td>
  <td></td>
  <td></td>
  <td>1-8</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th>RTRACECHK</th>
  <td>RTRACE</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>RLOOPCHK</th>
  <td>RLOOP</td>
  <td>1</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

RCHUNKCHK RCHUNKV, 1 1-4RVALID

### RCHUNKNUM, RCHUNKSTRB

Table E2-2 Parity check signals (continued)

| Check signal | Signals | Check signal | Granularity Check enable |
| --- | --- | --- | --- |
| ACVALIDCHK | ACVALID | 1 | 1ARESETn |
| ACREADYCHK | ACREADY | 1 | 1ARESETn |
| ACADDRCHK | ACADDR |  | 1-8 ACVALID |
| ACCTLCHK | ACSNOOP, | 1 | 3-7ACVALID |
|  | ACPROT |  |  |
| ACVMIDEXTCHK | ACVMIDEXT | 1 | 4ACVALID |
| ACTRACECHK | ACTRACE | 1 | 1ACVALID |
| CRVALIDCHK | CRVALID | 1 | 1ARESETn |
| CRREADYCHK | CRREADY | 1 | 1ARESETn |
| CRRESPCHK | CRRESP | 1 | 5CRVALID |
| CRTRACECHK | CRTRACE | 1 | 1CRVALID |
| CRNSAIDCHK | CRNSAID | 1 | 4CRVALID |
| CDVALIDCHK | CDVALID | 1 | 1ARESETn |
| CDREADYCHK | CDREADY | 1 | 1ARESETn |
| CDDATACHK | CDDATA |  | 8 CDVALID |
| CDLASTCHK | CDLAST | 1 | 1CDVALID |
| CDPOISONCHK | CDPOISON |  | 1-8 CDVALID |
| CDTRACECHK | CDTRACE | 1 | 1CDVALID |
| RACKCHK | RACK | 1 | 1ARESETn |
| WACKCHK | WACK | 1 | 1ARESETn |
|  |  | 1 | 4ARESETn |
|  |  | 1 | 4ARESETn |
| AWAKEUPCHK | AWAKEUP | 1 | 1ARESETn |
| ACWAKEUPCHK | ACWAKEUP | 1 | 1ARESETn |
| SYSCOREQCHK | SYSCOREQ | 1 | 1- |
| SYSCOACKCHK | SYSCOACK | 1 | 1- |
