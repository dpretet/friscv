# AMBA AXI Protocols

The core connects internally its modules with AMBA spirit. AMBA proposes a simple way to connect
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
