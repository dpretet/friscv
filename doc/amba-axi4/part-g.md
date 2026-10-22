# Part G

Appendices

## Appendix G1

### Transaction Naming

This appendix defines the naming scheme that this specification recommends for full cache line and partial cache
line write transactions. It contains the following section:

- Full and partial cache line write transaction naming on page G1-458

Appendix G1 Transaction Naming

### G1.1 Full and partial cache line write transaction naming

A more consistent naming terminology for write transactions is introduced, to differentiate between full cache line
and partial cache line transactions:

- Any transaction that is a full cache line write with all byte strobes asserted is identified by the name suffix
Full.
- Any transaction that is a partial cache line write that is not guaranteed to have all byte strobes asserted is
identified by the name suffix Ptl.

It is permitted for a transaction that is indicated as being a partial cache line write to be a full cache line write.

The name without a suffix, or using a * suffix, is used in any description that covers both the full and partial line
variant of the transaction.

Table G1-1 shows the augmented naming.

### Table G1-1 Augmented naming for write transactions

| Generic | Full cache line | Partial cache line | Notes |
| --- | --- | --- | --- |
| WriteUnique | WriteUniqueFull | WriteUniquePtl | - |
| WriteBack | WriteBackFull | WriteBackPtl | - |
| WriteClean | WriteCleanFull | WriteCleanPtl | - |
| WriteEvict | WriteEvictFull | - | There is no partial line |
|  |  |  | variant for WriteEvict |
| Adoption of the determined. | naming scheme is | and context always | the naming scheme in use to be |
| Note |  |  |  |
| ACE does not write. | an address phase | that a WriteBack or | transaction is a full or partial line |

## Appendix G2

### Signal Lists

Signals for each of the AMBA 5 interfaces are defined in a table with an indication of whether they are mandatory,
optional or configurable.

This Appendix contains:

- Signal matrix on page G2-460
- Check signal matrix on page G2-466

Appendix G2 Signal Lists

### G2.1 Signal matrix

AMBA 5 does not require a component to use the full set of signals available on an interface. To assist in the
connection of components that do not use every signal, Table G2-2 on page G2-461 defines which signals are
required, and which signals are optional in AMBA 5.

If an interface does not include a VALID and READY signal for a particular channel, then no other signals on that
channel can be present.

Table G2-1 lists the codes that are used in Table G2-2 on page G2-461.

### Table G2-1 Key for Signal Matrix

<table>
 <tr>
  <th>Code</th>
  <td>Meaning</td>
 </tr>
 <tr>
  <th>M</th>
  <td>Source is the Manager</td>
 </tr>
 <tr>
  <th>S</th>
  <td>Source is the Subordinate</td>
 </tr>
 <tr>
  <th>I</th>
  <td>Source is Interconnect</td>
 </tr>
 <tr>
  <th>V</th>
  <td>Value is configurable</td>
 </tr>
 <tr>
  <th>Y</th>
  <td>Mandatory for inputs and outputs</td>
 </tr>
 <tr>
  <th>N</th>
  <td>Must not be present</td>
 </tr>
 <tr>
  <th>O</th>
  <td>Optional for inputs and outputs</td>
 </tr>
 <tr>
  <th>OO</th>
  <td>Optional for output ports, mandatory for inputs</td>
 </tr>
 <tr>
  <th>OI</th>
  <td>Optional for input ports, mandatory for outputs</td>
 </tr>
 <tr>
  <th>C</th>
  <td>Conditional, must be present if property is True</td>
 </tr>
 <tr>
  <th>OC</th>
  <td>Optional conditional, optional but can only be present if property is True</td>
 </tr>
 <tr>
  <th>OM</th>
  <td>Optional for Manager interfaces, not present on Subordinate interfaces</td>
 </tr>
</table>

Appendix G2 Signal Lists

Table G2-2 Signal matrix

<table>
 <tr>
  <th>ACLK</th>
  <th>1 --</th>
  <th>-</th>
  <th>YYYYYY</th>
 </tr>
 <tr>
  <td>ARESETn</td>
  <td>1 --</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>AWVALID</td>
  <td>1M-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>AWREADY</td>
  <td>1 S-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>AWID</td>
  <td>V M All zeros</td>
  <td>-</td>
  <td>OO OO OO OO OO OO</td>
 </tr>
 <tr>
  <td>AWADDR</td>
  <td>VM-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>AWREGION</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td>AWLEN</td>
  <td>8 M0x00</td>
  <td>-</td>
  <td>OOOOOOOOOON</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>-</td>
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
  <td>width</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWBURST</td>
  <td>2 M0b01,</td>
  <td>-</td>
  <td>OO OOOONOON</td>
 </tr>
 <tr>
  <td>AWLOCK</td>
  <td>1 M0b0,</td>
  <td></td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td></td>
  <td>access</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>AWCACHE</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOOOON</td>
 </tr>
 <tr>
  <td>AWPROT</td>
  <td>3 M -</td>
  <td>-</td>
  <td>OI OI OI OI OI OI</td>
 </tr>
 <tr>
  <td>AWQOS</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td>AWUSER</td>
  <td>VMAll zeros</td>
  <td>-</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <td>AWDOMAIN</td>
  <td>2M-</td>
  <td>-</td>
  <td>YYYYNN</td>
 </tr>
 <tr>
  <td>AWSNOOP</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOOOOOOONN</td>
 </tr>
 <tr>
  <td>AWBAR</td>
  <td>2 M0b00</td>
  <td></td>
  <td>NNNNNN</td>
 </tr>
 <tr>
  <td>AWUNIQUE</td>
  <td>1 M0b0</td>
  <td></td>
  <td>CNNNNN</td>
 </tr>
 <tr>
  <td>AWSTASHNID</td>
  <td>11 M 0x0000</td>
  <td></td>
  <td>N OC OC OC N N</td>
 </tr>
 <tr>
  <td>AWSTASHNIDEN</td>
  <td>1 M0b0</td>
  <td></td>
  <td>N OC OC OC N N</td>
 </tr>
 <tr>
  <td>AWSTASHLPID</td>
  <td>5 M0b00000</td>
  <td></td>
  <td>N OC OC OC N N</td>
 </tr>
 <tr>
  <td>AWSTASHLPIDEN</td>
  <td>1 M0b0</td>
  <td></td>
  <td>N OC OC OC N N</td>
 </tr>
 <tr>
  <td>AWTRACE</td>
  <td>1 M0b0</td>
  <td>Trace_Signals</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <td>AWLOOP</td>
  <td>V M All zeros</td>
  <td></td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <td>AWMMUSECSID</td>
  <td>1 M0b0</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
</table>

### AWMMUSID

V

M All zeros

Untranslated_Transactions

OC N OC N OC N

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Property

Default

Source

Width

Signal

Appendix G2 Signal Lists

Table G2-2 Signal matrix (continued)

