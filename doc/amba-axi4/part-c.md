# Part C

AMBA AXI5 and AXI5-Lite Interface Specification

## Chapter C1

### AMBA AXI5

This chapter specifies the new capabilities in the AXI5 protocol specification. It contains the following sections:

- About the AXI5 protocol on page C1-130

- Signal Descriptions on page C1-132

### C1.1 About the AXI5 protocol

AXI5 extends the capabilities of the AXI4 protocol that is specified in Part A AMBA AXI Protocol Specification.To
maintain compatibility, a property is used to declare each new capability: Table C1-1 summarizes the AXI5
properties.

### Table C1-1 Properties that can be set on an AXI5 interface

<table>
 <tr>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>Atomic_Transactions</td>
  <td>Adds Atomic transactions that perform more than just a single access, and</td>
 </tr>
 <tr>
  <td></td>
  <td>have some form of operation that is associated with them. See Atomic</td>
 </tr>
 <tr>
  <td></td>
  <td>transactions on page E1-342.</td>
 </tr>
 <tr>
  <td>Check_Type</td>
  <td>Adds data checking signaling that is used to detect, and potentially correct,</td>
 </tr>
 <tr>
  <td></td>
  <td>data bytes that might have been corrupted. See Chapter E2 Interface and data</td>
 </tr>
 <tr>
  <td></td>
  <td>protection.</td>
 </tr>
 <tr>
  <td>Poison</td>
  <td>Adds Poison signaling that is used to indicate that a set of data bytes have been</td>
 </tr>
 <tr>
  <td></td>
  <td>previously corrupted. See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>QoS_Accept</td>
  <td>Adds two additional QoS interface signals that enable a Subordinate to</td>
 </tr>
 <tr>
  <td></td>
  <td>indicate the QoS value of transactions that it will accept. See QoS Accept</td>
 </tr>
 <tr>
  <td></td>
  <td>signaling on page E1-360.</td>
 </tr>
 <tr>
  <td>Trace_Signals</td>
  <td>Adds a Trace signal, which is associated with each channel, to support the</td>
 </tr>
 <tr>
  <td></td>
  <td>debugging, tracing, and performance measurement of systems. See Trace</td>
 </tr>
 <tr>
  <td></td>
  <td>signals on page E1-357.</td>
 </tr>
 <tr>
  <td>Loopback_Signals</td>
  <td>Adds loopback signaling that permits an agent that is issuing transactions to</td>
 </tr>
 <tr>
  <td></td>
  <td>store information relating to the transaction in an indexed table. See User</td>
 </tr>
 <tr>
  <td></td>
  <td>Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>Wakeup_Signals</td>
  <td>Adds wakeup signaling that is used to indicate that there is activity that is</td>
 </tr>
 <tr>
  <td></td>
  <td>associated with the interface. See Wake-up Signaling on page E1-362.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds untranslated transaction support and permits different transactions on<br/>the same interface to use different translation schemes. See Untranslated</td>
 </tr>
 <tr>
  <td></td>
  <td>transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>NSAccess_Identifiers</td>
  <td>Adds Non-secure access identifiers that support the storage and processing of</td>
 </tr>
 <tr>
  <td></td>
  <td>protected data. See Non-secure access identifiers on page E1-376.</td>
 </tr>
 <tr>
  <td>MPAM_Support</td>
  <td>Adds indicatation of interface supporting MPAM. See Memory Partitioning</td>
 </tr>
 <tr>
  <td></td>
  <td>and Monitoring (MPAM) on page E1-385.</td>
 </tr>
 <tr>
  <td>Unique_ID_Support</td>
  <td>Adds indicatation of interface supporting the Unique ID Indicator: See Unique</td>
 </tr>
 <tr>
  <td></td>
  <td>ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds indicatation of interface supporting the interleaving of read data beats<br/>from different transactions. See Read interleaving property on page E1-382.</td>
 </tr>
 <tr>
  <td>Read_Data_Chunking</td>
  <td>Adds indicatation of interface supporting the return of read data in reorderable</td>
 </tr>
 <tr>
  <td></td>
  <td>chunks. See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td>MTE_Support</td>
  <td>Used to indicate that a component supports the Memory Tagging Extension.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Memory tagging on page E1-387.</td>
 </tr>
