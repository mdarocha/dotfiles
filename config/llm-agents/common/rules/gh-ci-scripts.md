---
name: gh-ci-scripts
description: "Wait for CI and read failed logs with the github skill's scripts, not raw gh polling"
condition:
  - "gh\\s+run\\s+view\\b[^\\n]*--log"
  - "gh\\s+run\\s+watch\\b"
  - "gh\\s+pr\\s+checks\\b[^\\n]*--watch"
  - "sleep\\s+\\d+[^\\n]*gh\\s+(?:run|pr)\\b"
scope: ["tool:bash"]
interruptMode: tool-only
---

Raw `gh run view --log*`, `gh run watch`, `gh pr checks --watch`, and `sleep` loops around `gh` burn context on log prefixes and miss the check that finishes last. Use the `github` skill's scripts (paths relative to the skill directory):

- `scripts/ci-wait.sh --pr <number>` waits for every check on the PR head and prints failure excerpts. Exit 0 green, 1 failed, 2 timed out, 3 no checks.
- `scripts/ci-failures.sh <run-id>` or `--pr <number>` prints failed jobs and steps with log tails.
