---
description: Implement an approved FRISCV RTL/IP design plan and its focused tests
agent: build
---

Load `@rtl-change`. Implement this approved FRISCV plan: $ARGUMENTS

If no approved plan is provided in the arguments or current session, do not
implement yet; ask the user to run `/plan` and approve its design contract. Use
the approved plan as the scope boundary. Inspect the current working tree and
source before editing. Preserve unrelated work. If the plan conflicts with the
RTL, docs, or tests, or leaves a behaviorally important requirement unresolved,
stop and ask rather than silently changing the design contract. Implement
focused RTL and verification changes; do not commit. At completion, report
changed files, tests run, unverified cases, and whether `/verify`, `/synthesize`,
or `/review` remains appropriate.
