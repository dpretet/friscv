# FRISCV project guidance

FRISCV is a SystemVerilog RISC-V core and platform. `README.md` is an overview,
not a complete specification: confirm feature support and behavior in the RTL,
tests, and relevant `doc/` pages before making claims or changes. The repo map
and OpenCode workflow are in `.opencode/README.md`.

Before changing RTL, read the relevant module and architecture notes; preserve
existing interfaces, parameter behavior, reset behavior, and bus/protocol
handshakes unless the task explicitly changes them. Treat `dep/` as vendored
code and avoid editing it unless specifically requested.

## Working in this repository

- Keep changes focused and follow the style of neighboring SystemVerilog and
  testbench code.
- For RTL changes, identify the affected core/platform configuration and add or
  update a relevant test when practical.
- Load `rtl-architecture` when turning a feature request into a design plan,
  `rtl-change` when implementing it, `verification` when choosing or interpreting
  tests, and `rtl-synthesis` for synthesis runs or results.
- Do not commit changes unless explicitly asked. If asked to prepare a commit,
  load and follow the `git-commit` skill.
- Do not overwrite unrelated user changes or generated outputs. Some flow
  commands update logs and build artifacts; inspect the working tree before and
  after running them.

## Verification

Use the narrowest relevant checks, based on the change and the CI definitions in
`.github/workflows/ci.yaml`:

- RTL lint: `./flow.sh lint` (requires Verilator; writes `lint.log`).
- Simulations: `./flow.sh sim <suite> <core|platform> verilator`; suites include
  `wba-testsuite`, `priv_sec-testsuite`, `riscv-testsuite`, and `c-testsuite`.
- The SystemVerilog flow is `./flow.sh sim sv-testsuite`; it runs the I-cache and
  D-cache benches and requires the simulators/dependencies described in CI.
- Synthesis: `./flow.sh syn` (requires Yosys and updates synthesis logs); use
  when the change affects synthesis or when explicitly requested.

Do not claim a check passed unless it was run successfully. If a dependency is
missing or a flow cannot run, report that and the exact command attempted.
