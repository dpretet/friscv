# Part F

AMBA ACE5, ACE5-Lite, ACE5-LiteDVM, and ACE5-LiteACP
Interface Specification

## Chapter F1

### AMBA ACE5

This chapter specifies the new capabilities in the ACE5 protocol specification. It contains the following sections:

- About the ACE5 protocol on page F1-418
- Signal descriptions on page F1-420

### F1.1 About the ACE5 protocol

ACE5 extends the capabilities of the ACE protocol that is described in Part D AMBA ACE and ACE-Lite Protocol
Specification. Table F1-1 summarizes the properties used to declare capabilities.

Table F1-1 Properties that can be set on an ACE5 interface

<table>
 <tr>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>DVM_v8</td>
  <td>Specifies that a component supports DVMv8 and DVMv7 message</td>
 </tr>
 <tr>
  <td></td>
  <td>protocols.</td>
 </tr>
 <tr>
  <td></td>
  <td>See DVM message versions on page D13-323.</td>
 </tr>
 <tr>
  <td>DVM_v8.1</td>
  <td>Specifies that a component supports DVMv8.1, DVMv8 and DVMv7</td>
 </tr>
 <tr>
  <td></td>
  <td>message protocols.</td>
 </tr>
 <tr>
  <td></td>
  <td>See DVM message versions on page D13-323.</td>
 </tr>
 <tr>
  <td>CMO_On_Read</td>
  <td>Indicates whether an interface supports cache maintenance operations on</td>
 </tr>
 <tr>
  <td></td>
  <td>the read channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
 <tr>
  <td>Persist_CMO</td>
  <td>Adds an additional cache maintenance operation that is used to provide a</td>
 </tr>
 <tr>
  <td></td>
  <td>cache clean to the Point of Persistence operation.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO transactions on page D7-267.</td>
 </tr>
 <tr>
  <td>Check_Type</td>
  <td>Adds data or interface level parity signals for error detection.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>Poison</td>
  <td>Adds Poison signaling that is used to indicate that a set of data bytes have</td>
 </tr>
 <tr>
  <td></td>
  <td>been corrupted.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>QoS_Accept</td>
  <td>Adds two additional QoS interface signals that enable a Subordinate to</td>
 </tr>
 <tr>
  <td></td>
  <td>indicate the QoS value of transactions that it will accept.</td>
 </tr>
 <tr>
  <td></td>
  <td>See QoS Accept signaling on page E1-360.</td>
 </tr>
 <tr>
  <td>Trace_Signals</td>
  <td>Adds a Trace signal, which is associated with each channel, to support the</td>
 </tr>
 <tr>
  <td></td>
  <td>debugging, tracing, and performance measurement of systems.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>Loopback_Signals</td>
  <td>Adds loopback signaling that permits an agent that is issuing transactions</td>
 </tr>
 <tr>
  <td></td>
  <td>to store information relating to the transaction in an indexed table.</td>
 </tr>
 <tr>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>Wakeup_Signals</td>
  <td>Adds two wakeup signals that are used to indicate that there is activity that</td>
 </tr>
 <tr>
  <td></td>
  <td>is associated with the interface.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Wake-up Signaling on page E1-362.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds signaling to connect or disconnect this interface from the coherency<br/>system.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Coherency Connection signaling on page E1-364</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds untranslated transaction support and permits different transactions on<br/>the same interface to use different translation schemes.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>NSAccess_Identifiers</td>
  <td>Adds Non-secure access identifiers that support the storage and processing</td>
 </tr>
 <tr>
  <td></td>
  <td>of protected data.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Non-secure access identifiers on page E1-376.</td>
 </tr>
</table>

### Table F1-1 Properties that can be set on an ACE5 interface (continued)

| Property | Description |
| --- | --- |
| MPAM_Support | Used to indicate whether an interface supports MPAM. |
|  | See Memory Partitioning and Monitoring (MPAM) on page E1-385 |
| Unique_ID_Support | Indicates whether an interface supports the Unique ID Indicator. |
|  | See Unique ID indicator on page E1-383. |
| Consistent_DECERR | Used to define whether a Subordinate signals DECERR consistently across |
|  | all beats of read and write response. |
|  | See Consistent DECERR response on page E1-401. |
| DVM_Message_Support | Used to describe the types of DVM messages that are supported by an |
|  | interface. |
|  | See About DVM transactions on page D13-318 |
| Exclusive_Accesses | Used to define whether a Manager issues exclusive accesses or whether a |
|  | Subordinate supports them. |
|  | See Exclusive accesses on page E1-399. |
| Max_Transaction_Bytes | Defines the maximum size of a transaction in bytes. |
|  | See Maximum transaction size and boundary on page E1-400. |
| Regular_Transactions_Only | Used to define whether a Manager issues only Regular type transactions |
|  | and if a Subordinate only supports Regular transactions. |
|  | See Regular transactions property on page A3-53. |
| Shareable_Transactions | Used to define whether a Manager issues Inner Shareable or Outer |
|  | Shareable transactions and whether a Subordinate supports them. |
|  | See Shareable transactions on page E1-399. |

a. Support in ACE5 has restrictions. See Use of Untranslated Transactions with ACE5 on page E1-372.

### F1.2 Signal descriptions

This section introduces the additional ACE5 interface signals that support the new capabilities. It contains the
following subsections:

- Changes to existing ACE channels

- Additional signaling on page F1-424

See Chapter D2 Signal Descriptions for details of the ACE interface signals.

### F1.2.1 Changes to existing ACE channels

Additional signals are required on the following ACE channels:

- Write address channel

- Write data channel on page F1-421
- Write response channel on page F1-421
- Read address channel on page F1-422
- Read data channel on page F1-423
- Snoop address channel on page F1-423
- Snoop response channel on page F1-423
- Snoop data channel on page F1-424

Parity check signals are not included in the tables in this section.

### Write address channel

Table F1-2 shows the additional write address channel signals.

Table F1-2 Write address channel signals

| Signal | Source | Property |  | Description |
| --- | --- | --- | --- | --- |
| AWTRACE | Manager | Trace_Signals |  | Supports the tracing of specific transactions through the |
|  |  |  |  | system. |
|  |  |  |  | See Trace signals on page E1-357. |
| AWLOOP | Manager | Loopback_Signals |  | Loopback value for a write transaction. Reflected back |
|  |  |  |  | on BLOOP. |
|  |  |  |  | See User Loopback signaling on page E1-359. |
|  | Manager |  |  | Secure Stream Identifier for a write transaction. See Untranslated transactions on page E1-369. |
| AWMMUSID | Manager |  |  | Stream Identifier for a write transaction. |
|  |  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUSSIDV | Manager |  |  | Indicates if the AWMMUSSID signal is valid. |
|  |  |  |  | See Untranslated transactions on page E1-369. |
| AWMMUSSID | Manager |  |  | Substream Identifier for a write transaction. |
|  |  |  |  | See Untranslated transactions on page E1-369. |

### AWMMUATST

Manager Untranslated_Transactions Indicates whether a write transaction has undergone
PCIe ATS translation.
See Untranslated transactions on page E1-369.

Table F1-2 Write address channel signals (continued)