<table>
 <tr>
  <th>AWMMUSSIDV</th>
  <td>1 M0b0</td>
  <td>Untranslated_Transactions</td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <th>AWMMUSSID</th>
  <td>V M All zeros</td>
  <td>Untranslated_Transactions</td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <th>AWMMUATST</th>
  <td>1 M0b0</td>
  <td>Untranslated_Transactions</td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <th>AWMMUFLOW</th>
  <td>2 M0b00</td>
  <td>Untranslated_Transactions</td>
  <td>N N OC N OC N</td>
 </tr>
 <tr>
  <th>AWNSAID</th>
  <td>4 M0x0</td>
  <td>NSAccess_Identifiers</td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <th>AWATOP</th>
  <td>6 M0b000000</td>
  <td>Atomic_Transactions</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <th>AWMPAM</th>
  <td>11 M</td>
  <td>MPAM_Support</td>
  <td>C CCCCN</td>
 </tr>
 <tr>
  <th>AWIDUNQ</th>
  <td>1 M0b0</td>
  <td>Unique_ID_Support</td>
  <td>C CCCCC</td>
 </tr>
 <tr>
  <th>AWCMO</th>
  <td>2 M0b0</td>
  <td>CMO_On_Write</td>
  <td>N C C N N N</td>
 </tr>
 <tr>
  <th>AWTAGOP</th>
  <td>2 M -</td>
  <td>MTE_Support</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <th>WVALID</th>
  <td>1M-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <th>WREADY</th>
  <td>1 S-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <th>WDATA</th>
  <td>VM-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <th>WSTRB</th>
  <td>V M All ones</td>
  <td>-</td>
  <td>OO OO OO OO OO OO</td>
 </tr>
 <tr>
  <th>WLAST</th>
  <td>1 M -</td>
  <td>-</td>
  <td>OI OI OI OI OI N</td>
 </tr>
 <tr>
  <th>WUSER</th>
  <td>VMAll zeros</td>
  <td>-</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <th>WPOISON</th>
  <td>VM-</td>
  <td>Poison</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WTRACE</th>
  <td>1 M0b0</td>
  <td>Trace_Signals</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WTAG</th>
  <td>V M -</td>
  <td>MTE_Support</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <th>WTAGUPDATE</th>
  <td>V M -</td>
  <td>MTE_Support</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <th>BVALID</th>
  <td>1 S-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <th>BREADY</th>
  <td>1M-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <th>BID</th>
  <td>V S -</td>
  <td>-</td>
  <td>OI OI OI OI OI OI</td>
 </tr>
 <tr>
  <th>BRESP</th>
  <td>VSOKAY</td>
  <td>Untranslated _Transactions</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <th>BUSER</th>
  <td>VSAll zeros</td>
  <td>-</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <th>BTRACE</th>
  <td>1 S0b0</td>
  <td>Trace_Signals</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BLOOP</th>
  <td>V S All zeros</td>
  <td>Loopback_Signals</td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <th>BIDUNQ</th>
  <td>1 S0b0</td>
  <td>Unique_ID_Support</td>
  <td>C CCCCC</td>
 </tr>
</table>

### BCOMP

1

S0b0

CMO_On_Write, Persist_CMO,
MTE_Support

NCCNCN

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Property

Default

Source

Width

Signal

Appendix G2 Signal Lists

Table G2-2 Signal matrix (continued)

<table>
 <tr>
  <th>BPERSIST</th>
  <th>1 S0b0</th>
  <th>CMO_On_Write,</th>
  <th>Persist_CMO N C C N N N</th>
 </tr>
 <tr>
  <td>BTAGMATCH</td>
  <td>2 S -</td>
  <td>MTE_Support</td>
  <td>N N C N C N</td>
 </tr>
 <tr>
  <td>ARVALID</td>
  <td>1M-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>ARREADY</td>
  <td>1 S-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>ARID</td>
  <td>V M All zeros</td>
  <td>-</td>
  <td>OO OO OO OO OO OO</td>
 </tr>
 <tr>
  <td>ARADDR</td>
  <td>VM-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>ARREGION</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td>ARLEN</td>
  <td>8 M0x00</td>
  <td>-</td>
  <td>OOOOOOOOOON</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>-</td>
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
  <td>width</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ARBURST</td>
  <td>2 M0b01,</td>
  <td>-</td>
  <td>OO OOOONOON</td>
 </tr>
 <tr>
  <td>ARLOCK</td>
  <td>1 M0b0,</td>
  <td></td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td></td>
  <td>access</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ARCACHE</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOOOON</td>
 </tr>
 <tr>
  <td>ARPROT</td>
  <td>3 M -</td>
  <td>-</td>
  <td>OI OI OI OI OI OI</td>
 </tr>
 <tr>
  <td>ARQOS</td>
  <td>4 M0b0000</td>
  <td>-</td>
  <td>OOONON</td>
 </tr>
 <tr>
  <td>ARUSER</td>
  <td>VMAll zeros</td>
  <td>-</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <td>ARDOMAIN</td>
  <td>2M-</td>
  <td>-</td>
  <td>YYYYNN</td>
 </tr>
 <tr>
  <td>ARSNOOP</td>
  <td>4 M0x0</td>
  <td>-</td>
  <td>OOOOOOO NN</td>
 </tr>
 <tr>
  <td>ARBAR</td>
  <td>2 M0b00</td>
  <td></td>
  <td>NNNNNN</td>
 </tr>
 <tr>
  <td>ARVMIDEXT</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>DVM_v8.1</td>
  <td></td>
 </tr>
 <tr>
  <td>ARTRACE</td>
  <td>1M-</td>
  <td>Trace_Signals</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <td>ARLOOP</td>
  <td>V M All zeros</td>
  <td></td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <td>ARMMUSECSID</td>
  <td>1 M0b0</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <td>ARMMUSID</td>
  <td>V M All zeros</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <td>ARMMUSSIDV</td>
  <td>1 M0b0</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <td>ARMMUSSID</td>
  <td>V M All zeros</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <td>ARMMUATST</td>
  <td>1 M0b0</td>
  <td></td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <td>ARMMUFLOW</td>
  <td>2 M0b00</td>
  <td></td>
  <td>N N OC N OC N</td>
 </tr>
</table>

### ARNSAID

M0x0 NSAccess_Identifiers C C C N C N

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Property

Default

Source

Width

Signal

Appendix G2 Signal Lists

Table G2-2 Signal matrix (continued)

<table>
 <tr>
  <th>ARMPAM</th>
  <th>11 M</th>
  <th>MPAM_Support</th>
  <th>C CCCCN</th>
 </tr>
 <tr>
  <td>ARCHUNKEN</td>
  <td>1 M0b0</td>
  <td></td>
  <td>N CCCCN</td>
 </tr>
 <tr>
  <td>ARIDUNQ</td>
  <td>1 M0b0</td>
  <td></td>
  <td>C CCCCC</td>
 </tr>
 <tr>
  <td>ARTAGOP</td>
  <td>2 M -</td>
  <td>MTE_Support</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <td>RVALID</td>
  <td>1 S-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>RREADY</td>
  <td>1M-</td>
  <td>-</td>
  <td>YYYYYY</td>
 </tr>
 <tr>
  <td>RID</td>
  <td>V S -</td>
  <td>-</td>
  <td>OI OI OI OI OI OI</td>
 </tr>
 <tr>
  <td>RDATA</td>
  <td>VS-</td>
  <td>-</td>
  <td>YYYYYY</td>
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
  <td>RLAST</td>
  <td>1S-</td>
  <td>-</td>
  <td>OI OI OI OI OI N</td>
 </tr>
 <tr>
  <td>RUSER</td>
  <td>VSAll zeros</td>
  <td>-</td>
  <td>OOOOOO</td>
 </tr>
 <tr>
  <td>RPOISON</td>
  <td>VS-</td>
  <td>Poison</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <td>RTRACE</td>
  <td>1 S0b0</td>
  <td>Trace_Signals</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <td>RLOOP</td>
  <td>V S All zeros</td>
  <td></td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <td>RIDUNQ</td>
  <td>1 S0b0</td>
  <td></td>
  <td>C CCCCC</td>
 </tr>
 <tr>
  <td>RCHUNKV</td>
  <td>1 S0b0</td>
  <td></td>
  <td>N CCCCN</td>
 </tr>
 <tr>
  <td>RCHUNKNUM</td>
  <td>V S All zeros</td>
  <td></td>
  <td>N CCCCN</td>
 </tr>
 <tr>
  <td>RCHUNKSTRB</td>
  <td>V S All zeros</td>
  <td></td>
  <td>N CCCCN</td>
 </tr>
 <tr>
  <td>RTAG</td>
  <td>V S -</td>
  <td>MTE_Support</td>
  <td>N C C N C N</td>
 </tr>
 <tr>
  <td>ACVALID</td>
  <td>1 I-</td>
  <td>-</td>
  <td>YYNNNN</td>
 </tr>
 <tr>
  <td>ACREADY</td>
  <td>1M-</td>
  <td>-</td>
  <td>YYNNNN</td>
 </tr>
 <tr>
  <td>ACADDR</td>
  <td>V I-</td>
  <td>-</td>
  <td>YYNNNN</td>
 </tr>
 <tr>
  <td></td>
  <td></td>
  <td>-</td>
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
  <td>message</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ACPROT</td>
  <td>3 I0b000</td>
  <td>-</td>
  <td>YONNNN</td>
 </tr>
 <tr>
  <td></td>
  <td>-</td>
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
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td>ACTRACE</td>
  <td>1 I-</td>
  <td>Trace_Signals</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <td>CRVALID</td>
  <td>1M-</td>
  <td>-</td>
  <td>YYNNNN</td>
 </tr>
