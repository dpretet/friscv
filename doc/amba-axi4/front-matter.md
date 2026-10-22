[Back to document index](./amba_axi_protocol_spec.md)

# AMBA® AXI and ACE

## Protocol Specification

Copyright © 2003-2021 Arm Limited or its affiliates. All rights reserved.
ARM IHI 0022H.c (ID012621)

### AMBA AXI and ACE Protocol Specification

## Release Information

The following changes have been made to this specification:

## Change history

| Date | Issue | Confidentiality | Change |
| --- | --- | --- | --- |
| 16 June 2003 | A | Non-Confidential | First release |
| 19 March 2004 | B | Non-Confidential | First release of AXI specification v1.0 |
| 03 March 2010 | C | Non-Confidential | First release of AXI specification v2.0 |
| 03 June 2011 | D-2c | Non-Confidential | Public beta draft of AMBA AXI and ACE Protocol Specification |
| 28 October 2011 | D | Non-Confidential | First release of AMBA AXI and ACE Protocol Specification |
| 22 February 2013 | E | Non-Confidential | Second release of AMBA AXI and ACE Protocol Specification |
| 18 December 2017 | F | Non-Confidential | EAC-0 release of version F. |
|  |  |  | New interfaces defined for AMBA protocol: AXI5, AXI5-Lite, |
|  |  |  | ACE5, ACE5-Lite, ACE5-LiteDVM, ACE5-LiteACP. |
| 21 December 2017 | F.b | Non-Confidential | EAC-1 release to address issues found with the EAC-0 release of |
|  |  |  | release F. |
|  |  |  | No change in content compared to the EAC-0 version. |
| 30 July 2019 | G | Non-Confidential | EAC-0 release of version G. |
|  |  |  | New optional features defined for AMBA 5 interface variants. |
| 31 March 2020 | H | Non-Confidential | EAC-0 release of version H. |
|  |  |  | New optional features defined for AMBA 5 interface variants. |
| 11 January 2021 | H.b | Non-Confidential | Regularized terminology to use Manager to indicate the agent that |
|  |  |  | initiates transactions and Subordinate to indicate the agent that |
|  |  |  | receives and responds to requests. |
| 26 January 2021 | H.c | Non-Confidential | Corrected error in table D13-22 for AxADDR[15] |

Note that issue E.a, the first publication of issue E of this specification, was originally identified as issue E.

Issues B and C of this document included an AXI specification version, v1.0 and v2.0. These version numbers have been
discontinued to remove confusion with the AXI versions AXI3 and AXI4.

Non-Confidential

### Proprietary Notice

This document is NON-CONFIDENTIAL and any use by you is subject to the terms of this notice and the Arm AMBA
Specification Licence set about below.

This document is protected by copyright and other related rights and the practice or implementation of the information contained
in this document may be protected by one or more patents or pending patent applications. No part of this document may be
reproduced in any form by any means without the express prior written permission of Arm. No license, express or implied, by
estoppel or otherwise to any intellectual property rights is granted by this document unless specifically stated.

Your access to the information in this document is conditional upon your acceptance that you will not use or permit others to use
the information for the purposes of determining whether implementations infringe any third party patents.

THIS DOCUMENT IS PROVIDED "AS IS". ARM PROVIDES NO REPRESENTATIONS AND NO WARRANTIES,
EXPRESS, IMPLIED OR STATUTORY, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY, SATISFACTORY QUALITY, NON-INFRINGEMENT OR FITNESS FOR A PARTICULAR
PURPOSE WITH RESPECT TO THE DOCUMENT. For the avoidance of doubt, Arm makes no representation with respect to,
and has undertaken no analysis to identify or understand the scope and content of, patents, copyrights, trade secrets, or other rights.

This document may include technical inaccuracies or typographical errors.

TO THE EXTENT NOT PROHIBITED BY LAW, IN NO EVENT WILL ARM BE LIABLE FOR ANY DAMAGES,
INCLUDING WITHOUT LIMITATION ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, PUNITIVE, OR
CONSEQUENTIAL DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, ARISING
OUT OF ANY USE OF THIS DOCUMENT, EVEN IF ARM HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