</table>

Regular_Transactions_Only

Used to define whether a Manager issues only Regular type transactions and
if a Subordinate only supports Regular transactions. See Regular transactions
property on page A3-53.

### Table C1-1 Properties that can be set on an AXI5 interface (continued)

| Property | Description |
| --- | --- |
| Exclusive_Accesses | Used to define whether a Manager issues exclusive accesses or whether a |
|  | Subordinate supports them. See Exclusive accesses on page E1-399. |
| Max_Transaction_Bytes | Defines the maximum size of a transaction in bytes. See Maximum transaction |
|  | size and boundary on page E1-400. |
| Consistent_DECERR | Used to define whether a Subordinate signals DECERR consistently across all |
|  | beats of read and write response. See Consistent DECERR response on |
|  | page E1-401. |

### C1.2 Signal Descriptions

This section introduces the additional AXI5 interface signals that support the new capabilities. It contains the
following subsections:

- Additions to existing AXI channels

- Additional signaling on page C1-137

See Chapter A8 AMBA 4 Additional Signaling for details of the AXI4 interface signals.

### C1.2.1 Additions to existing AXI channels

Depending on the interface properties, signals might be added on the following AXI channels:

- Write address channel signals

- Write data channel signals on page C1-134
- Write response channel signals on page C1-135
- Read address channel signals on page C1-135
- Read data channel signals on page C1-136
- Parity check signals on page E2-411

### Write address channel signals

Table C1-2 shows the additional write address channel signals:

Table C1-2 Write address channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| AWATOP | Manager | Atomic_Transactions | Indicates the type and endianness of atomic |
|  |  |  | transactions. |
|  |  |  | See Atomic transactions on page E1-342. |
| AWTRACE | Manager | Trace_Signals | Supports the tracing of specific transactions through |
|  |  |  | the system. |
|  |  |  | See Trace signals on page E1-357. |
| AWLOOP | Manager | Loopback_Signals | Loopback value for a write transaction. |
|  |  |  | See User Loopback signaling on page E1-359. |
|  | Manager |  | Secure Stream Identifier for a write transaction. See Untranslated transactions on page E1-369. |
| AWMMUSID | Manager |  | Stream Identifier for a write transaction. |
|  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUSSIDV | Manager |  | Indicates if the AWMMUSSID signal is valid. |
|  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUSSID | Manager |  | Substream Identifier for a write transaction. |
|  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUATST | Manager |  | Indicates whether a write transaction has undergone |
|  |  |  | PCIe ATS translation. |
|  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUFLOW | Manager |  | Indicates the SMMU flow for managing translation |
|  |  |  | faults. |
|  |  |  | See Untranslated transactions on page E1-369. |

### Table C1-2 Write address channel signals (continued)

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| AWNSAID | Manager | NSAccess_Identifiers | Non-secure Access Identifier for a write transaction. |
|  |  |  | See Non-secure access identifiers on page E1-376. |
| AWMPAM | Manager | MPAM_Support | Write address channel MPAM information. |
|  |  |  | See Memory Partitioning and Monitoring (MPAM) |
|  |  |  | on page E1-385 |
| AWIDUNQ | Manager | Unique_ID_Support | Write address channel unique ID indicator, active |
|  |  |  | HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |
| AWTAGOP | Manager | MTE_Support | Write request tag operation.See MTE signaling on |
|  |  |  | page E1-388 |

### Write data channel signals

Table C1-3 shows the additional write data channel signals:

Table C1-3 Write data channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| WPOISON | Manager | Poison | Indicates that the write data in this transfer has been |
|  |  |  | corrupted. |
|  |  |  | See Chapter E2 Interface and data protection. |
| WTRACE | Manager | Trace_signals | Supports the tracing of specific transactions through |
|  |  |  | the system. |
|  |  |  | See Trace signals on page E1-357. |
| WTAG | Manager | MTE_Support | Indicates the tag that is associated with write data. |
|  |  |  | See MTE signaling on page E1-388. |
|  | Manager | MTE_Support | Indicates which tags must be written to memory in |
|  |  |  | an Update operation. |
|  |  |  | See MTE signaling on page E1-388 |

### Write response channel signals

