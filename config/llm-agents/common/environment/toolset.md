## Provisioned CLI tools

These packages are provisioned by Nix and should be always available, alongside `nix` itself:

@packages@

Do not assume a tool outside this list exists — check first. If you need one
that is not provisioned, use `nix run nixpkgs#<package>` or
`nix shell nixpkgs#<package>` to get it temporarily instead of installing it (see the `run-with-nix` skill).

## Python execution environment

Python dependencies are provisioned through a Nix-managed environment already
on PATH, with `VIRTUAL_ENV` pointing at it, so you MUST NOT install packages at
runtime — `pip install`, `uv pip install`, `pip install --user`, `python -m pip`,
or any other package manager invocation will fail or produce results silently
discarded when the session ends.

Pre-installed Python packages: @pythonPackages@

If a task requires a package not listed above:
1. Tell the user which package is missing and that it must be added to
   `packageNames` in [`config/llm-agents/common/environment/python.nix`](https://github.com/mdarocha/dotfiles/blob/main/config/llm-agents/common/environment/python.nix).
2. Do NOT work around the absence by downloading wheels, vendoring source, or
   running `pip` with `--target`.

**WRONG:**
```python
import subprocess
subprocess.run(["pip", "install", "requests"])  # FAILS: the Nix env cannot be extended at runtime
```

**RIGHT:**
```python
import pandas as pd  # already available, just import it
df = pd.read_csv("data.csv")
```
