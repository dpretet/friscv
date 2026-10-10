---
name: FRISCV RTL Architecture Planning
description: Translate a FRISCV feature or bug request into a requirements-backed RTL/IP design and verification plan without editing files
---

## Planning process

1. Restate the requested behavior. Separate explicit requirements from
   assumptions, and ask focused questions about externally visible behavior,
   reset, errors, compatibility, and supported parameter configurations when
   they are unspecified.
2. Identify whether the change belongs to the hart, platform, a peripheral,
   verification infrastructure, or software/test content.
3. Trace relevant RTL modules and their instantiations. Read the corresponding
   documentation, including `doc/architecture.md`, `doc/ios_params.md`, and
   protocol/feature-specific documents as applicable.
4. Check the relevant test-suite README and existing tests. Use
   `.github/workflows/ci.yaml` and `flow.sh` to identify actual verification
   entry points.
5. Consult `doc/project_mgt_hw.md` or `doc/project_mgt_sw.md` only as context for
   project direction. Backlog entries are not implementation requirements and
   may be stale; verify current behavior in RTL and tests.
6. Produce a design plan with:
   - requirements and open questions;
   - proposed behavior and compatibility constraints;
   - affected modules, interfaces, parameters, and documents;
   - test additions/updates and focused checks;
   - synthesis impact and risks.
7. Do not edit files. Do not claim tests or implementation have been performed.

For RISC-V ISA or bus-spec behavior, identify the relevant spec/version or ask
which requirement governs when the repository docs and request do not settle it.
