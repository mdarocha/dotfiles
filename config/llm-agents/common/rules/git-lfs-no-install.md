---
name: git-lfs-no-install
description: "Do not run git lfs install; LFS filters are configured globally"
condition: "git\\s+lfs\\s+install"
scope: ["tool:bash"]
interruptMode: tool-only
---

Do not run `git lfs install`. LFS filters are already configured globally (`filter.lfs.*` in `~/.config/git/config`, provisioned by home-manager's `programs.git.lfs.enable`). `add`, `commit`, `push`, and `checkout` already smudge and clean LFS-tracked files correctly without per-repo `.git/config` entries. `git-lfs` itself is on `$PATH`.
