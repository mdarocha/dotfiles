# llm-agents

Home Manager module that configures AI coding agents for local, privacy-conscious use.

Upstream packages come from the [`numtide/llm-agents.nix`][llm-agents] flake
(omp, copilot-cli, claude-code). This module adds configuration, sandboxing,
and skills on top.

[llm-agents]: https://github.com/numtide/llm-agents.nix

## Submodules

- **Common** (`common/`) — instructions and skills shared by every agent:
  - `instructions` — agent instructions (`common/instructions.md`) installed for all agents
  - `skills` — skill name → source directory, symlinked into each agent

- **oh-my-pi** (`oh-my-pi/`) — installs and configures `omp` from [oh-my-pi][omp].
  Its `sandbox/` wraps the binary in [agent-sandbox.nix][srt] (bubblewrap +
  seccomp); the unsandboxed `omp-nosandbox` binary gets the same toolset
  without the bwrap layer, and the generated `sandbox-instructions.ts`
  extension injects the mode-specific instructions at session start:
  - `sandbox/default.nix` — builds both binaries and wires the bind mounts,
    proxy allowlist and environment
  - `sandbox/packages.nix`, `sandbox/python.nix`, `sandbox/chromium.nix` — the
    toolset placed on PATH, the `eval` Python environment and the Chromium
    wrapper that trusts the proxy CA
  - `sandbox/domains.nix` — outbound allowlist, grouped for the instructions
  - `sandbox/paths.nix` — filesystem binds plus the activation step that
    pre-creates them
  - `sandbox/instructions/*.md` — toolset, sandboxed and host instruction
    chunks, with `@placeholder@` slots filled by `sandbox/instructions.nix`

- **Copilot CLI** (`copilot-cli/`) — installs [`copilot-cli`][copilot-cli], which
  sandboxes itself.

- **Claude Code** (`claude-code/`) — installs [`claude-code`][claude-code], which
  sandboxes itself. `claude-code.package = null` installs only the configuration,
  for environments that ship their own binary; `claude-code.fixNix` adds a
  SessionStart hook that puts Nix on PATH there.

[srt]: https://github.com/archie-judd/agent-sandbox.nix
[omp]: https://github.com/can1357/oh-my-pi
[copilot-cli]: https://github.com/github/copilot-cli
[claude-code]: https://github.com/anthropics/claude-code
