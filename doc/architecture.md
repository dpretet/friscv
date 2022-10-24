# Architecture

All draws have been created with draw.io, the document being stored in `doc` folder.

## Interfaces & Communication Protocol

The core connects internally its modules with AMBA philosophy. AMBA proposes a simple way to connect
and transfer data between two modules by handshaking with a simple `VALID`/`READY` schema. A master
module, driving information to a slave, asserts its `VALID` control signal as soon it can transfer a
new information, and can't deassert it before a handshake. A slave can accept whenever it wants the
transaction by asserting its `READY` control signal. These simple transaction rules ensure no
deadlock can occur and introduce natively back-pressure through a data & control flow across a core.

The core widely uses AMBA specification. The most simple AMBA communication is an AXI4-Stream
channel, a point-to-point channel carrying data + metadata, handshaking with a `TVALID`/`TREADY`
pair. `TDATA` (the payload) and all sideband signals is considered transfered when both `TVALID` and
`TREADY` are synchronously asserted high in the same clock cycle.

Most of the modules use this AXI4-stream spirit. When data to transfer requires a
memory-oriented access, the core uses AXI4-lite or AXI4. Control unit and data memory controller use
AXI4-lite while the cache layers use AXI4 to transfer a biggest amount of data (AXI4-lite can
transfer a single dataphase but AXI4 can move up to 256 dataphases). AXI4-lite/AXI4 are
splitted-transaction protocols, still relying on the rules explained above to handshake, using
several channels:

- Write address channel: carry address to write and additional info
- Write data channel: data to write to the targeted address
- Write reponse channel: reponse of the slave after the write transaction
- Read address channel: carry address to read and additional info
- Read data channel: slave response carrying the data read at the read address

Using a splitted-transaction protocol avoid useless blocking state during an access and enhance
significantly the global bandwidth of the core and so its performance. It also induces support of
outstanding requests, being able to perform read/write request ahead a data transmission/reception
without blocking the bus and permitting massive parallelism.

