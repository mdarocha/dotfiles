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
  git/gh permissions, skill invocation controls, and MCP integrations.

- **Copilot CLI** (`copilot-cli/`) — sandbox wrapper around `copilot`.

- **oh-my-pi** (`oh-my-pi/`) — sandbox wrapper around `omp` from [oh-my-pi][omp].

[srt]: https://github.com/anthropic-experimental/sandbox-runtime
[oc]: https://github.com/anomalyco/opencode
[omp]: https://github.com/can1357/oh-my-pi

## Patches

### sandbox-runtime (`sandbox/patches/`)

| Patch | Why |
|---|---|
| `srt-implement-allowlocalbinding-linux` | `allowLocalBinding` is macOS-only. Adds a reverse socat bridge so sandbox-bound ports are reachable from the host on Linux. |
| `srt-fix-dangerous-files-paths` | Resolves home-only `DANGEROUS_FILES` to `$HOME`. CWD files use `git check-ignore`: gitignored paths always denied; tracked paths denied only when they exist. |

### opencode (`opencode/patches/`)

| Patch | Why |
|---|---|
| `opencode-merge-plugin-auth-hooks` | Plugin auth hooks were last-wins per provider. Merges hooks so a plugin that adds only a loader doesn't clobber login methods registered by an earlier plugin (e.g. the built-in). |
| `opencode-skill-invocation-context` | When a skill is invoked via slash command, prepends a short header so the model understands the invocation was explicitly requested by the user. |
| `opencode-skill-invocation-control` | Adds `user-invocable` and `disable-model-invocation` frontmatter fields to skills. `user-invocable: false` hides the skill from slash commands and the UI; `disable-model-invocation: true` prevents the model from calling it as a tool directly. |

### opencode config vs. upstream defaults

| Setting | Upstream | This module |
|---|---|---|
| Web UI | Proxied from `app.opencode.ai` | Proxied from `app.opencode.ai` (local build broken, temporarily disabled) |
| Provider | `opencode` with `apiKey: "public"` | `opencode` provider disabled |
| Model | (none) | `github-copilot/claude-sonnet-4.6` |
| Small model | Provider's priority list | `github-copilot/gpt-5-mini` |
| Share | `enabled` | `disabled` |
| Network | Unrestricted | Sandbox allowlist (no `*.opencode.ai`) |
