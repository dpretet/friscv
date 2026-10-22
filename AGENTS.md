# FRISCV project guidance

FRISCV is a SystemVerilog RISC-V core and platform. `README.md` is an overview,
not a complete specification: confirm FRISCV behavior in the RTL, tests, and
relevant `doc/friscv-arch/` pages. For architectural requirements, also search
the local RISC-V sources in `doc/riscv-spec/`. The repo map and OpenCode workflow
are in `.opencode/README.md`.

## Documentation lookup

- Use `doc/friscv-arch/` for FRISCV-specific architecture, interfaces, and
  implementation behavior. Verify behavior against the RTL and tests as well.
- For AMBA AXI/ACE protocol requirements, start at
  `doc/amba-axi4/amba_axi_protocol_spec.md` and read the relevant Part file
  (`part-a.md` through `part-g.md`) and chapter/section. Cite the Part and
  chapter/section when the conclusion depends on the protocol. This is Arm
  IHI 0022H.c; distinguish its normative requirements from FRISCV support, which
  must be checked in `doc/friscv-arch/`, the RTL, and tests.
- Use `doc/riscv-spec/` for RISC-V ISA and privileged-architecture requirements.
  It contains searchable AsciiDoc sources; search them by topic/section (for
  example, `rg -n -i 'pmp|access-fault' doc/riscv-spec --glob '*.adoc'`) and
  follow relevant `include::` directives to their source files.
- When a conclusion depends on the specification, cite its volume and section
  and check that volume's preface for ratification/version status. Do not treat
  the spec as evidence that FRISCV implements a feature; distinguish normative
  requirements from implementation support and verify the latter in FRISCV RTL,
  docs, and tests. The imported upstream revision is not pinned; if an exact
  official version governs, verify it against that release or ask which version
  is intended rather than assuming this snapshot is current.

Before changing RTL, read the relevant module and architecture notes; preserve
existing interfaces, parameter behavior, reset behavior, and bus/protocol
handshakes unless the task explicitly changes them. Treat `dep/` as vendored
code and avoid editing it unless specifically requested.

## Working in this repository

- **Authorization gate:** Treat a checklist of remaining work, a feature
  description, or a design discussion as a request to understand, analyze, or
  plan—not as authorization to edit files. Modify RTL, tests, documentation, or
  configuration only when the user explicitly asks for implementation or file
  changes. Answers that clarify behavior or approve a design choice do not by
  themselves authorize implementation. If intent is unclear, ask before editing.
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