| Signal Source | Property | Description |
| --- | --- | --- |
| AWNSAID Manager | NSAccess_Identifiers | Non-secure Access Identifier for a write transaction. |
|  |  | See Non-secure access identifiers on page E1-376. |
| AWMPAM Manager | MPAM_Support | Write address channel MPAM information. |
|  |  | See Memory Partitioning and Monitoring (MPAM) on |
|  |  | page E1-385. |
| AWIDUNQ Manager | Unique_ID_Support | Write address channel unique ID indicator, active |
|  |  | HIGH. |
|  |  | See Unique ID indicator on page E1-383. |
| Write data Table F1-3 shows the | write data channel | signals. Table F1-3 Write data channel |
| Signal | Source Property | Description |
| WPOISON | Manager Poison | Indicates that the write data in this transfer has been |
|  |  | corrupted. |
|  |  | See Chapter E2 Interface and data protection. |
| WTRACE | Manager | Supports the tracing of specific transactions through the system. |
|  |  | See Trace signals on page E1-357. |
| Write response Table F1-4 shows the | write response | signals. Table F1-4 Write response channel |
| Signal | Property | Description |
| BTRACE | Trace_signals | Supports the tracing of specific transactions through the system. |
|  |  | See Trace signals on page E1-357. |
| BLOOP | Loopback_Signals | Loopback value for a write response. See User Loopback signaling on page E1-359. |
| BIDUNQ |  | Write response channel unique ID indicator, active HIGH. |
|  |  | See Unique ID indicator on page E1-383. |

Read address channel

Table F1-5 shows the additional read address channel signals.

Table F1-5 Read address channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| ARVMIDEXT | Manager | DVM_v8.1 | VMID extension for a read address. |
|  |  |  | See DVM message versions on page D13-323. |
| ARTRACE | Manager | Trace_Signals | Supports the tracing of specific transactions through the |
|  |  |  | system. |
|  |  |  | See Trace signals on page E1-357. |
| ARLOOP | Manager | Loopback_Signals | Loopback value for a read transaction. |
|  |  |  | See User Loopback signaling on page E1-359. |
|  | Manager |  | Secure Stream Identifier for a read transaction. See Untranslated transactions on page E1-369. |
| ARMMUSID | Manager |  | Stream Identifier for a read transaction. |
|  |  |  | See Untranslated transactions on page E1-369. |
| ARMMUSSIDV | Manager |  | Substream Identifier for a read transaction. |
|  |  |  | See Untranslated transactions on page E1-369. |
| ARMMUSSID | Manager |  | Indicates whether the ARMMUSSID signal is valid. |
|  |  |  | See Untranslated transactions on page E1-369. |
| ARMMUATST | Manager |  | Indicates whether a read transaction has undergone PCIe |
|  |  |  | ATS translation. |
|  |  |  | See Untranslated transactions on page E1-369. |
| ARNSAID | Manager | NSAccess_Identifiers | Non-secure Access Identifier for a read transaction. |
|  |  |  | See Non-secure access identifiers on page E1-376. |
| ARMPAM | Manager | MPAM_Support | Read address channel MPAM information. |
|  |  |  | See Memory Partitioning and Monitoring (MPAM) on |
|  |  |  | page E1-385 |
| ARIDUNQ | Manager | Unique_ID_Support | Read address channel unique ID indicator, active HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |

Read data channel

Table F1-6 shows the additional read data channel signals.

Table F1-6 Read data channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| RPOISON | Interconnect | Poison | Indicates that the read data in this transfer has been |
|  |  |  | corrupted. |
|  |  |  | See Chapter E2 Interface and data protection. |
| RTRACE | Interconnect | Trace_Signals | Supports the tracing of specific transactions through the |
|  |  |  | system. |
|  |  |  | See Trace signals on page E1-357. |
| RLOOP | Interconnect | Loopback_Signals | Loopback value for a read response. |
|  |  |  | See User Loopback signaling on page E1-359. |
| RIDUNQ | Subordinate |  | Read data channel unique ID indicator, active HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |
| Snoop Table F1-7 | the | snoop address | signals. Table F1-7 Snoop address channel |
| Signal |  | Property | Description |
|  |  | DVM_v8.1 | VMID extension for a snoop address. See DVM message versions on page D13-323. |
|  |  |  | Supports the tracing of specific transactions through the system. |
|  |  |  | See Trace signals on page E1-357. |
| Snoop Table F1-8 | the | snoop response | signals. Table F1-8 Snoop response channel |
| Signal | Source | Property | Description |
|  | Manager | Trace_Signals | Supports the tracing of specific transactions through the |
|  |  |  | system |
|  |  |  | See Trace signals on page E1-357. |
| CRNSAID | Manager |  | Non-secure Access Identifier for a snoop response. |
|  |  |  | See Non-secure access identifiers on page E1-376. |

### Snoop data channel

Table F1-9 shows the additional snoop data channel signals.

Table F1-9 Snoop data channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th></th>
 </tr>
 <tr>
  <td></td>
  <td>Manager</td>
  <td>Poison</td>
  <td>that the snoop data in this transfer has been</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See</td>
  <td>E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>CDTRACE</td>
  <td>Manager</td>
  <td>Trace_Signals</td>
  <td>the tracing of specific transactions through the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>system.</td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See</td>
  <td>signals on page E1-357.</td>
 </tr>
 <tr>
  <td>F1.2.2 Additional</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>on</td>
  <td>new<br/>Table F1-10 Additional</td>
 </tr>
 <tr>
  <td>Signal</td>
  <td>Source</td>
  <td>Property</td>
  <td>Description</td>
 </tr>
 <tr>
  <td>VAWQOSACCEPT</td>
  <td>Subordinate</td>
  <td>QoS_Accept</td>
  <td>QoS acceptance level for write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transactions.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See QoS Accept signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-360.</td>
 </tr>
 <tr>
  <td>VARQOSACCEPT</td>
  <td>Subordinate</td>
  <td>QoS_Accept</td>
  <td>QoS acceptance level for read</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transactions.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See QoS Accept signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-360.</td>
 </tr>
 <tr>
  <td>AWAKEUP</td>
  <td>Manager</td>
  <td>Wakeup_Signals</td>
  <td>Indicates that activity is initiated on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>the write or read address channels.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Wake-up Signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-362.</td>
 </tr>
 <tr>
  <td>ACWAKEUP</td>
  <td>Interconnect</td>
  <td>Wakeup_Signals</td>
  <td>Indicates that activity is initiated on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>the snoop address channels.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Wake-up Signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-362.</td>
 </tr>
 <tr>
  <td>SYSCOREQ</td>
  <td>Manager</td>
  <td></td>
  <td>Coherency connect request.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Coherency Connection</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>signaling on page E1-364.</td>
 </tr>
 <tr>
  <td>SYSCOACK</td>
  <td>Interconnect</td>
  <td></td>
  <td>Coherency connect acknowledge.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Coherency Connection</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>signaling on page E1-364.</td>
 </tr>
</table>

## Chapter F2

### AMBA ACE5-Lite

This chapter specifies the new capabilities in the ACE5-Lite protocol specification. It contains the following
sections:

- About the ACE5-Lite protocol on page F2-426

- ACE5-Lite signal descriptions on page F2-428

### F2.1 About the ACE5-Lite protocol

ACE5-Lite extends the capabilities of the ACE-Lite protocol that is specified in Chapter D11 AMBA ACE-Lite. To
maintain compatibility, a property is used to declare a new capability. Table F2-1 summarizes the properties.

