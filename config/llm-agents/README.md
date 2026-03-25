# llm-agents

Home Manager module that configures AI coding agents for local,
privacy-conscious use on NixOS.

Upstream packages come from the [`numtide/llm-agents.nix`][llm-agents] flake
(opencode, copilot-cli, sandbox-runtime). This module adds configuration,
sandboxing, and patches on top.

[llm-agents]: https://github.com/numtide/llm-agents.nix

## What it does

- **Sandbox** (`sandbox/`) — wraps agent binaries in Anthropic's
  [sandbox-runtime][srt] (bubblewrap + seccomp on Linux). Restricts
  filesystem access, allowlists network domains, and exposes a
  `wrapPackage` function that other submodules call.

- **Opencode** (`opencode/`) — configures [opencode][oc] with GitHub
  Copilot as the sole provider, a locally-built web UI, permissions for
  git/gh commands, and MCP tool integrations.

- **Copilot CLI** (`copilot-cli/`) — thin sandbox wrapper around the
  upstream `copilot` binary.

[srt]: https://github.com/anthropic-experimental/sandbox-runtime
[oc]: https://github.com/anomalyco/opencode

## Patches vs. upstream

### sandbox-runtime patches (`sandbox/patches/`)

| Patch | Why |
|---|---|
| `srt-fix-denyread-clobbers-allowwrite` | `--tmpfs` on a `denyRead` ancestor clobbers `--bind` mounts for `allowWrite` paths underneath it. Uses `--bind` (rw) instead of `--ro-bind` when re-allowing a path that is also writable. |
| `srt-implement-allowlocalbinding-linux` | `allowLocalBinding` is only wired for macOS (Seatbelt). Adds a reverse socat bridge so sandbox-bound ports are reachable from the host on Linux. |
| `srt-fix-dangerous-files-paths` | Resolves `DANGEROUS_FILES` relative to `$HOME` instead of cwd, skips files that don't exist, and skips git-tracked files in cwd. |

### opencode patches (`opencode/patches/`)

| Patch | Why |
|---|---|
| `opencode-serve-local-web-ui` | Replaces the `app.opencode.ai` reverse proxy in `server.ts` with Hono's `serveStatic`. The patched binary reads `OPENCODE_WEB_DIR` and serves the SPA directly — no runtime CDN dependency. |

### opencode config vs. upstream defaults

| Setting | Upstream default | This module |
|---|---|---|
| Web UI | Proxied from `app.opencode.ai` at runtime | Built from source, served locally |
| Provider | `opencode` auto-loads with `apiKey: "public"` | `opencode` provider disabled via `disabled_providers` |
| Model | (none) | `github-copilot/claude-opus-4.6` |
| Small model | Falls back to provider's priority list | `github-copilot/gpt-4.1` |
| Share | `enabled` | `disabled` |
| Network | Unrestricted | Sandbox allowlist (no `*.opencode.ai`) |
