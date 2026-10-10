---
description: Run and interpret the repository's Yosys synthesis flows for the FRISCV core
agent: build
---

Load `@rtl-synthesis`. Inspect the current working tree and synthesis outputs
first. If existing user changes would be overwritten, stop and ask. Run
`./flow.sh syn` only when requested by this command or when the user explicitly
asks for the synthesis check. Report the exact tool/flow, result, warnings,
generated outputs, and limitations. Do not claim timing, area, formal, or
hardware signoff beyond what the actual output establishes.