Table C1-4 shows the additional write response channel signals:

Table C1-4 Write response channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>BTRACE</td>
  <td></td>
  <td>Trace_signals</td>
  <td>Supports the tracing of specific write transactions</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>through the system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>BLOOP</td>
  <td></td>
  <td>Loopback_Signals</td>
  <td>Loopback value for a write response.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>BIDUNQ</td>
  <td></td>
  <td>Unique_ID_Support</td>
  <td>Write response channel unique ID indicator, active</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>HIGH.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>MTE_Support</td>
  <td>Indicates the result of a tag comparison on a write<br/>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388.</td>
 </tr>
 <tr>
  <td>BCOMP</td>
  <td></td>
  <td>CMO_On_Write,</td>
  <td>Indicates that a write is observable.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Persist_CMO,</td>
  <td>See PCMO response on the B channel on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>MTE_Support</td>
  <td>page D7-275.</td>
 </tr>
 <tr>
  <td>Read<br/>Table C1-5</td>
  <td>channel<br/>the</td>
  <td>signals<br/>read address channel</td>
  <td>Table C1-5 Read address channel</td>
 </tr>
 <tr>
  <td>Signal</td>
  <td>Source</td>
  <td>Property</td>
  <td>Description</td>
 </tr>
 <tr>
  <td>ARTRACE</td>
  <td>Manager</td>
  <td>Trace_Signals</td>
  <td>Supports the tracing of specific transactions through</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>the system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>ARLOOP</td>
  <td>Manager</td>
  <td>Loopback_Signals</td>
  <td>Loopback value for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Reflected back on RLOOP.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td></td>
  <td>Manager</td>
  <td></td>
  <td>Secure Stream Identifier for a read transaction.<br/>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>ARMMUSID</td>
  <td>Manager</td>
  <td></td>
  <td>Stream Identifier for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>ARMMUSSIDV</td>
  <td>Manager</td>
  <td></td>
  <td>Indicates whether the ARMMUSSID signal is valid.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>ARMMUSSID</td>
  <td>Manager</td>
  <td></td>
  <td>Substream Identifier for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>ARMMUATST</td>
  <td>Manager</td>
  <td></td>
  <td>Indicates whether a read transaction has undergone</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>PCIe ATS translation.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
</table>

Table C1-5 Read address channel signals (continued)

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td></td>
  <td>Manager</td>
  <td></td>
  <td>Indicates the SMMU flow for managing translation<br/>faults.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>ARNSAID</td>
  <td>Manager</td>
  <td>NSAccess_Identifiers</td>
  <td>Non-secure Access Identifier for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Non-secure access identifiers on page E1-376.</td>
 </tr>
 <tr>
  <td>ARMPAM</td>
  <td>Manager</td>
  <td>MPAM_Support</td>
  <td>Read address channel MPAM information. See</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Memory Partitioning and Monitoring (MPAM) on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-385</td>
 </tr>
 <tr>
  <td>ARIDUNQ</td>
  <td>Manager</td>
  <td>Unique_ID_Support</td>
  <td>Read address channel unique ID indicator, active</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>HIGH.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td></td>
  <td>Manager</td>
  <td>Read_Data_Chunking</td>
  <td>Read data chunking enable.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td>ARTAGOP</td>
  <td>Manager</td>
  <td>MTE_Support</td>
  <td>Read request tag operation.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
 <tr>
  <td>Read<br/>Table</td>
  <td>channel<br/>shows the</td>
  <td>read data channel</td>
  <td>Table C1-6 Read data channel</td>
 </tr>
 <tr>
  <td>Signal</td>
  <td>Source</td>
  <td>Property</td>
  <td>Description</td>
 </tr>
 <tr>
  <td>RPOISON</td>
  <td>Interconnect</td>
  <td>Poison</td>
  <td>Indicates that the read data in this transfer has been</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>corrupted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>RTRACE</td>
  <td>Interconnect</td>
  <td>Trace_Signals</td>
  <td>Supports the tracing of specific transactions through</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>the system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>RLOOP</td>
  <td>Interconnect</td>
  <td>Loopback_Signals</td>
  <td>Loopback value for a read response.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>RIDUNQ</td>
  <td>Subordinate</td>
  <td>Unique_ID_Support</td>
  <td>Read data channel unique ID indicator, active</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>HIGH.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td>RCHUNKV</td>
  <td>Subordinate</td>
  <td>Read_Data_Chunking</td>
  <td>Valid signal of RCHUNKNUM and</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>RCHUNKSTRB.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td></td>
  <td>Subordinate</td>
  <td>Read_Data_Chunking</td>
  <td>Read data chunk number.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td></td>
  <td>Subordinate</td>
  <td>Read_Data_Chunking</td>
  <td>Read data chunk strobe.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td>RTAG</td>
  <td>Subordinate</td>
  <td>MTE_Support</td>
  <td>The tag that is associated with read data.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