</table>

### CRREADY

1 I-

- YYNNNN

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Property

Default

Source

Width

Signal

Appendix G2 Signal Lists

Table G2-2 Signal matrix (continued)

<table>
 <tr>
  <th>CRRESP</th>
  <td>5 M0b00000</td>
  <td>-</td>
  <td>YONNNN</td>
 </tr>
 <tr>
  <th>CRTRACE</th>
  <td>1M-</td>
  <td>Trace_Signals</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>CRNSAID</th>
  <td>4M-</td>
  <td></td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDVALID</th>
  <td>1 M0b0</td>
  <td>-</td>
  <td>ONNNNN</td>
 </tr>
 <tr>
  <th>CDREADY</th>
  <td>1 I0b1</td>
  <td>-</td>
  <td>ONNNNN</td>
 </tr>
 <tr>
  <th>CDDATA</th>
  <td>VMAll zeros</td>
  <td>-</td>
  <td>ONNNNN</td>
 </tr>
 <tr>
  <th>CDLAST</th>
  <td>1 M0b0</td>
  <td>-</td>
  <td>ONNNNN</td>
 </tr>
 <tr>
  <th>CDPOISON</th>
  <td>VM-</td>
  <td>Poison</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDTRACE</th>
  <td>1M-</td>
  <td>Trace_Signals</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>RACK</th>
  <td>1M-</td>
  <td>-</td>
  <td>YNNNNN</td>
 </tr>
 <tr>
  <th>WACK</th>
  <td>1M-</td>
  <td>-</td>
  <td>YNNNNN</td>
 </tr>
 <tr>
  <th>VAWQOSACCEPT</th>
  <td>4 S -</td>
  <td>QoS_Accept</td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <th>VARQOSACCEPT</th>
  <td>4 S -</td>
  <td>QoS_Accept</td>
  <td>C C C N C N</td>
 </tr>
 <tr>
  <th>AWAKEUP</th>
  <td>1 M -</td>
  <td>Wakeup_Signals</td>
  <td>C CCCCC</td>
 </tr>
 <tr>
  <th>ACWAKEUP</th>
  <td>1 I -</td>
  <td>Wakeup_Signals</td>
  <td>C C NNNN</td>
 </tr>
 <tr>
  <th>SYSCOREQ</th>
  <td>1 M -</td>
  <td></td>
  <td>C C NNNN</td>
 </tr>
 <tr>
  <th>SYSCOACK</th>
  <td>1 I -</td>
  <td></td>
  <td>C C NNNN</td>
 </tr>
 <tr>
  <th>BROADCASTATOMIC</th>
  <td>1--</td>
  <td>-</td>
  <td>NOMOMNOMN</td>
 </tr>
 <tr>
  <th>BROADCASTINNER</th>
  <td>1 --</td>
  <td>-</td>
  <td>OMNNNNN</td>
 </tr>
 <tr>
  <th>BROADCASTOUTER</th>
  <td>1 --</td>
  <td>-</td>
  <td>OMNNNNN</td>
 </tr>
 <tr>
  <th></th>
  <td>1 --</td>
  <td>-</td>
  <td>OMNNNNN</td>
 </tr>
</table>

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Property

Default

Source

Width

Signal

Appendix G2 Signal Lists

### G2.2 Check signal matrix

Table G2-3 shows the protection signals that can be present on an interface, based on the value of the property
Check_Type.

Table G2-3 Signal matrix

<table>
 <tr>
  <th>AWVALIDCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>AWREADYCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>AWIDCHK</th>
  <td>V</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC OC</td>
 </tr>
 <tr>
  <th>AWADDRCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>AWLENCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC N</td>
 </tr>
 <tr>
  <th>AWCTLCHK0</th>
  <td>1</td>
  <td>M0b0</td>
  <td>OC OC OC OC OC OC</td>
 </tr>
 <tr>
  <th>AWCTLCHK1</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC N</td>
 </tr>
 <tr>
  <th>AWCTLCHK2</th>
  <td>1</td>
  <td>M0b0</td>
  <td>CCCCNN</td>
 </tr>
 <tr>
  <th>AWCTLCHK3</th>
  <td>1</td>
  <td>M0b0</td>
  <td>N OCOCNOCN</td>
 </tr>
 <tr>
  <th>AWUSERCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCOCOCOCOCOC</td>
 </tr>
 <tr>
  <th>AWSTASHNIDCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>N OCOCOCNN</td>
 </tr>
 <tr>
  <th>AWSTASHLPIDCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>N OCOCOCNN</td>
 </tr>
 <tr>
  <th>AWTRACECHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>AWLOOPCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>AWMMUCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <th>AWMMUSIDCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCNOCNOCN</td>
 </tr>
 <tr>
  <th>AWMMUSSIDCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCNOCNOCN</td>
 </tr>
 <tr>
  <th>AWNSAIDCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>AWMPAMCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCN</td>
 </tr>
 <tr>
  <th>WVALIDCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WREADYCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WDATACHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WSTRBCHK</th>
  <td>V</td>
  <td>M All zeros</td>
  <td>OCOCOCOCOCOC</td>
 </tr>
 <tr>
  <th>WLASTCHK</th>
  <td>1</td>
  <td>M-</td>
  <td>OCOCOCOCOCN</td>
 </tr>
 <tr>
  <th>WUSERCHK</th>
  <td></td>
  <td>ones</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WPOISONCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>WTRACECHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCCCC</td>
 </tr>
</table>

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Default

Source

Width

Signal

<table>
 <tr>
  <th>WTAGCHK</th>
  <td></td>
  <td></td>
  <td>NCCNCN</td>
 </tr>
 <tr>
  <th>BVALIDCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BREADYCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BIDCHK</th>
  <td>V</td>
  <td>S0b1</td>
  <td>OC OC OC OC OC OC</td>
 </tr>
 <tr>
  <th>BRESPCHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BUSERCHK</th>
  <td></td>
  <td>ones</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BTRACECHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>BLOOPCHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>ARVALIDCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>ARREADYCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>ARIDCHK</th>
  <td>V</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC OC</td>
 </tr>
 <tr>
  <th>ARADDRCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>ARLENCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC N</td>
 </tr>
 <tr>
  <th>ARCTLCHK0</th>
  <td>1</td>
  <td>M-</td>
  <td>OCOCOCOCOCOC</td>
 </tr>
 <tr>
  <th>ARCTLCHK1</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC OC OC OC OC N</td>
 </tr>
 <tr>
  <th>ARCTLCHK2</th>
  <td></td>
  <td></td>
  <td>CCCCNN</td>
 </tr>
 <tr>
  <th>ARCTLCHK3</th>
  <td></td>
  <td></td>
  <td>CCCCCN</td>
 </tr>
 <tr>
  <th>ARUSERCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCOCOCOCOCOC</td>
 </tr>
 <tr>
  <th>ARTRACECHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>ARLOOPCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>ARMMUCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OC N OC N OC N</td>
 </tr>
 <tr>
  <th>ARMMUSIDCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCNOCNOCN</td>
 </tr>
 <tr>
  <th>ARMMUSSIDCHK</th>
  <td>V</td>
  <td>M All ones</td>
  <td>OCNOCNOCN</td>
 </tr>
 <tr>
  <th>ARNSAIDCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>ARMPAMCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCN</td>
 </tr>
 <tr>
  <th>RVALIDCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RREADYCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RIDCHK</th>
  <td>V</td>
  <td>S0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RDATACHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RRESPCHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>C OCOCOCOCOC</td>
 </tr>
