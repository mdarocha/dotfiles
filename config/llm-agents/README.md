# llm-agents

Home Manager module that configures AI coding agents for local, privacy-conscious use.

Upstream packages come from the [`numtide/llm-agents.nix`][llm-agents] flake
(omp, copilot-cli, sandbox-runtime). This module adds configuration,
sandboxing, and skills on top.

[llm-agents]: https://github.com/numtide/llm-agents.nix

## Submodules

- **Sandbox** (`sandbox/`) — wraps agent binaries in Anthropic's
  [sandbox-runtime][srt] (bubblewrap + seccomp). Restricts filesystem access,
  allowlists network domains, and exposes a `wrapPackage` helper.

- **Copilot CLI** (`copilot-cli/`) — sandbox wrapper around `copilot`.

- **oh-my-pi** (`oh-my-pi/`) — sandbox wrapper around `omp` from [oh-my-pi][omp].
  Installs skills (commit, gh-cli, run-with-nix) and injects sandbox rules as `~/.omp/agent/AGENTS.md`.

[srt]: https://github.com/anthropic-experimental/sandbox-runtime
[omp]: https://github.com/can1357/oh-my-pi

## Patches

### sandbox-runtime (`sandbox/patches/`)

| Patch | Why |
|---|---|
| `srt-implement-allowlocalbinding-linux` | `allowLocalBinding` is macOS-only. Adds a reverse socat bridge so sandbox-bound ports are reachable from the host on Linux. |
| `srt-fix-dangerous-files-paths` | Resolves home-only `DANGEROUS_FILES` to `$HOME`. CWD files use `git check-ignore`: gitignored paths always denied; tracked paths denied only when they exist. |
