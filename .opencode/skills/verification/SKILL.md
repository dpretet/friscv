---
name: FRISCV Verification
description: Design focused FRISCV test coverage and select or interpret lint, simulation, and synthesis checks for a code change
---

Start from the approved behavior/design contract. Identify observable outcomes,
boundary cases, error/reset behavior, and relevant parameter configurations;
then choose the closest existing suite and add/update focused coverage where
practical. Use neighboring tests and each suite README for style and harness
details. Select the smallest meaningful check based on changed modules, tests,
and `.github/workflows/ci.yaml`.

Inspect `git status` first: some flows update logs, build products, or test
outputs. Do not delete or overwrite user changes.

## Test-suite selection

- `test/wba_testsuite/`: white-box core integration tests for instruction
  sequencing, memory operations, branches, CSRs, outstanding requests,
  interrupts/WFI, and related datapath behavior.
- `test/priv_sec_testsuite/`: privilege transitions, traps/interrupts, PMP, and
  access permissions.
- `test/riscv-tests/`: imported official RISC-V tests; use for ISA compliance
  behavior covered by this checkout.
- `test/c_testsuite/`: compiled C programs exercising toolchain and hart behavior.
- `test/sv/`: module-level I-cache and D-cache testbenches.
- `test/apps/`: platform applications/benchmarks, some interactive; use for
  end-to-end behavior or performance only when appropriate.
- `test/common/`: shared testbench, AXI RAM, utilities, and simulation support;
  changes here may affect multiple suites.

Do not treat a passing suite as proof for configurations or behaviors it does
not exercise. State coverage limitations explicitly.

## Checks

- RTL lint: `./flow.sh lint` (Verilator; writes `lint.log`).
- White-box: `./flow.sh sim wba-testsuite core verilator` and/or `platform`.
- Privilege/security: `./flow.sh sim priv_sec-testsuite core verilator` and/or
  `platform`.
- RISC-V compliance: `./flow.sh sim riscv-testsuite core verilator` and/or
  `platform`.
- C tests: `./flow.sh sim c-testsuite core verilator` and/or `platform`.
- Module-level cache tests: `./flow.sh sim sv-testsuite`. This flow runs both
  I-cache and D-cache benches; it does not select one based on an extra argument.
- Apps: the apps suite is separate from `flow.sh`; its README documents
  `cd test/apps && ./run.sh --tc tests/repl.v`. Apps use the platform and
  Verilator, and some require interactive input.
- Synthesis: `./flow.sh syn` runs both Yosys synthesis scripts and updates root
  synthesis logs. Use for synthesis-related changes or when explicitly asked.

## Environment and reporting

Simulation flows may require tools, initialized submodules, and SVUT. Inspect
`script/setup.sh` before running a flow if setup is missing: it can clone SVUT.
Do not install dependencies, initialize submodules, or trigger network access
without user approval. If prerequisites are unavailable, report the exact
command and blocker instead of treating the check as passed.

Report each command and its result. Separate checks actually run from checks
recommended but not run, and mention relevant logs or generated outputs.