Table F2-1 Properties that can be set on an ACE5-Lite interface

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
  <td>have some form of operation that is associated with the transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Atomic transactions on page E1-342.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds Cache Stashing transactions that enable one component to indicate that<br/>a particular cache line should be placed in the cache of another component</td>
 </tr>
 <tr>
  <td></td>
  <td>in the system.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Cache stashing on page E1-351.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds Deallocation transactions that permit an IO coherent Manager to<br/>influence the allocation of cache lines in the system.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Deallocating transactions on page E1-355.</td>
 </tr>
 <tr>
  <td>Persist_CMO</td>
  <td>Adds an additional cache maintenance operation that is used to provide a</td>
 </tr>
 <tr>
  <td></td>
  <td>cache clean to the point of persistence operation.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO transactions on page D7-267.</td>
 </tr>
 <tr>
  <td>Check_Type</td>
  <td>Adds data or interface level parity signals for error detection.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>Poison</td>
  <td>Adds Poison signaling, which is used to indicate that a set of data bytes have</td>
 </tr>
 <tr>
  <td></td>
  <td>been previously corrupted.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Chapter E2 Interface and data protection.</td>
 </tr>
 <tr>
  <td>QoS_Accept</td>
  <td>Adds two additional QoS interface signals that enable a Subordinate to</td>
 </tr>
 <tr>
  <td></td>
  <td>indicate the QoS value of transactions that it will accept.</td>
 </tr>
 <tr>
  <td></td>
  <td>See QoS Accept signaling on page E1-360.</td>
 </tr>
 <tr>
  <td>Trace_Signals</td>
  <td>Adds a Trace signal that is associated with each channel to support the</td>
 </tr>
 <tr>
  <td></td>
  <td>debugging, tracing, and performance measurement of systems.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>Loopback_Signals</td>
  <td>Adds loopback signaling, which permits an agent that is issuing transactions</td>
 </tr>
 <tr>
  <td></td>
  <td>to store information relating to the transaction in an indexed table.</td>
 </tr>
 <tr>
  <td></td>
  <td>See User Loopback signaling on page E1-359</td>
 </tr>
 <tr>
  <td>Wakeup_Signaling</td>
  <td>Adds wakeup signaling, which is used to indicate that there is activity that is</td>
 </tr>
 <tr>
  <td></td>
  <td>associated with the interface.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Wake-up Signaling on page E1-362.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds untranslated transaction support and permits different transactions on<br/>the same interface to use different translation schemes.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Untranslated transactions on page E1-369.</td>
 </tr>
 <tr>
  <td>NSAccess_Identifiers</td>
  <td>Adds Non-secure access identifiers that support the storage and processing</td>
 </tr>
 <tr>
  <td></td>
  <td>of protected data.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Non-secure access identifiers on page E1-376.</td>
 </tr>
 <tr>
  <td>MPAM_Support</td>
  <td>Used to indicate whether an interface supports MPAM.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Memory Partitioning and Monitoring (MPAM) on page E1-385.</td>
 </tr>
 <tr>
  <td>CMO_On_Read</td>
  <td>Indicates whether an interface supports cache maintenance operations on the</td>
 </tr>
 <tr>
  <td></td>
  <td>read channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
</table>

### Table F2-1 Properties that can be set on an ACE5-Lite interface (continued)

<table>
 <tr>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>CMO_On_Write</td>
  <td>Indicates whether a component supports cache maintenance operations on</td>
 </tr>
 <tr>
  <td></td>
  <td>write channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
 <tr>
  <td></td>
  <td>Indicates whether an interface supports the interleaving of read data beats<br/>from different transactions.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Read interleaving property on page E1-382.</td>
 </tr>
 <tr>
  <td>Read_Data_Chunking</td>
  <td>Indicates whether an interface supports the return of read data in reorderable</td>
 </tr>
 <tr>
  <td></td>
  <td>chunks.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Read data chunking on page E1-378.</td>
 </tr>
 <tr>
  <td>Unique_ID_Support</td>
  <td>Indicates whether an interface supports the Unique ID Indicator.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td>Write_Plus_CMO</td>
  <td>Used to indicate whether a component supports combined write and CMOs</td>
 </tr>
 <tr>
  <td></td>
  <td>on the write channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Write with CMO configuration on page D7-277.</td>
 </tr>
 <tr>
  <td>MTE_Support</td>
  <td>Used to indicate that a component supports the Memory Tagging Extension.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Memory tagging on page E1-387.</td>
 </tr>
 <tr>
  <td>Prefetch_Transaction</td>
  <td>Used to indicate whether a component supports prefetching.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Prefetch request and response on page E1-396</td>
 </tr>
 <tr>
  <td>WriteZero_Transaction</td>
  <td>Used to indicate whether an interface supports the WriteZero transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Write zero with no data on page E1-398</td>
 </tr>
 <tr>
  <td>Consistent_DECERR</td>
  <td>Used to define whether a Subordinate signals DECERR consistently across</td>
 </tr>
 <tr>
  <td></td>
  <td>all beats of read and write response.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Consistent DECERR response on page E1-401.</td>
 </tr>
 <tr>
  <td>Exclusive_Accesses</td>
  <td>Used to define whether a Manager issues exclusive accesses or whether a</td>
 </tr>
 <tr>
  <td></td>
  <td>Subordinate supports them.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Exclusive accesses on page E1-399.</td>
 </tr>
 <tr>
  <td>Max_Transaction_Bytes</td>
  <td>Defines the maximum size of a transaction in bytes.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Maximum transaction size and boundary on page E1-400.</td>
 </tr>
 <tr>
  <td></td>
  <td>Used to define whether a Manager issues only Regular type transactions and<br/>if a Subordinate only supports Regular transactions.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Regular transactions property on page A3-53.</td>
 </tr>
 <tr>
  <td>Shareable_Transactions</td>
  <td>Used to define whether a Manager issues Inner Shareable or Outer Shareable</td>
 </tr>
 <tr>
  <td></td>
  <td>transactions and whether a Subordinate supports them.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Shareable transactions on page E1-399.</td>
 </tr>
</table>

### F2.2

### F2.2.1 ACE5-Lite signal descriptions

This section introduces the additional ACE5-Lite interface signals that support the new capabilities. It contains the
following subsections:

- Changes to existing ACE-Lite channels

- Additional signaling on page F2-433

See Chapter D11 AMBA ACE-Lite for details of the ACE-Lite interface signals.

### Changes to existing ACE-Lite channels

Additional signals are required on the following ACE-Lite channels:

- Write address channel

- Write data channel on page F2-430
- Write response channel on page F2-430
- Read address channel on page F2-431
- Read data channel on page F2-432

Parity check signals are not included in the tables in this section.

### Write address channel

Table F2-2 shows the additional write address channel signals.

### Table F2-2 Write address channel signals

| Signal | Source | Property |  | Description |
| --- | --- | --- | --- | --- |
| AWATOP | Manager | Atomic_Transactions |  | Indicates the type and endianness of atomic |
|  |  |  |  | transactions. |
|  |  |  |  | See Atomic transactions on page E1-342. |
| AWSTASHNID | Manager |  |  | Node Identifier of the target for a stash |
|  |  |  |  | operation. |
|  |  |  |  | See Cache stashing on page E1-351. |
|  | Manager |  |  | Write address Stash Node ID Enable. See Cache stashing on page E1-351. |
| AWSTASHLPID | Manager |  |  | Logical Processor Identifier within the |
|  |  |  |  | target for a stash operation. |
|  |  |  |  | See Cache stashing on page E1-351. |
|  | Manager |  |  | Indicates whether the AWSTASHLPID signal is valid. |
|  |  |  |  | See Cache stashing on page E1-351. |
| AWTRACE | Manager | Trace_Signals |  | Supports the tracing of specific transactions |
|  |  |  |  | through the system. |
|  |  |  |  | See Trace signals on page E1-357. |

