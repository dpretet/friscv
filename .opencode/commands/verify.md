---
description: Select and run the most relevant FRISCV lint or simulation checks
agent: build
---

Load `@verification`. Inspect the current changes and select the narrowest
meaningful verification from the changed behavior, `AGENTS.md`, and
`.github/workflows/ci.yaml`. Check the working tree and possible generated
outputs first. Run selected checks when prerequisites are available; do not
install dependencies, initialize submodules, or trigger network access without
approval. Report exact commands/results and any gaps. Do not claim a check passed
unless it did.
