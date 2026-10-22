# OpenCode setup for FRISCV

This directory contains repository-specific OpenCode workflows. It deliberately
does not select a model, provider, MCP server, or global permission policy; those
depend on each contributor's environment.

## Repository map

- `rtl/`: SystemVerilog implementation. Start with `friscv_rv32i_core.sv` for the
  hart and `friscv_rv32i_platform.sv` for the integrated platform. The design
  also has control/processing, CSR, memory protection, cache, memory, and
  peripheral modules.
- `doc/friscv-arch/`: FRISCV-authored architecture and implementation documents.
  Start with `architecture.md` for top-level design and block descriptions,
  `ios_params.md` for module parameters and interfaces, and `axi.md` for
  handshakes and transaction behavior. Also consult `ordering_cache.md`,
  `dcache.md`, `privilege.md`, or other focused documents for the affected block.
- `doc/amba-axi4/`: the converted Arm AMBA AXI/ACE protocol specification
  (IHI 0022H.c). Use `amba_axi_protocol_spec.md` as the index, then read the
  relevant `part-a.md` through `part-g.md` chapter/section when a task depends
  on protocol requirements. This specifies the protocol, not FRISCV support.
- `doc/riscv-spec/`: local searchable AsciiDoc sources for RISC-V architectural
  requirements. Search relevant topics and follow included source files; check
  each volume's preface for version/ratification status before citing it. The
  imported upstream revision is not pinned, so verify the required official
  release when exact versioning matters.
- `test/`: white-box assembler, privilege/security, RISC-V compliance, C,
  application, and SystemVerilog tests. Each suite's README explains its focus.
- `flow.sh` and `.github/workflows/ci.yaml`: local entry points and CI's chosen
  lint, simulation, and synthesis checks.
- `dep/`: third-party dependencies; do not change them as part of ordinary RTL
  work.

Treat the root `README.md` as an orientation, not as proof that every listed
feature is currently enabled or tested. When behavior matters, verify it against
the implementation, parameters, FRISCV architecture docs, and tests. For ISA or
privileged-architecture requirements, also search `doc/riscv-spec/`; that spec
does not prove FRISCV implements a feature.

## How the setup behaves

You do not need a special keybinding. Start OpenCode in this repository and type
the commands below in the normal prompt/composer.

- **`AGENTS.md` is automatic.** OpenCode loads it as project guidance when you
  work in the repository. It contains general FRISCV constraints and links to
  this map.
- **Commands are explicit.** Files in `commands/` register slash commands, but
  OpenCode does not run them on its own. Type one when you want that workflow
  stage.
- **Skills are available context, not a required keyword.** OpenCode advertises
  each skill's ID and description to the model; the model can load a relevant
  skill when needed. The skill body is loaded only when selected. To request one
  explicitly, mention its ID as `@skill-id` in your prompt.
- **Agents are role profiles, not separate always-running bots.** A command can
  select an agent. In this setup `/plan` and `/review` start a child session for
  their specialist agent and return its result; the other commands use the
  current session with the Build agent.
- **This README is for people.** It documents the setup; it is not itself an
  OpenCode command or skill. There is no project-specific model/provider config
  or custom keybinding.

## RTL/IP workflow commands

| Command | What it does | Typical use |
| --- | --- | --- |
| `/plan <request>` | Runs the read-only `rtl-architect` specialist. It inspects the RTL, docs, tests, and flow, then returns requirements/open questions, a design contract, affected files, checks, and risks. | `/plan Add a PMP access-fault test for this behavior` |
| `/rtl-implement <approved plan>` | Uses Build to implement an approved plan and focused tests. It should stop if the plan is absent or leaves important behavior unclear. | `/rtl-implement Implement the approved plan above` |
| `/verify [scope]` | Selects and runs the narrowest relevant lint/simulation check, then reports actual results and gaps. It will not install dependencies or initialize submodules without approval. | `/verify the dcache changes` |
| `/synthesize [scope]` | Runs `./flow.sh syn` (both repository Yosys synthesis scripts) when requested or relevant. It checks for existing output changes first. | `/synthesize check the core after this RTL change` |
| `/review [scope]` | Starts the read-only `rtl-reviewer` specialist to look for bugs, regressions, interface/parameter issues, and missing tests. | `/review against the approved plan` |
| `/commit [context]` | Drafts a message for staged changes using FRISCV's convention. It never stages files and asks you to confirm the exact message before committing. | `/commit` |

### Recommended sequence

1. Type `/plan <request>` and answer any clarification questions.
2. Review the proposed design contract. Tell OpenCode explicitly if you approve
   it or want changes.
3. Type `/rtl-implement <approved plan>` (or refer to the approved plan in the
   current session). Review the diff.
4. Type `/verify` to run focused checks. Check its report for checks that could
   not run and configurations not covered.
5. Type `/synthesize` when synthesis is part of the task. This runs both Yosys
   flows and updates their logs/outputs; it is not timing closure, formal
   equivalence, or hardware signoff.
6. Type `/review` for an independent review of the current changes.
7. Optionally type `/commit` to prepare a commit. Review the staged-change
   summary and exact message, then explicitly confirm before the commit is made.

These stages are explicit rather than fully autonomous: planning and review do
not edit RTL, and implementation requires both a clear design contract and an
explicit user request to change files (normally `/rtl-implement`). A task list,
design discussion, or answer to a clarification question is not implementation
authorization. Implementation does not commit, and no command stages files or
commits without your confirmation. Test/synthesis commands are not run until
requested through their stage or the task itself.

## Skills you can request explicitly

Use these exact IDs with `@` in a prompt, or let the model load one when it
recognizes the task:

| Skill ID | Intended use |
| --- | --- |
| `@rtl-architecture` | Turn a feature/bug request into a requirements-backed design plan without editing files. |
| `@rtl-change` | Implement an approved RTL change while preserving interfaces, parameters, reset, and protocol behavior. |
| `@verification` | Design focused test coverage, choose a suite, and interpret results. |
| `@rtl-synthesis` | Run and interpret the repository's synthesis flow without overstating signoff. |
| `@git-commit` | Format a commit message using FRISCV's convention and require confirmation before committing. |

Example: `Please load @verification and propose tests for the new cache behavior.`

## Files in this directory

- `agents/rtl-architect.md`: planning specialist used by `/plan`.
- `agents/rtl-reviewer.md`: review specialist used by `/review`.
- `commands/`: the slash-command prompt templates listed above.
- `skills/`: reusable task-specific guidance listed above.
- `.opencode/README.md`: this human-facing usage guide.