AWLOOP Manager Loopback_Signals

Loopback value for a write transaction.
Reflected back on BLOOP.
See User Loopback signaling on
page E1-359.

Table F2-2 Write address channel signals (continued)

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>AWMMUSECSID</td>
  <td>Manager</td>
  <td></td>
  <td>Secure Stream Identifier for a write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWMMUSID</td>
  <td>Manager</td>
  <td></td>
  <td>Stream Identifier for a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWMMUSSIDV</td>
  <td></td>
  <td></td>
  <td>Indicates if the AWMMUSSID is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>valid.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWMMUSSID</td>
  <td>Manager</td>
  <td></td>
  <td>Substream Identifier for a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>This is valid if AWMMUSSIDV</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>is asserted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWMMUATST</td>
  <td>Manager</td>
  <td></td>
  <td>Indicates whether a write transaction has</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>undergone PCIe ATS translation.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWMMUFLOW</td>
  <td>Manager</td>
  <td></td>
  <td>Indicates the SMMU flow for managing</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>translation faults.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Untranslated transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-369.</td>
 </tr>
 <tr>
  <td>AWNSAID</td>
  <td>Manager</td>
  <td>NSAccess_Identifiers</td>
  <td>Non-secure Access Identifier for a write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Non-secure access identifiers on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-376.</td>
 </tr>
 <tr>
  <td>AWIDUNQ</td>
  <td>Manager</td>
  <td>Unique_ID_Support</td>
  <td>Write address channel unique ID indicator,</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>active HIGH.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td>AWCMO</td>
  <td>Manager</td>
  <td>CMO_On_Write</td>
  <td>Write address channel CMO indicator.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
 <tr>
  <td>AWMPAM</td>
  <td>Manager</td>
  <td>MPAM_Support</td>
  <td>Write address channel MPAM information.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Memory Partitioning and Monitoring</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>(MPAM) on page E1-385</td>
 </tr>
 <tr>
  <td>AWTAGOP</td>
  <td>Manager</td>
  <td>MTE_Support</td>
  <td>Write request tag operation.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
</table>

Write data channel

Table F2-3 shows the additional write data channel signals.

Table F2-3 Write data channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>WPOISON</td>
  <td></td>
  <td>Poison</td>
  <td>Indicates that the write data in this transfer has been</td>
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
  <td>WTRACE</td>
  <td></td>
  <td></td>
  <td>Supports the tracing of specific transactions through<br/>the system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>WTAG</td>
  <td></td>
  <td></td>
  <td>Indicates the tag that is associated with write data.<br/>See MTE signaling on page E1-388</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Indicates which tags must be written to memory in<br/>an Update operation.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
 <tr>
  <td>Write</td>
  <td>channel</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Table F2-4 Write response channel</td>
 </tr>
 <tr>
  <td>Signal</td>
  <td>Source</td>
  <td>Property</td>
  <td>Description</td>
 </tr>
 <tr>
  <td>BTRACE</td>
  <td>Interconnect</td>
  <td>Trace_signals</td>
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
  <td>BLOOP</td>
  <td>Interconnect</td>
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
  <td>Subordinate</td>
  <td></td>
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
  <td>BTAGMATCH</td>
  <td>Subordinate</td>
  <td>MTE_Support</td>
  <td>Indicates the result of a tag comparison on a write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
 <tr>
  <td>BCOMP</td>
  <td>Subordinate</td>
  <td>CMO_On_Write,</td>
  <td>Response flag that indicates that a write is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Persist_CMO,</td>
  <td>observable.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>MTE_Support</td>
  <td>See PCMO response on the B channel on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page D7-275 and MTE signaling on page E1-388.</td>
 </tr>
 <tr>
  <td>BPERSIST</td>
  <td>Subordinate</td>
  <td>CMO_On_Write,</td>
  <td>Response flag that indicates that write data is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Persist_CMO</td>
  <td>updated in persistent memory.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See PCMO response on the B channel on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page D7-275</td>
 </tr>
</table>

Read address channel

Table F2-5 shows the additional read address channel signals.

Table F2-5 Read address channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Property</th>
  <th>Description</th>
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
  <td>Indicates whether the ARMMUSSID signal is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>valid.</td>
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
 <tr>
  <td>ARMMUFLOW</td>
  <td>Manager</td>
  <td></td>
  <td>Indicates the SMMU flow for managing translation</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>faults.</td>
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
  <td>Read address channel MPAM information.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Memory Partitioning and Monitoring (MPAM)</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>on page E1-385</td>
 </tr>
 <tr>
  <td>ARCHUNKEN</td>
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
</table>

Read data channel

Table F2-6 shows the additional read data channel signals. Parity check signals are not included in this table.

Table F2-6 Read data channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| RPOISON | Interconnect | Poison | Indicates that the read data in this transfer has been |
|  |  |  | corrupted. |
|  |  |  | See Chapter E2 Interface and data protection. |
| RTRACE | Interconnect | Trace_Signals | Supports the tracing of specific transactions through |
|  |  |  | the system. |
|  |  |  | See Trace signals on page E1-357. |
| RLOOP | Interconnect | Loopback_Signals | Loopback value for a read response. |
|  |  |  | See User Loopback signaling on page E1-359. |
| RIDUNQ | Subordinate | Unique_ID_Support | Read data channel unique ID indicator, active |
|  |  |  | HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |
| RCHUNKV | Subordinate |  | Valid signal of RCHUNKNUM and |
|  |  |  | RCHUNKSTRB. |
|  |  |  | See Read data chunking on page E1-378. |
|  | Subordinate |  | Read data chunk number. See Read data chunking on page E1-378. |
|  | Subordinate |  | Read data chunk strobe. See Read data chunking on page E1-378. |
| RTAG | Subordinate | MTE_Support | The tag that is associated with read data. |
|  |  |  | See MTE signaling on page E1-388 |

### F2.2.2 Additional signaling

The following ancillary signaling is required on the ACE5-Lite interface to support the new capabilities. Table F2-7
shows the additional QoS accept and Wakeup signaling.

Table F2-7 QoS accept and Wakeup signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
|  | Subordinate | QoS_Accept | QoS acceptance level for write transactions. |
|  |  |  | See QoS Accept signaling on page E1-360. |
|  | Subordinate | QoS_Accept | QoS acceptance level for read transactions. |
|  |  |  | See QoS Accept signaling on page E1-360. |
| AWAKEUP |  |  | Indicates that is initiated on the write or read |
|  |  |  | address channels. |
|  |  |  | See Wake-up Signaling on page E1-362. |

## Chapter F3

### AMBA ACE5-LiteDVM

This chapter describes the new ACE5-LiteDVM protocol specification that is introduced in AMBA 5. It contains
the following sections:

- About the ACE5-LiteDVM protocol on page F3-436

- ACE5-LiteDVM signal descriptions on page F3-439

