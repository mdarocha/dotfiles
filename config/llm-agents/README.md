# llm-agents

Home Manager module that configures AI coding agents for local, privacy-conscious use.

Upstream packages come from the [`numtide/llm-agents.nix`][llm-agents] flake
(omp, copilot-cli, sandbox-runtime). This module adds configuration,
sandboxing, and skills on top.

[llm-agents]: https://github.com/numtide/llm-agents.nix

## Submodules

- **Sandbox** (`sandbox/`) — wraps agent binaries in
  [agent-sandbox.nix][srt] (bubblewrap + seccomp). Restricts filesystem access,
  allowlists network domains, and exposes a `wrapPackage` helper.
  Key options:
  - `sandbox.enable` — toggle sandboxing on/off (default: `true`)
  - `sandbox.allowedDomainGroups` — grouped outbound network allowlist (default groups: GitHub, GitHub Copilot, npm, Python, Nix, Azure DevOps, MCP tools, docs, NuGet, Figma, Contentful, models.dev)
  - `sandbox.allowedPackages` — packages available on PATH inside the sandbox (default: git, gh, nix, python3, nodejs, bun, coreutils, curl, jq, ripgrep, fd, …)
  - `sandbox.wrapPackage` — helper `name: pkg → wrappedPkg` used by other submodules

- **Copilot CLI** (`copilot-cli/`) — installs [`copilot-cli`][copilot-cli] and wraps the `copilot` binary with the sandbox.

- **oh-my-pi** (`oh-my-pi/`) — installs and configures `omp` from [oh-my-pi][omp].

[srt]: https://github.com/archie-judd/agent-sandbox.nix
[omp]: https://github.com/can1357/oh-my-pi
[copilot-cli]: https://github.com/github/copilot-cli