</table>

### C1.2.2 Additional signaling

The following ancillary signaling is optional on the AXI5 interface to support the new capabilities.

### QoS accept

Table C1-7 shows the additional QoS accept signaling.

Table C1-7 QoS accept signals

Source

VAWQOSACCEPT Subordinate QoS_Accept

VARQOSACCEPT Subordinate QoS_Accept

### Low-power signals

Table C1-8 shows the additional wakeup low-power signaling.

Source Property

Manager

Wakeup_Signals

signals

## Chapter C2

### AMBA AXI5-Lite

This chapter specifies the new capabilities in the AXI5-Lite protocol specification. It contains the following
sections:

- Definition of AXI5-Lite on page C2-140
- AXI5-Lite compared with other interfaces on page C2-141
- Interoperability on page C2-142
- Conversion from AXI5 to AXI5-Lite on page C2-143
- Upgrading an AXI4-Lite Subordinate to AXI5-Lite on page C2-145
- AXI5-Lite signal list on page C2-146

### C2.1 Definition of AXI5-Lite

AXI5-Lite is a subset of AXI5, where all transactions are completed in a single beat. It is intended for
communication with register-based components and simple memories when bursts of data transfer are not
advantageous.

AXI5-Lite extends the definition of AXI4-Lite, adding more flexibility on bus width and ordering. These features
enable the interface to be used for peripherals that are closely coupled to high-performance processors when it is
important to minimize response latency. For example, an AXI5-Lite Manager can issue multiple requests to
peripherals with different response latencies, without the slower peripherals affecting the latency of faster ones.

Figure C2-1 shows an example where AXI5-Lite might be used.

<table>
 <tr>
  <th colspan="2">Processor<br/>ACE5 AXI5-Lite</th>
 </tr>
 <tr>
  <td>128</td>
  <td>64<br/>Private<br/>Memory<br/>System</td>
 </tr>
 <tr>
  <td>Shared</td>
  <td>Simple Interconnect</td>
 </tr>
 <tr>
  <td>System</td>
  <td>32 64 64<br/>AXI5-Lite AXI5-Lite Async<br/>Peripheral SRAM<br/>AXI5-Lite<br/>Peripheral</td>
 </tr>
</table>

### Figure C2-1 Example of memory system that uses AXI5-Lite

The key functionality of AXI5-Lite operation is:

- All transactions have burst length 1.

- Reordering of responses is permitted when requests have different IDs.

- All accesses are considered Device Non-bufferable.

- Exclusive accesses are not supported.

### C2.2 AXI5-Lite compared with other interfaces

If a component does not benefit from burst access, AXI5-Lite is a better choice of interface than AXI5. Compared
with AXI5, an AXI5-Lite interface is simpler to implement and verify.

Compared with AXI4-Lite, AXI5-Lite permits any data width and responses can be reordered. Flexibility in data
width enables an AXI5-Lite Subordinate to be easily connected to the main memory system interconnect. If data
width conversion is required, performing it in the AXI5-Lite domain, is less complex than in AXI. Response
reordering is optional, but can improve performance when communicating with Subordinates with differing
response latencies.

Table C2-1 shows the summary of differences:

### Table C2-1 AXI5-Lite interface comparison