</table>

Appendix G2 Signal Lists

Table G2-3 Signal matrix (continued)

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Default

Source

Width

Signal

Appendix G2 Signal Lists

Table G2-3 Signal matrix (continued)

<table>
 <tr>
  <th>RLASTCHK</th>
  <td>1</td>
  <td>S-</td>
  <td>CCCCCN</td>
 </tr>
 <tr>
  <th>RCHUNKCHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>NCCCCN</td>
 </tr>
 <tr>
  <th>RUSERCHK</th>
  <td>V</td>
  <td>S All ones</td>
  <td>OCOCOCOCOCOC</td>
 </tr>
 <tr>
  <th>RPOISONCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RTRACECHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>CCCCCC</td>
 </tr>
 <tr>
  <th>RLOOPCHK</th>
  <td>1</td>
  <td>S0b1</td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>RTAGCHK</th>
  <td></td>
  <td></td>
  <td>NCCNCN</td>
 </tr>
 <tr>
  <th>ACVALIDCHK</th>
  <td>1</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>ACREADYCHK</th>
  <td></td>
  <td></td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>ACADDRCHK</th>
  <td>V</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>ACCTLCHK</th>
  <td>1</td>
  <td>I0b1</td>
  <td>C OCNNNN</td>
 </tr>
 <tr>
  <th>ACVMIDEXTCHK</th>
  <td>1</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>ACTRACECHK</th>
  <td>1</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>CRVALIDCHK</th>
  <td></td>
  <td></td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>CRREADYCHK</th>
  <td>1</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>CRRESPCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>C OCNNNN</td>
 </tr>
 <tr>
  <th>CRTRACECHK</th>
  <td></td>
  <td></td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>CRNSAIDCHK</th>
  <td></td>
  <td></td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDVALIDCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDREADYCHK</th>
  <td>1</td>
  <td>I0b0</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDDATACHK</th>
  <td></td>
  <td>ones</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDLASTCHK</th>
  <td>1</td>
  <td>M0b1</td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDPOISONCHK</th>
  <td></td>
  <td></td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>CDTRACECHK</th>
  <td></td>
  <td></td>
  <td>OCNNNNN</td>
 </tr>
 <tr>
  <th>RACKCHK</th>
  <td></td>
  <td></td>
  <td>CNNNNN</td>
 </tr>
 <tr>
  <th>WACKCHK</th>
  <td></td>
  <td></td>
  <td>CNNNNN</td>
 </tr>
 <tr>
  <th>VAWQOSACCEPTCHK</th>
  <td></td>
  <td></td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>VARQOSACCEPTCHK</th>
  <td></td>
  <td></td>
  <td>CCCNCN</td>
 </tr>
 <tr>
  <th>AWAKEUPCHK</th>
  <td></td>
  <td></td>
  <td>CCCCCC</td>
 </tr>
</table>

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Default

Source

Width

Signal

Appendix G2 Signal Lists

### Table G2-3 Signal matrix (continued)

<table>
 <tr>
  <th>Signal<br/>ACWAKEUPCHK</th>
  <td>Width<br/>1</td>
  <td>Source Default<br/>S-</td>
  <td>ACE5 ACE5-LiteDVM ACE5-Lite ACE5-LiteACP AXI5 AXI5-Lite<br/>CCNNNN</td>
 </tr>
 <tr>
  <th>SYSCOREQCHK</th>
  <td></td>
  <td></td>
  <td>CCNNNN</td>
 </tr>
 <tr>
  <th>SYSCOACKCHK</th>
  <td>1</td>
  <td>I-</td>
  <td>CCNNNN</td>
 </tr>
</table>

Appendix G2 Signal Lists

## Appendix G3

### Interface Property Summary

Appendix G3 Interface Property Summary

### G3.1 Summary of interface properties

If an entry is not "Y", then the property must be False or undeclared for that interface type.

### Table G3-1 Summary of interface properties

### Property

<table>
 <tr>
  <th></th>
  <td>E Y - - - - - Y - - - -</td>
 </tr>
 <tr>
  <th>DVM_v8</th>
  <td>EYY----Y----</td>
 </tr>
 <tr>
  <th>Multi_Copy_Atomicity</th>
  <td>E Y Y Y Y Y Y Y Y Y Y Y</td>
 </tr>
 <tr>
  <th>Ordered_Write_Observation</th>
  <td>EYYYYYYYYYYY</td>
 </tr>
 <tr>
  <th>WriteEvict_Transaction</th>
  <td>E Y - - - - - Y - - - -</td>
 </tr>
 <tr>
  <th>Atomic_Transactions</th>
  <td>F - Y Y - Y - - - - - -</td>
 </tr>
 <tr>
  <th>Barrier_Transactions</th>
  <td>F - - - - - - Y Y - - -</td>
 </tr>
 <tr>
  <th>Cache_Stash_Transactions</th>
  <td>F - Y Y Y - - - - - - -</td>
 </tr>
 <tr>
  <th>Check_Type</th>
  <td>F Y Y Y Y Y Y - - - - -</td>
 </tr>
 <tr>
  <th></th>
  <td>F Y Y - - - - - - - - -</td>
 </tr>
 <tr>
  <th>DeAllocation_Transactions</th>
  <td>F - Y Y - - - - - - - -</td>
 </tr>
 <tr>
  <th>DVM_v8.1</th>
  <td>F Y Y - - - - Y - - - -</td>
 </tr>
 <tr>
  <th>Loopback_Signals</th>
  <td>F Y Y Y - Y - - - - - -</td>
 </tr>
 <tr>
  <th>NSAccess_Identifiers</th>
  <td>F Y Y Y - Y - - - - - -</td>
 </tr>
 <tr>
  <th>Persist_CMO</th>
  <td>F Y Y Y - - - - - - - -</td>
 </tr>
 <tr>
  <th>Poison</th>
  <td>FYYYYYY-----</td>
 </tr>
 <tr>
  <th>QoS_Accept</th>
  <td>FYYY-Y------</td>
 </tr>
 <tr>
  <th>Trace_Signals</th>
  <td>F Y Y Y Y Y Y - - - - -</td>
 </tr>
 <tr>
  <th>Untranslated_Transactions</th>
  <td>F Ya -Y-Y------</td>
 </tr>
 <tr>
  <th>Wakeup_Signals</th>
  <td>F Y Y Y Y Y Y - - - - -</td>
 </tr>
 <tr>
  <th>CMO_On_Read</th>
  <td>G Y Y Y - - - - - - - -</td>
 </tr>
 <tr>
  <th>CMO_On_Write</th>
  <td>G-YY--------</td>
 </tr>
 <tr>
  <th>MPAM_Support</th>
  <td>G Y Y Y Y Y - - - - - -</td>
 </tr>
 <tr>
  <th>Read_Data_Chunking</th>
  <td>G - Y Y Y Y - - - - - -</td>
 </tr>
 <tr>
  <th>Read_Interleaving_Disabled</th>
  <td>G - Y Y Y Y - - - - - -</td>
 </tr>
 <tr>
  <th>Unique_ID_Support</th>
  <td>G Y Y Y Y Y Y - - - - -</td>
 </tr>
</table>

AXI3

