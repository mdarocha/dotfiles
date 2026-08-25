---
name: no-nix-store-source-search
description: "Read flake/package sources from GitHub, not by searching /nix/store"
condition: ["find\\s+/nix/store[^;\\n]*-name", "/nix/store/[a-z0-9]+-[^/\\s]+-source"]
scope: ["tool:bash", "tool:grep", "tool:glob"]
---

Do not search `/nix/store` for source files belonging to a flake input. Instead:
1. Look up the input's `rev` and `owner/repo` from `flake.lock`.
2. Read files directly from GitHub: `https://raw.githubusercontent.com/<owner>/<repo>/<rev>/path/to/file.nix`.

Searching `/nix/store` is slow (the store may not be populated), fragile (paths are content-addressed and change), and unnecessary when the source is on GitHub.