<table>
 <tr>
  <th></th>
  <td>AXI5</td>
  <td>AXI5-Lite</td>
  <td>AXI4-Lite</td>
 </tr>
 <tr>
  <th>Number of interface wires (32-bit</th>
  <td>and data) 224</td>
  <td>175</td>
  <td>160</td>
 </tr>
 <tr>
  <th>Data width (bits)</th>
  <td>Up to 1024</td>
  <td>Up to 1024</td>
  <td>32 or 64</td>
 </tr>
 <tr>
  <th>Transaction length</th>
  <td>Up to 256</td>
  <td>1</td>
  <td>1</td>
 </tr>
 <tr>
  <th>Transaction size</th>
  <td>Up to bus</td>
  <td>Up to bus</td>
  <td>Full bus width</td>
 </tr>
 <tr>
  <th>Address buses</th>
  <td>Read and</td>
  <td>Read and</td>
  <td>Read and write</td>
 </tr>
 <tr>
  <th>Memory types</th>
  <td>Any</td>
  <td>Device</td>
  <td>Device</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>Non-bufferable</td>
 </tr>
 <tr>
  <th>Write strobes</th>
  <td>Mandatory</td>
  <td>Mandatory</td>
  <td>optional</td>
 </tr>
 <tr>
  <th>Response Ordering</th>
  <td>In-order or</td>
  <td>In-order or</td>
  <td>In-order</td>
 </tr>
 <tr>
  <th></th>
  <td>out-of-order</td>
  <td>out-of-order</td>
  <td></td>
 </tr>
 <tr>
  <th>IDs</th>
  <td>Mandatory</td>
  <td>Mandatory</td>
  <td>optional</td>
 </tr>
 <tr>
  <th>Exclusive accesses</th>
  <td>Supported</td>
  <td>No</td>
  <td>No</td>
 </tr>
 <tr>
  <th>Check_Type</th>
  <td>optional</td>
  <td>optional</td>
  <td>No</td>
 </tr>
 <tr>
  <th>Poison</th>
  <td>optional</td>
  <td>optional</td>
  <td>No</td>
 </tr>
 <tr>
  <th>Trace_Signals</th>
  <td>optional</td>
  <td>optional</td>
  <td>No</td>
 </tr>
 <tr>
  <th>Wakeup_Signals</th>
  <td>optional</td>
  <td>optional</td>
  <td>No</td>
 </tr>
 <tr>
  <th>Unique_ID_Support</th>
  <td>optional</td>
  <td>optional</td>
  <td>No</td>
 </tr>
</table>

### C2.3 Interoperability

This section describes the interoperability of AXI5-Lite with AXI5 and AXI4-Lite components.
Table C2-2 shows combinations of interface, and indicates that special consideration must be given when an AXI5
Manager is connected to an AXI5-Lite Subordinate and an AXI5-Lite Manager is connected to an AXI4-Lite
Subordinate.

### Table C2-2 Interoperability of AXI5-Lite with AXI5 and AXI4-Lite

| Manager | Subordinate | Interoperability |
| --- | --- | --- |
| AXI5 | AXI5-Lite | Can connect if uses |
|  |  | AXI5-Lite subset of transactions. Otherwise |
|  |  | needs conversion, protection, or detection. |
|  |  | See Conversion, protection, and detection |
|  |  | on page B1-125 |
| AXI5-Lite | AXI5 | Fully operational. |
| AXI4-Lite | AXI5-Lite | Fully operational. |
| AXI5-Lite | AXI4-Lite | AXI ID reflection is required on |
|  |  | Subordinate. Can connect directly if |
|  |  | Manager uses bus-width transactions. |
|  |  | Otherwise needs conversion, protection, or |
|  |  | detection. See Conversion, protection, and |
|  |  | detection on page B1-125 |

### C2.4 Conversion from AXI5 to AXI5-Lite

If an AXI5 Manager uses transactions that are not within the AXI5-Lite subset, a bridge can be used to convert the
AXI5 transactions into those suitable for an AXI5-Lite Subordinate.

The rules for conversion are as follows:

If a transaction has a burst length greater than 1, then the burst is broken into multiple transactions of burst
length 1. The number of transactions that are created depends on the burst length of the original transaction.

When generating the address for subsequent beats of a burst, the conversion of bursts with a length greater
than 1 must consider the burst type. An unaligned start address must be incremented and aligned for
subsequent beats of an INCR or WRAP burst. For a FIXED burst, the same address is used for all beats.

