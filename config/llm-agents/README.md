# llm-agents

Home Manager module that configures AI coding agents for local, privacy-conscious use.

Upstream packages come from the [`numtide/llm-agents.nix`][llm-agents] flake
(opencode, copilot-cli, sandbox-runtime). This module adds configuration,
sandboxing, and patches on top.

[llm-agents]: https://github.com/numtide/llm-agents.nix

## Submodules

- **Sandbox** (`sandbox/`) — wraps agent binaries in Anthropic's
  [sandbox-runtime][srt] (bubblewrap + seccomp). Restricts filesystem access,
  allowlists network domains, and exposes a `wrapPackage` helper.

- **Opencode** (`opencode/`) — configures [opencode][oc] with GitHub Copilot,
  a locally-built web UI, git/gh permissions, and MCP integrations.

- **Copilot CLI** (`copilot-cli/`) — sandbox wrapper around `copilot`.

- **oh-my-pi** (`oh-my-pi/`) — sandbox wrapper around `omp` from [oh-my-pi][omp].

[srt]: https://github.com/anthropic-experimental/sandbox-runtime
[oc]: https://github.com/anomalyco/opencode
[omp]: https://github.com/can1357/oh-my-pi

## Patches

### sandbox-runtime (`sandbox/patches/`)

| Patch | Why |
|---|---|
| `srt-fix-denyread-clobbers-allowwrite` | `--tmpfs` on a `denyRead` ancestor clobbers `--bind` mounts for `allowWrite` paths underneath it. Uses `--bind` (rw) instead of `--ro-bind` when re-allowing a writable path. |
| `srt-implement-allowlocalbinding-linux` | `allowLocalBinding` is macOS-only. Adds a reverse socat bridge so sandbox-bound ports are reachable from the host on Linux. |
| `srt-fix-dangerous-files-paths` | Resolves home-only `DANGEROUS_FILES` to `$HOME`. CWD files use `git check-ignore`: gitignored paths always denied; tracked paths denied only when they exist. |

### opencode (`opencode/patches/`)

| Patch | Why |
|---|---|
| `opencode-serve-local-web-ui` | Replaces the `app.opencode.ai` reverse proxy with Hono's `serveStatic`. Reads `OPENCODE_WEB_DIR` and serves the SPA locally — no CDN dependency. |

### opencode config vs. upstream defaults

| Setting | Upstream | This module |
|---|---|---|
| Web UI | Proxied from `app.opencode.ai` | Built from source, served locally |
| Provider | `opencode` with `apiKey: "public"` | `opencode` provider disabled |
| Model | (none) | `github-copilot/claude-opus-4.6` |
| Small model | Provider's priority list | `github-copilot/gpt-4.1` |
| Share | `enabled` | `disabled` |
| Network | Unrestricted | Sandbox allowlist (no `*.opencode.ai`) |
