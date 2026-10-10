---
description: Prepare a FRISCV commit message and commit only after explicit confirmation
agent: build
---

Load `@git-commit`. Prepare a commit for the currently staged FRISCV changes.

First inspect `git status` and the staged diff. Include staged changes only; do
not stage files or include unstaged changes. If there is nothing staged, explain
that and ask the user to stage the intended files themselves.

Draft a message using the repository's required title prefix (`New`, `Fix`, or
`Change`) and body format. Keep each body line under 100 characters. Show the
exact proposed message and summarize which staged changes it describes. Do not
run `git commit` in this step. Ask the user to confirm the exact message and
commit. After confirmation, re-check the staged diff; if it changed, ask again.
Then create the commit with the approved message. Never amend, push, or stage
files as part of this command.
