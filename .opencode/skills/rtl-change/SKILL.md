---
name: FRISCV RTL Change
description: Plan or implement SystemVerilog RTL changes in FRISCV while preserving architecture, interfaces, parameters, and verification coverage
---

## Workflow

1. **Confirm implementation is explicitly requested before editing.** A list of
   remaining tasks, a feature description, or a design discussion is not by
   itself authorization to change files. Clarification answers and agreement on
   behavior settle the design contract; they do not authorize implementation.
   If the user asks only to read, investigate, or plan, stay read-only. If intent
   is unclear, ask first.
2. Use an approved `/plan` result when available. If no design contract exists,
   first restate the requested behavior and identify whether it affects the hart,
   platform, or both. Ask before assuming behavior that is not specified. Begin
   implementation only after both the behavior is clear and the user explicitly
   authorizes file changes.
3. Read the target module and its instantiations. Trace the relevant path through
   the core/platform instead of treating a module in isolation.
4. Read the relevant design references, as applicable:
   - `doc/friscv-arch/architecture.md` for block relationships and core/platform
     structure.
   - `doc/friscv-arch/ios_params.md` for parameters and interfaces.
   - `doc/friscv-arch/axi.md` for handshake, channels, IDs, and outstanding
     transactions.
   - For AMBA AXI/ACE protocol requirements, use
     `doc/amba-axi4/amba_axi_protocol_spec.md` to navigate to the relevant
     chapter/section in `part-a.md` through `part-g.md`. Check that protocol
     requirements against FRISCV docs, RTL, and tests; the spec alone does not
     establish implementation support.
   - `doc/friscv-arch/cache_layers.md`, `dcache.md`, or `ordering_cache.md` for
     cache behavior and ordering.
   - `doc/friscv-arch/privilege.md`, `traps.md`, or `registers.md` for privilege,
     exceptions, and CSR behavior.
   For behavior defined by the RISC-V ISA or privileged architecture, search
   `doc/riscv-spec/` (AsciiDoc sources), follow relevant `include::` directives,
   and check the volume preface for version/ratification status. Cite the volume
   and section in reasoning or reports. Treat the spec as requirements, not
   evidence that FRISCV implements the feature; verify support in RTL and tests.
5. Preserve existing interface and parameter behavior unless the task requests a
   change. In particular, check reset behavior, backpressure, transaction
   ordering/IDs, and every relevant configuration path.
6. Make a focused change in the existing style. Do not edit generated files or
   third-party code in `dep/` unless asked.
7. Find the closest existing test in `test/`; add or update coverage when
   practical. Pick verification using the `verification` skill.
8. Report the implementation, tests actually run, and any unverified
   configurations or risks. Never imply a test passed if it was not run. Leave
   synthesis and independent review as separate flow stages unless requested.

## Feature claims

The root README is an overview and may describe optional features. Confirm the
current implementation, parameter defaults, and test coverage before claiming a
feature is present or enabled. Treat plans/backlog documents as plans, not proof
of implementation.
