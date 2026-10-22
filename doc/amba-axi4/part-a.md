# Part A

## Chapter A1

### Introduction

This chapter introduces the architecture of the AXI protocol and the terminology that is used in this specification:

- About the AXI protocol on page A1-26

- AXI Architecture on page A1-27
- Terminology on page A1-30

### A1.1 About the AXI protocol

The AMBA AXI protocol supports high-performance, high-frequency system designs for communication between
Manager and Subordinate components.

The AXI protocol features are:

- It is suitable for high-bandwidth and low-latency designs.

- High-frequency operation is provided, without using complex bridges.

- The protocol meets the interface requirements of a wide range of components.

- It is suitable for memory controllers with high initial access latency.

- Flexibility in the implementation of interconnect architectures is provided.

- It is backward-compatible with AHB and APB interfaces.

The key features of the AXI protocol are:

- Separate address/control and data phases.

- Support for unaligned data transfers, using byte strobes.

- Uses burst-based transactions with only the start address issued.

- Separate read and write data channels, that can provide low-cost Direct Memory Access (DMA).

- Support for issuing multiple outstanding addresses.

- Support for out-of-order transaction completion.

- Permits easy addition of register stages to provide timing closure.

The AXI protocol includes:

AXI4-Lite, a subset of AXI4 for communication with simpler control register style interfaces within
components. See Chapter B1 AMBA AXI4-Lite.

AXI5-Lite, a subset of AXI5 for using AXI5 features with simpler control register style interfaces within
components. See Chapter C2 AMBA AXI5-Lite.

### A1.2 AXI Architecture

The AXI protocol is burst-based and defines five independent transaction channels:

- Read address, which has signal names beginning with AR.
- Read data, which has signal names beginning with R.
- Write address, which has signal names beginning with AW.
- Write data, which has signal names beginning with W.
- Write response, which has signal names beginning with B.

An address channel carries control information that describes the nature of the data to be transferred. The data is
transferred between Manager and Subordinate using either:

A write data channel to transfer data from the Manager to the Subordinate. In a write transaction, the
Subordinate uses the write response channel to signal the completion of the transfer to the Manager.

- A read data channel to transfer data from the Subordinate to the Manager.

The AXI protocol:

- Permits address information to be issued ahead of the actual data transfer.

- Supports multiple outstanding transactions.

- Supports out-of-order completion of transactions.

Figure A1-1 shows how a write transaction uses the write address, write data, and write response channels.

<table>
 <tr>
  <th colspan="5">Write address channel</th>
 </tr>
 <tr>
  <td rowspan="5">Manager<br/>interface</td>
  <td>Address<br/>and control</td>
  <td colspan="2"></td>
  <td rowspan="5">Subordinate<br/>interface</td>
 </tr>
 <tr>
  <td colspan="3">Write data channel</td>
 </tr>
 <tr>
  <td></td>
  <td>Write Write Write Write<br/>data data data data</td>
  <td></td>
 </tr>
 <tr>
  <td colspan="3">Write response channel</td>
 </tr>
 <tr>
  <td colspan="2"></td>
  <td>Write<br/>response</td>
 </tr>
</table>

### Figure A1-1 Channel architecture of writes

Figure A1-2 shows how a read transaction uses the read address and read data channels.

<table>
 <tr>
  <th colspan="4">Read address channel</th>
 </tr>
 <tr>
  <td rowspan="3">Manager<br/>interface</td>
  <td>Address<br/>and control</td>
  <td></td>
  <td rowspan="3">Subordinate<br/>interface</td>
 </tr>
 <tr>
  <td colspan="2">Read data channel</td>
 </tr>
 <tr>
  <td></td>
  <td>Read Read Read Read<br/>data data data data</td>
 </tr>
</table>

### Figure A1-2 Channel architecture of reads

### A1.2.1 Channel definition

Each of the five independent channels consists of a set of information signals and VALID and READY signals that
provide a two-way handshake mechanism. See Basic read and write transactions on page A3-41.

The information source uses the VALID signal to show when valid address, data, or control information is available
on the channel. The destination uses the READY signal to show when it can accept the information. Both the read
data channel and the write data channel also include a LAST signal to indicate the transfer of the final data item in
a transaction.

### Read and write address channels

Read and write transactions each have their own address channel. The appropriate address channel carries all the
required address and control information for a transaction.

### Read data channel

The read data channel carries both the read data and the read response information from the Subordinate to the
Manager, and includes:

- The data bus, which can be 8, 16, 32, 64, 128, 256, 512, or 1024 bits wide.

- A read response signal indicating the completion status of the read transaction.

### Write data channel

The write data channel carries the write data from the Manager to the Subordinate and includes:

- The data bus, which can be 8, 16, 32, 64, 128, 256, 512, or 1024 bits wide.

- A byte lane strobe signal for every eight data bits, indicating the bytes of the data that are valid.

Write data channel information is always treated as buffered, so that the Manager can perform write transactions
without Subordinate acknowledgement of previous write transactions.

### Write response channel

A Subordinate uses the write response channel to respond to write transactions. All write transactions require
completion signaling on the write response channel.

As Figure A1-1 on page A1-27 shows, completion is signaled only for a complete transaction, not for each data
transfer in a transaction.

### Interface and interconnect

### A1.2.2

A typical system consists of several Manager and Subordinate devices that are connected together through some
form of interconnect, as Figure A1-3 shows.

<table>
 <tr>
  <th rowspan="2">Manager1 Manager2 Manager3<br/>Interface</th>
 </tr>
 <tr>
 </tr>
 <tr>
  <th>Interconnect</th>
 </tr>
 <tr>
  <th>Interface</th>
 </tr>
 <tr>
  <th>Subordinate1 Subordinate2 Subordinate3 Subordinate4</th>
 </tr>
</table>

### Figure A1-3 Interface and interconnect

The AXI protocol provides a single interface definition, for the interfaces between:

- A Manager and the interconnect

- A Subordinate and the interconnect

- A Manager and a Subordinate

This interface definition supports many different interconnect implementations.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>An to Manager ports</td>
 </tr>
 <tr>
  <td>that the real Manager and Subordinate devices can be connected.</td>
 </tr>
</table>

### Typical system topologies

Most systems use one of three interconnect topologies:

- Shared address and data buses

- Shared address buses and multiple data buses

- Multilayer, with multiple address and data buses

In most systems, the address channel bandwidth requirement is significantly less than the data channel bandwidth
requirement. Such systems can achieve a good balance between system performance and interconnect complexity
by using a shared address bus with multiple data buses to enable parallel data transfers.

### A1.2.3 Register slices

Each AXI channel transfers information in only one direction, and the architecture does not require any fixed
relationship between the channels. These qualities mean that a register slice can be inserted at almost any point in
any channel, at the cost of an additional cycle of latency.

### Note

These qualities make the following possible:

- Trade-off between cycles of latency and maximum frequency of operation.

- Direct, fast connection between a processor and high-performance memory, but to use simple register slices to isolate a longer path to less performance critical peripherals.

### A1.3

### A1.3.1

### A1.3.2

### A1.3.3

### A1.3.4 Terminology

This section summarizes terms that are used in this specification, and are defined in the Glossary, or elsewhere.
Where appropriate, terms that are listed in this section link to the corresponding glossary definition.

### AXI components and topology

The following terms describe AXI components:

- Component
- Manager component
- Subordinate component, which includes Memory Subordinate
components
- Interconnect component

components and Peripheral Subordinate

For a particular AXI transaction, Upstream and Downstream refer to the relative positions of AXI components
within the AXI topology.

### AXI transactions, and memory types

When an AXI Manager initiates an AXI operation, targeting an AXI Subordinate:

- The complete set of required operations on the AXI bus form the AXI Transaction

- Any required payload data is transferred as an AXI Burst

- A burst can comprise multiple data transfers, or AXI Beats

### Caches and cache operation

This specification does not define standard cache terminology, that is defined in any reference work on caching.
However, the glossary entries for Cache and Cache line clarify how these terms are used in this document.

### Temporal description

The AXI specification uses the term in a timely manner.

## Chapter A2

### Signal Descriptions

This chapter introduces the AXI interface signals. Most of the signals are required for AXI3 and AXI4
implementations of the protocol, and the tables summarizing the signals identify the exceptions. This chapter
contains the following sections:

- Global signals on page A2-32

- Write address channel signals on page A2-33

- Write data channel signals on page A2-34

- Write response channel signals on page A2-35

- Read address channel signals on page A2-36
- Read data channel signals on page A2-37

Later chapters define the signal parameters and usage.

### A2.1 Global signals

Table A2-1 shows the global AXI signals. These signals are used by the AXI3 and AXI4 protocols.

### Table A2-1 Global signals

| Signal | Source | Description |
| --- | --- | --- |
| ACLK | Clock source | Global clock signal. Synchronous signals are sampled on the rising edge of the |
|  |  | global clock. |
|  |  | See Clock on page A3-40. |
| ARESETn | Reset source | Global reset signal. This signal is active-LOW. |
|  |  | See Reset on page A3-40. |

All signals are sampled on the rising edge of the global clock.

### A2.2 Write address channel signals

Table A2-2 shows the AXI write address channel signals. Unless the description indicates otherwise, a signal is used
by AXI3 and AXI4.

### Table A2-2 Write address channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>AWID</td>
  <td>Manager</td>
  <td>Identification tag for a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See ID signals on page A5-81.</td>
 </tr>
 <tr>
  <td>AWADDR</td>
  <td>Manager</td>
  <td>The address of the first transfer in a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Address structure on page A3-48.</td>
 </tr>
 <tr>
  <td>AWLEN</td>
  <td></td>
  <td>the exact number of data transfers in a write transaction. This information</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>determines the number of data transfers associated with the address.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>This changes between AXI3 and AXI4.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst length on page A3-48.</td>
 </tr>
 <tr>
  <td>AWSIZE</td>
  <td>Manager</td>
  <td>Size, the number of bytes in each data transfer in a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst size on page A3-49.</td>
 </tr>
 <tr>
  <td>AWBURST</td>
  <td>Manager</td>
  <td>Burst type, indicates how address changes between each transfer in a write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst type on page A3-49.</td>
 </tr>
 <tr>
  <td>AWLOCK</td>
  <td>Manager</td>
  <td>Provides information about the atomic characteristics of a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>This changes between AXI3 and AXI4.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Locked accesses on page A7-99.</td>
 </tr>
 <tr>
  <td>AWCACHE</td>
  <td>Manager</td>
  <td>Indicates how a write transaction is required to progress through a system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Memory types on page A4-69.</td>
 </tr>
 <tr>
  <td>AWPROT</td>
  <td>Manager</td>
  <td>Protection attributes of a write transaction: privilege, security level, and access</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>type.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Access permissions on page A4-75.</td>
 </tr>
 <tr>
  <td>AWQOS</td>
  <td>Manager</td>
  <td>Quality of Service identifier for a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See QoS signaling on page A8-102.</td>
 </tr>
 <tr>
  <td>AWREGION</td>
  <td>Manager</td>
  <td>Region indicator for a write transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Multiple region signaling on page A8-103.</td>
 </tr>
 <tr>
  <td>AWUSER</td>
  <td>Manager</td>
  <td>User-defined extension for the write address channel.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See User-defined signaling on page A8-104.</td>
 </tr>
 <tr>
  <td>AWVALID</td>
  <td>Manager</td>
  <td>Indicates that the write address channel signals are valid.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Channel handshake signals on page A3-42.</td>
 </tr>
 <tr>
  <td>AWREADY</td>
  <td>Subordinate</td>
  <td>Indicates that a transfer on the write address channel can be accepted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Channel handshake signals on page A3-42.</td>
 </tr>
</table>

### A2.3 Write data channel signals

Table A2-3 shows the AXI write data channel signals. Unless the description indicates otherwise, a signal is used
by AXI3 and AXI4.

### Table A2-3 Write data channel signals

| Signal | Source | Description |
| --- | --- | --- |
| WID | Manager | The ID tag of the write data transfer. |
|  |  | Implemented in AXI3 only. |
|  |  | See ID signals on page A5-81. |
| WDATA | Manager | Write data. |
|  |  | See Write data channel on page A3-43. |
| WSTRB | Manager | Write strobes, indicate which byte lanes hold valid data. |
|  |  | See Write strobes on page A3-54. |
| WLAST | Manager | Indicates whether this is the last data transfer in a write transaction. |
|  |  | See Write data channel on page A3-43. |
| WUSER | Manager | User-defined extension for the write data channel. |
|  |  | Not implemented in AXI3. |
|  |  | See User-defined signaling on page A8-104. |
| WVALID | Manager | Indicates that the write data channel signals are valid. |
|  |  | See Channel handshake signals on page A3-42. |
| WREADY | Subordinate | Indicates that a transfer on the write data channel can be accepted. |
|  |  | See Channel handshake signals on page A3-42. |

### A2.4 Write response channel signals

Table A2-4 shows the AXI write response channel signals. Unless the description indicates otherwise, a signal is
used by AXI3 and AXI4.

### Table A2-4 Write response channel signals

| Signal | Source | Description |
| --- | --- | --- |
| BID | Subordinate | Identification tag for a write response. |
|  |  | See ID signals on page A5-81. |
| BRESP | Subordinate | Write response, indicates the status of a write transaction. |
|  |  | See Read and write response structure on page A3-59. |
| BUSER | Subordinate | User-defined extension for the write response channel. |
|  |  | Not implemented in AXI3. |
|  |  | See User-defined signaling on page A8-104. |
| BVALID | Subordinate | Indicates that the write response channel signals are valid. |
|  |  | See Channel handshake signals on page A3-42. |
| BREADY | Manager | Indicates that a transfer on the write response channel can be accepted. |
|  |  | See Channel handshake signals on page A3-42. |

### A2.5 Read address channel signals

Table A2-5 shows the AXI read address channel signals. Unless the description indicates otherwise, a signal is used
by AXI3 and AXI4.

Table A2-5 Read address channel signals

<table>
 <tr>
  <th>Signal</th>
  <th>Source</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>ARID</td>
  <td>Manager</td>
  <td>Identification tag for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See ID signals on page A5-81.</td>
 </tr>
 <tr>
  <td>ARADDR</td>
  <td>Manager</td>
  <td>The address of the first transfer in a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Address structure on page A3-48.</td>
 </tr>
 <tr>
  <td>ARLEN</td>
  <td></td>
  <td>the exact number of data transfers in a read transaction. This between</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>AXI3 and AXI4.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst length on page A3-48.</td>
 </tr>
 <tr>
  <td>ARSIZE</td>
  <td>Manager</td>
  <td>Size, the number of bytes in each data transfer in a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst size on page A3-49.</td>
 </tr>
 <tr>
  <td>ARBURST</td>
  <td>Manager</td>
  <td>Burst type, indicates how address changes between each transfer in a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Burst type on page A3-49.</td>
 </tr>
 <tr>
  <td>ARLOCK</td>
  <td>Manager</td>
  <td>Provides information about the atomic characteristics of a read transaction. This</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>changes between AXI3 and AXI4.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Locked accesses on page A7-99.</td>
 </tr>
 <tr>
  <td>ARCACHE</td>
  <td>Manager</td>
  <td>Indicates how a read transaction is required to progress through a system.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Memory types on page A4-69.</td>
 </tr>
 <tr>
  <td>ARPROT</td>
  <td>Manager</td>
  <td>Protection attributes of a read transaction: privilege, security level, and access type.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Access permissions on page A4-75.</td>
 </tr>
 <tr>
  <td>ARQOS</td>
  <td>Manager</td>
  <td>Quality of Service identifier for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See QoS signaling on page A8-102.</td>
 </tr>
 <tr>
  <td>ARREGION</td>
  <td>Manager</td>
  <td>Region indicator for a read transaction.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Multiple region signaling on page A8-103.</td>
 </tr>
 <tr>
  <td>ARUSER</td>
  <td>Manager</td>
  <td>User-defined extension for the read address channel.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Not implemented in AXI3.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See User-defined signaling on page A8-104.</td>
 </tr>
 <tr>
  <td>ARVALID</td>
  <td>Manager</td>
  <td>Indicates that the read address channel signals are valid.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Channel handshake signals on page A3-42.</td>
 </tr>
 <tr>
  <td>ARREADY</td>
  <td>Subordinate</td>
  <td>Indicates that a transfer on the read address channel can be accepted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>See Channel handshake signals on page A3-42.</td>
 </tr>