This document consists solely of commercial items. You shall be responsible for ensuring that any use, duplication or disclosure
of this document complies fully with any relevant export laws and regulations to assure that this document or any portion thereof
is not exported, directly or indirectly, in violation of such export laws. Use of the word "partner" in reference to Arm's customers
is not intended to create or refer to any partnership relationship with any other company. Arm may make changes to this document
at any time and without notice.

This document may be translated into other languages for convenience, and you agree that if there is any conflict between the
English version of this document and any translation, the terms of the English version of the Agreement shall prevail.

The Arm corporate logo and words marked with ® or ™ are registered trademarks or trademarks of Arm Limited (or its
subsidiaries) in the US and/or elsewhere. All rights reserved. Other brands and names mentioned in this document may be the
trademarks of their respective owners. Please follow Arm's trademark usage guidelines at
http://www.arm.com/company/policies/trademarks.

Copyright © [2020] Arm Limited (or its affiliates). All rights reserved.

Arm Limited. Company 02557590 registered in England.
110 Fulbourn Road, Cambridge, England CB1 9NJ.
LES-PRE-21451 version 2.2

## AMBA SPECIFICATION LICENCE

"LICENSEE" means You and your Subsidiaries.

THIS END USER LICENCE AGREEMENT ("LICENCE") IS A LEGAL AGREEMENT BETWEEN YOU (EITHER A
SINGLE INDIVIDUAL, OR SINGLE LEGAL ENTITY) AND ARM LIMITED ("ARM") FOR THE USE OF ARM'S
INTELLECTUAL PROPERTY (INCLUDING, WITHOUT LIMITATION, ANY COPYRIGHT) IN THE RELEVANT AMBA
SPECIFICATION ACCOMPANYING THIS LICENCE. ARM LICENSES THE RELEVANT AMBA SPECIFICATION TO
YOU ON CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY CLICKING "I AGREE" OR
OTHERWISE USING OR COPYING THE RELEVANT AMBA SPECIFICATION YOU INDICATE THAT YOU AGREE TO
BE BOUND BY ALL THE TERMS OF THIS LICENCE.

"Subsidiary" means, if You are a single entity, any company the majority of whose voting shares is now or hereafter owned or
controlled, directly or indirectly, by You. A company shall be a Subsidiary only for the period during which such control exists.

1. Subject to the provisions of Clauses 2, 3 and 4, Arm hereby grants to LICENSEE a perpetual, non-exclusive, non-transferable, royalty free, worldwide licence to:

(i) use and copy the relevant AMBA Specification for the purpose of developing and having developed products
that comply with the relevant AMBA Specification;

1. manufacture and have manufactured products which either: (a) have been created by or for LICENSEE under the licence granted in Clause 1(i); or (b) incorporate a product(s) which has been created by a third party(s) under a licence granted by Arm in Clause 1(i) of such third party's AMBA Specification Licence; and

2. offer to sell, sell, supply or otherwise distribute products which have either been (a) created by or for LICENSEE under the licence granted in Clause 1(i); or (b) manufactured by or for LICENSEE under the licence granted in Clause 1(ii).

2. LICENSEE hereby agrees that the licence granted in Clause 1 is subject to the following restrictions:
(i) where a product created under Clause 1(i) is an integrated circuit which includes a CPU then either: (a) such
CPU shall only be manufactured under licence from Arm; or (b) such CPU is neither substantially compliant
with nor marketed as being compliant with the Arm instruction sets licensed by Arm from time to time;

1. the licences granted in Clause 1(iii) shall not extend to any portion or function of a product that is not itself compliant with part of the relevant AMBA Specification; and

2. no right is granted to LICENSEE to sublicense the rights granted to LICENSEE under this Agreement.