### F3.1 About the ACE5-LiteDVM protocol

Issue F of the AMBA AXI and ACE protocol specification introduced the AMBA protocol ACE5-LiteDVM.
ACE5-LiteDVM extends the capabilities of the ACE5-Lite protocol that is specified in Chapter F2 AMBA
ACE5-Lite.

ACE5-LiteDVM is identical to ACE5-Lite, with the addition of support for IO coherent components that include
SMMU functionality and therefore receive DVM transactions.

Untranslated transactions are not supported on ACE5-LiteDVM interfaces, since this interface is intended to be used
after translation has occurred.

An ACE5-LiteDVM Manager must be able to receive DVM messages on the AC channel. For DVM Syncronization
messages, the Manager must also be able to send DVM Complete messages on the AR channel.

An interconnect with an ACE5-LiteDVM interface can issue DVM messages on the AC channel, and must be able
to receive DVM Complete messages on the AR channel.

To maintain compatibility, a property is used to declare a new capability. Table F3-1 summarizes the properties.

### Table F3-1 Properties that can be set on an ACE5-LiteDVM interface

| Property | Description |
| --- | --- |
| Atomic_Transactions | Adds Atomic transactions that perform more than just a single access, |
|  | and have some form of operation that is associated with the transaction. |
|  | See Atomic transactions on page E1-342. |
| DVM_v8 | Specifies that a component supports DVMv8 and DVMv7 message |
|  | protocols. |
|  | See DVM message versions on page D13-323. |
| DVM_v8.1 | Specifies that a component supports DVMv8.1, DVMv8, and DVMv7 |
|  | message protocols. |
|  | See DVM message versions on page D13-323. |
| DVM_v8.4 | Specifies that a component supports DVMv8.4, DVMv8.1, DVMv8, |
|  | and DVMv7 message protocols. |
|  | See DVM message versions on page D13-323. |
|  | Adds Cache Stashing transactions that enable one component to indicate that a particular cache line should be placed in the cache of another |
|  | component in the system. |
|  | See Cache stashing on page E1-351. |
|  | Adds Deallocation transactions that permit an IO coherent Manager to influence the allocation of cache lines in the system. |
|  | See Deallocating transactions on page E1-355. |
| Persist_CMO | Adds an additional cache maintenance operation that is used to provide |
|  | a cache clean to the point of persistence operation. See CMO |
|  | transactions on page D7-267. |
| Check_Type | Adds data checking signaling, which is used to detect, and potentially |
|  | correct, data bytes that might have been corrupted. |
|  | See Chapter E2 Interface and data protection. |
| Poison | Adds Poison signaling, which is used to indicate that a set of data bytes |
|  | have been previously corrupted. |
|  | See Chapter E2 Interface and data protection. |

### Table F3-1 Properties that can be set on an ACE5-LiteDVM interface (continued)

<table>
 <tr>
  <th>Property</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>QoS_Accept</td>
  <td>Adds two additional QoS interface signals that enable a Subordinate to</td>
 </tr>
 <tr>
  <td></td>
  <td>indicate the QoS value of transactions that it will accept.</td>
 </tr>
 <tr>
  <td></td>
  <td>See QoS Accept signaling on page E1-360.</td>
 </tr>
 <tr>
  <td>Trace_Signals</td>
  <td>Adds a Trace signal, which is associated with each channel, to support</td>
 </tr>
 <tr>
  <td></td>
  <td>the debugging, tracing, and performance measurement of systems.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Trace signals on page E1-357.</td>
 </tr>
 <tr>
  <td>Loopback_Signals</td>
  <td>Adds loopback signaling that permits an agent that is issuing</td>
 </tr>
 <tr>
  <td></td>
  <td>transactions to store information to the transaction in an indexed</td>
 </tr>
 <tr>
  <td></td>
  <td>table.</td>
 </tr>
 <tr>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>Wakeup_Signals</td>
  <td>Adds two wakeup signals, which are used to indicate that there is activity</td>
 </tr>
 <tr>
  <td></td>
  <td>that is associated with the interface.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Wake-up Signaling on page E1-362.</td>
 </tr>
 <tr>
  <td></td>
  <td>Adds signaling to connect or disconnect this interface from the<br/>coherency system.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Coherency Connection signaling on page E1-364.</td>
 </tr>
 <tr>
  <td>NSAccess_Identifiers</td>
  <td>Adds Non-secure access identifiers that support the storage and</td>
 </tr>
 <tr>
  <td></td>
  <td>processing of protected data.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Non-secure access identifiers on page E1-376.</td>
 </tr>
 <tr>
  <td>MPAM_Support</td>
  <td>Used to indicate whether an interface supports MPAM.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Memory Partitioning and Monitoring (MPAM) on page E1-385.</td>
 </tr>
 <tr>
  <td>Unique_ID_Support</td>
  <td>Used to indicate if an interface supports the Unique ID Indicator:</td>
 </tr>
 <tr>
  <td></td>
  <td>See Unique ID indicator on page E1-383</td>
 </tr>
 <tr>
  <td>CMO_On_Write</td>
  <td>Indicates whether a component supports cache maintenance operations</td>
 </tr>
 <tr>
  <td></td>
  <td>on write channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
 <tr>
  <td>CMO_On_Read</td>
  <td>Indicates whether an interface supports cache maintenance operations</td>
 </tr>
 <tr>
  <td></td>
  <td>on the read channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See CMO signaling on page D7-271.</td>
 </tr>
 <tr>
  <td></td>
  <td>Used to indicate whether an interface supports the interleaving of read<br/>data beats from different transactions.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Read interleaving property on page E1-382</td>
 </tr>
 <tr>
  <td>Read_Data_Chunking</td>
  <td>Used to indicate whether an interface supports the return of read data in</td>
 </tr>
 <tr>
  <td></td>
  <td>reorderable chunks.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Read data chunking on page E1-378</td>
 </tr>
 <tr>
  <td>Write_Plus_CMO</td>
  <td>Used to indicate whether a component supports combined write and</td>
 </tr>
 <tr>
  <td></td>
  <td>CMOs on the write channels.</td>
 </tr>
 <tr>
  <td></td>
  <td>See Write with CMO configuration on page D7-277</td>
 </tr>
 <tr>
  <td>DVM_Message_Support</td>
  <td>Used to describe the types of DVM messages that are supported by an</td>
 </tr>
 <tr>
  <td></td>
  <td>interface.</td>
 </tr>
 <tr>
  <td></td>
  <td>See About DVM transactions on page D13-318</td>
 </tr>
</table>

Table F3-1 Properties that can be set on an ACE5-LiteDVM interface (continued)

| Property | Description |
| --- | --- |
| MTE_Support | Used to indicate that a component supports the Memory Tagging |
|  | Extension. |
|  | See Memory tagging on page E1-387 |
| Prefetch_Transaction | Used to indicate whether a component supports prefetching. |
|  | See Prefetch request and response on page E1-396 |
| WriteZero_Transaction | Used to indicate whether an interface supports the WriteZero |
|  | transaction. |
|  | See Write zero with no data on page E1-398 |
| Consistent_DECERR | Used to define whether a Subordinate signals DECERR consistently |
|  | across all beats of read and write response. See Consistent DECERR |
|  | response on page E1-401. |
| Exclusive_Accesses | Used to define whether a Manager issues exclusive accesses or whether |
|  | a Subordinate supports them. |
|  | See Exclusive accesses on page E1-399. |
| Max_Transaction_Bytes | Defines the maximum size of a transaction in bytes. See Maximum |
|  | transaction size and boundary on page E1-400. |
| Regular_Transactions_Only | Used to define whether a Manager issues only Regular type transactions |
|  | and if a Subordinate only supports Regular transactions. See Regular |
|  | transactions property on page A3-53. |
| Shareable_Transactions | Used to define whether a Manager issues Inner Shareable or Outer |
|  | Shareable transactions and whether a Subordinate supports them. |
|  | See Shareable transactions on page E1-399. |