</table>

### A2.6 Read data channel signals

Table A2-6 shows the AXI read data channel signals. Unless the description indicates otherwise, a signal is used by
AXI3 and AXI4.

### Table A2-6 Read data channel signals

| Signal | Source | Description |
| --- | --- | --- |
| RID | Subordinate | Identification tag for read data and response. |
|  |  | See ID signals on page A5-81. |
| RDATA | Subordinate | Read data. |
|  |  | See Read data channel on page A3-43. |
| RRESP | Subordinate | Read response, indicates the status of a read transfer. |
|  |  | See Read and write response structure on page A3-59. |
| RLAST | Subordinate | Indicates whether this is the last data transfer in a read transaction. |
|  |  | See Read data channel on page A3-43. |
| RUSER | Subordinate | User-defined extension for the read data channel. |
|  |  | Not implemented in AXI3. |
|  |  | See User-defined signaling on page A8-104. |
| RVALID | Subordinate | Indicates that the read data channel signals are valid. |
|  |  | See Channel handshake signals on page A3-42. |
| RREADY | Manager | Indicates that a transfer on the read data channel can be accepted. |
|  |  | See Channel handshake signals on page A3-42. |

## Chapter A3

### Single Interface Requirements

This chapter describes the basic AXI protocol transaction requirements between a single Manager and Subordinate.
It contains the following sections:

- Clock and reset on page A3-40

- Basic read and write transactions on page A3-41

- Relationships between the channels on page A3-44
- Transaction structure on page A3-48

### A3.1 Clock and reset

This section describes the requirements for implementing the AXI global clock and reset signals ACLK and
ARESETn.

### A3.1.1 Clock

Each AXI interface has a single clock signal, ACLK. All input signals are sampled on the rising edge of ACLK.
All output signal changes can only occur after the rising edge of ACLK.

On Manager and Subordinate interfaces, there must be no combinatorial paths between input and output signals.

### A3.1.2 Reset

The AXI protocol uses a single active-LOW reset signal, ARESETn. The reset signal can be asserted
asynchronously, but deassertion can only be synchronous with a rising edge of ACLK.

During reset the following interface requirements apply:

- A Manager interface must drive ARVALID, AWVALID, and WVALID LOW.

- A Subordinate interface must drive RVALID and BVALID LOW.

- All other signals can be driven to any value.

The earliest point after reset that a Manager is permitted to begin driving ARVALID, AWVALID, or WVALID
HIGH is at a rising ACLK edge after ARESETn is HIGH. Figure A3-1 shows the earliest point after reset that
ARVALID, AWVALID, or WVALID, can be driven HIGH.

<table>
 <tr>
  <th rowspan="2">ACLK<br/>ARESETn<br/>VALID</th>
 </tr>
 <tr>
 </tr>
</table>

### Figure A3-1 Exit from reset

### A3.2 Basic read and write transactions

This section defines the basic mechanisms for AXI protocol transactions. The basic mechanisms are:

- The Handshake process

- The Channel signaling requirements on page A3-42

### A3.2.1 Handshake process

All five transaction channels use the same VALID/READY handshake process to transfer address, data, and control
information. This two-way flow control mechanism means both the Manager and Subordinate can control the rate
that the information moves between Manager and Subordinate. The source generates the VALID signal to indicate
when the address, data, or control information is available. The destination generates the READY signal to indicate
that it can accept the information. Transfer occurs only when both the VALID and READY signals are HIGH.

On Manager and Subordinate interfaces, there must be no combinatorial paths between input and output signals.

Figure A3-2 to Figure A3-4 on page A3-42 show examples of the handshake process.

The source presents information after T1 and asserts the VALID signal as shown in Figure A3-2. The destination
asserts the READY signal after T2. The source must keep its information stable until the transfer occurs at T3, when
this assertion is recognized.

T1

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
 </tr>
</table>

T2

T3

### Figure A3-3 READY before VALID handshake

A destination is permitted to wait for VALID to be asserted before asserting the corresponding READY.

If READY is asserted, it is permitted to deassert READY before VALID is asserted.

In Figure A3-4, both the source and destination happen to indicate that they can transfer the address, data, or control
information after T1. In this case, the transfer occurs at the rising clock edge when the assertion of both VALID and
READY can be recognized. These assertions means that the transfer occurs at T2.

T1

<table>
 <tr>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
  <th></th>
 </tr>
</table>

T2

INFORMATION

### Figure A3-4 VALID with READY handshake

The individual AXI protocol channel handshake mechanisms are described in Channel signaling requirements.

### Channel signaling requirements

### A3.2.2

The following sections define the handshake signals and the handshake rules for each channel:

- Channel handshake signals
- Write address channel
- Write data channel on page A3-43
- Write response channel on page A3-43
- Read address channel on page A3-43
- Read data channel on page A3-43

### Channel handshake signals

Each channel has its own VALID/READY handshake signal pair. Table A3-1 shows the signals for each channel.

Table A3-1 Transaction channel handshake pairs

<table>
 <tr>
  <th>Transaction channel</th>
  <td>Handshake pair</td>
 </tr>
 <tr>
  <th>Write address channel</th>
  <td>AWVALID, AWREADY</td>
 </tr>
 <tr>
  <th>Write data channel</th>
  <td>WVALID, WREADY</td>
 </tr>
 <tr>
  <th>Write response channel</th>
  <td>BVALID, BREADY</td>
 </tr>
 <tr>
  <th>Read address channel</th>
  <td>ARVALID, ARREADY</td>
 </tr>
 <tr>
  <th>Read data channel</th>
  <td>RVALID, RREADY</td>
 </tr>
</table>

### Write address channel

The Manager can assert the AWVALID signal only when it drives valid address and control information. When
asserted, AWVALID must remain asserted until the rising clock edge after the Subordinate asserts AWREADY.

The default state of AWREADY can be either HIGH or LOW. This specification recommends a default state of
HIGH. When AWREADY is HIGH, the Subordinate must be able to accept any valid address that is presented to it.

### Note

This specification does not recommend a default AWREADY state of LOW, because it forces the transfer to take
at least two cycles, one to assert AWVALID and another to assert AWREADY.

Write data channel

During a write burst, the Manager can assert the WVALID signal only when it drives valid write data. When
asserted, WVALID must remain asserted until the rising clock edge after the Subordinate asserts WREADY.

The default state of WREADY can be HIGH, but only if the Subordinate can always accept write data in a single
cycle.

The Manager must assert the WLAST signal while it is driving the final write transfer in the burst.

This specification recommends that WDATA is driven to zero for inactive byte lanes.

### Write response channel

The Subordinate can assert the BVALID signal only when it drives a valid write response. When asserted, BVALID
must remain asserted until the rising clock edge after the Manager asserts BREADY.

The default state of BREADY can be HIGH, but only if the Manager can always accept a write response in a single
cycle.

### Read address channel

The Manager can assert the ARVALID signal only when it drives valid address and control information. When
asserted, ARVALID must remain asserted until the rising clock edge after the Subordinate asserts the ARREADY
signal.

The default state of ARREADY can be either HIGH or LOW. This specification recommends a default state of
HIGH. If ARREADY is HIGH, then the Subordinate must be able to accept any valid address that is presented to it.

### Note

This specification does not recommend a default ARREADY value of LOW, because it forces the transfer to take
at least two cycles, one to assert ARVALID and another to assert ARREADY.

### Read data channel

The Subordinate can assert the RVALID signal only when it drives valid read data. When asserted, RVALID must
remain asserted until the rising clock edge after the Manager asserts RREADY. Even if a Subordinate has only one
source of read data, it must assert the RVALID signal only in response to a request for data.

The Manager interface uses the RREADY signal to indicate that it accepts the data. The default state of RREADY
can be HIGH, but only if the Manager is able to accept read data immediately when it starts a read transaction.

The Subordinate must assert the RLAST signal when it is driving the final read transfer in the burst.

This specification recommends that RDATA is driven to zero for inactive byte lanes.

### A3.3

### A3.3.1 Relationships between the channels

The AXI protocol requires the following relationships to be maintained:

- A write response must always follow the last write transfer in a write

- Read data must always follow the read address of the data.

- Channel handshakes must conform to the dependencies defined in Dependencies signals.

transaction.

between channel handshake

The protocol does not define any other relationship between the channels.

The lack of relationship means, for example, that the write data can appear at an interface before the write address
for the transaction. This can occur if the write address channel contains more register stages than the write data
channel. Similarly, the write data might appear in the same cycle as the address.

When a Manager issues a write request, it must be able to provide all write data for that transaction, without
dependency on other transactions from that Manager.

When a Manager issues a read request, it must be able to accept all read data for that transaction, without
dependency on other transactions from that Manager.

Note that a Manager can rely on read data returning in order from transactions that use the same ID, so the Manager
only needs enough storage for read data from transactions with different IDs.

### Dependencies between channel handshake signals

To prevent a deadlock situation, the dependency rules that exist between the handshake signals must be observed.

As summarized in Channel signaling requirements on page A3-42, in any transaction:

The VALID signal of the AXI interface sending information must not be dependent on the READY signal
of the AXI interface receiving that information.

An AXI interface that is receiving information can wait until it detects a VALID signal before it asserts its
corresponding READY signal.

In addition, there are dependencies between the handshake signals on different channels, and AXI4 defines an
additional write response dependency. The following subsections define these dependencies:

- Read transaction dependencies on page A3-45
- AXI3 write transaction dependencies on page A3-45
- AXI4 and AXI5 write transaction dependencies on page A3-46

In the dependency diagrams:

- Single-headed arrows point to signals that can be asserted before or after the signal at the start of the arrow.
- Double-headed arrows point to signals that must be asserted only after assertion of the signal at the start of
the arrow.

### Read transaction dependencies

Figure A3-5 shows the read transaction handshake signal dependencies, and shows that, in a read transaction:

- The Manager must not wait for the Subordinate to assert ARREADY before asserting ARVALID.

- The Subordinate can wait for ARVALID to be asserted before it asserts ARREADY.

- The Subordinate can assert ARREADY before ARVALID is asserted.

The Subordinate must wait for both ARVALID and ARREADY to be asserted before it asserts RVALID to
indicate that valid data is available.

The Subordinate must not wait for the Manager to assert RREADY before asserting RVALID.

The Manager can wait for RVALID to be asserted before it asserts RREADY.

The Manager can assert RREADY before RVALID is asserted.

ARVALID RVALID

ARREADY RREADY

Figure A3-5 Read transaction handshake dependencies

### AXI3 write transaction dependencies

Figure A3-6 shows the write transaction handshake signal dependencies, and shows that in a write transaction:

The Manager must not wait for the Subordinate to assert AWREADY or WREADY before asserting
AWVALID or WVALID.

The Subordinate can wait for AWVALID or WVALID, or both before asserting AWREADY.

The Subordinate can assert AWREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate can wait for AWVALID or WVALID, or both, before asserting WREADY.

The Subordinate can assert WREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate must wait for both WVALID and WREADY to be asserted before asserting BVALID.
The Subordinate must also wait for WLAST to be asserted before asserting BVALID. Waiting is required
because the write response, BRESP, must be signaled only after the last data transfer of a write transaction.

- The Subordinate must not wait for the Manager to assert BREADY before asserting BVALID.

- The Manager can wait for BVALID before asserting BREADY.

- The Manager can assert BREADY before BVALID is asserted.

<table>
 <tr>
  <th>AWVALID WVALID† BVALID</th>
 </tr>
 <tr>
  <td>AWREADY WREADY BREADY</td>
 </tr>
 <tr>
  <td>† Dependencies on the assertion of WVALID also require the assertion of WLAST</td>
 </tr>
</table>

Figure A3-6 AXI3 write transaction handshake dependencies

<table>
 <tr>
  <th>Caution</th>
 </tr>
 <tr>
  <td>must to prevent a For a Manager must not</td>
 </tr>
 <tr>
  <td>AWREADY to be asserted before driving WVALID. A deadlock condition can occur if the Subordinate is waiting</td>
 </tr>
 <tr>
  <td>for WVALID before asserting AWREADY.</td>
 </tr>
</table>

### AXI4 and AXI5 write transaction dependencies

AXI4 and AXI5 define an additional Subordinate write response dependency. The Subordinate must wait for
AWVALID, AWREADY, WVALID, and WREADY to be asserted before asserting BVALID. By issuing a write
response, the Subordinate takes responsibility for hazard checking the write transaction against all subsequent
transactions.

Figure A3-7 shows all the AXI4 and AXI5 required Subordinate write response handshake dependencies. The
single-headed arrows point to signals that can be asserted before or after the previous signal is asserted.
Double-headed arrows point to signals that must be asserted only after assertion of the previous signal.

These dependencies are:

The Manager must not wait for the Subordinate to assert AWREADY or WREADY before asserting
AWVALID or WVALID.

The Subordinate can wait for AWVALID or WVALID, or both, before asserting AWREADY.

The Subordinate can assert AWREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate can wait for AWVALID or WVALID, or both, before asserting WREADY.

The Subordinate can assert WREADY before AWVALID or WVALID, or both, are asserted.

The Subordinate must wait for AWVALID, AWREADY, WVALID, and WREADY to be asserted before
asserting BVALID.

The Subordinate must also wait for WLAST to be asserted before asserting BVALID. This wait is because
the write response, BRESP, must be signaled only after the last data transfer of a write transaction.

The Subordinate must not wait for the Manager to assert BREADY before asserting BVALID.

The Manager can wait for BVALID before asserting BREADY.

The Manager can assert BREADY before BVALID is asserted.

<table>
 <tr>
  <th>AWVALID WVALID† BVALID</th>
 </tr>
 <tr>
  <td>AWREADY WREADY BREADY</td>
 </tr>
 <tr>
  <td>† Dependencies on the assertion of WVALID also require the assertion of WLAST</td>
 </tr>
</table>

Figure A3-7 AXI4 and AXI5 write transaction handshake dependencies

### A3.3.2 Legacy considerations

The additional dependency that is described in AXI4 and AXI5 write transaction dependencies on page A3-46
means that an AXI3 Subordinate that accepts all write data and provides a write response before accepting the
address is not compliant with AXI4 or AXI5. Converting an AXI3 legacy Subordinate to AXI4 or AXI5 requires
the addition of a wrapper. That wrapper ensures a returning write response is not provided until the appropriate
address has been accepted by the Subordinate.

### Note

This specification strongly recommends that any new AXI3 Subordinate implementation includes this additional
dependency.

Any AXI3 Manager complies with the AXI4 and AXI5 write response requirements.

### A3.4

### A3.4.1 Transaction structure

This section describes the structure of transactions. The following sections define the address, data, and response
structures:

- Address structure
- Pseudocode description of the transfers on page A3-52
- Data read and write structure on page A3-54
- Read and write response structure on page A3-59

For the definitions of terms that are used in this section, see Glossary on page Glossary-493.

### Address structure

The AXI protocol is burst-based. The Manager begins each burst by driving control information and the address of
the first byte in the transaction to the Subordinate. As the burst progresses, the Subordinate must calculate the
addresses of subsequent transfers in the burst.

A burst must not cross a 4KB address boundary.

### Burst length

The burst length is specified by:

- ARLEN[7:0], for read transfers

- AWLEN[7:0], for write transfers

In this specification, AxLEN indicates ARLEN or AWLEN.

AXI3 supports burst lengths of 1-16 transfers, for all burst types.

AXI4 extends burst length support for the INCR burst type to 1-256 transfers. Support for all other burst types in
AXI4 remains at 1-16 transfers.

The burst length for AXI3 is defined as:

Burst_Length = AxLEN[3:0] + 1

To accommodate the extended burst length of the INCR burst type in AXI4, the burst length for AXI4 is defined as:

Burst_Length = AxLEN[7:0] + 1

AXI has the following rules governing the use of bursts:

- For wrapping bursts, the burst length must be 2, 4, 8, or 16.

- A burst must not cross a 4KB address boundary.

- Early termination of bursts is not supported.

No component can terminate a burst early. However, to reduce the number of data transfers in a write burst, the
Manager can disable further writing by deasserting all the write strobes. In this case, the Manager must complete
the remaining transfers in the burst. In a read burst, the Manager can discard read data, but it must complete all
transfers in the burst.

In AXI4, transactions with INCR burst type and length greater than 16 can be converted to multiple smaller bursts,
even if the transaction attributes indicate that the transaction is Non-modifiable. See AXI4 changes to memory
attribute signaling on page A4-64. In this case, the generated bursts must retain the same transaction characteristics
as the original transaction, the only exception is that:

- The burst length is reduced.

- The address of the generated bursts is adapted appropriately.

Note

The ability to break longer bursts into multiple shorter bursts is required for AXI3 compatibility. This ability might
also be needed to reduce the impact of longer bursts on the QoS guarantees.

### Burst size

The maximum number of bytes to transfer in each data transfer, or beat, in a burst, is specified by:

- ARSIZE[2:0], for read transfers

- AWSIZE[2:0], for write transfers

In this specification, AxSIZE indicates ARSIZE or AWSIZE.

Table A3-2 shows the AxSIZE encoding.

### Table A3-2 Burst size encoding

|  | Bytes in transfer |
| --- | --- |
| 0b000 | 1 |
| 0b001 | 2 |
| 0b010 | 4 |
| 0b011 | 8 |
| 0b100 | 16 |
| 0b101 | 32 |
| 0b110 | 64 |
| 0b111 | 128 |

If the AXI bus is wider than the burst size, the AXI interface must determine from the transfer address which byte
lanes of the data bus to use for each transfer. See Data read and write structure on page A3-54.

The size of any transfer must not exceed the data bus width of either agent in the transaction.

### Burst type

The AXI protocol defines three burst types:

FIXED In a fixed burst:

- The address is the same for every transfer in the burst.

- The byte lanes that are valid are constant for all beats in the burst. However, within those byte lanes, the actual bytes that have WSTRB asserted can differ for each beat in the burst.

This burst type is used for repeated accesses to the same location such as when loading or emptying
a FIFO.

### INCR

Incrementing. In an incrementing burst, the address for each transfer in the burst is an increment of
the address for the previous transfer. The increment value depends on the size of the transfer. For
example, for an aligned start address, the address for each transfer in a burst with a size of 4 bytes
is the previous address plus four.

This burst type is used for accesses to normal sequential memory.

### WRAP

A wrapping burst is similar to an incrementing burst, except that the address wraps around to a lower
address if an upper address limit is reached.

The following restrictions apply to wrapping bursts:

- The start address must be aligned to the size of each transfer.

- The length of the burst must be 2, 4, 8, or 16 transfers.

The behavior of a wrapping burst is:

- The lowest address that is used by the burst is aligned to the total size of the data to be
transferred, that is, to ((size of each transfer in the burst) × (number of transfers in the burst)).
This address is defined as the wrap boundary.

After each transfer, the address increments in the same way as for an INCR burst. However,
if this incremented address is ((wrap boundary) + (total size of data to be transferred)),
then the address wraps round to the wrap boundary.

The first transfer in the burst can use an address that is higher than the wrap boundary, subject
to the restrictions that apply to wrapping bursts. The address wraps for any WRAP burst
when the first address is higher than the wrap boundary.

This burst type is used for cache line accesses.

The burst type is specified by:

- ARBURST[1:0], for read transfers
- AWBURST[1:0], for write transfers

In this specification, AxBURST indicates ARBURST or AWBURST.

Table A3-3 shows the AxBURST signal encoding.

Table A3-3 Burst type encoding

|  | Burst type |
| --- | --- |
| 0b00 | FIXED |
| 0b01 | INCR |
| 0b10 | WRAP |
| 0b11 | Reserved |

### Burst address

This section provides methods for determining the address and byte lanes of transfers within a burst. The equations
use the following variables:

Start_Address

Number_Bytes

Data_Bus_Bytes

Aligned_Address

Burst_Length

Address_N

The start address that is issued by the Manager.

The maximum number of bytes in each data transfer.

The number of byte lanes in the data bus.

The aligned version of the start address.

The total number of data transfers within a burst.

The address of transfer N in a burst. N is 1 for the first transfer in a burst.

### Wrap_Boundary

### Lower_Byte_Lane

### Upper_Byte_Lane

### INT(x)

### The lowest address within a wrapping burst.

The byte lane of the lowest addressed byte of a transfer.

The byte lane of the highest addressed byte of a transfer.

The rounded-down integer value of x.

These equations determine addresses of transfers within a burst:

Start_Address = AxADDR
Number_Bytes = 2 ^ AxSIZE
Burst_Length = AxLEN +1
Aligned_Address = (INT(Start_Address /

Number_Bytes)) × Number_Bytes

This equation determines the address of the first transfer in a burst:

Address_1 = Start_Address

For an INCR burst, and for a WRAP burst for which the address has not wrapped, this equation determines the
address of any transfer after the first transfer in a burst:

Address_N = Aligned_Address + (N - 1) × Number_Bytes

For a WRAP burst, the Wrap_Boundary variable defines the wrapping boundary:

Wrap_Boundary = (INT(Start_Address / (Number_Bytes × Burst_Length)))× (Number_Bytes × Burst_Length)

For a WRAP burst, if Address_N = Wrap_Boundary + (Number_Bytes × Burst_Length), then:

- Use this equation for the current transfer:

- Address_N = Wrap_Boundary

- Use this equation for any subsequent transfers:

- Address_N = Start_Address + ((N - 1) × Number_Bytes) - (Number_Bytes × Burst_Length)

These equations determine the byte lanes to use for the first transfer in a burst:

Lower_Byte_Lane = Start_Address - (INT(Start_Address / Data_Bus_Bytes)) × Data_Bus_Bytes

Upper_Byte_Lane = Aligned_Address + (Number_Bytes - 1) -
(INT(Start_Address / Data_Bus_Bytes)) × Data_Bus_Bytes

These equations determine the byte lanes to use for all transfers after the first transfer in a burst:

Lower_Byte_Lane = Address_N - (INT(Address_N / Data_Bus_Bytes)) × Data_Bus_Bytes
Upper_Byte_Lane = Lower_Byte_Lane + Number_Bytes - 1

Data is transferred on:

DATA((8 × Upper_Byte_Lane) + 7: (8 × Lower_Byte_Lane))

The transaction container describes all the bytes that could be accessed in that transaction, if the address is aligned
and strobes are asserted:

Container_Size = Number_Bytes x Burst_Length

For INCR bursts:

Container_Lower = Aligned_Address
Container_Upper = Aligned_Address + Container_Size

For WRAP bursts:

Container_Lower = Wrap_Boundary
Container_Upper = Wrap_Boundary + Container_Size

### Pseudocode description of the transfers

### A3.4.2

// DataTransfer()

// ==============

DataTransfer(Start_Address, Number_Bytes, Burst_Length, Data_Bus_Bytes, Mode, IsWrite)

// Data_Bus_Bytes is the number of 8-bit byte lanes in the bus

// Mode is the AXI transfer mode

// IsWrite is TRUE for a write, and FALSE for a read

assert Mode IN {FIXED, WRAP, INCR};

addr = Start_Address; // Variable for current address

Aligned_Address = (INT(addr/Number_Bytes) * Number_Bytes);

aligned = (Aligned_Address == addr); // Check whether addr is aligned to nbytes

dtsize = Number_Bytes * Burst_Length; // Maximum total data transaction size

if mode == WRAP then

Lower_Wrap_Boundary = (INT(addr/dtsize) * dtsize);

// addr must be aligned for a wrapping burst

Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

for n = 1 to Burst_Length