3. Except as specifically licensed in accordance with Clause 1, LICENSEE acquires no right, title or interest in any Arm
technology or any intellectual property embodied therein. In no event shall the licences granted in accordance with Clause
1 be construed as granting LICENSEE, expressly or by implication, estoppel or otherwise, a licence to use any Arm
technology except the relevant AMBA Specification.

1. THE RELEVANT AMBA SPECIFICATION IS PROVIDED "AS IS" WITH NO REPRESENTATION OR WARRANTIES EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF SATISFACTORY QUALITY, MERCHANTABILITY, NON-INFRINGEMENT OR FITNESS FOR A PARTICULAR PURPOSE, OR THAT ANY USE OR IMPLEMENTATION OF SUCH ARM TECHNOLOGY WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADE SECRETS OR OTHER INTELLECTUAL PROPERTY RIGHTS.

2. NOTWITHSTANDING ANYTHING TO THE CONTRARY CONTAINED IN THIS AGREEMENT, TO THE FULLEST EXTENT PETMITTED BY LAW, THE MAXIMUM LIABILITY OF ARM IN AGGREGATE FOR ALL CLAIMS MADE AGAINST ARM, IN CONTRACT, TORT OR OTHERWISE, IN CONNECTION WITH THE SUBJECT MATTER OF THIS AGREEMENT (INCLUDING WITHOUT LIMITATION (I) LICENSEE'S USE OF THE ARM TECHNOLOGY; AND (II) THE IMPLEMENTATION OF THE ARM TECHNOLOGY IN ANY PRODUCT CREATED BY LICENSEE UNDER THIS AGREEMENT) SHALL NOT EXCEED THE FEES PAID (IF ANY) BY LICENSEE TO ARM UNDER THIS AGREEMENT. THE EXISTENCE OF MORE THAN ONE CLAIM OR SUIT WILL NOT ENLARGE OR EXTEND THE LIMIT. LICENSEE RELEASES ARM FROM ALL OBLIGATIONS, LIABILITY, CLAIMS OR DEMANDS IN EXCESS OF THIS LIMITATION.

3. No licence, express, implied or otherwise, is granted to LICENSEE, under the provisions of Clause 1, to use the Arm tradename, or AMBA trademark in connection with the relevant AMBA Specification or any products based thereon. Nothing in Clause 1 shall be construed as authority for LICENSEE to make any representations on behalf of Arm in respect of the relevant AMBA Specification.

4. This Licence shall remain in force until terminated by you or by Arm. Without prejudice to any of its other rights if LICENSEE is in breach of any of the terms and conditions of this Licence then Arm may terminate this Licence immediately upon giving written notice to You. You may terminate this Licence at any time. Upon expiry or termination

of this Licence by You or by Arm LICENSEE shall stop using the relevant AMBA Specification and destroy all copies of
the relevant AMBA Specification in your possession together with all documentation and related materials. Upon expiry
or termination of this Licence, the provisions of clauses 6 and 7 shall survive.

8. The validity, construction and performance of this Agreement shall be governed by English Law.

### Confidentiality Status

This document is Non-Confidential. The right to use, copy and disclose this document may be subject to license restrictions in
accordance with the terms of the agreement entered into by ARM and the party that ARM delivered this document to.

## Product Status

The information in this document is final, that is for a developed product.

## Web Address

http://www.arm.com

## Progressive terminology commitment

Arm values inclusive communities. Arm recognizes that we and our industry have used terms that can be offensive. Arm strives
to lead the industry and create change.

Previous issues of this document included terms that can be offensive. We have replaced these terms.

If you find offensive terms in this document, please contact terms@arm.com.

## Preface

This preface introduces the AMBA AXI and ACE Protocol Specification. It contains the following sections:

- About this specification on page xiv

- Using this specification on page xv

- Conventions on page xix

- Additional reading on page xxi

- Feedback on page xxii

## About this specification

This specification describes the AMBA protocols for AXI and ACE. Several release levels and variants are
described:

- The AMBA 3 AXI protocol release is referred to as AXI3.

- The AMBA 4 AXI protocol releases are referred to as AXI4 and AXI4-Lite.

- The AMBA 5 AXI protocol releases are referred to as AXI5 and AXI5-Lite.

- The AMBA 4 ACE protocol releases are referred to as ACE and ACE-Lite.

- The AMBA 5 ACE protocol releases are referred to as:
  - ACE5
  - ACE5-Lite
  - ACE5-LiteDVM
  - ACE5-LiteACP

Specifications for AXI3 apply to all subsequent versions, with some exceptions. AXI4 extends AXI3 and has some
protocol changes. AXI4 protocol differences are marked appropriately.

AMBA 5 introduces new features that are generally optional additions to the previous AMBA 4 specifications.
Those working with new designs are encouraged to use the AMBA 5 family of interfaces.

Early issues of this document describe earlier versions of the AMBA AXI Protocol Specification. In particular, Issue
B of the document describes the version that is now called AXI3.

Issue C adds the definition of an extended version of the protocol that is called AXI4 and a new interface,
AXI4-Lite.

Issue D integrates the definitions of AXI3 and AXI4 that were presented separately in Issue C.

Issue E adds clarifications, recommendations, and specifies new capabilities. To maintain compatibility, a property
is used to declare a new capability.

Issue F defines new AMBA 5 interfaces: ACE5, ACE5-Lite, ACE5-LiteDVM, ACE5-LiteACP, AXI5, AXI5-Lite.

Issue G and Issue H add new optional features that are defined for AMBA 5 interface variants.

## Note

Some previous issues of this document included a version number in the title. That version number does not refer
to the version of the AXI protocol.

## Intended audience

This specification is written for hardware and software engineers who want to become familiar with AMBA and
design systems and modules that are compatible with the AXI protocol.

## Using this specification

The information in this specification is organized into parts, as described in this section.
If using an AXI3 or AXI4 interface, the following sections should be read:

- Part A AMBA AXI Protocol Specification
If using an AXI4-Lite interface, the following sections should be read:
- Part A AMBA AXI Protocol Specification
- Part B AMBA AXI4-Lite Interface Specification

If using either AXI5 or AXI5-Lite interfaces, the following sections should be read:

- Part A AMBA AXI Protocol Specification
- Part C AMBA AXI5 and AXI5-Lite Interface Specification
- Part E AMBA 5 Protocol Features

ACE and ACE-Lite interfaces are an extension of AXI interfaces. If using ACE or ACE-Lite types of interface, the
following sections should be read:

- Part A AMBA AXI Protocol Specification
- Part D AMBA ACE and ACE-Lite Protocol Specification
- Part E AMBA 5 Protocol Features
- Part F AMBA ACE5, ACE5-Lite, ACE5-LiteDVM, and ACE5-LiteACPInterface Specification

Those already familiar with this specification need only read the new and changed sections of this specification.
Refer to Appendix G7 Revisions.

## Part A, AMBA AXI Protocol Specification

Part A describes the AXI architecture, protocol and signaling. This is common to all interfaces described in this
specification. AXI3 and AXI4 interfaces are fully described in this part. It contains the following chapters:

## Chapter A1 Introduction

An introduction to the AXI architecture and terminology that is used in this specification.

## Chapter A2 Signal Descriptions

A description of the signals that are used by the AXI3 and AXI4 protocols.

## Chapter A3 Single Interface Requirements

A description of the basic AXI protocol transaction requirements between a Manager and
Subordinate.

## Chapter A4 Transaction Attributes

A description of the AXI protocol and signaling that supports system topology and system level
caches.

## Chapter A5 Transaction Identifiers

A description of the AXI protocol and signaling that supports out-of-order transaction completion
and the issuing of multiple outstanding addresses.

## Chapter A6 AXI Ordering Model

A description of the AXI ordering model.

## Chapter A7 Atomic Accesses

A description of the mechanisms that support atomic accesses.

## Chapter A8 AMBA 4 Additional Signaling

A description of the additional signaling introduced in AXI4 to extend the application of the AXI
interface.

## Chapter A9 Default Signaling and Interoperability

A description of the interoperability of interfaces that use reduced AXI signal sets.

## Part B, AMBA AXI4-Lite Interface Specification

Part B describes AMBA AXI4-Lite. It contains the following chapter:

Chapter B1 AMBA AXI4-Lite
A description of AXI4-Lite that provides a simpler control register-style interface for systems that
do not require the full functionality of AXI4.

## Part C, AMBA AXI5 and AXI5-Lite Interface Specification

Part C describes the signals and features for AXI5 and AXI5-Lite interfaces. It contains the following chapters:

Chapter C1 AMBA AXI5
An overview of the new capabilities, the set of properties that specify the supported behavior, and
the AXI5 interface signaling requirements.

Chapter C2 AMBA AXI5-Lite
An overview of the new capabilities, the set of properties that specify the supported behavior, and
the AXI5-Lite interface signaling requirements.

## Part D, AMBA ACE and ACE-Lite Protocol Specification

Part D describes the ACE protocol. It contains the following chapters:

Chapter D1 About ACE
An overview of system level coherency and the architecture of the AXI Coherency Extensions
(ACE) protocol.

## Chapter D2 Signal Descriptions

A description of the additional ACE interface signals.

## Chapter D3 Channel Signaling

A description of the basic channel signaling requirements on an ACE interface.

Chapter D4 Coherency Transactions on the Read Address and Write Address Channels
A description of the transactions issued on the read address and write address channels.

## Chapter D5 Snoop Transactions

A description of the snoop transactions seen on the snoop address channel.

## Chapter D6 Interconnect Requirements

A description of the ACE interconnect requirements.

## Chapter D7 Cache Maintenance

A description of the ACE cache maintenance operations.

## Chapter D8 Barrier Transactions

A description of the ACE memory and synchronization barrier transactions.

## Chapter D9 Exclusive Accesses from ACE Managers

A description of the ACE Exclusive Accesses to Shareable memory.

## Chapter D10 Optional External Snoop Filtering

A description of using an external snoop filter in an ACE system.

## Chapter D11 AMBA ACE-Lite

A description of the ACE-Lite interface.

## Chapter D12 Interface Control

A description of the optional signals that can be used to configure the ACE interface.

## Chapter D13 Distributed Virtual Memory Transactions

A description of Distributed Virtual Memory (DVM) transactions.

## Chapter D14 Manager Design Recommendations

A set of recommendations for the design of Manager components that improve the ability to bridge
the Manager to different protocol interfaces.

## Part E AMBA 5 Protocol Features

Part E describes changes to the AMBA family of interfaces in version 5. It contains the following chapters:

## Chapter E1 Additional Features in AMBA 5

A description of the new features in AMBA 5.

## Chapter E2 Interface and data protection

Specification of schemes for the protection of data and interfaces with the addition of poison and
parity signaling.

## Part F AMBA ACE5, ACE5-Lite, ACE5-LiteDVM, and ACE5-LiteACP Interface Specification

Part F describes the ACE5 and ACE5-Lite family of interfaces. It contains the following chapters:

Chapter F1 AMBA ACE5
An overview of the new capabilities, the set of properties that specify the supported behavior, and
the ACE5 interface signaling requirements.

Chapter F2 AMBA ACE5-Lite
A description of the new capabilities in the ACE5-Lite protocol specification.

## Chapter F3 AMBA ACE5-LiteDVM

A description of the new ACE5-LiteDVM protocol specification introduced in AMBA 5.

Chapter F4 ACE5-LiteACP
A description of the ACE5-LiteACP protocol specification introduced in AMBA 5.

## Chapter F5 Changes in ACE5 and ACE5-Lite

A description of the changes in AMBA 5 to the ACE and ACE-Lite channel signaling requirements.

## Part G Appendices

This specification contains the following appendices:

## Appendix G1 Transaction Naming

This appendix defines the naming scheme for full cache line and partial cache line write
transactions.

Appendix G2 Signal Lists
This appendix defines the required and optional signals for each of the AMBA 5 interfaces.

## Appendix G3 Interface Property Summary

This appendix defines properties of the AMBA 5 interfaces and when each interface property was
introduced into this specification.

## Appendix G4 Summary of AxSNOOP encodings

This appendix shows all possible AxSNOOP encodings and the property that is used to determine
if a particular value is supported for a given interface.

## Appendix G5 Summary of ID constraints

This appendix lists the restrictions on ID usage that are specified in this document.

## Appendix G6 Summary of response codes

This appendix contains a summary of read and write response codes.

## Appendix G7 Revisions

This appendix describes the technical changes between released issues of this specification.

## Conventions

The following sections describe conventions that this specification can use:

- Typographic conventions

- Timing diagrams

- Signals on page xx
- Numbers on page xx

## Typographic conventions

The typographical conventions are:

## italic

bold

Highlights important notes, introduces special terminology, and denotes internal
cross-references and citations.

Denotes signal names, and is used for terms in descriptive lists, where appropriate.

monospace

## SMALL CAPITALS

Used for assembler syntax descriptions, pseudocode, and source code examples.
Also used in the main text for instruction mnemonics and for references to other items
appearing in assembler syntax descriptions, pseudocode, and source code examples.

Used for a few terms that have specific technical meanings.

## Timing diagrams

The figure named Key to timing diagram conventions explains the components used in timing diagrams. Variations,
when they occur, have clear labels. You must not assume any timing information that is not explicit in the diagrams.

Shaded bus and signal areas are undefined, so the bus or signal can assume any value within the shaded area at that
time. The actual level is unimportant and does not affect normal operation.

Clock

HIGH to LOW

Transient

HIGH/LOW to HIGH

Bus stable

Bus to high impedance

Bus change

High impedance to stable bus

## Key to timing diagram conventions

Timing diagrams sometimes show single-bit signals as HIGH and LOW at the same time and they look similar to
the bus change shown in Key to timing diagram conventions. If a timing diagram shows a single-bit signal in this
way then its value does not affect the accompanying description.

## Signals

## Numbers

The signal conventions are:

## Signal level

The level of an asserted signal depends on whether the signal is active-HIGH or
active-LOW. Asserted means:

- HIGH for active-HIGH signals

- LOW for active-LOW signals.

## Lower-case n

Lower-case x

At the start or end of a signal name denotes an active-LOW signal.

At the second letter of a signal name denotes a collective term for both Read and Write. For
example, AxCACHE refers to both the ARCACHE and AWCACHE signals.

Numbers are normally written in decimal. Binary numbers are preceded by 0b, and hexadecimal numbers by 0x.
Both are written in a monospace font.

## Additional reading

This section lists relevant publications from Arm.
See Arm Developer https://developer.arm.com/docs, for access to Arm documentation.

## Arm publications

-
-
-
-

AMBA APB Protocol Specification (ARM IHI 0024)
AMBA 4 AXI4-Stream Protocol Specification (ARM IHI 0051)
AMBA 5 CHI Architecture Specification (ARM IHI 0050)
AMBA Low Power Interface Specification (ARM IHI 0068)
Arm® Architecture Reference Manual Armv8, for Armv8-A architecture profile (ARM DDI 0487)
Arm®Architecture Reference Manual Supplement Memory System Resource Partitioning and Monitoring
(MPAM), for Armv8-A (ARM DDI 0598)

- Arm System Memory Management Unit Architecture Specification (ARM IHI 0070)

## Feedback

Arm welcomes feedback on its documentation.

## Feedback on this specification

If you have comments on the content of this specification, send e-mail to errata@arm.com. Give:

- The title, AMBA AXI and ACE Protocol Specification

- The number, ARM IHI 0022H.c

- The page number(s) that your comments apply

- A concise explanation of your comments

Arm also welcomes general suggestions for additions and improvements.