### F3.2 ACE5-LiteDVM signal descriptions

This section introduces the additional ACE5-LiteDVM interface signals that support the new capabilities. It
contains the following subsections:

- Changes to existing ACE-Lite channels

- Additional channels on page F3-442
- Additional signaling on page F3-443

See Chapter D11 AMBA ACE-Lite for details of the ACE-Lite interface signals.

### F3.2.1 Changes to existing ACE-Lite channels

Additional signals are required on the following ACE-Lite channels:

- Write address channel

- Write data channel on page F3-440
- Write response channel on page F3-441
- Read address channel on page F3-441
- Read data channel on page F3-442

Parity check signals are not included in the following tables in this section.

### Write address channel

Table F3-2 shows the additional write address channel signals.

### Table F3-2 Write address channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
| AWATOP | Manager | Atomic_Transactions | Indicates the type and endianness of atomic |
|  |  |  | transactions. |
|  |  |  | See Atomic transactions on page E1-342. |
| AWSTASHNID | Manager |  | Node Identifier of the target for a stash |
|  |  |  | operation. |
|  |  |  | See Cache stashing on page E1-351. |
|  | Manager |  | Indicates whether the AWSTASHNID signal is valid. |
|  |  |  | See Cache stashing on page E1-351. |
| AWSTASHLPID | Manager |  | Logical Processor Identifier within the target |
|  |  |  | for a stash operation. |
|  |  |  | See Cache stashing on page E1-351. |
|  | Manager |  | Indicates whether a write transaction has undergone PCIe ATS translation |
|  |  |  | See Cache stashing on page E1-351. |
| AWTRACE | Manager | Trace_Signals | Supports the tracing of specific transactions |
|  |  |  | through the system. |
|  |  |  | See Trace signals on page E1-357. |
| AWLOOP | Manager | Loopback_Signals | Loopback value for a write transaction. |
|  |  |  | See User Loopback signaling on |
|  |  |  | page E1-359. |

Table F3-2 Write address channel signals (continued)

| Signal | Source |  |  | Description |
| --- | --- | --- | --- | --- |
| AWMPAM | Manager |  |  | Write address channel MPAM information. |
|  |  |  |  | See Memory Partitioning and Monitoring |
|  |  |  |  | (MPAM) on page E1-385 |
| AWNSAID | Manager |  |  | Non-secure Access Identifier for a write |
|  |  |  |  | transaction. |
|  |  |  |  | See Non-secure access identifiers on |
|  |  |  |  | page E1-376. |
| AWIDUNQ | Manager |  |  | Write address channel unique ID indicator, |
|  |  |  |  | active HIGH. |
|  |  |  |  | See Unique ID indicator on page E1-383. |
| AWCMO | Manager |  |  | Write address channel CMO indicator. |
|  |  |  |  | See CMO signaling on page D7-271. |
| AWTAGOP | Manager |  |  | Write request tag operation. |
|  |  |  |  | See MTE signaling on page E1-388 |
| Write data |  |  |  |  |
|  |  |  |  | Table F3-3 Write data channel |
| Signal |  |  | Property | Description |
|  |  |  | Poison | Indicates that the write data in this transfer has been corrupted. |
|  |  |  |  | See Chapter E2 Interface and data protection. |
| WTRACE |  |  | Trace_Signals | Supports the tracing of specific transactions through |
|  |  |  |  | the system. |
|  |  |  |  | See Trace signals on page E1-357. |
| WTAG |  |  | MTE_Support | Indicates the tag that is associated with write data. |
|  |  |  |  | See MTE signaling on page E1-388. |
|  |  |  | MTE_Support | Indicates which tags must be written to memory in an Update operation. |
|  |  |  |  | See MTE signaling on page E1-388 |

### Write response channel

Table F3-4 shows the additional write response channel signals.

Table F3-4 Write response channel signals

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
  <td>Supports the tracing of specific transactions</td>
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
  <td></td>
  <td>Write response channel unique ID indicator,<br/>active HIGH.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Unique ID indicator on page E1-383.</td>
 </tr>
 <tr>
  <td>BTAGMATCH</td>
  <td></td>
  <td>MTE_Support</td>
  <td>Indicates the result of a tag comparison on a</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See MTE signaling on page E1-388</td>
 </tr>
 <tr>
  <td>BCOMP</td>
  <td></td>
  <td>CMO_On_Write,</td>
  <td>Response flag that indicates that a write is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Persist_CMO,</td>
  <td>observable.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>MTE_Support</td>
  <td>See PCMO response on the B channel on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page D7-275 and MTE signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-388.</td>
 </tr>
 <tr>
  <td>BPERSIST</td>
  <td></td>
  <td>CMO_On_Write,</td>
  <td>Response flag that indicates that write data is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Persist_CMO</td>
  <td>updated in persistent memory.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See PCMO response on the B channel on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page D7-275.</td>
 </tr>
 <tr>
  <td>Read</td>
  <td>channel</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>Table F3-5 Read address channel</td>
 </tr>
 <tr>
  <td>Signal</td>
  <td>Source</td>
  <td></td>
  <td>Description</td>
 </tr>
 <tr>
  <td>ARVMIDEXT</td>
  <td>Manager</td>
  <td></td>
  <td>VMID extension for a read address.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See DVM message versions on page D13-323.</td>
 </tr>
 <tr>
  <td>ARTRACE</td>
  <td>Manager</td>
  <td></td>
  <td>Supports the tracing of specific transactions</td>
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
  <td>ARLOOP</td>
  <td>Manager</td>
  <td></td>
  <td>Loopback value for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See User Loopback signaling on page E1-359.</td>
 </tr>
 <tr>
  <td>ARNSAID</td>
  <td>Manager</td>
  <td></td>
  <td>Non-secure Access Identifier for a read</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Non-secure access identifiers on</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>page E1-376.</td>
 </tr>
 <tr>
  <td>ARMPAM</td>
  <td>Manager</td>
  <td></td>
  <td>Read address channel MPAM information.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>See Memory Partitioning and Monitoring</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
  <td>(MPAM) on page E1-385</td>
 </tr>
</table>