Lower_Byte_Lane = addr - (INT(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;

if aligned then

Upper_Byte_Lane = Lower_Byte_Lane + Number_Bytes - 1

else

Upper_Byte_Lane = Aligned_Address + Number_Bytes - 1

- (INT(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;

// Peform data transfer

if IsWrite then

dwrite(addr, low_byte, high_byte)

else

dread(addr, low_byte, high_byte);

// Increment address if necessary

if mode != FIXED then

if aligned then

addr = addr + Number_Bytes;

if mode == WRAP then

// WRAP mode is always aligned

if addr >= Upper_Wrap_Boundary then addr = Lower_Wrap_Boundary;

else

addr = Aligned_Address + Number_Bytes;

aligned = TRUE; // All transfers after the first are aligned

return;

### A3.4.3 Regular transactions

There are many options of burst, size, and length for a transaction. However, some interfaces and transaction types
might only use a subset of these options. If a Subordinate component is attached to a Manager which uses only a
subset of transaction options, it can be designed with simplified decode logic.

The Regular attribute is defined, to identify transactions which meet the following criteria:

- AxLEN is 1, 2, 4, 8, or 16.
- AxSIZE is the same as the data bus width, if AxLEN is greater than 1.

- AxBURST is INCR or WRAP, not FIXED.

- AxADDR is aligned to the transaction container for INCR transactions.
- AxADDR is aligned to AxSIZE for WRAP transactions.

### Regular transactions property

The Regular_Transactions_Only property is used to define whether a Manager issues only Regular type transactions
and if a Subordinate only supports Regular transactions:
TRUE Only Regular transactions are supported.
FALSE All legal combinations of AxBURST, AxSIZE, and AxLEN are supported.

If Regular_Transactions_Only is not declared, it is considered to be False.

The Regular_Transactions_Only property can be True for the following interfaces:

- AXI5

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

### Interoperability

Table A3-4 gives guidance applies for connecting Manager and Subordinate components with different property
values:

Table A3-4 Regular_Transactions_Only Interoperability

|  | Subordinate: False | Subordinate: True |
| --- | --- | --- |
| Manager: False | Compatible. | Not compatible. If the Manager issues a transaction that is not Regular, then data corruption or deadlock might occur. |
| Manager: True | Compatible. | Compatible. |

### Data read and write structure

### A3.4.4

This section describes the transfers of varying sizes on the AXI read and write data buses and how the interface
performs mixed-endian and unaligned transfers. It contains the following sections:

- Write strobes
- Narrow transfers
- Byte invariance on page A3-55
- Unaligned transfers on page A3-56

### Write strobes

The WSTRB[n:0] signals when HIGH, specify the byte lanes of the data bus that contain valid information. There
is one write strobe for each 8 bits of the write data bus, therefore WSTRB[n] corresponds to
WDATA[(8n)+7: (8n)].

A Manager must ensure that the write strobes are HIGH only for byte lanes that contain valid data.

When WVALID is LOW, the write strobes can take any value, although this specification recommends that they are
either driven LOW or held at their previous value.

### Narrow transfers

In Figure A3-8:

- The burst has five transfers.

- The starting address is 0.

- Each transfer is 8 bits.

- The transfers are on a 32-bit bus.

- The burst type is INCR.

When a Manager generates a transfer that is narrower than its data bus, the address and control information
determine the byte lanes that the transfer uses:

- In incrementing or wrapping bursts, different byte lanes are used on each beat of the burst.

- In a fixed burst, the same byte lanes are used on each beat.

Figure A3-8 and Figure A3-9 on page A3-55 give two examples of byte lanes use. The shaded cells indicate bytes
that are not transferred.

<table>
 <tr>
  <th>31 24</th>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>D[7:0]</td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td>D[15:8]</td>
  <td></td>
  <td>2nd transfer</td>
 </tr>
 <tr>
  <th></th>
  <td>D[23:16]</td>
  <td></td>
  <td></td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th>D[31:24]</th>
  <td></td>
  <td></td>
  <td></td>
  <td>4th transfer</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td>D[7:0]</td>
  <td>5th transfer</td>
 </tr>
 <tr>
  <th colspan="5"></th>
 </tr>
</table>

### Figure A3-8 Narrow transfer example with 8-bit transfers

In Figure A3-9:

- The burst has three transfers.

- The starting address is 4.

- Each transfer is 32 bits.

- The transfers are on a 64-bit bus.

<table>
 <tr>
  <th>63 56</th>
  <td>55 48</td>
  <td>47 40</td>
  <td>39 32</td>
  <td>31 24</td>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th>D[63:56]</th>
  <td>D[55:48]</td>
  <td>D[47:40]</td>
  <td>D[39:32]</td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th></th>
  <td></td>
  <td></td>
  <td></td>
  <td>D[31:24]</td>
  <td>D[23:16]</td>
  <td>D[15:8]</td>
  <td>D[7:0]</td>
  <td>2nd transfer</td>
 </tr>
 <tr>
  <th>D[63:56]</th>
  <td>D[55:48]</td>
  <td>D[47:40]</td>
  <td>D[39:32]</td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th colspan="9">WDATA[63:0]</th>
 </tr>
</table>

### Figure A3-9 Narrow transfer example with 32-bit transfers

### Byte invariance

To access mixed-endian data structures in a single memory space, the AXI protocol uses a byte-invariant endianness
scheme.

Byte-invariant endianness means that, for any multi-byte element in a data structure:

- The element uses the same continuous bytes of memory, regardless of the endianness of the data.

The endianness determines the order of those bytes in memory, meaning it determines whether the first byte
in memory is the most significant byte (MSB) or the least significant byte (LSB) of the element.

Any byte transfer to an address passes the 8 bits of data on the same data bus wires, to the same address
location, regardless of the endianness of any larger data element that it is a constituent of.

Components that have only one transfer width must have their byte lanes that are connected to the appropriate byte
lanes of the data bus. Components that support multiple transfer widths might require a more complex interface to
convert an interface that is not naturally byte-invariant.

Most little-endian components can connect directly to a byte-invariant interface. Components that support only
big-endian transfers require a conversion function for byte-invariant operation.

The examples in Figure A3-10 and on page A3-56 show a 32-bit number 0x0A0B0C0D, stored in a register and in a
memory.

Figure A3-10 shows an example of the big-endian, byte-invariant, data structure. In this structure:

- The most significant byte (MSB) of the data, which is 0x0A, is stored in the MSB position in the register.
- The MSB of the data is stored in the memory location with the lowest address.
- The other data bytes are positioned in decreasing order of significance.

<table>
 <tr>
  <th>Addr<br/>31 24 23 16 15 8 7 0 Addr+1<br/>0x0A 0x0B 0x0C 0x0D<br/>Addr+2<br/>Register<br/>Addr+3</th>
  <th>0x0A<br/>0x0B<br/>0x0C<br/>0x0D</th>
  <th>Memory</th>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td></td>
 </tr>
</table>

Figure A3-10 Example big-endian byte-invariant data structure

Figure A3-11 shows an example of the little-endian, byte-invariant, data structure. In this structure:

- The least significant byte (LSB) of the data, which is 0x0D, is stored in the LSB position in the register.

- The LSB of the data is stored in the memory location with the lowest address.

- The other data bytes are positioned in increasing order of significance.

<table>
 <tr>
  <th>Addr<br/>31 24 23 16 15 8 7 0 Addr+1<br/>0x0A 0x0B 0x0C 0x0D<br/>Addr+2<br/>Register<br/>Addr+3</th>
  <th>0x0D<br/>0x0C<br/>0x0B<br/>0x0A</th>
  <th>Memory</th>
 </tr>
</table>

### Figure A3-11 Example little-endian byte-invariant data structure

The examples in Figure A3-10 on page A3-55 and Figure A3-11 show that byte invariance ensures that big-endian
and little-endian structures can coexist in a single memory space without corruption. Figure A3-12 shows an
example of a data structure that requires byte-invariant access. In this example, the header fields use little-endian
ordering, and the payload uses big-endian ordering.

<table>
 <tr>
  <th>31 24 23 16 15 8 7 0</th>
 </tr>
 <tr>
  <th>D0† Source Packet</th>
 </tr>
 <tr>
  <th>Checksum D1†</th>
 </tr>
 <tr>
  <th>Data items</th>
 </tr>
 <tr>
  <th>Payload</th>
 </tr>
 <tr>
  <th>Payload</th>
 </tr>
 <tr>
  <th>Payload</th>
 </tr>
 <tr>
  <th>Payload</th>
 </tr>
</table>

byte ordering

Header, little-endian

Payload, big-endian

byte ordering

† 16-bit continuous

field

Destination

### Figure A3-12 Example mixed-endian data structure

In this structure, for example, Data items is a two-byte little-endian element, meaning its lowest address is its LSB.
The use of byte invariance ensures that a big-endian access to the payload does not corrupt the little-endian element.

### Unaligned transfers

AXI supports unaligned transfers. For any burst that is made up of data transfers wider than 1 byte, the first bytes
accessed might be unaligned with the natural address boundary. For example, a 32-bit data packet that starts at a
byte address of 0x1002 is not aligned to the natural 32-bit address boundary.

A Manager can:

- Use the low-order address lines to signal an unaligned start address.
- Provide an aligned address and use the byte lane strobes to signal the

unaligned start address.

### Note

The information on the low-order address lines must be consistent with the information on the byte lane strobes.

The Subordinate is not required to take special action based on any alignment information from the Manager.

Figure A3-13 shows examples of incrementing bursts, with aligned and unaligned 32-bit transfers, on a 32-bit bus.
Each row in the figure represents a transfer and the shaded cells indicate bytes that are not transferred.

| 31 24 | 23 16 | 15 8 | 7 0 |
| --- | --- | --- | --- |
| 0x03 | 0x02 | 0x01 | 0x00 |
| 0x07 | 0x06 | 0x05 | 0x04 |
| 0x0B | 0x0A | 0x09 | 0x08 |
| 0x0F | 0x0E | 0x0D | 0x0C |

Address: 0x00
Transfer size: 32-bits
Burst type: incrementing
Burst length: 4 transfers

Address: 0x01
Transfer size: 32-bits
Burst type: incrementing
Burst length: 4 transfers

Address: 0x01
Transfer size: 32-bits
Burst type: incrementing
Burst length: 5 transfers

Address: 0x07
Transfer size: 32-bits
Burst type: incrementing
Burst length: 5 transfers

1st transfer

2nd transfer

3rd transfer

4th transfer

WDATA[31:0]

| 31 24 | 23 16 | 15 8 | 7 0 |
| --- | --- | --- | --- |
| 0x03 | 0x02 | 0x01 | 0x00 |
| 0x07 | 0x06 | 0x05 | 0x04 |
| 0x0B | 0x0A | 0x09 | 0x08 |
| 0x0F | 0x0E | 0x0D | 0x0C |

1st transfer

2nd transfer

3rd transfer

4th transfer

WDATA[31:0]

| 31 24 | 23 16 | 15 8 | 7 0 |
| --- | --- | --- | --- |
| 0x03 | 0x02 | 0x01 | 0x00 |
| 0x07 | 0x06 | 0x05 | 0x04 |
| 0x0B | 0x0A | 0x09 | 0x08 |
| 0x0F | 0x0E | 0x0D | 0x0C |
| 0x13 | 0x12 | 0x11 | 0x10 |

1st transfer

2nd transfer

3rd transfer

4th transfer

5th transfer

WDATA[31:0]

| 31 24 | 23 16 | 15 8 | 7 0 |
| --- | --- | --- | --- |
| 0x07 | 0x06 | 0x05 | 0x04 |
| 0x0B | 0x0A | 0x09 | 0x08 |
| 0x0F | 0x0E | 0x0D | 0x0C |
| 0x13 | 0x12 | 0x11 | 0x10 |
| 0x17 | 0x16 | 0x15 | 0x14 |

1st transfer

2nd transfer

3rd transfer

4th transfer

5th transfer

WDATA[31:0]

### Figure A3-13 Aligned and unaligned transfers on a 32-bit bus

Figure A3-14 shows examples of incrementing bursts, with aligned and unaligned 32-bit transfers, on a 64-bit bus.
Each row in the figure represents a transfer and the shaded cells indicate bytes that are not transferred.

<table>
 <tr>
  <th></th>
  <td>63 56</td>
  <td>55 48</td>
  <td>47 40</td>
  <td>39 32</td>
  <td>31 24</td>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th>Address: 0x00</th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>2nd</td>
 </tr>
 <tr>
  <th>Burst type: incrementing</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th></th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>4th transfer</td>
 </tr>
 <tr>
  <th colspan="10">WDATA[63:0]</th>
 </tr>
 <tr>
  <th></th>
  <td>63 56</td>
  <td>55 48</td>
  <td>47 40</td>
  <td>39 32</td>
  <td>31 24</td>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th>Address: 0x07</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>2nd</td>
 </tr>
 <tr>
  <th>Burst type: incrementing</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th></th>
  <td>0x17</td>
  <td>0x16</td>
  <td>0x15</td>
  <td>0x14</td>
  <td>0x13</td>
  <td>0x12</td>
  <td>0x11</td>
  <td>0x10</td>
  <td>4th transfer</td>
 </tr>
 <tr>
  <th colspan="10">WDATA[63:0]</th>
 </tr>
 <tr>
  <th></th>
  <td>63 56</td>
  <td>55 48</td>
  <td>47 40</td>
  <td>39 32</td>
  <td>31 24</td>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th>Address: 0x07</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>2nd</td>
 </tr>
 <tr>
  <th>Transfer size: 32-bits</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th>Burst length: 5 transfers</th>
  <td>0x17</td>
  <td>0x16</td>
  <td>0x15</td>
  <td>0x14</td>
  <td>0x13</td>
  <td>0x12</td>
  <td>0x11</td>
  <td>0x10</td>
  <td>4th transfer</td>
 </tr>
 <tr>
  <th></th>
  <td>0x17</td>
  <td>0x16</td>
  <td>0x15</td>
  <td>0x14</td>
  <td>0x13</td>
  <td>0x12</td>
  <td>0x11</td>
  <td>0x10</td>
  <td>5th transfer</td>
 </tr>
 <tr>
  <th colspan="10">WDATA[63:0]</th>
 </tr>
</table>

### Figure A3-14 Aligned and unaligned transfers on a 64-bit bus

Figure A3-15 shows an example of a wrapping burst, with aligned 32-bit transfers, on a 64-bit bus. Each row in the
figure represents a transfer and the shaded cells indicate bytes that are not transferred.

<table>
 <tr>
  <th></th>
  <td>63 56</td>
  <td>55 48</td>
  <td>47 40</td>
  <td>39 32</td>
  <td>31 24</td>
  <td>23 16</td>
  <td>15 8</td>
  <td>7 0</td>
  <td></td>
 </tr>
 <tr>
  <th></th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>1st transfer</td>
 </tr>
 <tr>
  <th>Address: 0x04</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>2nd transfer</td>
 </tr>
 <tr>
  <th>Burst type: wrapping</th>
  <td>0x0F</td>
  <td>0x0E</td>
  <td>0x0D</td>
  <td>0x0C</td>
  <td>0x0B</td>
  <td>0x0A</td>
  <td>0x09</td>
  <td>0x08</td>
  <td>3rd transfer</td>
 </tr>
 <tr>
  <th></th>
  <td>0x07</td>
  <td>0x06</td>
  <td>0x05</td>
  <td>0x04</td>
  <td>0x03</td>
  <td>0x02</td>
  <td>0x01</td>
  <td>0x00</td>
  <td>4th transfer</td>
 </tr>
 <tr>
  <th colspan="10">WDATA[63:0]</th>
 </tr>
</table>

### Figure A3-15 Aligned wrapping transfers on a 64-bit bus

### A3.4.5 Read and write response structure

The AXI protocol provides response signaling for both read and write transactions:

- For read transactions, the response information from the Subordinate is signaled on the read data channel.

- For write transactions the response information is signaled on the write response channel.

The responses are signaled by:

- RRESP[1:0], for read transfers.

- BRESP[1:0], for write transfers.

The responses are:

### OKAY

Normal access success. Indicates that a normal access has been successful. Can also indicate that an
exclusive access has failed. See OKAY, normal access success.

### EXOKAY

Exclusive access okay. Indicates that either the read or write portion of an exclusive access has been
successful. See EXOKAY, exclusive access success on page A3-60.

### SLVERR

Subordinate error. Used when the access has reached the Subordinate successfully, but the
Subordinate wishes to return an error condition to the originating Manager. See SLVERR,
Subordinate error on page A3-60.

### DECERR

Decode error. Generated, typically by an interconnect component, to indicate that there is no
Subordinate at the transaction address. See DECERR, decode error on page A3-60.

Table A3-5 shows the encoding of the RRESP and BRESP signals.

### Table A3-5 RRESP and BRESP encoding

|  | Response |
| --- | --- |
| 0b00 | OKAY |
| 0b01 | EXOKAY |
| 0b10 | SLVERR |
| 0b11 | DECERR |

For a write transaction, a single response is signaled for the entire burst, and not for each data transfer within the
burst.

In a read transaction, the Subordinate can signal different responses for different transfers in a burst. For example,
in a burst of 16 read transfers the Subordinate might return an OKAY response for 15 of the transfers and a SLVERR
response for one of the transfers.

The protocol specifies that the required number of data transfers must be performed, even if an error is reported. For
example, if a read of eight transfers is requested from a Subordinate but the Subordinate has an error condition, the
Subordinate must perform eight data transfers, each with an error response. The remainder of the burst is not
canceled if the Subordinate gives a single error response.

### OKAY, normal access success

An OKAY response indicates any one of the following:

- The success of a normal access.

- The failure of an exclusive access.

- An exclusive access to a Subordinate that does not

support exclusive access.

OKAY is the response for most transactions.

### EXOKAY, exclusive access success

An EXOKAY response indicates the success of an exclusive access. This response can only be given as the response
to an exclusive read or write. See Exclusive accesses on page A7-96.

### SLVERR, Subordinate error

The SLVERR response indicates an unsuccessful transaction.

To simplify system monitoring and debugging, this specification recommends that error responses are used only for
error conditions and not for signaling normal, expected events. Examples of Subordinate error conditions are:

- FIFO or buffer overrun or underrun condition

- Unsupported transfer size attempted.

- Write access attempted to read-only location

- Timeout condition in the Subordinate

- Access attempted to a disabled or powered-down function

### DECERR, decode error

The DECERR response indicates that the interconnect cannot successfully decode a Subordinate access.

If the interconnect cannot successfully decode a Subordinate access, it must return the DECERR response. This
specification recommends that the interconnect routes the access to a default Subordinate, and the default
Subordinate returns the DECERR response.

The AXI protocol requires that all data transfers for a transaction are completed, even if an error condition occurs.
Any component giving a DECERR response must meet this requirement.

## Chapter A4

### Transaction Attributes

This chapter describes the attributes that determine how a transaction should be treated by system components such
as caches, buffers, and memory controllers. It contains the following sections:

- Transaction types and attributes on page A4-62

- AXI3 memory attribute signaling on page A4-63
- AXI4 changes to memory attribute signaling on page A4-64
- Memory types on page A4-69
- Mismatched memory attributes on page A4-73
- Transaction buffering on page A4-74
- Access permissions on page A4-75
- Legacy considerations on page A4-76
- Usage examples on page A4-77

### A4.1 Transaction types and attributes

Subordinates are classified as either:

### Memory Subordinate

A Memory Subordinate is required to handle all transaction types correctly.

### Peripheral Subordinate

A Peripheral Subordinate has an IMPLEMENTATION DEFINED method of access. Typically, the
method of access is defined in the component data sheet, that describes the transaction types that the
Subordinate handles correctly.
Any access to the Peripheral Subordinate that is not part of the IMPLEMENTATION DEFINED method
of access must complete, in compliance with the protocol. However, when such an access has been
made, there is no requirement that the Peripheral Subordinate continues to operate correctly. It is
only required to continue to complete further transactions in a protocol-compliant manner.

### Note

Compliant completion of all transaction types is required to prevent system deadlock,
however, continued correct operation of the Peripheral Subordinate is not required.

Because a Peripheral Subordinate is required to work correctly only for a defined method of
access, it can have a reduced set of interface signals.

The AXI protocol defines a set of transaction attributes that support memory and Peripheral Subordinates. The
ARCACHE and AWCACHE signals specify the transaction attributes. They control:

- How a transaction progresses through the system.

- How any system-level caches handle the transaction.

In this specification, the term AxCACHE refers collectively to the ARCACHE and AWCACHE signals.

The following sections describe the transaction attributes:

- AXI3 memory attribute signaling on page A4-63
- AXI4 changes to memory attribute signaling on page

### A4.2 AXI3 memory attribute signaling

In AXI3, the AxCACHE[3:0] signals specify the Bufferable, Cacheable, and Allocate attributes of the transaction.
Table A4-1 shows the AxCACHE encoding.

### Table A4-1 Transaction attribute encoding

|  |  | Transaction attribute |
| --- | --- | --- |
| [0] | 0 | Non-bufferable |
|  | 1 | Bufferable |
| [1] | 0 | Non-cacheable |
|  | 1 | Cacheable |
| [2] | 0 | No Read-Allocate |
|  | 1 | Read-Allocate |
| [3] | 0 | No Write-Allocate |
|  | 1 | Write-Allocate |

### AxCACHE[0], Bufferable (B) bit

When this bit is asserted, the interconnect, or any component, can delay the transaction reaching its
final destination for any number of cycles.

### Note

Normally, the Bufferable attribute is only relevant to writes.

### AxCACHE[1], Cacheable (C) bit

When this bit is deasserted, allocation of the transaction is forbidden.
When this bit is asserted:

- Allocation of the transaction is permitted. RA and WA give additional hint information.

- The characteristics of a transaction at the final destination does not have to match the characteristics of the original transaction. For writes this means that several different writes can be merged together. For reads this means that the contents of a location can be prefetched, or the values from a single fetch can be used for multiple read transactions.

AxCACHE[2], Read-Allocate (RA) bit
When this bit is asserted, read allocation of the transaction is recommended but is not mandatory.
The RA bit must not be asserted if the C bit is deasserted.

### AxCACHE[3], Write-Allocate (WA) bit

When this bit is asserted, write allocation of the transaction is recommended but is not mandatory.
The WA bit must not be asserted if the C bit is deasserted.

### A4.3 AXI4 changes to memory attribute signaling

AXI4 makes the following changes to the AXI3 memory attribute signaling:

- The AxCACHE[1] bits are renamed as the Modifiable bits.
- Ordering requirements are defined for Non-modifiable transactions.

- The meanings of Read-Allocate and Write-Allocate are updated.

### A4.3.1 AxCACHE[1], Modifiable

In AXI4, the AxCACHE[1] bit is the Modifiable bit. When HIGH, Modifiable indicates that the characteristics of
the transaction can be modified. When Modifiable is LOW, the transaction is Non-modifiable.

### Note

The AxCACHE[1] bit is renamed from the Cacheable bit to the Modifiable bit to better describe the required
functionality. The actual functionality is unchanged.

The following sections describe the properties of Non-modifiable and Modifiable transactions.

### Non-modifiable transactions

A Non-modifiable transaction is indicated by setting AxCACHE[1] LOW.

A Non-modifiable transaction must not be split into multiple transactions or merged with other transactions.

In a Non-modifiable transaction, the parameters that are shown in Table A4-2 must not be changed.

Table A4-2 Parameters fixed as Non-modifiable

<table>
 <tr>
  <th>Parameter</th>
  <td>Signals</td>
 </tr>
 <tr>
  <th>Transfer</th>
  <td>AxADDR, and therefore AxREGION</td>
 </tr>
 <tr>
  <th>Burst size</th>
  <td>AxSIZE</td>
 </tr>
 <tr>
  <th>Burst length</th>
  <td>AxLEN</td>
 </tr>
 <tr>
  <th>Burst type</th>
  <td>AxBURST</td>
 </tr>
 <tr>
  <th>Lock type</th>
  <td>AxLOCK</td>
 </tr>
 <tr>
  <th>Protection type</th>
  <td>AxPROT</td>
 </tr>
</table>

The AxCACHE attribute can only be modified to convert a transaction from being Bufferable to Non-bufferable.
No other change to AxCACHE is permitted.

The transaction ID and the QoS values can be modified.

A Non-modifiable transaction with burst length greater than 16 can be split into multiple transactions. Each
resulting transaction must meet the requirements that are given in this subsection, except that:

- The burst length is reduced.

- The address of the generated bursts is adapted appropriately.

A Non-modifiable transaction that is an Exclusive access, as indicated by AxLOCK asserted, is permitted to have
the transaction size, AxSIZE, and the transaction length, AxLEN, modified if the total number of bytes accessed
remains the same.

Note

There are circumstances where it is not possible to meet the requirements of Non-modifiable transactions. For
example, when downsizing to a bus width narrower than that required by the transaction size, AxSIZE, the
transaction must be modified.

A component that performs such an operation can optionally include an IMPLEMENTATION DEFINED mechanism to
indicate that a modification has occurred. This mechanism can assist with software debug.

### Modifiable transactions

A Modifiable transaction is indicated by asserting AxCACHE[1].

A Modifiable transaction can be modified in the following ways:

- A transaction can be broken into multiple transactions.

- Multiple transactions can be merged into a single transaction.

- A read transaction can fetch more data than required.

A write transaction can access a larger address range than required, using the WSTRB signals to ensure that
only the appropriate locations are updated.

In each generated transaction, the following signals can be modified:
- The transfer address, AxADDR
- The burst size, AxSIZE
- The burst length, AxLEN
- The burst type, AxBURST

The following must not be changed:

- The lock type, AxLOCK

- The protection type, AxPROT

The memory attribute, AxCACHE, can be modified, but any modification must ensure that the visibility of
transactions by other components is not reduced, either by preventing propagation of transactions to the required
point, or by changing the need to look up a transaction in a cache. Any modification to the memory attributes must
be consistent for all transactions to the same address range.

The transaction ID and QoS values can be modified.

No transaction modification is permitted that:

- Causes accesses to a different 4KByte address space than that of the original transaction.

Causes a single access to a single-copy atomicity sized region to be performed as multiple accesses. See
Single-copy atomicity size on page A7-94.

### A4.3.2 Updated meaning of Read-Allocate and Write-Allocate

In AXI4, the meaning of the Read-Allocate and Write-Allocate bits is updated so that one bit indicates that an
allocation that occurred for the transaction and the other bit indicates that an allocation could have been made due
to another transaction.

For read transactions, the Write-Allocate bit is redefined to indicate that:

The location could have been previously allocated in the cache because of a write transaction (as the AXI3
definition).

The location could have been previously allocated in the cache because of the actions of another Manager
(additional AXI4 definition).

For write transactions, the Read-Allocate bit is redefined to indicate that:

The location could have been previously allocated in the cache because of a read transaction (as the AXI3
definition).

The location could have been previously allocated in the cache because of the actions of another Manager
(additional AXI4 definition).

These changes mean:

- A transaction must be looked up in a cache if the value of AxCACHE[3:2] is not 0b00.

- A transaction does not need to be looked up in a cache if the value of AxCACHE[3:2] is 0b00.

### Note

The change to the definition of AxCACHE means that these signals can differ for a read and write transaction to
the same location.

Table A4-3 shows the AXI4 bit allocations for the AWCACHE signals.

### Table A4-3 AWCACHE bit allocations

<table>
 <tr>
  <th>Signal</th>
  <th>AXI4</th>
  <th>Description</th>
 </tr>
 <tr>
  <td>AWCACHE[3]</td>
  <td>Allocate</td>
  <td>When asserted, the transaction must be looked up in a cache because</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>it could have been previously allocated. The transaction must also be</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>looked up in a cache if AWCACHE[2] is asserted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When deasserted, if AWCACHE[2] is also deasserted, then the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction does not need to be looked up in a cache and the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction must propagate to the final destination.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When asserted, this specification recommends that this transaction is</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>allocated in the cache for performance reasons.</td>
 </tr>
 <tr>
  <td>AWCACHE[2]</td>
  <td>Other Allocate</td>
  <td>When asserted, the transaction must be looked in a cache because</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>it could have been previously allocated in the cache by another</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction, either a read transaction or a transaction from another</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>Manager. The transaction must also be looked up in a cache if</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>AWCACHE[3] is asserted.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When deasserted, if AWCACHE[3] is also deasserted, then the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction does not need to be looked up in a cache and the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction must propagate to the final destination.</td>
 </tr>
 <tr>
  <td>AWCACHE[1]</td>
  <td>Modifiable</td>
  <td>When asserted, the characteristics of the transaction can be modified</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>and writes can be merged. When deasserted, the characteristics of</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>the transaction must not be modified.</td>
 </tr>
 <tr>
  <td>AWCACHE[0]</td>
  <td>Bufferable</td>
  <td>When deasserted, if both of AWCACHE[3:2] are deasserted, the</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>write response must be given from the final destination.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When asserted, if both of AWCACHE[3:2] are deasserted, the write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>response can be given from an intermediate point, but the write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction is required to be made visible at the final destination in a</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>timely manner.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When deasserted, if either of AWCACHE[3:2] is asserted, the write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>response can be given from an intermediate point, but the write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction is required to be made visible at the final destination in a</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>timely manner.</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>When asserted, if either of AWCACHE[3:2] is asserted, the write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>response can be given from an intermediate point. The write</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>transaction is not required to be made visible at the final destination.</td>
 </tr>
</table>

Table A4-4 shows the AXI4 bit allocations for the ARCACHE signals.

### Table A4-4 ARCACHE bit allocations

| Signal | AXI4 | Description |
| --- | --- | --- |
| ARCACHE[3] | Other Allocate | When asserted, the transaction must be looked up in a cache because |
|  |  | it could have been allocated in the cache by another transaction, |
|  |  | either a write transaction or a transaction from another Manager. The |
|  |  | transaction must also be looked in a cache if ARCACHE[2] is |
|  |  | asserted. |
|  |  | When deasserted, if ARCACHE[2] is also deasserted, then the |
|  |  | transaction does not need to be looked up in a cache. |
| ARCACHE[2] | Allocate | When asserted, the transaction must be looked up in a cache because |
|  |  | it could have been allocated. The transaction must also be looked up |
|  |  | in a cache if ARCACHE[3] is asserted. |
|  |  | When deasserted, if ARCACHE[3] is also deasserted, then the |
|  |  | transaction does not need to be looked up in a cache. |
|  |  | When asserted, this specifacation recommends that this transaction |
|  |  | is allocated in the cache for performance reasons. |
| ARCACHE[1] | Modifiable | When asserted, the characteristics of the transaction can be modified |
|  |  | and a larger quantity of read data can be fetched than is required. |
|  |  | When deasserted the characteristics of the transaction must not be |
|  |  | modified. |
| ARCACHE[0] | Bufferable | This bit has no effect when ARCACHE[3:1] are deasserted. |
|  |  | When ARCACHE[3:2] are deasserted and ARCACHE[1] is |
|  |  | asserted: |
|  |  | - If this bit is deasserted, the read data must be obtained from |
|  |  | the final destination. |
|  |  | - If this bit is asserted, the read data can be obtained from the |
|  |  | final destination or from a write that is progressing to the final |
|  |  | destination. |
|  |  | When either ARCACHE[3] is asserted, or ARCACHE[2] is |
|  |  | asserted, this bit can be used to distinguish between Write-Through |
|  |  | and Write-Back memory types. |

### A4.4 Memory types

The AXI4 protocol introduces new names for the memory types that are identified by the AxCACHE encoding.
Table A4-5 shows the AXI4 AxCACHE encoding and associated memory types. Some memory types have
different encodings in AXI3 and these encodings are shown in brackets.

### Note

The same memory type can have different encodings on the read channel and write channel. These encodings
provide backwards compatibility with AXI3 AxCACHE definitions.

In AXI4, it is legal to use more than one AxCACHE value for a particular memory type. Table A4-5 shows the
preferred AXI4 value with the legal AXI3 value in brackets.

|  |  | Table A4-5 Memory type encoding |
| --- | --- | --- |
|  |  | Memory type |
| 0b0000 | 0b0000 | Device Non-bufferable |
| 0b0001 | 0b0001 | Device Bufferable |
| 0b0010 | 0b0010 | Normal Non-cacheable Non-bufferable |
| 0b0011 | 0b0011 | Normal Non-cacheable Bufferable |
| 0b1010 | 0b0110 | Write-Through No-Allocate |
| 0b1110 | 0b0110 | Write-Through Read-Allocate |
| 0b1010 | 0b1110 | Write-Through Write-Allocate |
| 0b1110 | 0b1110 | Write-Through Read and |
|  |  | Write-Allocate |
| 0b1011 | 0b0111 | Write-Back No-Allocate |
| 0b1111 | 0b0111 | Write-Back Read-Allocate |
| 0b1011 | 0b1111 | Write-Back Write-Allocate |
| 0b1111 | 0b1111 | Write-Back Read and Write-Allocate |

All values that are not shown in Table A4-5 are reserved.

### A4.4.1 Memory type requirements

This section specifies the required behavior for each of the memory types.

### Device Non-bufferable

The required behavior for Device Non-bufferable memory is:

- The write response must be obtained from the final destination.

- Read data must be obtained from the final destination.

- Transactions are Non-modifiable, see Non-modifiable transactions on
- Reads must not be prefetched. Writes must not be merged.

page A4-64.

### Device Bufferable

The required behavior for the Device Bufferable memory type is:

- The write response can be obtained from an intermediate point.

Write transactions must be made visible at the final destination in a timely manner, as defined in Transaction
buffering on page A4-74.

Read data must be obtained from the final destination.

Transactions are Non-modifiable, see Non-modifiable transactions on page A4-64.

Reads must not be prefetched. Writes must not be merged.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>Both Device memory types are Non-modifiable. In this protocol specification, the terms Device memory and</td>
 </tr>
 <tr>
  <td>Non-modifiable memory are interchangeable.</td>
 </tr>
</table>

For read transactions, there is no difference in the required behavior for Device Non-bufferable and Device
Bufferable memory types.

### Normal Non-cacheable Non-bufferable

The required behavior for the Normal Non-cacheable Non-bufferable memory type is:

- The write response must be obtained from the final destination.

- Read data must be obtained from the final destination.

- Transactions are Modifiable, see Modifiable transactions on page A4-65

- Writes can be merged.

### Normal Non-cacheable Bufferable

The required behavior for the Normal Non-cacheable Bufferable memory type is:

- The write response can be obtained from an intermediate point.

Write transactions must be made visible at the final destination in a timely manner, as defined in Transaction
buffering on page A4-74. There is no mechanism to determine when a write transaction is visible at its final
destination.

Read data must be obtained from either:
- The final destination
- A write transaction that is progressing to its final destination
If read data is obtained from a write transaction:
- It must be obtained from the most recent version of the write.
- The data must not be cached to service a later read.

Transactions are Modifiable, see Modifiable transactions on page A4-65.

Writes can be merged.

### Write-Through No-Allocate

The required behavior for the Write-Through No-Allocate memory type is:

- The write response can be obtained from an intermediate point.

Write transactions must be made visible at the final destination in a timely manner, as defined in Transaction
buffering on page A4-74. There is no mechanism to determine when a write transaction is visible at the final
destination.

Read data can be obtained from an intermediate cached copy.

Transactions are Modifiable, see Modifiable transactions on page A4-65.

Reads can be prefetched.

Writes can be merged.

A cache lookup is required for read and write transactions.

The No-Allocate attribute is an allocation hint, that is, it is a recommendation to the memory system that, for
performance reasons, these transactions are not allocated. However, the allocation of read and write
transactions is not prohibited.

### Write-Through Read-Allocate

The required behavior for the Write-Through Read-Allocate memory type is the same as for Write-Through
No-Allocate memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is recommended.

- Allocation of write transactions is not recommended.

### Write-Through Write-Allocate

The required behavior for the Write-Through Write-Allocate memory type is the same as for Write-Through
No-Allocate memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is not recommended.

- Allocation of write transactions is recommended.

### Write-Through Read and Write-Allocate

The required behavior for the Write-Through Read and Write-Allocate memory type is the same as for
Write-Through No-Allocate memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is recommended.

- Allocation of write transactions is recommended.

### Write-Back No-Allocate

The required behavior for the Write-Back No-Allocate memory type is:

- The write response can be obtained from an intermediate point.

- Write transactions are not required to be made visible at the final destination.

- Read data can be obtained from an intermediate cached copy.

- Transactions are Modifiable, see Modifiable transactions on page A4-65.

- Reads can be prefetched.

- Writes can be merged.

- A cache lookup is required for read and write transactions.

The No-Allocate attribute is an allocation hint, that is, it is a recommendation to the memory system that, for
performance reasons, these transactions are not allocated. However, the allocation of read and write
transactions is not prohibited.

### Write-Back Read-Allocate

The required behavior for the Write-Back Read-Allocate memory type is the same as for Write-Back No-Allocate
memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is recommended.

- Allocation of write transactions is not recommended.

### Write-Back Write-Allocate

The required behavior for the Write-Back Write-Allocate memory type is the same as for Write-Back No-Allocate
memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is not recommended.
- Allocation of write transactions is recommended.

### Write-Back Read and Write-Allocate

The required behavior for the Write-Back Read and Write-Allocate memory type is the same as for Write-Back
No-Allocate memory. But in this case the allocation hint is that, for performance reasons:

- Allocation of read transactions is recommended.

- Allocation of write transactions is recommended.

### A4.5 Mismatched memory attributes

Multiple agents that are accessing the same area of memory, can use mismatched memory attributes. However, for
functional correctness, the following rules must be obeyed:

All Managers accessing the same area of memory must have a consistent view of the cacheability of that area
of memory at any level of hierarchy. The rules to be applied are:

Address region not Cacheable

All Managers must use transactions with both AxCACHE[3:2] deasserted.

### Address region Cacheable

All Managers must use transactions with either of AxCACHE[3:2] asserted.

Different Managers can use different allocation hints.

If an addressed region is Normal Non-cacheable, any Manager can access it using a Device memory
transaction.

If an addressed region has the Bufferable attribute, any Manager can access it using transactions that do not
permit bufferable behavior.

### Note

For example, a transaction that requires the response from the final destination does not permit bufferable
behavior.

### A4.5.1 Changing memory attributes

The attributes for a particular memory region can be changed from one type to another incompatible type. For
example, the attribute can be changed from Write-Through Cacheable to Normal Non-cacheable. This change
requires a suitable process to perform the change. Typically, the following process is performed:

1. All Managers stop accessing the region.

2. A single Manager performs any required cache maintenance operations.

3. All Managers restart accessing the memory region, using the new attributes.

### A4.6 Transaction buffering

Write access to the following memory types do not require a transaction response from the final destination, but do
require that write transactions are made visible at the final destination in a timely manner:

- Device Bufferable

- Normal Non-cacheable Bufferable

- Write-Through

For write transactions, all three memory types require the same behavior. For read transactions, the required
behavior is as follows:

- For Device Bufferable memory, read data must be obtained from the final destination.
- For Normal Non-cacheable Bufferable memory, read data must be obtained either from the final destination
or from a write transaction that is progressing to its final destination.
- For Write-Through memory, read data can be obtained from an intermediate cached copy.

In addition to ensuring that write transactions progress towards their final destination in a timely manner,
intermediate buffers must behave as follows:

An intermediate buffer that can respond to a transaction must ensure that, over time, any read transaction to
Normal Non-cacheable Bufferable propagates towards its destination. This propagation means that, when
forwarding a read transaction, the attempted forwarding must not continue indefinitely, and any data that is
used for forwarding must not persist indefinitely. The protocol does not define any mechanism for
determining how long data that is used for forwarding a read transaction can persist. However, in such a
mechanism, the act of reading the data must not reset the data timeout period.

For information about the required behavior of read accesses to these memory types, see:

- Device Bufferable on page A4-70
- Normal Non-cacheable Bufferable on page A4-70
- Write-Through No-Allocate on page A4-71

### A4.7 Access permissions

AXI provides access permissions signals that can be used to protect against illegal transactions:

- ARPROT[2:0] defines the access permissions for read accesses.

- AWPROT[2:0] defines the access permissions for write accesses.

The term AxPROT refers collectively to the ARPROT and AWPROT signals.

Table A4-6 shows the AxPROT[2:0] encoding.

### Table A4-6 Protection encoding

|  |  | Function |
| --- | --- | --- |
| [0] | 0 | Unprivileged access |
|  | 1 | Privileged access |
| [1] | 0 | Secure access |
|  | 1 | Non-secure access |
| [2] | 0 | Data access |
|  | 1 | Instruction access |

The protection attributes are:

Unprivileged or privileged

An AXI Manager might support more than one level of operating privilege, and extend this concept
of privilege to memory access. AxPROT[0] identifies an access as unprivileged or privileged.

### Secure or Non-secure

An AXI Manager might support Secure and Non-secure operating states, and extend this concept of
security to memory access. AxPROT[1] identifies an access as Secure or Non-secure. AxPROT[1]
can be considered as defining two address spaces, a Secure address space and a Non-secure address
space. This signal can be treated as an additional address bit. Any aliasing between the Secure and
Non-secure address spaces must be handled correctly.

### Instruction or data

This bit indicates that the transaction is an instruction access or a data access.
The AXI protocol defines this indication as a hint. It is not accurate in all cases, for example, where
a transaction contains a mix of instruction and data items. This specification recommends that a
Manager sets AxPROT[2] LOW, to indicate a data access unless the access is known to be an
instruction access.

### A4.8 Legacy considerations

AXI4 introduces additional requirements for the handling of some of the AxCACHE memory attributes.
In AXI4, all Device transactions using the same ID to the same Subordinate must be ordered with respect to each
other.

### Note

This ordering is not an explicit requirement of AXI3. Any AXI4 component that relies on this behavior
cannot be connected to an AXI3 interconnect that does not exhibit this behavior.

Arm believes that most implemented AXI3 interconnects support the required AXI4 behavior.

This specification strongly recommends that any new AXI3 design implements the AXI4 requirement.

For AxCACHE bits names and memory type names, it is required that AXI4 uses the new terms. AXI3 components
can use either the AXI3 or AXI4 names.

### A4.9 Usage examples

This section gives examples of memory type usage.

### A4.9.1 Use of Device memory types

The specification supports the combined use of Device Non-bufferable and Device Bufferable memory types to
force write transactions to reach their final destination and ensure that the issuing Manager knows when the
transaction is visible to all other Managers.

A write transaction that is marked as Device Bufferable is required to reach its final destination in a timely manner.
However, the write response for the transaction can be signaled by an intermediate buffer. Therefore, the issuing
Manager cannot know when the write is visible to all other Managers.

If a Manager issues a Device Bufferable write transaction, or stream of write transactions, followed by a Device
Non-bufferable write transaction, and all transactions use the same AXI ID, the AXI ordering requirements force
all of the Device Bufferable write transactions to reach the final destination before a response is given to the Device
Non-bufferable transaction. Therefore, the response to the Device Non-bufferable transaction indicates that all the
transactions are visible to all Managers.

Note

A Device Non-bufferable transaction can only guarantee the completion of Device Bufferable transactions that are
issued with the same ID, and are to the same Subordinate device.

## Chapter A5

### Transaction Identifiers

This chapter describes the mechanism that enables out-of-order transaction completion and the issuing of multiple
outstanding addresses. It contains the following sections:

- AXI transaction identifiers on page A5-80

- ID signals on page A5-81

### A5.1 AXI transaction identifiers

The AXI protocol includes AXI ID transaction identifiers. A Manager can use these to identify separate transactions
that must be returned in order.

All transactions with a given AXI ID value must remain ordered, but there is no restriction on the ordering of
transactions with different ID values. A single physical port can support out-of-order transactions by acting as a
number of logical ports, each handling its transactions in order.

By using AXI IDs, a Manager can issue transactions without waiting for earlier transactions to complete. This can
improve system performance, because it enables parallel processing of transactions.

### Note

There is no requirement for Subordinates or Managers to use AXI transaction IDs. Managers and Subordinates can
process one transaction at a time. Transactions are processed in the order they are issued.

Subordinates are required to reflect on the appropriate BID or RID response an AXI ID received from a Manager.

### A5.2 ID signals

Each transaction channel has its own transaction ID. Table A5-1 shows these designated signals.

### Table A5-1 Channel

<table>
 <tr>
  <th>Transaction channel</th>
  <td>Transaction ID</td>
 </tr>
 <tr>
  <th>Write address channel</th>
  <td>AWID</td>
 </tr>
 <tr>
  <th>Write data channel, AXI3</th>
  <td>WIDa</td>
 </tr>
 <tr>
  <th>Write response channel</th>
  <td>BID</td>
 </tr>
 <tr>
  <th>Read address channel</th>
  <td>ARID</td>
 </tr>
 <tr>
  <th>Read data channel</th>
  <td>RID</td>
 </tr>
</table>

transaction ID

a. The WID signal is implemented only in AXI3.

Note

The AXI4 protocol supports an extended ordering model based on the use of the AXI ID transaction identifier. See
Chapter A6 AXI Ordering Model.

### A5.2.1 Read data ordering

The Subordinate must ensure that the RID value of any returned data matches the ARID value of the address that
it is responding to.

The interconnect must ensure that the read data from a sequence of transactions with the same ARID value targeting
different Subordinates is received by the Manager in the order that it issued the addresses.

The read data reordering depth is the number of addresses pending in the Subordinate that can be reordered. A
Subordinate that processes all transactions in order has a read data reordering depth of one. The read data reordering
depth is a static value that must be specified by the designer of the Subordinate.

There is no mechanism that a Manager can use to determine the read data reordering depth of a Subordinate.

### A5.2.2 Write data ordering

A Manager must issue write data in the same order that it issues the transaction addresses.

An interconnect that combines write transactions from different Managers must ensure that it forwards the write
data in address order.

The interleaving of write data with different IDs was permitted in AXI3, but is deprecated in AXI4 and later. See
the AMBA AXI and ACE Protocol Specification issue F specification for more details on write data interleaving.

### A5.2.3 Interconnect use of transaction identifiers

When a Manager is connected to an interconnect, the interconnect appends additional bits to the ARID, AWID and
WID identifiers that are unique to that Manager port. This has two effects:

Managers do not have to know what ID values are used by other Managers because the interconnect makes
the ID values used by each Manager unique by appending the Manager number to the original identifier.

- The ID identifier at a Subordinate interface is wider than the ID identifier at a Manager interface.

For read data, the interconnect uses the additional bits of the RID identifier to determine which Manager port the
read data is destined for. The interconnect removes these bits of the RID identifier before passing the RID value to
the correct Manager port.

For write response, the interconnect uses the additional bits of the BID identifier to determine which Manager port
the write response is destined for. The interconnect removes these bits of the BID identifier before passing the BID
value to the correct Manager port.

## Chapter A6

### AXI Ordering Model

This chapter specifies:

- AXI ordering model overview on page A6-84
- Memory locations and Peripheral regions on page A6-85
- Transactions and ordering on page A6-86
- Observation and completion definitions on page A6-87
- Manager ordering guarantees on page A6-88
- Ordering requirements on page A6-89
- Response before the endpoint on page A6-90
- Ordered write observation on page A6-91

### A6.1 AXI ordering model overview

The AXI ordering model is based on the use of the transaction identifier, which is signaled on ARID or AWID.
Transaction requests on the same channel, with the same ID and destination are guaranteed to remain in order.
Transaction responses with the same ID are returned in the same order as the requests were issued.
The ordering model does not give any ordering guarantees between:

- Transactions from different Managers

- Read and write transactions

- Transactions with different IDs

- Transactions to different Peripheral regions

- Transactions to different Memory locations

If a Manager requires ordering between transactions that have no ordering guarantee, the Manager must wait to
receive a response to the first transaction before issuing the second transaction.

### A6.2 Memory locations and Peripheral regions

The address map in AMBA is made up of Memory locations and Peripheral regions.
A Memory location has all of the following properties:

- A read of a byte from a Memory location returns the last value that was written to that byte location.

- A write to a byte of a Memory location updates the value at that location to a new value that is obtained by a subsequent read of that location.

- Reading or writing to a Memory location has no side-effects on any other Memory location.

- Observation guarantees for Memory are given for each location.

- The size of a Memory location is equal to the single-copy atomicity size for that component.

A Peripheral region has all of the following properties:

- A read from an address in a Peripheral region does not necessarily return the last value that is written to that address.

- A write to a byte address in a Peripheral region does not necessarily update the value at that address to a new value that is obtained by subsequent reads.

- Accessing an address within a Peripheral region might have side-effects on other addresses within that region.

- Observation guarantees for Peripherals are given per region.

The size of a Peripheral region is IMPLEMENTATION DEFINED, but it must be contained within a single
Subordinate component.

### A6.3 Transactions and ordering

A transaction is a read or a write to one or more address locations. The locations are determined by AxADDR and
any relevant qualifiers such as the Non-secure bit in AxPROT.

- Ordering guarantees are given only between accesses to the same Memory location or Peripheral region.
- A transaction to a Peripheral region must be entirely contained within that region.
- A transaction that spans multiple Memory locations has multiple ordering guarantees.

Transactions can be either of type Device or Normal:

### Device

A read or write where the request has AxCACHE[1] deasserted.
Device transactions can be used to access Peripheral regions or Memory locations.

### Normal

A read or write where the request has AxCACHE[1] asserted.
Normal transactions are used to access Memory locations and are not expected to be used to access
Peripheral regions.

A Normal access to a Peripheral region must complete in a protocol-compliant manner, but the
result is IMPLEMENTATION DEFINED.

A write transaction can be either Non-bufferable or Bufferable. It is possible to send an early response to Bufferable
writes.

- A Non-bufferable write has AWCACHE[0] deasserted.
- A Bufferable write has AWCACHE[0] asserted.

### A6.4 Observation and completion definitions

For accesses to Peripheral regions, a Device read or write access DRW1 is observed by a Device read or write access
DRW2, when DRW1 arrives at the Subordinate component before DRW2.

For accesses to Memory locations, all of the following apply:

- A write W1 is observed by a write W2, if W2 takes effect after W1.

- A read R1 is observed by a write W2, if R1 returns data from a write W3, when W2 is after W3.

- A write W1 is observed by a read R2, if R2 returns data from either W1 or from write W3, when W3 is after W1.

Read R1 or write W1 can be of type Device or Normal.

The definitions of write and read completions are:

Write completion response

The cycle when the associated BRESP handshake is given, when BVALID and BREADY are
asserted.

### Read completion response

The cycle when the last associated RDATA handshake is given, when RVALID, RLAST and
RREADY are asserted.

### A6.5

### A6.5.1

### A6.5.2

### A6.5.3 Manager ordering guarantees

There are three types of ordering model guarantees:

- Observability guarantees before a completion response is received.

- Observability guarantees from a completion response.
- Response ordering guarantees.

### Guarantees before a completion response is received

All of the following guarantees apply to transactions from the same Manager, using the same ID:

A Device write DW1 is guaranteed to arrive at the destination before Device write DW2, where DW2 is
issued after DW1 and to the same Peripheral region.

A Device read DR1 is guaranteed to arrive at the destination before Device read DR2, where DR2 is issued
after DR1 and to the same Peripheral region.

A write W1 is guaranteed to be observed by a write W2, where W2 is issued after W1 and to the same
Memory location.

A write W1 that has been observed by a read R2 is guaranteed to be observed by a read R3, where R3 is issued
after R2 and to the same Memory location.

The guarantees imply that there are ordering guarantees between Device and Normal accesses to the same Memory
location.

### Guarantees from a completion response

A completion response guarantees all of the following:

A completion response to a read request guarantees that it is observable to a subsequent read or write request
from any Manager.

A completion response to a write request guarantees that it is observable to a subsequent read or write request
from any Manager. This observability is a requirement of a system that is multi-copy atomic.

Systems that contain Arm Architecture-compliant processors must be multi-copy atomic. That is, the
Multi_Copy_Atomicity property must be True.

The response to a Bufferable write request can be sent from an intermediate point. It does not guarantee that the
write has completed at the endpoint, but it is observable to future transactions.

### Response ordering guarantees

Transaction responses have all the following ordering guarantees:

A read R1 is guaranteed to receive a response before the response to a read R2, where R2 is issued from the
same Manager after R1 with the same ID.

A write W1 is guaranteed to receive a response before the response to a write W2, where W2 is issued from
the same Manager after W1 with the same ID.

### A6.6 Ordering requirements

To meet the Manager ordering guarantees, there are certain requirements on Subordinate and interconnect
components.

### A6.6.1 Subordinate ordering requirements

For Peripheral locations, the execution order of transactions to Peripheral locations is IMPLEMENTATION DEFINED.
This execution order is typically expected to match the arrival order, but that is not a requirement.

For Memory locations:

A write W1 must be ordered before a write W2 with the same ID, to the same Memory location, where W2
is received after W1 is received.

A write W1 must be ordered before a write W2 to the same Memory location, where W2 is received after the
completion response for W1 is given.

A write W1 must be ordered before a read R2 to the same Memory location, where R2 is received after the
completion response for W1 is given.

A read R1 must be ordered before a write W2 to the same Memory location, where W2 is received after the
completion response for R1 is given.

Response ordering requirements:

The response to read R1 must be returned before the response to a read R2, where R2 is received after R1
with the same ID.

The response to write W1 must be returned before the response to a write W2, where W2 is received after
W1 with the same ID.

### A6.6.2 Interconnect ordering requirements

An interconnect component has the following attributes:

- A request is received on one port and is either issued on a different port or responded to.
- A response is received on one port and is either issued on a different port or consumed.

When the interconnect issues requests or responses, it must adhere to the following requirements:

A read R1 request must be issued before a read R2 request, where R2 is received after R1, with the same ID
and to the same or overlapping locations.

A write W1 request must be issued before a write W2 request, where W2 is received after W1, with the same
ID, to the same or overlapping locations.

A Device read DR1 request must be issued before a Device read DR2 request, where DR2 is received after
DR1, with the same ID and to the same Peripheral region.

A Device write DW1 request must be issued before a Device write DW2 request, where DW2 is received
after DW1, with the same ID and to the same Peripheral region.

A read R1 response must be issued before a read R2 response, where R2 is received after R1, with the same

1.

A write W1 response must be issued before a write W2 response, where W2 is received after W1, with the
same ID.

When the interconnect is acting as a Subordinate component, it must also adhere to the Subordinate requirements.

Any manipulation of the AXI ID values that are associated with a transaction must ensure that the ordering
requirements of the original ID values are maintained.

### A6.7

### A6.7.1

### A6.7.2 Response before the endpoint

To improve system performance, it is possible for an intermediate component to issue a response to some
transactions. This action is known as an early response. The intermediate component issuing an early response must
ensure that visibility and ordering guarantees are met.

### Early read response

For Normal read transactions, an intermediate component can respond with read data from a local memory if it is
up-to-date with respect to all earlier writes to the same or overlapping address. In this case, the request is not
required to propagate beyond the intermediate component.

An intermediate component must observe ID ordering rules, which means a read response can only be sent if all
earlier reads with the same ID have already had a response.

### Early write response

For Bufferable write transactions, an intermediate component can send an early write response for transactions that
have no downstream observers. If the intermediate component sends an early write response, the intermediate
component can store a local copy of the data, but must propagate the transaction downstream, before discarding that
data.

An intermediate component must observe ID ordering rules, that means a write response can only be sent if all
earlier writes with the same ID have already had a response.

After sending an early write response, the component must be responsible for ordering and observability of that
transaction until the write has been propagated downstream and a write response is received. During the period
between sending the early write response and receiving a response from downstream, the component must ensure
that:

If an early write response was given for a Normal transaction, all subsequent transactions to the same or
overlapping Memory locations are ordered after the write that has had an early response.

If an early write response was given for a Device transaction, then all subsequent transactions to the same
Peripheral region are ordered after the write that has had an early response.

When giving an early write response for a Device Bufferable transaction, the intermediate component is expected
to propagate the write transaction without dependency on other transactions. The intermediate component cannot
wait for another read or write to arrive before propagating a previous Device write.

### A6.8 Ordered write observation

To improve compatibility with interface protocols that support a different ordering model, a Subordinate interface
can give stronger ordering guarantees for write transactions. A stronger ordering guarantee is known as Ordered
Write Observation.

The Ordered_Write_Observation property is used to define whether an interface exhibits Ordered Write
Observation, it can be True or False for a single interface.

### True

An interface is defined as having the Ordered Write Observation property.

False

An interface that does not have the Ordered Write Observation property.
If Ordered_Write_Observation is not declared, it is considered False.

An interface that exhibits Ordered Write Observation gives guarantees for write transactions that are not dependent
on the destination or address:

A write W1 is guaranteed to be observed by a write W2, where W2 is issued after W1, from the same
Manager, with the same ID.

A Manager using the Producer-Consumer ordering model that is connected to a Subordinate interface that exhibits
Ordered Write Observation is not required to wait for the completion response from earlier writes before issuing
dependent writes.

## Chapter A7

### Atomic Accesses

This chapter describes the AXI4 concept of single-copy atomicity size and how the AXI protocol implements
exclusive access and locked access mechanisms. It contains the following sections:

- Single-copy atomicity size on page A7-94
- Exclusive accesses on page A7-96
- Locked accesses on page A7-99
- Atomic access signaling on page A7-100

### A7.1 Single-copy atomicity size

The AXI4 protocol introduces the concept of single-copy atomicity size. This term defines the minimum number of
bytes that a transaction updates atomically. The AXI4 protocol requires a transaction that is larger than the
single-copy atomicity size must update memory in blocks of at least the single-copy atomicity size.

### Note

Atomicity does not define the exact instant when the data is updated. What must be ensured is that no Manager can
ever observe a partially updated form of the atomic data. For example, in many systems data structures such as
linked lists are made up of 32-bit atomic elements. An atomic update of one of these elements requires that the entire

32-bit value is updated at the same time. It is not acceptable for any Manager to observe an update of only 16-bits
at one time, and then the update of the other 16-bits at a later time.

More complex systems require support for larger atomic elements, in particular 64-bit atomic elements, so that
Managers can communicate using data structures that are based on these larger atomic elements.

The single-copy atomicity sizes that are supported in a system are important because all of the components involved
in a given communication must support the required size of atomic element. If two Managers are communicating
through an interconnect and a single Subordinate, then all of the components involved must ensure that transactions
of the required size are treated atomically.

The AXI4 protocol does not require a specific single-copy atomicity size and systems can be designed to support
different single-copy atomicity sizes.

Different groups of components can have different single-copy atomicity sizes for communication within the
groups. In AXI4 the term single-copy atomic group describes a group of components that can communicate at a
particular atomicity. For example, Figure A7-1 shows a system in which:

- The processor, Digital Signal Processor (DSP), DRAM controller, DMA controller, peripherals, SRAM memory and associated interconnect, are in a 32-bit single-copy atomic group.

- The processor, DSP, DRAM controller, and associated interconnect, are also in a 64-bit single-copy atomic group.

atomic

32-bit single-copy atomic group

Controller

Bridge

Interconnect

Timer

### Figure A7-1 Example system with different single-copy atomic groups

A transaction never has an atomicity guarantee greater than the alignment of its start address. For example, a burst
in a 64-bit single-copy atomic group that is not aligned to an 8-byte boundary does not have any 64-bit single-copy
atomic guarantee.

Byte strobes associated with a transaction do not affect the single-copy atomicity size.

### A7.1.1 Multi-copy write atomicity

To specify that a system provides multi-copy atomicity, a Multi_Copy_Atomicity property is defined.
True Multi_Copy_Atomicity is supported.
False Multi_Copy_Atomicity is not supported. If Multi_Copy_Atomicity is not declared, it is considered
False.

A system is defined as being multi-copy atomic if:

- Writes to the same location are observed in the same order by all agents.

- A write to a location that is observable by an agent, is observable by all agents.

Multi-copy atomicity can be ensured by:

Using a single Point of Serialization, for a given address, so that all accesses to the same location are ordered.
This must ensure that all coherent cached copies of a location are invalidated before the new value of the
location is made visible to any agents.

Avoiding the use of forwarding buffers that are upstream of any agents. This prevents a buffered write of a
location becoming visible to some agents before it is visible to all agents.

It is required that the Multi_Copy_Atomicity property is True for Issue G and later of this specification.

### Note

A system must have the Multi_Copy_Atomicity property if Arm v8 Architecture processors are used. This is
required to support the Load with Acquire and Store with Release instructions. The Store with Release instruction
requires that the store is multi-copy atomic.

### A7.2 Exclusive accesses

The exclusive access mechanism can provide semaphore-type operations without requiring the bus to remain
dedicated to a particular Manager for the duration of the operation. This means the semaphore-type operations do
not impact either the bus access latency or the maximum achievable bandwidth.

The AxLOCK signals select exclusive access, and the RRESP and BRESP signals indicate the success or failure
of the exclusive access read or write respectively.

The Subordinate requires additional logic to support exclusive access. The AXI protocol provides a mechanism to
indicate when a Manager attempts an exclusive access to a Subordinate that does not support it. The remainder of
this section describes the AXI Exclusive access mechanism.

### A7.2.1 Exclusive access process

The basic mechanism of an exclusive access is:

1. A Manager performs an exclusive read from an address.

2. At some later time, the Manager attempts to complete the exclusive operation by performing an exclusive write to the same address, and with an AWID that matches the ARID used for the exclusive read.

3. This exclusive write access is signaled as either:
- Successful, if no other Manager has written to that location since the exclusive read access. In this case the exclusive write updates memory.

Failed, if another Manager has written to that location since the exclusive read access. In this case the
memory location is not updated.

A Manager might not complete the write portion of an exclusive operation. The exclusive access monitoring
hardware monitors only one address for each transaction ID. If a Manager does not complete the write portion
of an exclusive operation, a subsequent exclusive read by that Manager using the same transaction ID
changes the address that is being monitored for exclusive accesses.

### A7.2.2 Exclusive access from the perspective of the Manager

A Manager starts an exclusive operation by performing an exclusive read. If the transaction is successful, the
Subordinate returns the EXOKAY response, indicating that the Subordinate recorded the address to be monitored
for exclusive accesses.

If the Manager attempts an exclusive read from a Subordinate that does not support exclusive accesses, the
Subordinate returns the OKAY response instead of the EXOKAY response.

### Note

The Manager can treat the OKAY response as an error condition indicating that the exclusive access is not
supported. This specification recommends that the Manager does not perform the write portion of this exclusive
operation.

At some time after the exclusive read, the Manager tries an exclusive write to the same location. If the contents of
the addressed location have not been updated since the exclusive read, the exclusive write operation succeeds. The
Subordinate returns the EXOKAY response, and updates the memory location.

If the contents of the addressed location have been updated since the exclusive read, the exclusive write attempt
fails, and the Subordinate returns the OKAY response instead of the EXOKAY response. The exclusive write
attempt does not update the memory location.

A Manager might not complete the write portion of an exclusive operation. If this happens, the Subordinate
continues to monitor the address for exclusive accesses until another exclusive read starts a new exclusive access
sequence.

A Manager must not start the write part of an exclusive access sequence until the read part is complete.

### A7.2.3 Exclusive access from the perspective of the Subordinate

A Subordinate that does not support exclusive accesses can ignore the AxLOCK signals. It must provide an OKAY
response for both normal and exclusive accesses.

A Subordinate that supports exclusive access must have monitor hardware. This specification recommends that such
a Subordinate has a monitor unit for each exclusive-capable Manager ID that can access it. The Arm Architecture
Reference Manual, Armv7-A and Armv7-R edition defines an exclusive access monitor, and a single-ported
Subordinate can have such an exclusive access monitor external to the Subordinate. A multiported Subordinate
might require internal monitoring.

The exclusive access monitor records the address and ARID value of any exclusive read operation. Then it monitors
that location until either a write occurs to that location or until another exclusive read with the same ARID value
resets the monitor to a different address.

When the Subordinate receives an exclusive write with a given AWID value, the monitor checks to see if that
address is being monitored for exclusive access with that AWID. If it is, then this indicates that no write has
occurred to that location since the exclusive read access, and the exclusive write proceeds, completing the exclusive
access. The Subordinate returns the EXOKAY response to the Manager, and updates the addressed memory
location.

If the address is not being monitored with the same AWID value at the time of an exclusive write, this indicates one
of the following:

- The location has been updated since the exclusive read access.
- The monitor has been reset to another location.
- The Manager did not issue an exclusive read with the same attributes as the exclusive write.

In both cases the exclusive write must not update the addressed location, and the Subordinate must return the OKAY
response instead of the EXOKAY response.

### Exclusive access restrictions

### A7.2.4

The following restrictions apply to exclusive accesses:

The address of an exclusive access must be aligned to the total number of bytes in the transaction, that is, the
product of the burst size and burst length.

The number of bytes to be transferred in an exclusive access burst must be a power of 2, that is, 1, 2, 4, 8, 16,
32, 64, or 128 bytes.

- The maximum number of bytes that can be transferred in an exclusive burst is 128.

- The burst length for an exclusive access must not exceed 16 transfers.

The value of the AxCACHE signals must guarantee that the transaction reaches the Subordinate that is
monitoring exclusive accesses. If there is a buffer or cache which might respond to an exclusive access before
it reaches the monitor, then the exclusive access must be Non-bufferable or Non-cacheable.

The domain must be Non-shareable or System-shareable.

- The transaction type must be ReadNoSnoop or WriteNoSnoop.

Failure to observe these restrictions causes UNPREDICTABLE behavior.

For an exclusive read and an exclusive write to be considered part of the same exclusive access sequence, the
following signals must be the same for both transfers:

- AxID

- AxADDR

- AxREGION

- AxLEN

- AxSIZE

- AxBURST

- AxLOCK

- AxCACHE

- AxPROT

- AxDOMAIN

- AxSNOOP

- AxMMUSECSID

- AxMMUSID

- AxMMUSSIDV

- AxMMUSSID

- AxMMUATST

The minimum number of bytes to be monitored during an exclusive operation is defined by the burst length and
burst size of the transaction. The Subordinate can monitor a larger number of bytes, up to 128, which is the
maximum size of an exclusive access. However, this can result in a successful exclusive access being indicated as
failing because a neighboring byte was updated.

### A7.2.5 Responses to exclusive access

The response signals, RRESP and BRESP, include an OKAY response for successful normal accesses and an
EXOKAY response for successful exclusive accesses. This means that a Subordinate that does not support exclusive
accesses can provide an OKAY response to indicate the failure of an exclusive access.

### Note

An exclusive write to a Subordinate that does not support exclusive access always updates the memory
location.

An exclusive write to a Subordinate that supports exclusive access updates the memory location only if the
exclusive write is successful.

An exclusive write has a single response using BRESP, which can be OKAY, EXOKAY, SLVERR or DECERR.

An exclusive read has one or more response beats. These can be a mixture of EXOKAY, SLVERR and DECERR or
a mixture of OKAY, SLVERR and DECERR. Mixing EXOKAY and OKAY responses in the same transaction is
not permitted.

### A7.3 Locked accesses

AXI4 does not support locked transactions. However, an AXI3 implementation must support locked transactions.

Note

AXI4 removes support for locked transactions because:

- The majority of components do not require locked transactions.

- The implementation of locked transactions has a significant effect on:
  - The complexity of the interconnect
  - The ability to make QoS guarantees

In this specification, AxLOCK indicates ARLOCK or AWLOCK.

When a Manager uses the AxLOCK signals for a transaction to show that it is a locked transaction then the
interconnect must ensure that only that Manager can access the targeted Subordinate region, until an unlocked
transaction from the same Manager completes. An arbiter within the interconnect must enforce this restriction.

Before a Manager starts a locked sequence of either read or write transactions it must ensure that it has no other
transactions waiting to complete.

Any transaction with AxLOCK indicating a locked transaction forces the interconnect to lock the following
transaction. Therefore, a locked sequence must always complete with a final transaction that does not have
AxLOCK indicating a locked transaction. This final transaction is included in the locked sequence and effectively
removes the lock.

When completing a locked sequence, before issuing the final unlocking transaction, a Manager must ensure that all
previous locked transactions are complete. It must then ensure that the final unlocking transaction has completed
before it starts any further transactions.

The Manager must ensure that all transactions in a locked sequence have the same AxID value.

This specification recommends the following restrictions, but they are not mandatory:

- Keep any locked transaction sequence within a single 4 KB address region.

- Limit any locked transaction sequence to two transactions.

### A7.4 Atomic access signaling

In AXI3 the AxLOCK signals specify normal, exclusive, and locked accesses. Table A7-1 shows the AXI3
encoding of the AxLOCK signals.

Table A7-1 AXI3 atomic access encoding

|  | Access type |
| --- | --- |
| 0b00 | Normal access |
| 0b01 | Exclusive access |
| 0b10 | Locked access |
| 0b11 | Reserved |

AXI4 removes the support for locked transactions and uses only a 1-bit lock signal. Table A7-2 shows the AXI4
signal encoding of the AxLOCK signals.

Table A7-2 AXI4 atomic access encoding

|  | Access type |
| --- | --- |
| 0b0 | Normal access |
| 0b1 | Exclusive access |

### A7.4.1 Legacy considerations

In an AXI4 environment, any AXI3 locked transaction is converted as follows:

- AWLOCK[1:0] = 0b10 is converted to a normal write transaction, AWLOCK = 0b0

- ARLOCK[1:0] = 0b10 is converted to a normal read transaction, ARLOCK = 0b0

This specification recommends that any component performing such a conversion, typically an interconnect,
includes an optional mechanism to detect and flag that such a translation has occurred.

Any component that cannot operate correctly if this translation is performed cannot be used in an AXI4
environment.

### Note

For many legacy cases that use locked transactions, such as the execution of a SWP instruction, a software change
might be required to prevent the use of any instruction that forces a locked transaction.

## Chapter A8

### AMBA 4 Additional Signaling

This chapter describes the additional signaling that is introduced in AMBA 4 to extend the application of the AXI
interface. It contains the following sections:

- QoS signaling on page A8-102
- Multiple region signaling on page A8-103
- User-defined signaling on page A8-104

### A8.1 QoS signaling

This section describes the additional signaling in the AXI4 protocol to support Quality of Service (QoS).

### A8.1.1 QoS interface signals

The AXI4 signal set is extended to support two 4-bit QoS identifiers:
AWQOS A 4-bit QoS identifier, sent on the write address channel for each write transaction.
ARQOS A 4-bit QoS identifier, sent on the read address channel for each read transaction.

In this specification, AxQOS indicates AWQOS or ARQOS.

The protocol does not specify the exact use of the QoS identifier. This specification recommends that AxQOS is
used as a priority indicator for the associated write or read transaction. A higher value indicates a higher priority
transaction.

A default value of 0b0000 indicates that the interface is not participating in any QoS scheme.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>Additional interpretations of the QoS identifier can be used.</td>
 </tr>
</table>

### A8.1.2 Manager considerations

A Manager can produce its own AxQOS values, and if it can produce multiple streams of traffic it can choose
different QoS values for the different streams.

Support for QoS requires a system-level understanding of the QoS scheme in use, and collaboration between all
participating components. For this reason, this specification recommends that a Manager component includes some
programmability that can be used to control the exact QoS values that are used for any given scenario.

If a Manager component does not support a programmable QoS scheme, it can use QoS values that represent the
relative priorities of the transactions it generates. These values can then be mapped to alternative system level QoS
values if appropriate.

A Manager that cannot produce its own AxQOS values must use the default value.

### A8.1.3 System considerations

QoS signaling, as defined in AXI4, can be used with any compatible system-level QoS methodology.

The default system-level implementation of QoS is that any component with a choice of more than one transaction
to process selects the transaction with the higher QoS value to process first. This selection only occurs when there
is no other AXI constraint that requires the transactions to be processed in a particular order.

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>This means that the AXI ordering rules take precedence over ordering for QoS purposes.</td>
 </tr>
</table>

More sophisticated QoS schemes that are compatible with this default scheme can be implemented.

### A8.2 Multiple region signaling

This section describes the optional additional signaling in the AXI4 protocol to support multiple region interfaces.

### A8.2.1 Additional interface signals

Optionally, the AXI4 interface signal set can be extended to support two 4-bit region identifiers:
AWREGION A region identifier, sent on the write address channel for each write transaction.
ARREGION A region identifier, sent on the read address channel for each read transaction.

In this specification, AxREGION indicates AWREGION or ARREGION.

The 4-bit region identifier can be used to uniquely identify up to 16 different regions. The region identifier can
provide a decode of higher-order address bits. The region identifier must remain constant within any 4K-byte
address space.

The use of region identifiers means that a single physical interface on a Subordinate can provide multiple logical
interfaces, each with a different location in the system address map. The use of the region identifier means that the
Subordinate does not have to support the address decode between the different logical interfaces.

This protocol expects an interconnect to produce AxREGION signals when performing the address decode function
for a single Subordinate that has multiple logical interfaces. If a Subordinate only has a single physical interface in
the system address map, the interconnect must use the default AxREGION values. See Chapter A9 Default
Signaling and Interoperability.

There are a number of usage models for the region identifier including, but not limited to, the following:

A peripheral can have its main data path and control registers at different locations in the address map, and
be accessed through a single interface without the need for the Subordinate to perform an address decode.

A Subordinate can exhibit different behaviors in different memory regions. For example, a Subordinate might
provide read and write access in one region, but read only access in another region.

A Subordinate must ensure the correct protocol signaling and the correct ordering of transactions are maintained. A
Subordinate must ensure that it provides the responses to two transactions to different regions with the same AXI
ID in the correct order.

A Subordinate must also ensure the correct protocol signaling for any values of AxREGION. If a Subordinate
implements fewer than sixteen regions, then the Subordinate must ensure the correct protocol signaling on any
attempted access to an unsupported region. How this is achieved is IMPLEMENTATION DEFINED. For example, the
Subordinate might ensure this by:

- Providing an error response for any transaction that accesses an unsupported region.

Aliasing supported regions across all unsupported regions, to ensure that a protocol-compliant response is
given for all accesses.

The AxREGION signals only provide an address decode of the existing address space that can be used by
Subordinates to remove the need for an address decode function. The signals do not create new independent address
spaces. AxREGION must only be present on an interface that is downstream of an address decode function.

### A8.3 User-defined signaling

User-defined signaling was introduced in AMBA 4. For AMBA 5, the usage and configuration of these signals is
further clarified and unified across protocols.

An AXI interface can include a set of user-defined signals, called the User signals. The signals can be used to
augment information to a transaction, where there is a requirement that is not covered by the existing AMBA
specification.

Information can be added to:

- A transaction request

- A transaction response

- Each beat of read or write

data within a transaction

Generally, this specification recommends not to use User signals. The AXI protocol does not define the functions
of these signals, which can lead to interoperability issues if two components use the same User signals in an
incompatible manner.

### A8.3.1 User-defined signaling configuration

The presence and width of User signals is specified by the properties in Table A8-1:

Table A8-1 User signals properties

| Name | Min | Max | Applies to |
| --- | --- | --- | --- |
| USER_REQ_WIDTH | 0 | 128 | AWUSER, ARUSER |
| USER_DATA_WIDTH | 0 |  | WUSER, RUSER |
| USER_RESP_WIDTH | 0 | 16 | BUSER, RUSER |

If a property has a value of zero, then the associated signals are not present on the interface.

The maximum values are for guidance only, in order to set a reasonable maximum for configurable interfaces.

The following interface types can include User signals:

- ACE5

- ACE5-Lite

- ACE5-LiteDVM

- ACE5-LiteACP

- AXI5

- AXI5-Lite

### A8.3.2 Signaling

The User signal names that are defined for each channel are shown in Table A8-2:

### Table A8-2 User-defined signals

| Signal | Width | Description |
| --- | --- | --- |
| ARUSER | USER_REQ_WIDTH | User-defined read request attribute. |
|  |  | This has the same validity requirements as the other AR |
|  |  | channel signals. |
| AWUSER | USER_REQ_WIDTH | User-defined write request attribute. |
|  |  | This has the same validity requirements as the other AW |
|  |  | channel signals. |
| WUSER | USER_DATA_WIDTH | User-defined write data attribute. |
|  |  | This has the same validity requirements as the other W |
|  |  | channel signals. |
| RUSER | USER_DATA_WIDTH + | User-defined read data and response attribute. |
|  | USER_RESP_WIDTH | This has the same validity requirements as the other R |
|  |  | channel signals. |
| BUSER | USER_RESP_WIDTH | User-defined write response attribute. |
|  |  | This has the same validity requirements as the other B |
|  |  | channel signals. |

### A8.3.3 Usage considerations

Where User signals are implemented, it is not required that User signals are supported on all channels. The design
decision whether to include User signals is made independently for request, data, and response channels.

To assist with data width and protocol conversion, this specification recommends that:

- USER_DATA_WIDTH is an integer multiple of the width of the data buses in bytes.

- User response bits are the same value for every beat of a read or write response.

- The lower bits of RUSER are used to transport per-transaction response information.
- The upper bits of RUSER are used to transport per-beat read data information.

## Chapter A9

### Default Signaling and Interoperability

This chapter describes the default signaling and interoperability of the AXI interface.

The AXI protocol does not require a component to use the full set of signals available on an AXI interface. To assist
in the connection of components that do not use every signal, this chapter defines the major categories of interfaces
together with the restrictions that apply to each category. It contains the following sections:

- Interoperability principles on page A9-108
- Major interface categories on page A9-109
- Default signal values on page A9-110

### A9.1 Interoperability principles

The following interoperability principles apply to both AXI3 and AXI4 components.
As a general principle, components must support all combinations of inputs, but do not have to generate all
combinations of outputs. For example, a Subordinate must support all the different possible lengths of burst, but a
Manager only has to generate the types of burst that it uses. This policy ensures that all components work with all
other components.

The conditions that a signal can be omitted from an AXI interface are:

### Optional Outputs

If a component might require a value that does not match the default value, then the component must
have the output signal present.

If a component always requires the value that matches the default value, specified in Default signal
values on page A9-110, then it is not required that the component has the signal present.

### Optional Inputs

An input signal can be omitted if the Manager or Subordinate does not need to observe the input
signal for correct functional operation.

### Note

Interconnect components can also omit signals when appropriate. For example, when a signal is only ever driven to
its default value, there is no requirement to transport that signal across the interconnect. The signal can be created
at its destination. Similarly, if a signal is not used at any destination then there is no requirement to transport it across
the interconnect.

### A9.2 Major interface categories

The following sections describe the major interface categories.

### A9.2.1 Read/write interface

A read write interface includes the following AXI channels:
AR Read address channel
R Read data channel
AW Write address channel
W Write data channel
B Write response channel

### A9.2.2 Read-only interface

A read-only interface supports only read transactions and includes the following AXI channels:
AR Read address channel
R Read data channel

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>A read-only interface does not support exclusive accesses.</td>
 </tr>
</table>

### A9.2.3 Write-only interface

A write-only interface supports only write transactions and includes the following AXI channels:
AW Write address channel
W Write data channel
B Write response channel

<table>
 <tr>
  <th>Note</th>
 </tr>
 <tr>
  <td>A write-only interface does not support exclusive accesses.</td>
 </tr>
</table>

### A9.2.4 Memory Subordinates and Peripheral Subordinates

AXI Subordinates are classified as Memory Subordinates or Peripheral Subordinates.

A Memory Subordinate must handle all transaction types correctly.

Peripheral Subordinates are expected to have a defined method of access that establishes the types of transaction
that can be used to access a device, and if there are any restrictions on how the device is accessed. Typically, the
defined method of access is described in the data sheet for the component. Any access that is not a defined method
of access might cause the Peripheral Subordinate to fail but is expected to complete in a protocol-compliant fail-safe
manner, to prevent system deadlock. Continued correct operation of the Peripheral Subordinate is not required.

Because a Peripheral Subordinate is required to work correctly only for its defined method of access, a Peripheral
Subordinate can have a significantly reduced set of interface signals.

### Note

All peripherals are expected to support a subset of transactions that permit the peripheral to be controlled using
accesses that can be specified in C code. For example, single 8-bit, single 16-bit or single 32-bit aligned transactions
might be supported.

No minimum subset is required, because the subset of supported transactions can differ between peripherals. For
example, one peripheral might only support 16-bit accesses and another peripheral might only support 32-bit
accesses.

### A9.3 Default signal values

This specification suggests that, in general, for maximum IP reuse, an AXI component interface includes all signals.
The presence of all signals reduces the risk of error at the system integration phase of the design flow and it can also
help support some design flows that do not effectively support default values for absent signals.

The following tables show the AXI required and optional signals, and the default signals values that apply when an
optional signal is not implemented:

- Table A9-1 shows the Manager interface write channel signals.
- Table A9-2 on page A9-112 shows the Memory Subordinate interface write channel signals.
- Table A9-3 on page A9-113 shows the Manager interface read channel signals.
- Table A9-4 on page A9-114 shows the Memory Subordinate interface read channel.

The following sections give more information about the default signal requirements:

- Manager addresses on page A9-114
- Subordinate addresses on page A9-115
- Memory Subordinates on page A9-115
- Write transactions on page A9-115
- Read transactions on page A9-115
- Response signaling on page A9-115
- Non-secure and Secure accesses on page A9-115

Table A9-1 Manager interface write channel signals and default signal values

Signal Direction Required? Default

ACLK Input Required -

ARESETn Input

Required -

AWID Output Optional All zeros

AWADDR Output Required -

AWREGION Output

Optional All zeros

### AWLEN

Output Optional All zeros, Length 1

AWSIZE Output Optional Data bus width

AWBURST Output

Optional 0b01, INCR

AWLOCK Output Optional All zeros, Normal access

AWCACHE Output

Optional 0b0000

AWPROT Output Required -

AWQOS Output Optional 0b0000

AWVALID Output Required -

AWREADY Input

Required -

WDATA Output Required -

WSTRB Output Optional All ones

WLAST Output Required -

WVALID Output Required -

WREADY Input

Required -

Table A9-1 Manager interface write channel signals and default signal values (continued)

<table>
 <tr>
  <th>Signal</th>
  <td></td>
  <td>Required?</td>
  <td>Default</td>
 </tr>
 <tr>
  <th>BID</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BRESP</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BVALID</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BREADY</th>
  <td>Output</td>
  <td>Required</td>
  <td>-</td>
 </tr>
</table>

Table A9-2 Memory Subordinate interface write channel signals and default signal values

<table>
 <tr>
  <th>Signal name</th>
  <td></td>
  <td>Required?</td>
  <td>Default</td>
 </tr>
 <tr>
  <th>ACLK</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>ARESETn</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWID</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWADDR</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWREGION</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWLEN</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWSIZE</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWBURST</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWLOCK</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWCACHE</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWPROT</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWQOS</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWVALID</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>AWREADY</th>
  <td>Output</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WDATA</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WSTRB</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WLAST</th>
  <td>Input</td>
  <td>Optional</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WVALID</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>WREADY</th>
  <td>Output</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BID</th>
  <td>Output</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BRESP</th>
  <td>Output</td>
  <td>Optional</td>
  <td>0b00, OKAY</td>
 </tr>
 <tr>
  <th>BVALID</th>
  <td>Output</td>
  <td>Required</td>
  <td>-</td>
 </tr>
 <tr>
  <th>BREADY</th>
  <td>Input</td>
  <td>Required</td>
  <td>-</td>
 </tr>
</table>

Table A9-3 Manager interface read channel signals and default signals values

| Signal name | Direction | Required? | Default |
| --- | --- | --- | --- |
| ARID | Output | Optional | All zeros |
| ARADDR | Output | Required | - |
| ARREGION | Output | Optional | 0x0 |
| ARLEN | Output | Optional | All zeros, Length 1 |
| ARSIZE | Output | Optional | Data bus width |
| ARBURST | Output | Optional | 0b01, INCR |
| ARLOCK | Output | Optional | All zeros, Normal access |
| ARCACHE | Output | Optional | 0b0000 |
| ARPROT | Output | Required | - |
| ARQOS | Output | Optional | 0b0000 |
| ARVALID | Output | Required | - |
| ARREADY | Input | Required | - |
| RID | Input | Optional | - |
| RDATA | Input | Required | - |
| RRESP | Input | Optional | - |
| RLAST | Input | Optional | - |
| RVALID | Input | Required | - |
| RREADY | Output | Required | - |

Table A9-4 Memory Subordinate interface read channel signals and default signals values

| Signal name | Direction | Required? | Default |
| --- | --- | --- | --- |
| ARID | Input | Required | - |
| ARADDR | Input | Required | - |
| ARREGION | Input | Optional | - |
| ARLEN | Input | Required | - |
| ARSIZE | Input | Required | - |
| ARBURST | Input | Required | - |
| ARLOCK | Input | Optional | - |
| ARCACHE | Input | Optional | - |
| ARPROT | Input | Optional | - |
| ARQOS | Input | Optional | - |
| ARVALID | Input | Required | - |
| ARREADY | Output | Required | - |
| RID | Output | Required | - |
| RDATA | Output | Required | - |
| RRESP | Output | Optional | 0b00, OKAY |
| RLAST | Output | Required | - |
| RVALID | Output | Required | - |
| RREADY | Input | Required | - |

### A9.3.1 Manager addresses

### AxADDR

There is no minimum requirement for the number of address bits supplied by a Manager.
If the system that the Manager is connected to has a different address bus width than that provided
by the Manager:

If the system address is wider than is provided by the Manager then the default value of all
zeros must be used for the additional high-order address bits.

If the system address is narrower than is provided by the Manager then the high-order address
bits from the Manager must be left unconnected.

### Note

Typically a Manager supplies 32-bits of addressing, optionally a Manager can support up to 64-bits
of addressing.

### A9.3.2 Subordinate addresses

### AxADDR

There is no minimum requirement for the number of address bits used by a Subordinate.
A Subordinate is not required to have low-order address bits to support decoding within the width
of the system data bus and can assume that such low-order address bits have a default value of all
zeros. If the Subordinate has more address bits than supplied by the interconnect, the higher order
address bits use a default value of all zeros.

Typically a Memory Subordinate has at least enough address bits to fully decode a 4KB address
range.

A9.3.3

### Memory Subordinates

### AxLOCK

### AxCACHE

A Memory Subordinate is not required to use the AxLOCK inputs. However, a Memory
Subordinate that supports exclusive accesses requires these signals.

A Memory Subordinate is not required to make use of the AxCACHE inputs. A Memory
Subordinate does not require these signals if either:

- It has no caching behavior.

- It caches all transactions in the same way.

| A9.3.4 | Write |  |  |
| --- | --- | --- | --- |
|  |  | A | is not required to use the write strobe signals WSTRB if it always performs full data |
|  |  | bus | write transactions. The default value for write strobes is all signals asserted. |
|  |  | A | is not required to use the WLAST signal. Since the length of a write burst is defined, |
|  |  | a | can calculate the last write data transfer from the burst length AWLEN[7:0] signals. |
| A9.3.5 | Read |  |  |
|  |  | A | is not required to use the RLAST signal. Since the length of a read burst is defined, a |
|  |  | Manager | can calculate the last read data transfer from the burst length ARLEN[7:0] signals. |
| A9.3.6 | Response | signaling |  |
|  |  | BRESP | Manager does not require the RRESP and BRESP inputs if it both: |
|  |  |  | Does not perform exclusive accesses |
|  |  |  | Does not require notification of transaction errors |
|  |  |  | Subordinate does not require the RRESP and BRESP outputs if it both: |
|  |  |  | Does not support exclusive accesses |
|  |  |  | Does not generate error responses |
| A9.3.7 |  | and Secure | accesses |
|  |  | A | that is not required to differentiate between Non-secure and Secure accesses, and that |

Subordinate
does not require any additional protection support, does not require the AxPROT input signals.

### Caution

Take great care with the AxPROT signals. The AxPROT[1] signals indicate the Secure or
Non-secure nature of the transactions, and incorrect assignment of these bits can lead to incorrect
system behavior.
