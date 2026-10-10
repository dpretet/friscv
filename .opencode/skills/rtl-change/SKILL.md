---
name: FRISCV RTL Change
description: Plan or implement SystemVerilog RTL changes in FRISCV while preserving architecture, interfaces, parameters, and verification coverage
---

## Workflow

1. Use an approved `/plan` result when available. If no design contract exists,
   first restate the requested behavior and identify whether it affects the hart,
   platform, or both. Ask before assuming behavior that is not specified.
2. Read the target module and its instantiations. Trace the relevant path through
   the core/platform instead of treating a module in isolation.
3. Read the relevant design references, as applicable:
   - `doc/architecture.md` for block relationships and core/platform structure.
   - `doc/ios_params.md` for parameters and interfaces.
   - `doc/axi.md` for handshake, channels, IDs, and outstanding transactions.
   - `doc/cache_layers.md`, `doc/dcache.md`, or `doc/ordering_cache.md` for cache
     behavior and ordering.
   - `doc/privilege.md`, `doc/traps.md`, or `doc/registers.md` for privilege,
     exceptions, and CSR behavior.
4. Preserve existing interface and parameter behavior unless the task requests a
   change. In particular, check reset behavior, backpressure, transaction
   ordering/IDs, and every relevant configuration path.
5. Make a focused change in the existing style. Do not edit generated files or
   third-party code in `dep/` unless asked.
6. Find the closest existing test in `test/`; add or update coverage when
   practical. Pick verification using the `verification` skill.
7. Report the implementation, tests actually run, and any unverified
   configurations or risks. Never imply a test passed if it was not run. Leave
   synthesis and independent review as separate flow stages unless requested.

## Feature claims

The root README is an overview and may describe optional features. Confirm the
current implementation, parameter defaults, and test coverage before claiming a
feature is present or enabled. Treat plans/backlog documents as plans, not proof
of implementation.