Where a write burst with length greater than 1 is converted into multiple write transactions, the component
responsible for the conversion must combine the responses for all the generated transactions to produce a
single response for the original burst. Any error response is sticky. That is, an error response that is received
for any of the generated transactions is retained, and the single combined response indicates an error. If both
a SLVERR and a DECERR are received, then the first response that is received is the one that is used for the
combined response.

A transaction that is wider than the destination AXI5-Lite interface is broken into multiple transactions of the
same width as the AXI5-Lite interface. For transactions with an unaligned start address, the breaking up of
the burst occurs on boundaries that are aligned to the width of the AXI5-Lite interface.

Where a wide transaction is converted to multiple narrower transactions, the component responsible for the
conversion must combine the responses to all the narrower transactions, to produce a single response for the
original transaction. Any error response is sticky. If both an SLVERR and a DECERR are received then the
first response received is used for the combined response.

Transactions that are narrower than the AXI5-Lite interface are passed directly and are not converted.

Transaction IDs are passed directly, unmodified.

Write strobes are passed directly, unmodified.

For an exclusive sequence, the AXI signaling requirements mean that any exclusive write access must fail.

The AxCACHE signals are discarded. All transactions are treated as Non-modifiable and Non-bufferable.

The AxPROT signals are passed directly, unmodified.

The WLAST signal is discarded.

The RLAST signal is not required, and is considered asserted for every transfer on the read data channel.

### C2.5 Upgrading an AXI4-Lite Manager to AXI5-Lite

An AXI4-Lite Manager can be upgraded to AXI5-Lite by doing the following:

- If not already present, add ID signals. If the Manager supports only in-order responses, then use a single-bit ID and tie off ARID and AWID to 0b0.

Add AWSIZE and ARSIZE outputs. An AXI4-Lite Manager only generates transactions that are full bus
width, so these signals can be tied off to 0b010 for a 32-bit bus or 0b011 for a 64-bit bus.

### C2.6 Upgrading an AXI4-Lite Subordinate to AXI5-Lite

An AXI4-Lite Subordinate can be upgraded to AXI5-Lite by doing the following:

- If not already present, add ID signals. The Subordinate must mirror ARID onto RID and AWID onto BID. Responses can continue to be provided in-order, or out-of-order capability can be added.

t Add heAWSIZE input. It can be decided whether to use this, or use WSTRB to determine which bytes to
write.

Modify the Subordinate to fully support WSTRB, if it does not already. The Subordinate must only write
those bytes indicated by the relevant WSTRB bits. A write with no strobes asserted must be supported.

t Add heARSIZE input. The Subordinate can choose to use this input to drive only the active bytes in the
transfer, or it can continue to drive the full bus width of read data.

### C2.7 AXI5-Lite signal list

Table C2-3 lists the signals available on each channel with AXI5-Lite. Some signals are optional or conditional on
interface properties, see Table G2-2 on page G2-461.

Table C2-3 AXI5-Lite signals

<table>
 <tr>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
 </tr>
 <tr>
  <td></td>
  <td colspan="2"></td>
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
  <td colspan="2"></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

<table>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td>BVALID</td>
  <td>ARVALID RVALID</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td>BREADY</td>
  <td>ARREADY RREADY</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td>-</td>
  <td>ARADDR RDATA</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td></td>
  <td></td>
  <td>BRESP</td>
  <td>ARPROTa RRESP</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td>-</td>
  <td></td>
  <td>BID</td>
  <td>ARID RID</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td>-</td>
  <td></td>
  <td>BIDUNQ</td>
  <td>ARIDUNQ RIDUNQ</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td>-</td>
  <td></td>
  <td></td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td></td>
  <td></td>
  <td>BUSER</td>
  <td>ARUSER RUSER</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td></td>
  <td></td>
  <td>BTRACE</td>
  <td>ARTRACE RTRACE</td>
 </tr>
 <tr>
  <th>-<br/>a.</th>
  <td>AxPROT is<br/>parity</td>
  <td>as 3 bits wide, but only<br/>can also be included on</td>
  <td></td>
  <td>-<br/>(secure) is used by<br/>interface, see</td>
  <td>-RPOISON<br/>interface.<br/>check signals on page E2-411.</td>
 </tr>
</table>