AXI4-Lite

AXI4

ACE-Lite

ACE

AXI5- Lite

AXI5

ACE5- LiteACP

ACE5- Lite

ACE5- LiteDVM

ACE5

Issue introduced

Appendix G3 Interface Property Summary

### Table G3-1 Summary of interface properties (continued)

### Property

<table>
 <tr>
  <th>ADDR_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Consistent_DECERR</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <th>DATA_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>DVM_Message_Support</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <th>DVM_v8.4</th>
  <td>H</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>Exclusive_Accesses</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <th>ID_R_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>ID_W_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>LOOP_R_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>LOOP_W_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Max_Transaction_Bytes</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
 </tr>
 <tr>
  <th>MTE_Support</th>
  <td>H</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>Prefetch_Transaction</th>
  <td>H</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>Regular_Transactions_Only</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
 </tr>
 <tr>
  <th>Shareable_Transactions</th>
  <td>H</td>
  <td>Y</td>
  <td>Y</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
 </tr>
 <tr>
  <th>SID_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>SSID_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>USER_DATA_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>USER_REQ_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>USER_RESP_WIDTH</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>Write_Plus_CMO</th>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <th>WriteZero_Transaction</th>
  <td>H</td>
  <td>-</td>
  <td>Y</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
  <td>-</td>
 </tr>
</table>

a. v2 option is not supported on ACE5 interfaces.

AXI3

AXI4-Lite

AXI4

ACE-Lite

ACE

AXI5- Lite

AXI5

ACE5- LiteACP

ACE5- Lite

ACE5- LiteDVM

ACE5

Issue introduced

Appendix G3 Interface Property Summary

## Appendix G4

### Summary of AxSNOOP encodings

This appendix shows all possible ARSNOOP and AWSNOOP encodings and the property that is used to determine
if a particular value is supported for a given interface. It contains the following sections:

- ARSNOOP encodings on page G4-476

- AWSNOOP encodings on page G4-477

Encodings for ACSNOOP can be found in Table D3-19 on page D3-193.

Appendix G4 Summary of AxSNOOP encodings

### G4.1 ARSNOOP encodings

Table G4-1 shows the properties and interface types that are supported for all possible ARSNOOP encodings.

### Table G4-1 Summary of ARSNOOP encodings

<table>
 <tr>
  <th>Cache Cache<br/>Code Transaction type Domain optionsa Property Regular transaction line sized or line<br/>smaller</th>
 </tr>
 <tr>
  <th>0b0000 ReadNoSnoop NSH, SY -</th>
 </tr>
 <tr>
  <th>ReadOnce ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b0001 ReadShared ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b0010 ReadClean ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b0011 ReadNotSharedDirty ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b0100 ReadOnceCleanInvalid ISH, OSH Shareable_Transactions,<br/>DeAllocation_Transactions</th>
 </tr>
 <tr>
  <th>0b0101 ReadOnceMakeInvalid ISH, OSH Shareable_Transactions,<br/>DeAllocation_Transactions</th>
 </tr>
 <tr>
  <th>0b0110 Reserved - -</th>
 </tr>
 <tr>
  <th>0b0111 ReadUnique ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b1000 CleanShared NSH, CMO_On_Read<br/>ISH, OSH</th>
 </tr>
 <tr>
  <th>0b1001 CleanInvalid NSH, CMO_On_Read<br/>ISH, OSH</th>
 </tr>
 <tr>
  <th>0b1010 CleanSharedPersist NSH, CMO_On_Read,<br/>ISH, OSH Persist_CMO</th>
 </tr>
 <tr>
  <th>0b1011 CleanUnique ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b1100 MakeUnique ISH, OSH Shareable_Transactions</th>
 </tr>
 <tr>
  <th>0b1101 MakeInvalid NSH, CMO_On_Read<br/>ISH, OSH</th>
 </tr>
 <tr>
  <th>0b1110 DVM Complete ISH, OSH DVM_Message_Support</th>
 </tr>
 <tr>
  <th>0b1111 DVM Message ISH, OSH DVM_Message_Support</th>
 </tr>
</table>

---YYYYYY

---YYYY--

YY-Y-----

YY-Y-----

YY-Y-----

--Y-YY---

--Y-YY---

-

YY-Y-----

YY-YYY---

YY-YYY---

YY-YYY---

YY-Y-----

YY-Y-----

YY-YYY---

---YY----

---YY----

a. NSH is Non-shareable, ISH is Inner Shareable, OSH is Outer Shareable, SY is System Shareable

AXI5-Lite

AXI5

ACE5-LiteACP

ACE5-Lite

ACE5-LiteDVM

ACE5

Appendix G4 Summary of AxSNOOP encodings

### G4.2 AWSNOOP encodings

Table G4-2 shows the properties and interface types that are supported for all possible AWSNOOP encodings.

### Table G4-2 Summary of AWSNOOP encodings

<table>
 <tr>
  <th>Cache Cache<br/>Code Transaction type Domain optionsa Property Regular transaction line sized or line<br/>smaller</th>
  <td>ACE5 ACE5-LiteDVM ACE5-Lite ACE5-LiteACP AXI5 AXI5-Lite</td>
 </tr>
 <tr>
  <th>0b0000 WriteNoSnoop NSH, SY -<br/>WriteUniquePtl ISH, OSH Shareable_Transactions<br/>Atomic Transactions NSH, Atomic_Transactions<br/>ISH,<br/>OSH, SY</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0001 WriteUniqueFull ISH, OSH Shareable_Transactions</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0010 WriteClean NSH, -<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0011 WriteBack NSH, -<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0100 Evict ISH, OSH Shareable_Transactions</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0101 WriteEvict NSH, WriteEvict_Transaction<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0110 CMO NSH, CMO_On_Write<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b0111 WriteZero NSH, WriteZero_Transaction Y Y -<br/>ISH,<br/>OSH, SY</th>
  <td>- Y Y - - -</td>
 </tr>
 <tr>
  <th>0b1000 WriteUniquePtlStash ISH, OSH Shareable_Transactions,<br/>Cache_Stash_Transactions</th>
  <td></td>
 </tr>
 <tr>
  <th>0b1001 WriteUniqueFullStash ISH, OSH Shareable_Transactions,<br/>Cache_Stash_Transactions</th>
  <td></td>
 </tr>
 <tr>
  <th>0b1010 WritePtlCMO NSH, Write_Plus_CMO<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b1011 WriteFullCMO NSH, Write_Plus_CMO<br/>ISH, OSH</th>
  <td></td>
 </tr>
 <tr>
  <th>0b1100 StashOnceShared NSH, Cache_Stash_Transactions Y Y -<br/>ISH, OSH</th>
  <td>- Y Y Y - -</td>
 </tr>
</table>

Appendix G4 Summary of AxSNOOP encodings

### Table G4-2 Summary of AWSNOOP encodings (continued)

<table>
 <tr>
  <th>Cache Cache<br/>Code Transaction type Domain optionsa Property Regular transaction line sized or line<br/>smaller</th>
  <td>ACE5 ACE5-LiteDVM ACE5-Lite ACE5-LiteACP AXI5 AXI5-Lite</td>
 </tr>
 <tr>
  <th>0b1101 StashOnceUnique NSH, Cache_Stash_Transactions Y Y -<br/>ISH, OSH</th>
  <td>- Y Y Y - -</td>
 </tr>
 <tr>
  <th>0b1110 StashTranslation NSH, Untranslated_Transactions,<br/>ISH, Cache_Stash_Transactions<br/>OSH, SY</th>
  <td></td>
 </tr>
 <tr>
  <th>0b1111 Prefetch NSH, Prefetch_Transaction Y Y -<br/>ISH, OSH</th>
  <td>- Y Y - - -</td>
 </tr>
</table>

a. NSH is Non-shareable, ISH is Inner Shareable, OSH is Outer Shareable, SY is System Shareable

