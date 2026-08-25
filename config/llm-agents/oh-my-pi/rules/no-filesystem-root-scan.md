---
name: no-filesystem-root-scan
description: "Prevent resource-intensive filesystem scans rooted at /"
condition: ["find\\s+/\\s", "find\\s+/$", "du\\s+/\\s", "du\\s+/$", "ls\\s+-[a-zA-Z]*R[a-zA-Z]*\\s+/\\s", "ls\\s+-[a-zA-Z]*R[a-zA-Z]*\\s+/$", "grep\\s+.*\\s+-r\\s+/\\s", "grep\\s+.*\\s+-r\\s+/$"]
scope: ["tool:bash"]
---

Do not scan the entire filesystem from `/`. These operations traverse millions of inodes, are extremely slow, and can stall or OOM the session.

Instead, narrow the search to a specific directory:

- Need a file by name? Use `locate <name>` or `find /home /etc /var -name <name>` with explicit, bounded roots.
- Need disk usage? Use `du -sh /home /var /etc` or another bounded subtree.
- Need to grep across sources? Scope to the project directory or a known subtree.
- Need a package binary? Use `which <cmd>`, `command -v <cmd>`, or `type <cmd>`.
- Need to find a library? Use `ldconfig -p | grep <name>` or check `/usr/lib`, `/usr/local/lib` directly.

If you genuinely need to search the whole system, use `locate` (fast indexed lookup) or `find` with `-maxdepth 3` and explicit top-level paths instead of bare `/`.