Table F3-5 Read address channel signals (continued)

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
|  | Manager | Read_Data_Chunking | Read data chunking enable. See Read data chunking on page E1-378. |
| ARIDUNQ | Manager | Unique_ID_Support | Read address channel unique ID indicator, |
|  |  |  | active HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |
| ARTAGOP | Manager | MTE_Support | Read request tag operation. |
|  |  |  | See MTE signaling on page E1-388 |
| Read data |  |  |  |
|  |  |  | Table F3-6 Read data channel |
| Signal | Source | Property | Description |
| RPOISON | Interconnect | Poison | Indicates that the read data in this transfer has |
|  |  |  | been corrupted. |
|  |  |  | See Chapter E2 Interface and data protection. |
| RTRACE | Interconnect | Trace_Signals | Supports the tracing of specific transactions |
|  |  |  | through the system. |
|  |  |  | See Trace signals on page E1-357. |
| RLOOP | Interconnect | Loopback_Signals | Loopback value for a read response. |
|  |  |  | See User Loopback signaling on page E1-359. |
| RIDUNQ | Subordinate | Unique_ID_Support | Read data channel unique ID indicator, active |
|  |  |  | HIGH. |
|  |  |  | See Unique ID indicator on page E1-383. |
| RCHUNKV | Subordinate |  | Valid signal of RCHUNKNUM and |
|  |  |  | RCHUNKSTRB. |
|  |  |  | See Read data chunking on page E1-378. |
|  | Subordinate |  | Read data chunk number. See Read data chunking on page E1-378. |
|  | Subordinate |  | Read data chunk strobe. See Read data chunking on page E1-378. |
| RTAG | Subordinate | MTE_Support | The tag that is associated with read data. |
|  |  |  | See MTE signaling on page E1-388 |

### F3.2.2 Additional channels

Two additional snoop channels are required on the ACE5-LiteDVM interface to support DVM message transfers.
See Chapter D13 Distributed Virtual Memory Transactions.

### Snoop address channel

Table F3-7 shows the additional signals on the snoop address channel.

Table F3-7 Snoop address channel signals

| Signal | Source | Property | Description |
| --- | --- | --- | --- |
|  |  | DVM_v8.1 | VMID extension for a snoop address. See DVM message versions on page D13-323. |
|  |  | Trace_Signals | Supports the tracing of specific transactions through the system. |
|  |  |  | See Trace signals on page E1-357. |
| Snoop Table F3-8 | shows the | signal on the snoop | channel. Table F3-8 Snoop response channel signal |
| Signal | Source | Property | Description |
|  | Manager | Trace_Signals | Supports the tracing of specific transactions |
|  |  |  | through the system. |
|  |  |  | See Trace signals on page E1-357. |
| F3.2.3 Additional |  |  |  |
|  |  |  | Table F3-9 QoS accept |
| Signal | Source | Property | Description |
| AWAKEUP | Manager | Wakeup_Signals | Indicates that activity is initiated on the |
|  |  |  | write or read address channels. |
|  |  |  | See Wake-up Signaling on page E1-362. |
| ACWAKEUP | Interconnect | Wakeup_Signals | Indicates that activity is initiated on the |
|  |  |  | snoop address channels. |
|  |  |  | See Wake-up Signaling on page E1-362. |
|  | Subordinate | QoS_Accept | QoS acceptance level for write transactions. |
|  |  |  | See QoS Accept signaling on page E1-360. |
| VARQOSACCEPT | Subordinate | QoS_Accept | QoS acceptance level for read transactions. |
|  |  |  | See QoS Accept signaling on page E1-360. |
| SYSCOREQ | Manager |  | Coherency connect request. |
|  |  |  | See Coherency Connection signaling on |
|  |  |  | page E1-364 |
| SYSCOACK | Interconnect |  | Coherency connect acknowledge. |
|  |  |  | See Coherency Connection signaling on |
|  |  |  | page E1-364 |

## Chapter F4

### ACE5-LiteACP

This chapter describes ACE5-LiteACP interface and associated protocol. It contains the following sections:

- Definition of ACE5-LiteACP on page F4-446
- Optional Extensions on page F4-447
- Interoperability on page F4-448
- ACE5-LiteACP signal list on page F4-449

### F4.1 Definition of ACE5-LiteACP

ACE5-LiteACP, which is a subset of ACE5-Lite, is intended for tightly coupling accelerator components to a
processor cluster. The interface is optimized for coherent cache line accesses and is less complex than an ACE5-Lite
interface. This simpler protocol enables high frequency, low latency implementations in this performance critical
application.

The ACE5-LiteACP interface supersedes the AMBA4 Accelerator Coherency Port (ACP) defined in ARM IHI
0022E.

Table F4-1 shows the differences between ACE5-Lite and ACE5-LiteACP interfaces. Any ACE5-Lite features
which are not mentioned in this specification are unchanged in ACE5-LiteACP. Table G2-1 on page G2-460 shows
the required and optional signals for an ACE-LiteACP interface.

Table F4-1 Differences between ACE5-Lite and ACE5-LiteACP

### ACE5-Lite

Data width

Up to 1024 bits

Transaction length

Up to 256 beats

Transaction size

Write strobes

| AxBURST | Any | INCR only |
| --- | --- | --- |
| AxCACHE | Any | Write-Back only: |
|  |  | - AxCACHE[1:0] is 0b11 |
|  |  | - AxCACHE[3:2] must not be 0b00 |

Any

Up to data bus width

AxDOMAIN Any

### ARSNOOP

0b0000 ReadNoSnoop / ReadOnce

0b1000 CleanShared

0b1001 CleanInvalid

0b1101 MakeInvalid

| AWSNOOP | 0b0000 WriteNoSnoop / WriteUniquePtl |
| --- | --- |
|  | 0b0001 WriteUniqueFull |
|  | 0b1000 WriteUniquePtlStash |
|  | 0b1001 WriteUniqueFullStash |
|  | 0b1100 StashOnceShared |
|  | 0b1101 StashOnceUnique |

0b1110 StashTranslation

| AxQOS | Supported | Not supported |
| --- | --- | --- |
| AxREGION | Supported | Not supported |
| Exclusive | Supported | Not supported |

### ACE5-LiteACP

128 bits

1 or 4 beats

128 bits

Any

0b00 Non-shareable

0b10 Outer Shareable

0b0000 ReadNoSnoop / ReadOnce

### F4.2 Optional Extensions

ACE5-LiteACP has a restricted number of AMBA 5 optional extensions, Table 2 shows which properties are
permitted to be True for ACE5-Lite and ACE5-LiteACP.

Table F4-2 Property options for ACE5-Lite and ACE5-LiteACP

<table>
 <tr>
  <th rowspan="31">Property<br/>Cache_Stash_Transactions<br/>Wakeup_Signals<br/>Check_Type<br/>Poison<br/>Trace_Signals<br/>QoS_Accept<br/>Loopback_Signals<br/>Untranslated_Transactions<br/>NSAccess_Identifiers<br/>Persist_CMO<br/>Atomic_Transactions<br/>DeAllocation_Transactions<br/>Unique_ID_Support<br/>Ordered_Write_Observation<br/>CMO_On_Read<br/>CMO_On_Write<br/>MPAM_Support<br/>Read_Interleaving_Disabled<br/>Read_Data_Chunking<br/>Multi-Copy_Atomicity<br/>Write_Plus_CMO<br/>MTE_Support<br/>Prefetch_Transaction<br/>WriteZero_Transaction<br/>Regular_Transactions_Only<br/>Exclusive_Accesses<br/>Sharable_Transactions<br/>Consistent_DECERR<br/>Max_Transaction_Bytes</th>
  <th>ACE5-Lite</th>
  <th>ACE5-LiteACP</th>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ARM IHI 0022H.c Copyright © 2003-2021 Arm Limited or its<br/>ID012621 Non-Confidential</td>
  <td>All rights reserved.</td>
  <td></td>
 </tr>
</table>

### F4.3

Interoperability

This section describes the interoperability of ACE5-Lite, ACE5-LiteACP, and ACP Managers and Subordinates.