## Appendix G5

### Summary of ID constraints

The following restrictions on ID usage are specified in this document; they are summarized here for reference.

Appendix G5 Summary of ID constraints

### G5.1 ID constraints

Must not use the same ID for in-flight transactions:

- Barrier and non-barrier transactions

- DVM transactions and non-DVM transactions

- Atomic and Non-atomic transactions

- Multiple Atomic transactions

- StashOnce and non-StashOnce transactions

- StashTranslation and non-StashTranslation transactions

- Prefetch transactions

- WriteZero transactions

- Read transactions with data chunking enabled
- Transactions which transport MTE tags

It is recommended that the following transactions use an ID that is unique in-flight:

- WriteBack

- WriteClean

- WriteEvict

- Evict

Must use the same ID:

- Transactions in an exclusive access pair

- Transactions in a locked sequence (AXI3 only)

- Transactions in a barrier pair (ACE and ACE-Lite only)

## Appendix G6

### Summary of response codes

This appendix contains a summary of read and write response codes:

- Read response codes on page G6-482

- Write response codes on page G6-483
- Write response combinations on page G6-484

Appendix G6 Summary of response codes

### G6.1 Read response codes

For interfaces where the Untranslated_Transactions property is v2 or the Prefetch_Transaction property is True,
RRESP is extended from 2-bits to 3-bits to enable the signaling of additional responses.

The full list of possible read response encodings is shown in Table G6-1.

### Table G6-1 Read responses

<table>
 <tr>
  <th>RRESP[2:0]</th>
  <th>Response</th>
  <th>Indication</th>
 </tr>
 <tr>
  <td rowspan="2">0b000</td>
  <td rowspan="2">OKAY</td>
  <td>Transaction has completed successfully.<br/>Read data is valid. Read tags are valid if they were requested.</td>
 </tr>
 <tr>
  <td>Exclusive read to a Subordinate which does not support exclusive<br/>accesses.</td>
 </tr>
 <tr>
  <td>0b001</td>
  <td>EXOKAY</td>
  <td>Exclusive read succeeded.</td>
 </tr>
 <tr>
  <td>0b010</td>
  <td>SLVERR</td>
  <td>Subordinate error. The access has reached the Subordinate<br/>successfully, but the Subordinate wishes to return an error condition<br/>to the originating Manager.</td>
 </tr>
 <tr>
  <td>0b011</td>
  <td>DECERR</td>
  <td>Decode error. Generated, typically by an interconnect component, to<br/>indicate that there is no Subordinate at the transaction address.</td>
 </tr>
 <tr>
  <td>0b100</td>
  <td>PREFETCHED</td>
  <td>Read data is valid and has been sourced from a prefetched value.</td>
 </tr>
 <tr>
  <td>0b101</td>
  <td>TRANSFAULT</td>
  <td>Transaction was terminated because of a translation fault which<br/>might be resolved by a PRI request. Read data is not valid.</td>
 </tr>
 <tr>
  <td>0b110</td>
  <td>Reserved</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b111</td>
  <td>Reserved</td>
  <td>-</td>
 </tr>
</table>

Appendix G6 Summary of response codes

### G6.2 Write response codes

For interfaces where the Untranslated_Transactions property is v2, BRESP is extended from 2-bits to 3-bits to
enable the signaling of a TRANSFAULT response. The full list of possible write response encodings is shown in
Table G6-2.

### Table G6-2 Write responses

<table>
 <tr>
  <th>BRESP[2:0]</th>
  <th>Response</th>
  <th>Indication</th>
 </tr>
 <tr>
  <td rowspan="2">0b000</td>
  <td rowspan="2">OKAY</td>
  <td>Non-exclusive access: write data can be seen by all observers.</td>
 </tr>
 <tr>
  <td>Exclusive access: write failed to update the location.</td>
 </tr>
 <tr>
  <td>0b001</td>
  <td>EXOKAY</td>
  <td>Exclusive write succeeded.</td>
 </tr>
 <tr>
  <td>0b010</td>
  <td>SLVERR</td>
  <td>Subordinate error. The access has reached the Subordinate<br/>successfully, but the Subordinate wishes to return an error condition<br/>to the originating Manager.</td>
 </tr>
 <tr>
  <td>0b011</td>
  <td>DECERR</td>
  <td>Decode error. Generated, typically by an interconnect component, to<br/>indicate that there is no Subordinate at the transaction address.</td>
 </tr>
 <tr>
  <td>0b100</td>
  <td>Reserved</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b101</td>
  <td>TRANSFAULT</td>
  <td>Transaction was terminated because of a translation fault which<br/>might be resolved by a PRI request.</td>
 </tr>
 <tr>
  <td>0b110</td>
  <td>Reserved</td>
  <td>-</td>
 </tr>
 <tr>
  <td>0b111</td>
  <td>Reserved</td>
  <td>-</td>
 </tr>
</table>

Appendix G6 Summary of response codes

### G6.3 Write response combinations

Table G6-2 on page G6-483 shows the legal write response combinations for interfaces which include the BCOMP
signal. Transaction types in Table G6-2 on page G6-483 are defined as:

- Tag Match is any transaction where AWTAGOP is 0b11 (Match).
- Persist is any transaction where AWCMO is 0b10 (CSP) or 0b11 (CSDP).

### Table G6-3 Write response combinations

<table>
 <tr>
  <th>OKAY</th>
  <th></th>
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
  <td>Not Persist, 1 00b00<br/>not Tag Match</td>
  <td>beat r esponse.</td>
 </tr>
 <tr>
  <td>Persist 0 1 0b00 Y -</td>
  <td>Y Y - Persist response.</td>
 </tr>
 <tr>
  <td></td>
  <td>Part of 2-part response.</td>
 </tr>
 <tr>
  <td>1 00b00 Y -</td>
  <td>Y Y - Completion response.</td>
 </tr>
 <tr>
  <td></td>
  <td>Part of 2-part response.</td>
 </tr>
 <tr>
  <td>1 10b00 Y -</td>
  <td>Y Y Y Combined response.</td>
 </tr>
 <tr>
  <td></td>
  <td>Single beat response.</td>
 </tr>
 <tr>
  <td>Tag Match 1 0 0b01</td>
  <td>response.<br/>Part of 2-part response.</td>
 </tr>
 <tr>
  <td>0 00b10 / Y -</td>
  <td>Y Y - Match response.</td>
 </tr>
 <tr>
  <td>0b11</td>
  <td>Part of 2-part response.</td>
 </tr>
 <tr>
  <td>1 00b10 /<br/>0b11</td>
  <td>response.<br/>Single beat response.</td>
 </tr>
</table>

## Appendix G7

### Revisions

Appendix G7 Revisions

This appendix describes the technical changes between released issues of this specification.

Table G7-1 Issue B

<table>
 <tr>
  <th>Change Location</th>
 </tr>
 <tr>
  <td>First release of Version 1.0 -</td>
 </tr>
</table>

