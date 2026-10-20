# AMBA AXI ID & Ordering

## AXI Transaction Identifier

### Overview

The AXI protocol includes AXI ID transaction identifiers. A Manager can use these to identify
separate transactions that must be returned in order. All transactions with a given AXI ID value
must remain ordered, but there is no restriction on the ordering of transactions with different ID
values. 

A single physical port can support out-of-order transactions by acting as a number of logical ports,
each handling its transactions in order. 

By using AXI IDs, a Manager can issue transactions without waiting for earlier transactions to
complete. This can improve system performance, because it enables parallel processing of
transactions. 

There is no requirement for Subordinates or Managers to use AXI transaction IDs. Managers and
Subordinates can process one transaction at a time. Transactions are processed in the order they are
issued. 

Subordinates are required to reflect on the appropriate BID or RID response an AXI ID received from
a Manager.

### Read Data Ordering

The Subordinate must ensure that the RID value of any returned data matches the ARID value of the
address that it is responding to.

The interconnect must ensure that the read data from a sequence of transactions with the same ARID
value targeting different Subordinates is received by the Manager in the order that it issued the
addresses.

The read data reordering depth is the number of addresses pending in the Subordinate that can be
reordered. A Subordinate that processes all transactions in order has a read data reordering depth
of one. The read data reordering depth is a static value that must be specified by the designer of
the Subordinate.

There is no mechanism that a Manager can use to determine the read data reordering depth of a
Subordinate.

### Write data ordering

A Manager must issue write data in the same order that it issues the transaction addresses.

An interconnect that combines write transactions from different Managers must ensure that it
forwards the write data in address order.


### Interconnect use of transaction identifiers

When a Manager is connected to an interconnect, the interconnect appends additional bits to the
ARID, AWID and WID identifiers that are unique to that Manager port. This has two effects:

- Managers do not have to know what ID values are used by other Managers because the interconnect
  makes the ID values used by each Manager unique by appending the Manager number to the original
  identifier.
- The ID identifier at a Subordinate interface is wider than the ID identifier at a Manager
  interface.

For response, the interconnect uses the additional bits of the xID identifier to determine which
Manager port the response is destined for. The interconnect removes these bits of the xID
identifier before passing the xID value to the correct Manager port.


#### Master

#### Slave

#### Interconnect