The core uses IDs to identify the transactions when using AXI4-lite, which is an optional feature
which permits an easy translation from/to AXI4. More information about AMBA can be found in the
[ARM](https://developer.arm.com/documentation/ihi0022/e?_ga=2.67820049.1631882347.1556009271-151447318.1544783517)
website.

## Architecture


### Core

<p align="center"> <img src="assets/friscv-core-top.png"> </p>

The core is compact and composed by:
- the control unit, fetching and sequencing the instructions
- the processing unit, executing the arithmetic and memory access instructions
- the cache units, at the moment only the instruction cache is available
- the CSR unit, providing the registers to connect the features and extensions
- the ISA registers, shared between control and processing units


### Platform

<p align="center"> <img src="assets/friscv-platform-top.png"> </p>

The FRISCV platform is a top layer instanciating the core, an [AXI4 crossbar](https://github.com/dpretet/axi-crossbar),
and multiple peripherals to interact with external environment. The platform reserves an AXI4 master
interface to connect a RAM, for instance a DDR controller. This interface can be used by instruction
and data buses. The platform also provides a CLINT implmentatiion, some GPIOs and an UART. All
peripherals use an APB interface, binded by an APB interconnect doing a bridge to the AXI4-lite
land.


### Control Unit

<p align="center"> <img src="assets/control-top.png"> </p>

The control unit is the central piece of the core. It acts as a sequencer to fetch and distribute
instructions across the hart. The unit is composed by several pieces:

- The central FSM sequencing the execution
- The program counter management based on current instruction to execute
- A FIFO to buffer the incoming instructions
- An instruction decoder to decompose the machine code and ease the processing

<p align="center"> <img src="assets/control-fetch.png"> </p>

The FSM sequencing the operations manages the PC (program counter) and acts depending the incoming
instructions. It activates the processing unit, manages the jump/branch instruction or read/write
the CSRs.

The control unit pre-loads the next instructions through an AXI4-lite interface, using its
non-blocking nature to read multiple outstanding requests and so unleash the performance of the
core. In case a jump or a branching is necessary, it will drop the next useless incoming requests
and reboot a new batch of requests up to the next jump.

<p align="center"> <img src="assets/control-or.png"> </p>

The above figure illustrates a processor booting at address `0x0`, issuing multiple outstanding
requests. Addresses from `0x0` to `0x2` return instructions to execute in the next cycle but address
`0x3` returns a JAL (jump) to move to address `0xA`. So outstanding requests coming back with
addresses `0x4` and `0x5` are discarded and only instructions from `0xA` will be used. To identify
this new memory section read, the control unit increments the address channel ID when jumping to
ease this batch identification.

The FIFO present as a front-end of the module is very important to store incoming instructions in
case the processing unit, the CSRs are not ready to execute an instruction (for instance if reading
the external central memory).

In case the control unit pre-loaded too much instruction while a branch needs to be taken, it can
flush the front-end FIFO and the iCache buffer and restarts faster to follow the new branch.

The controls unit also manages the exceptions occuring and the traps (asynchronous or synchronous).


### Processing Unit

The processing unit encloses the memory controller managing LOAD/STORE instructions and the ALU unit
managing the arithmetic and logical instructions. It's nowadays very simple and executes the
instructions in-order.

<p align="center"> <img src="assets/processing.png"> </p>


### Cache Units

At this moment, only an instruction cache is available in the core. A data cache module is present
but can only manages AXI4-lite to AXI4 interface conversion when using the
[platform](../rtl/friscv_rv32i_platform.sv).


#### Instruction Cache

<p align="center"> <img src="./assets/iCache-top.png"> </p>

The instruction cache stage acts a local buffer storing the most frequently used instructions to
avoid doing read requests to the central memory, which would take significantly longer time to be
accessed than a local memory. This stage increases the bandwidth when fetching the next instructions
to process and thus increases the overall processor performance.

Features:

- Direct-mapped placement policy
- Parametrizable cache depth
- Parametrizable cache line width
- Parametrizable number of outstanding requests
- Software-based flush control with FENCE.i instruction
- Transparent operation for user, no need of any kind of management
- Cache prefetch can be activated in the internal memory controller to enhance efficiency
- AXI4-lite slave interface to fetch an instruction
- AXI4 master interface to read the system memory

Explanations about the basics of cache layers can be found in this [document](./cache_layers.md).

The cache unit is built around the central FSM, the fetcher stage:

<p align="center"> <img src="./assets/iCache-fetcher.png"> </p>

The fetch stage receives the read request from the control unit and parses the caches blocks to find
the requested instructions. The fetcher uses two FIFOs, one to store the incoming requests, the
other to store the cache-miss requests. As long the instructions are available in the cache, the
fetcher uses the first FIFO; once a cache-miss is reached, the missing address is stored in the
second FIFO. Then, the memory controller reads the central memory with the missing address and fills
the cache blocks to serve again the cache-miss FIFO. The fetcher stage navigates back and forth
between the two FIFOs, between the cache blocks and the memory controller.

<p align="center"> <img src="./assets/iCache-cache-lines.png"> </p>

The cache blocks are organized with a direct-mapped cache architecture. Each line width can be
configured as well the number of cache lines (the cache depth). Each line stores the tag, the
instuctions and the set bit. The tag is the part of an address's MSB used to identify the real
address stored, the set bit indicates if this lines as been already written or not.

<p align="center"> <img src="./assets/iCache-address.png"> </p>

The above figure illustrates how an address is exploited to organize and retrive an instruction:

addr = | tag | index | offset |

- offset: log2(nb instructions per block) bits, selects the right instruction in the cache block
- index:  log2(cache depth) bits, selects a cache block in the pool
- tag:    the remaining MSBs, the part helping to determine a cache hit/miss


#### Data Cache

<p align="center"> <img src="./assets/dCache-top.png"> </p>

The data cache (dCache) relies on the same read flow than iCache. The differences are the dCache
implements a write flow and manages read re-ordering.

Features:

- Direct-mapped placement policy
- Write-through policy for write management
- Parametrizable cache depth
- Parametrizable cache line width
- Parametrizable number of outstanding requests
- IO Region configurable to manage uncachable requests
- Cache prefetch can be activated in the internal memory controller to enhance efficiency
- AXI4-lite slave interface to fetch an instruction
- AXI4 master interface to read/write the system memory

##### Write Path

<p align="center"> <img src="./assets/dCache-pusher.png"> </p>

Pusher stage manages the write path, updating the cache blocks if the address to write is cached
and issuing write request to the memory. It can buffer a certain number of write requests to unleash 
performance, this number being configurable with a parameter. If a write request targets an IO
region, the application indicates with AWCACHE the request is not cachable and need to be directly 
written in the system memory and not in the cache blocks.

##### Read Path

<p align="center"> <img src="./assets/dCache-read-path.png"> </p>

The read path, if needs to manage IO region (uncachable) read multiplex the Block-Fetcher and 
IO-Fetcher modules based on the ARCACHE attribute. IO-Fetcher is always serviced first to issue
request to the memory controller.


##### Read Out-Of-Order Management

<p align="center"> <img src="./assets/dCache-ooo.png"> </p>

Read request can target either an IO region or a cachable region, the application needs to
indicate this information with ARCACHE. Block-Fetcher stage (same module than iCache) manages the
read request in the cache blocks, IO-Fetcher manages the IO request to route directly in the memory
with the memory controller. Because read request can come back out-of-order with the latency
different between block and memory, the dCache uses one more module to manage that. The OoO Manager
module substitutes ARID to make it unique for each read request and uses them to reorder the read 
data completion to the application. This stage can be deactivated if not necessary, if the
application can manage by itself the reordering or if doesn't target IO region (Block-Fetcher always
completes requets in-order).

The module also manages the data interface resizing, the cache block and memory interface being
always wider than XLEN (32 or 64 bits).

##### AXI4 Ordering Rules

AXI doesn't provide advanced ordering rules and instructs the user to issue first a sequence of
write then a sequence of read only once write completions have been all received (and vice versa).
Internally, the cache could still processing or waiting for write requests while the application is
already able to issue new series of R/W requests. The cache manages that situation by monitoring all
read and write modules and block any situation that could lead to read / write collision and data
integrity corruption.

However, the read and write path always buffer request with FIFO, preventing to slow down the
application performance. Only the processing of the request will be stopped, the communication with
the cache will remain active as long the FIFO are not full.


### CSR Unit

The core implements in a dedicated module the supported registers described in the ISA manuel volume
2 (privileged specification).

The core implements the following CSR registers into the dedicated module:

- mhartid (RO)
- mstatus (RW)
- misa (RW)
- mie (RW)
- mip (RW)
- mtvec (RW)
- mcounteren (RW)
- mscratch (RW)
- mepc (RW)
- mcause (RW)
- mtval (RW)
- rdcycle (RO)
- rdtime (RO)
- rdinstret (RO)

Next CSRs are available as a memory-mapped peripheral:

- mtime (RO)
- mtimecmp (RW)

They are not available if using only the [core](../rtl/friscv_rv32i_core.sv) module and not its
ready-to-use [platform](../rtl/friscv_rv32i_platform.sv) module including the core and an AXI4
crossbar to connect the peripherals.


### Interrupts

The core and the platform supports few interrupts:

- MEIP, External IRQ: an input from any external source
- MTIP, timer IRQ: MTIME & MTIMECMP CSRs, connected in a memory-mapped peripheral (the CLINT module)
- MSIP(i) software IRQ input: an input from another hart
- MSIP(o) software IRQ output: an output to trigger another hart

The MTIP/MSIP interrupts are implemented in a controller most commonly named CLINT (Core Local
Interrupt). MSIP(o) output is used to trigger another hart with a software interrupt. MTIP, MEIP &
MSIP(i) inputs are directly connected in the CSR management module described above.

The core always handles in its clock domain the interrupts by synchronizing them through a two-stage
FFDs.


#### MSIP Output [RW] - Address 0x0

Output software interrupt MSIP to trigger another core (1 bit)

#### MTIME LSB [RW] - Address 0x4

MTIME CSR, `bit 31:0`

#### MTIME MSB [RW] - Address 0x8

MTIME CSR, `bit 63:32`

#### MTIMECMP LSB [RW] - Address 0xC

MTIMECMP CSR, `bit 31:0`

#### MTIMECMP MSB [RW] - Address 0x10

MTIMECMP CSR, `bit 63:32`


### IO Peripherals

The IOs are connected to a master port of the crossbar through a sub-system interconnect. The IO
modules use APB protocol, so requests from the core are first translated from/to AXI4-lite with
an APB interconnect

#### GPIOS

The GPIOs are binded behind two registers:

##### OUTPUTS [RW] - Address 0x0

XLEN wide general purpose outputs

##### INPUTS [RW] - Address 0x4

XLEN wide general purpose inputs

Reading and writing a GPIOs' register is never blocking.


#### UART

The UART uses few IOs:

- `rx`: serial input, data from an external transmitter
- `tx`: serial output, data to an external receiver
- `rts`: back-pressure flag to indicate the core can't receive anymore data
- `cts`: back-pressure flag to indicate the external receiver can't receive data anymore

The UART uses a FIFO to store data to transmit, and another to store data received. If the FIFOs are
full, the UART can't receive anymore data and rises the RTS flag, or can't transmit anymore and
block the APB bus until the receiver desasserts its CTS flag.

The UART owns few registers. Any attempt to write in a read-only (`RO`) register or a reserved field
will be without effect and can't change the register content neither the engine behavior. Read-write
(`RW`) registers can be written partially by setting properly the WSTRB signal. A read in a write-only
(`WO`) register is not garanteed to return a valid value written previously.

If a transfer (RX or TX) is active and the enable bit is setup back to 0, the transfer will
terminate only after the complete frame transmission.


##### CONTROL AND STATUS [RW/RO] - Address 0x0

- `Bit 0`       : Enable the UART engine (both RX and TX) [RW]
- `Bit 1`       : Loopback mode, every received data will be stored in RX FIFO and forwarded back to TX [RW]
- `Bit 2`       : Enable parity bit [RW]
- `Bit 3`       : 0 for even parity, 1 for odd parity [RW]
- `Bit 4`       : 0 for one stop bit, 1 for two stop bits [RW]
- `Bit 7:5`     : Reserved
- `Bit 8`       : Busy flag, the UART engine is processing (RX or TX) [RO]
- `Bit 9`       : TX FIFO is empty [RO]
- `Bit 10`      : TX FIFO is full [RO]
- `Bit 11`      : RX FIFO is empty [RO]
- `Bit 12`      : RX FIFO is full [RO]
- `Bit 13`      : UART RTS, flagging it can't receive anymore data [RO]
- `Bit 14`      : UART CTS, flagging it can't send anymore data [RO]
- `Bit 15`      : Parity error of the last RX transaction [RO]
- `Bit 31:16`   : Reserved


##### CLOCK DIVIDER [RW] - Address 0x4

The number of CPU core cycles to divide down to get the UART data bit rate (baud rate).

- `Bit 15:0`  : Clock divider
- `Bit 31:16` : Reserved

An update during an ongoing operation will certainly lead to compromise the transfer integrity and
possibly make unstable the UART engine. The user is advised to configure the baud rate during
start-up and be sure the engine is disabled before changing this value.

##### TX FIFO [WO] - Address 0x8

Push data into TX FIFO. Writing into this register will block the APB write request if TX FIFO is
full, until the engine transmit a new word.

- `Bit 7:0`  : data to write
- `Bit 31:8` : Reserved


##### RX FIFO [RO] - Address 0xC

Pull data from RX FIFO. Reading into this register will block the APB read request if FIFO is empty,
until the engine receives a new word.

- `Bit 7:0`  : data ready to be read
- `Bit 31:8` : Reserved

Current limitations:
- only support 8 bits wide data word
- no parity support
- no loopback mode
- no interrupt supported
- be able to free the FIFOs with a register bit when disabling the module