| Change | Location |
| --- | --- |
| Additional section describing the chapter layout of Version 2.0 of | document AXI revisions on page A1-21 |
| Additional details on the constraints for the VALID and READY | Handshake process on page 3-2 |
| Additional equation for wrapping bursts | Burst address on page 4-7 |
| Additional chapter describing the AXI4 update to the AXI3 | Chapter 13 AXI4 |
| Additional chapter describing the AXI4-Lite subset of the AXI4 | Chapter 14 AXI4-Lite |
| Table G7-3 | between issue C and issue D |
| Change Location |  |
| Full integration of the AXI3 and AXI4 content Part A AXI3 and | Protocol Specification |
| Additional Part added describing the ACE update Part C AXI to the AXI protocol | Extensions (ACE) Protocol Specification |
| Table G7-4 | Differences between issue D and issue E |
| Change | Location |
| Clarification of the byte lane strobes' requirement for FIXED bursts | Burst type in Address structure on |
|  | page A3-48 |
| Correction to pseudo code routine: //Increment address if necessary | Pseudocode description of the |
|  | transfers on page A3-52 |
| Additional section describing the Ordered_Write_Observation | Ordered write observation on page A6-91 |
| Additional section describing the Multi_Copy_Atomocity property | Multi-copy write atomicity on |
|  | page A7-95 |
| Clarification of the Peripheral Subordinate transaction subset | Memory Subordinates and Peripheral |
|  | Subordinates on page A9-109 |
| Additional section describing the AWUNIQUE signal | AWUNIQUE signal on page D3-181 |
| Clarification of WriteUnique Propagation to Main Memory | WriteUnique on page D4-223 and |
|  | WriteLineUnique on page D4-223 |
| Additional section describing the WriteEvict transaction | WriteEvict on page D4-225 |

Table G7-2 Differences between issue B and issue C

Appendix G7 Revisions

Table G7-4 Differences between issue D and issue E (continued)

### Change

Clarification of WriteNoSnoop blocked by WriteUnique and
WriteLineUnique

<table>
 <tr>
  <th>Clarification of sequencing Coherent and Cache Maintenance transactions to</th>
  <td>Sequencing transactions on</td>
 </tr>
 <tr>
  <th>a cache line</th>
  <td>page D6-249</td>
 </tr>
 <tr>
  <th>Additional section describing the Continuous_Cache_Line_Read_Data</th>
  <td>Continuous read data return on</td>
 </tr>
 <tr>
  <th>property</th>
  <td>page D6-250</td>
 </tr>
</table>

Clarification of Exclusive Accesses and naturally evicted cache lines

Clarification of the Shareable terminology in Exclusive Accesses

Additional section describing optional DVM message support for Armv8

Additional section describing DVMv7 and DVMv8 address spaces

Additional format definitions for DVMv8 messages

Additional format definitions for the TLB Invalidate message to support
DVMv8

Additional section describing DVMv7 and DVMv8 conversion

Additional chapter providing a set of recommendations for the design of
Manager components

Additional appendix describing full cache line and partial cache line write
transaction naming

Additional appendix describing the ACP interface requirements

### Location

Restrictions on WriteUnique and
WriteLineUnique usage on
page D4-226

Exclusive Store on page D9-298

About Exclusive accesses from ACE
Managers on page D9-296 and
Transaction requirements on
page D9-304

DVM message versions on
page D13-323

Addresses in DVM messages on
page D13-324

Addresses in DVM messages on
page D13-324

TLB Invalidate on page D13-330

DVM message versions on
page D13-323

Chapter D14 Manager Design
Recommendations

Appendix G1 Transaction Naming

Appendix F4 Accelerator Coherency
Port Interface Restrictions

### Table G7-5 Differences between issue E and issue F

### Change

Removed Low Power Interface chapter, this content has been superseded by
a separate specification (ARM IHI 0068C)

New interfaces defined: AXI5, AXI5-Lite

Rule that a snoop response must give IsShared asserted while a Write is in
progress with AWUNIQUE asserted is clarified to only apply to WriteBack
and WriteEvict

Clarification that a line might become dirty when a CleanShared is in
progress

### Location

Was Chapter A9

Part C AMBA AXI5 and AXI5-Lite
Interface Specification

AWUNIQUE signal on page D3-181

CleanShared on page D4-218

Appendix G7 Revisions

### Table G7-5 Differences between issue E and issue F (continued)

| Change | Location |
| --- | --- |
| Change which adds restrictions when using Evict transactions with | Restrictions on WriteUnique and |
| WriteUnique and WriteLineUnique | WriteLineUnique usage on |
|  | page D4-226 |
| Added a missing row to the table of Alternative Snoop Transactions to MakeInvalid | Table D5-2 on page D5-233 |
| Change to allow an Evict and WriteEvict to be issued while a CleanShared in progress | Cache maintenance propagation on page D7-270 |
| Change to the mismatched shareability and cacheability rules to allow for | Chapter D7 Cache Maintenance |
| cache maintenance transactions |  |
| Clarification that a component is not permitted to wait for a DVM relating to a DVM Sync it has issued, before it provides DVM Complete a DVM Sync it has received | DVM Synchronization and DVM Complete transactions on page D13-320 |
| Clarification that an ACE/ACE-Lite Manager is permitted to wait for both | DVM message transactions on |
| parts of a 2-part DVM message before responding on CR channel | page D13-319 |
| New interfaces and features defined: ACE5, ACE5-Lite, ACE5-LiteDVM, | Part E AMBA 5 Protocol Features |
| ACE5-LiteACP |  |
| Deprecation of Inner Shareable domain for AMBA5 interfaces | Shareability domain support on |
|  | page F5-452 |
| Deprecation of Barrier transaction support for AMBA5 interfaces | Barrier transaction support on |
|  | page F5-453 |
| Removed Accelerator Coherency Port Interface Restrictions appendix, this | Was Appendix B |
| content has been superseded by ACE5-LiteACP |  |

<table>
 <tr>
  <th>Change</th>
  <th>Location</th>
 </tr>
 <tr>
  <td>Clarified that an EXOKAY response can only be given for exclusive</td>
  <td>Read and write response</td>
 </tr>
 <tr>
  <td>accesses.</td>
  <td>structure on page A3-59</td>
 </tr>
 <tr>
  <td>Rewrite of AXI ordering chapter to improve clarity.</td>
  <td>Chapter A6 AXI Ordering</td>
 </tr>
 <tr>
  <td></td>
  <td>Model</td>
 </tr>
 <tr>
  <td>Change that Multi_Copy_Atomicity property must be True for</td>
  <td>Multi-copy write atomicity on</td>
 </tr>
 <tr>
  <td>interfaces compliant with Issue G and later.</td>
  <td>page A7-95</td>
 </tr>
 <tr>
  <td>Clarification of permitted responses to exclusive accesses.</td>
  <td>Responses to exclusive access</td>
 </tr>
 <tr>
  <td></td>
  <td>on page A7-98</td>
 </tr>
 <tr>
  <td>Removed table D3-10 as it does not add value to the text.</td>
  <td>Cache line size restrictions on</td>
 </tr>
 <tr>
  <td></td>
  <td>page D3-182</td>
 </tr>
 <tr>
  <td>Rewrite of chapter on Cache Maintenance Operations, adding Clean<br/>Deep Persistence and option for CMOs on write channels.</td>
  <td>Chapter D7 Cache<br/>Maintenance</td>
 </tr>
 <tr>
  <td>Clarification of rules for Atomic transactions.</td>
  <td>Atomic transactions attributes</td>
 </tr>
 <tr>
  <td></td>
  <td>on page E1-343</td>
 </tr>
 <tr>
  <td>Clarification that WriteUniqueStash and StashOnce transactions<br/>not cross a cache line boundary.</td>
  <td>Stash transaction signaling on<br/>page E1-352</td>
 </tr>
 <tr>
  <td>Change that Stash transactions are permitted to be Inner Shareable.</td>
  <td>Stash transaction signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-352</td>
 </tr>
 <tr>
  <td>Change that Deallocating transactions are permitted to be Inner</td>
  <td>Deallocating transaction</td>
 </tr>
 <tr>
  <td>Shareable.</td>
  <td>signaling on page E1-356</td>
 </tr>
 <tr>
  <td>Clarified that for Atomic transactions with a read response,<br/>should be asserted if AWTRACE is asserted.</td>
  <td>Trace signals on page E1-357</td>
 </tr>
 <tr>
  <td>Clarified that for Atomic transactions with a read response, RLOOP</td>
  <td>User Loopback signaling on</td>
 </tr>
 <tr>
  <td>must be identical to AWLOOP.</td>
  <td>page E1-359</td>
 </tr>
 <tr>
  <td>Clarified rules for AWAKEUP assertion.</td>
  <td>Wake-up Signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-362</td>
 </tr>
 <tr>
  <td>Clarified that SYSCOREQ and SYSCOACK are synchronous</td>
  <td>Untranslated transactions on<br/>page E1-369</td>
 </tr>
 <tr>
  <td>Change that the Untranslated_Transactions property must not be<br/>for ACE5-LiteDVM interfaces.</td>
  <td>Untranslated transactions on<br/>page E1-369</td>
 </tr>
 <tr>
  <td>Added section on read data chunking.</td>
  <td>Read data chunking on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-378</td>
 </tr>
 <tr>
  <td>Added section on the read interleaving property.</td>
  <td>Read interleaving property on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-382</td>
 </tr>
 <tr>
  <td>Added section on unique ID indication.</td>
  <td>Unique ID indicator on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-383</td>
 </tr>
 <tr>
  <td>Added section on MPAM support.</td>
  <td>Memory Partitioning and</td>
 </tr>
 <tr>
  <td></td>
  <td>Monitoring (MPAM) on</td>
 </tr>
 <tr>
  <td></td>
  <td>page E1-385</td>
 </tr>