Note

The ACP interface was defined in ARM IHI 0022E and is superseded with ACE5-LiteACP in this specification.

Table F4-3 Interoperability of ACE5-Lite, ACE5-LiteACP, and ACP Managers and Subordinates

| Manager | Subordinate | Interoperability |
| --- | --- | --- |
| ACE5-Lite | ACE5-LiteACP | Can connect directly if Manager uses ACE5-LiteACP subset of |
|  |  | transactions and optional features. |
| ACE5-LiteACP | ACE5-Lite | Fully operational. Tie off unused inputs according to Table 2. |
| ACP | ACE5-LiteACP | Fully operational. Set optional properties on ACE5-LiteACP to |
|  |  | False. |
| ACE5-LiteACP | ACP | Fully operational if Manager does not issue 64-byte write bursts with |
|  |  | sparse strobes. Set optional properties on ACE5-LiteACP to False. |

When connecting an ACE5-LiteACP Manager directly to an ACE5-Lite Subordinate interface, undriven inputs on
the ACE5-Lite Subordinate interface must be tied according to Table F4-4.

Table F4-4 Tie-offs for undriven signals in ACE5-LiteACP

| Signal | Tie-off | Meaning |
| --- | --- | --- |
| AxSIZE | 0b100 | 128 bit |
| AxBURST | 0b00 | INCR |
| AxLOCK | 0b0 | Normal access |
| AxQOS | 0b0000 | - |
| AxREGION | 0b0000 | - |

#### F4.4

### ACE5-LiteACP signal list

Table F4-5 lists the signals available on each channel with ACE5-LiteACP. Check signals are not included in this
table.

Table F4-5 ACE5-LiteACP signals

<table>
 <tr>
  <th></th>
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
 </tr>
 <tr>
  <th></th>
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
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>ACLK</th>
  <td>AWVALID</td>
  <td></td>
  <td>BVALID ARVALID</td>
  <td>RVALID</td>
 </tr>
 <tr>
  <th></th>
  <td>AWREADY</td>
  <td></td>
  <td>BREADY ARREADY</td>
  <td>RREADY</td>
 </tr>
 <tr>
  <th></th>
  <td>AWADDR</td>
  <td></td>
  <td>BRESP ARADDR</td>
  <td>RDATA</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWID</td>
  <td></td>
  <td>BID ARID</td>
  <td>RID</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWLEN</td>
  <td></td>
  <td>- ARLEN</td>
  <td>RLAST</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWCACHE</td>
  <td>-</td>
  <td>-ARCACHE</td>
  <td>RRESP</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWPROT</td>
  <td>-</td>
  <td>-ARPROT</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWDOMAIN</td>
  <td>-</td>
  <td>-AWDOMAIN</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWSNOOP</td>
  <td>-</td>
  <td>-ARSNOOP</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWTRACEa</td>
  <td></td>
  <td>BTRACEa ARTRACEa</td>
  <td>RTRACEa</td>
 </tr>
 <tr>
  <th>-</th>
  <td>-</td>
  <td></td>
  <td>- -</td>
  <td>RPOISONa</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWSTAHNIDa</td>
  <td>-</td>
  <td>- -</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td>-</td>
  <td>- -</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWSTASHLPIDa</td>
  <td>-</td>
  <td>- -</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td></td>
  <td>-</td>
  <td>- -</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWMPAMa</td>
  <td>-</td>
  <td>-ARMPAMa</td>
  <td>-</td>
 </tr>
 <tr>
  <th>-</th>
  <td>AWIDUNQa</td>
  <td>-</td>
  <td>BIDUNQa ARIDUNQa</td>
  <td>RIDUNQa</td>
 </tr>
 <tr>
  <th>-</th>
  <td>-</td>
  <td>-</td>
  <td></td>
  <td>RCHUNKVa</td>
 </tr>
 <tr>
  <th>-</th>
  <td>-</td>
  <td>-</td>
  <td>- -</td>
  <td>RCHUNKNUMa</td>
 </tr>
 <tr>
  <th>-</th>
  <td>-</td>
  <td>-</td>
  <td>- -</td>
  <td>RCHUNKSTRBa</td>
 </tr>
</table>

a. These signals are optional. See Table G2-1 on page G2-460

## Chapter F5

### Changes in ACE5 and ACE5-Lite

This chapter describes the changes in AMBA 5 to the ACE and ACE-Lite channel signaling requirements. It
contains the following sections:

- Shareability domain support on page F5-452

- Barrier transaction support on page F5-453

- AWSNOOP signal width on page F5-454

### F5.1 Shareability domain support

To simplify the specification and clarify the expected use of domains, from Issue F onward, the use of the Inner
Shareable domain is deprecated in the following interfaces:

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

This specification recommends that new designs use the Outer Shareable domain for all transactions that would
previously have been indicated as Inner Shareable.

Table F5-1 shows the updated definitions.

### Table F5-1 ACE5 and ACE5-Lite shareability domain encoding

|  | Description | Note |
| --- | --- | --- |
| 0b00 | Non-shareable | No change |
| 0b01 | Inner Shareable | Deprecated, use 0b10 |
| 0b10 | Outer Shareable | No change |
| 0b11 | System Shareable | No change |

### F5.2 Barrier transaction support

From Issue F onward, barrier transactions are not supported in ACE5 and ACE5-Lite variant interfaces. ACE5 and
ACE5-Lite Managers that require specific ordering or observability must delay the issue of dependent requests until
earlier transactions are complete.

The interface property Barrier_Transactions is used to indicate whether a component supports barrier transactions:

### True

The interface has the AxBAR signals and barrier transactions are supported. If Barrier_Transactions
is not declared, it is considered True.

The interface does not have AxBAR signals and barrier transactions are not supported.

False

The default for the Barrier_Transactions property is True, because legacy ACE and ACE-Lite components that
support barrier transactions might not have the Barrier_Transactions property defined.

Table F5-2 shows interoperability and indicates that special consideration must be given when connecting an ACE
or ACE-Lite Manager to an ACE5 or ACE5-Lite Subordinate.

### Table F5-2 Barrier Compatibility

| Manager | Subordinate | Barrier Compatibility |
| --- | --- | --- |
| ACE5 or | ACE5 or | Fully compatible. |
| ACE5-Lite | ACE5-Lite |  |

ACE5 or
ACE5-Lite

ACE or
ACE-Lite

ACE or
ACE-Lite

ACE5 or
ACE5-Lite

Fully compatible, tie off AxBAR Subordinate inputs to 0b00.

Compatible if Barrier_Transactions property is False or can be
configured to be False. AxBAR Manager outputs can be left
unconnected. Needs a bridging component if Barrier_Transactions
is True for Manager.

### F5.3 AWSNOOP signal width

From Issue G onward for ACE5-Lite, ACE5-LiteDVM, and ACE5-LiteACP interfaces, AWSNOOP is extended to
be 4 bits wide, to accommodate additional operations that are permitted on those interfaces.

When connecting a Manager with a 3-bit AWSNOOP output to a Subordinate interface with a 4-bit AWSNOOP
input, AWSNOOP[3] must be tied LOW.

When connecting a Manager with a 4-bit AWSNOOP output to a Subordinate interface with a 3-bit AWSNOOP
input, AWSNOOP[3] can be left unconnected. The Manager must not use any cache stash transactions.