</table>

Appendix G7 Revisions

### Table G7-6 Differences between issue F and issue G

Appendix G7 Revisions

Table G7-6 Differences between issue F and issue G (continued)

<table>
 <tr>
  <th>Change</th>
  <th>Location</th>
 </tr>
 <tr>
  <td>Added support for interface parity, combined with<br/>data parity and poison.</td>
  <td>section on Chapter E2 Interface and data<br/>protection</td>
 </tr>
 <tr>
  <td>Change that AWSNOOP is extended to 4 bits for<br/>ACE5-LiteDVM and ACE5-LiteACP interfaces,<br/>property settings.</td>
  <td>AWSNOOP signal width on<br/>of page F5-454</td>
 </tr>
 <tr>
  <td>Updated signal matrix with new signals.</td>
  <td>Signal matrix on page G2-460</td>
 </tr>
 <tr>
  <td>Change that ARVMIDEXT is optional for interfaces<br/>DVM_v8.1 property set, where the Manager can receive</td>
  <td>the Signal matrix on page G2-460<br/>but not issue</td>
 </tr>
 <tr>
  <td>DVM messages.</td>
  <td></td>
 </tr>
 <tr>
  <td>Updated property table with new properties.</td>
  <td>Summary of interface</td>
 </tr>
 <tr>
  <td></td>
  <td>properties on page G3-472</td>
 </tr>
 <tr>
  <td>Updated tables showing AxSNOOP encodings.</td>
  <td>Appendix G4 Summary of</td>
 </tr>
 <tr>
  <td></td>
  <td>AxSNOOP encodings</td>
 </tr>
 <tr>
  <td>Added summary of ID constraints.</td>
  <td>Appendix G5 Summary of ID</td>
 </tr>
 <tr>
  <td></td>
  <td>constraints</td>
 </tr>
 <tr>
  <td>Added interface property timeline.</td>
  <td>Summary of interface</td>
 </tr>
 <tr>
  <td></td>
  <td>properties on page G3-472</td>
 </tr>
 <tr>
  <td>Table</td>
  <td>Differences between issue G and issue H</td>
 </tr>
 <tr>
  <td>Change</td>
  <td>Location</td>
 </tr>
 <tr>
  <td>Clarified rules regarding inter-transaction dependencies</td>
  <td>a Manager. Relationships between the<br/>channels on page A3-44</td>
 </tr>
 <tr>
  <td>Added recommendation that WDATA and RDATA are<br/>byte lanes.</td>
  <td>for inactive Channel signaling<br/>requirements on page A3-42</td>
 </tr>
 <tr>
  <td>Added section on Regular Transactions</td>
  <td>Regular transactions on</td>
 </tr>
 <tr>
  <td></td>
  <td>page A3-53</td>
 </tr>
 <tr>
  <td>Updated section on User Defined Signaling</td>
  <td>User-defined signaling on</td>
 </tr>
 <tr>
  <td></td>
  <td>page A8-104</td>
 </tr>
 <tr>
  <td>Consolidated all CMO content into a single chapter</td>
  <td>Chapter D7 Cache</td>
 </tr>
 <tr>
  <td></td>
  <td>Maintenance</td>
 </tr>
 <tr>
  <td>Added Write with CMO transaction</td>
  <td>Write with cache maintenance</td>
 </tr>
 <tr>
  <td></td>
  <td>on page D7-277</td>
 </tr>
 <tr>
  <td>Rewrite of DVM message chapter</td>
  <td>Chapter D13 Distributed</td>
 </tr>
 <tr>
  <td></td>
  <td>Virtual Memory Transactions</td>
 </tr>
 <tr>
  <td>Added support for DVM v8.4 messages</td>
  <td>DVM message versions on</td>
 </tr>
 <tr>
  <td></td>
  <td>page D13-323</td>
 </tr>
 <tr>
  <td>Corrected transaction sizes for AtomicStore,<br/>AtomicSwap</td>
  <td>and Atomic transactions attributes<br/>on page E1-343</td>
 </tr>
</table>

Appendix G7 Revisions

### Table G7-7 Differences between issue G and issue H (continued)

### Change

Clarified that for an AtomicCompare transaction, a burst length of 1 is
permitted and AWADDR is not required to be aligned.

Clarified that Manager might ignore the write response to an Atomic
Transaction

Renamed width parameters for Loopback signaling

Added v2 functionality to Untranslated Transactions

Moved StashTranslation description from Cache Stashing to
Untranslated Transactions chapter

Relaxed rule for RCHUNKNUM and RCHUNKSTRB value when
RCHUNKV is deasserted

Added section on Memory Tagging

Added Prefetch request and response

Added Write zero with no data

Added new interface properties

Added new signal width properties

Added parity check signals to cover signals added in Issue H

Updated signal matrix with new signals

<table>
 <tr>
  <th>Removed erroneous signals AWIDUNQCHK and ARIDUNQCHK</th>
  <td>Check signal matrix on</td>
 </tr>
 <tr>
  <th>from check signal matrix</th>
  <td>page G2-466</td>
 </tr>
 <tr>
  <th>Updated summary of interface properties, now includes property</th>
  <td>Appendix G3 Interface</td>
 </tr>
 <tr>
  <th>timeline</th>
  <td>Property Summary</td>
 </tr>
</table>

Enhanced and updated summary of AxSNOOP encodings

Added summary of response codes

### Location

Atomic transactions attributes
on page E1-343

Response signaling on
page E1-347

User Loopback signaling on
page E1-359

SMMU flows on page E1-373

StashTranslation on
page E1-374

Read data chunking protocol
rules on page E1-378

Memory tagging on
page E1-387

Prefetch request and response
on page E1-396

Write zero with no data on
page E1-398

Additional interface
properties on page E1-399

Signal width properties on
page E1-403

Parity check signals on
page E2-411

Signal matrix on page G2-460

Appendix G4 Summary of
AxSNOOP encodings

Appendix G6 Summary of
response codes

Appendix G7 Revisions

Table G7-8 Differences between issue H and H.b

| Change | Location |
| --- | --- |
| Regularized terminology to use Manager to indicate the agent that | Throughout this specification |
| initiates transactions and Subordinate to indicate the agent that receives |  |
| and responds to requests. |  |
| Regularized terminology to caching Manager, replacing instances of | Throughout this specification |
| cached Manager. |  |
| Table G7-9 | between issue H.b and |
| Change | Location |
| Corrected error in table D13-22 for AxADDR[15], should have been | Chapter D13 Distributed |
| "Completion required" | Virtual Memory Transactions, |
|  | Table D13-22 on |
|  | page D13-334 |
