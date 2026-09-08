---
description: Audit Nix-managed config files against their live, tool-edited state and .backup snapshots; propose repo updates for durable drift, then commit approved changes to main.
---

# Managed configuration audit

Some config files are owned by the tool's own UI and only deep-merged with Nix
defaults — see `modules/managed-config/default.nix` (the
`mdarocha.managedConfigFiles` option) and `modules/managed-config/config-merge.nix`
(merge/backup logic). Those files drift at runtime: the tool writes settings
Nix never declared. This audit finds that drift and, with approval, folds
anything durable back into the repo. It also checks the repo's own declared
values against the tool's current schema, since a setting can go stale even
with no runtime drift at all — the tool renamed or removed it upstream and is
now silently ignoring what the repo declares.

Driven by evaluating the flake itself, not a hardcoded tool list — new
`mdarocha.managedConfigFiles` entries added by future modules are audited
automatically.

If a directory referenced below (e.g. a `configDir`) isn't accessible, check
whether you're running in a sandbox and, if so, ask the user to disable it —
managed config lives under the real `$HOME`, not a sandboxed one.

Argument (optional): `$1` — a single `mdarocha.managedConfigFiles` entry name
to scope the audit to. Blank means audit every entry.

## Phase 0 — resolve the active configuration

```bash
source scripts/lib.sh
CONFIGURATION="$(detect_configuration)"
export CONFIGURATION
```

Same detection `nix run .#apply` uses. Trust it over guessing from hostname/env.

## Phase 1 — discover managed entries

```bash
nix eval --json ".#homeConfigurations.$CONFIGURATION.config.mdarocha.managedConfigFiles"
```

Returns `{ <entry>: { configDir, fileName, format, label, value }, ... }`.
`configDir` is a literal string that may contain a `$HOME` token — expand it
against the real `$HOME`. If `$1` was given, keep only that entry.

Discover the real backup suffix instead of assuming `"backup"`:

```bash
grep -n 'HOME_MANAGER_BACKUP_EXT' flake-modules/apps.nix modules/managed-config/default.nix
```

## Phase 2 — three-way comparison per entry

For every entry whose `$configDir/$fileName` exists on disk, load three states:

- **repo** — the entry's `value` from Phase 1 (what the next `nix run .#apply`
  would write).
- **current** — `$configDir/$fileName` right now. Parse with `jq` (json /
  json-array format) or `yq -o=json` (yaml format).
- **backup** — `$configDir/$fileName.<suffix>`, if present: content
  immediately before the _last_ activation ran.

Reconcile at the same top-level-key granularity
`modules/managed-config/config-merge.nix`'s `_config_diff_warn` uses:

- keys present in `current`/`backup` but absent from `repo` → the tool wrote
  these itself; never declared in Nix.
- keys present in both `repo` and `backup` with different values → the last
  apply overwrote a locally-edited value. Check whether `current` has since
  drifted from `repo` again at that key — a strong signal the user keeps
  re-setting it, not one-off noise.

`format = "json-array"` entries are replaced wholesale, not merged, so only
compare `backup` (or `current`, they're equal) against `repo` as whole lists.

Skip an entry with no on-disk file or no backup yet — nothing to compare.

## Phase 3 — decide what's worth adopting

- Skip secrets, tokens, credentials, session ids, cache paths, timestamps, or
  other locally-generated/ephemeral state — never propose committing those.
- Skip anything plausibly specific to this one machine or `$CONFIGURATION`
  variant rather than a general preference.
- Keep candidates that look like a deliberate, durable preference set through
  the tool's own settings UI.
- Exclude keys that are set to their default values in the tool's own defaults. Prefer an authoritative lookup over guessing:
    - If the tool has an introspection CLI (e.g. `omp config list --json`), get the _built-in_ defaults by running it against an empty/isolated config dir rather than the user's own (e.g. `PI_CODING_AGENT_DIR=$(mktemp -d) omp config list --json`) — this sidesteps the user's already-applied repo config entirely.
    - Otherwise, fetch the tool's shipped default settings file straight from its upstream repo (e.g. Zed's `assets/settings/default.json` on GitHub) and grep it directly before reaching for web search.
    - Only fall back to web search/docs for keys not present in either source (e.g. settings delegated to an underlying LSP server rather than the editor itself) — and if the default still can't be confirmed, exclude the key rather than guess.
    - Before checking any of this, skip a key outright if a prior audit already recorded a decision for it — see the "recording decisions" step below.

## Phase 4 — check the repo's own declared values for obsolete/removed keys

Independent of runtime drift: check every key in each entry's Phase 1 `value`
against what the tool's *currently pinned* version actually still accepts.
Renamed or removed settings are typically ignored silently, not rejected, so
this needs an explicit schema check rather than diffing live files.

1. Resolve the exact version this flake deploys before consulting any schema
   — never check against a tool's `main`/latest branch:
   - Packaged via its own flake input: read that input's locked `rev` from
     `flake.lock`, then read the packaging repo's own version-pin file at
     that exact commit (e.g. `numtide/llm-agents.nix`'s
     `packages/omp/hashes.json` gives the upstream `oh-my-pi` tag/version).
   - Packaged from nixpkgs: use `nodes.nixpkgs.locked.rev` from `flake.lock`
     and read the derivation's `version`/`src.rev` at that revision.
2. Fetch the schema/reference sources for that exact version — see the table
   below.
3. Flag any repo-declared key path the schema no longer defines. Before
   proposing it obsolete, search the schema for an equivalent setting under a
   different path/name — renames usually keep the same value set (grep the
   old value among the candidates' enum options, not just the key name).
4. An unrecognized key is a defect, not a preference: apply the fix directly
   in Phase 6 without routing it through Phase 5's `ask` gate, unless the
   replacement value is genuinely ambiguous — then ask like any other
   candidate. Report what was renamed/removed and its replacement in the
   final summary either way.

### Schema sources by tool

Prefer a GitHub-versioned/commit-pinned machine-readable source over docs,
and docs over running the actual binary. Extend this table when a new
`managedConfigFiles` entry is added for a tool not yet listed here.

**Zed editor** (`zed-settings`, `zed-keymap` entries)

- No committed or fetchable JSON Schema exists: settings/keymap schemas are
  generated at runtime from Rust structs plus installed fonts/themes/
  languages, and `zed://schemas/...` is an internal URI, not a fetchable URL.
  Tracked upstream request to publish one: zed-industries/zed#52880 (open).
- Primary reference: `docs/src/reference/all-settings.md` at the pinned
  commit — exhaustive per-key prose with types, defaults, and options.
  `https://raw.githubusercontent.com/zed-industries/zed/<rev>/docs/src/reference/all-settings.md`
- Cross-check: `assets/settings/default.json` at the pinned commit for exact
  default values.
  `https://raw.githubusercontent.com/zed-industries/zed/<rev>/assets/settings/default.json`
  Absence from this file does not by itself mean a key is invalid — many
  valid keys are `Option<T>` with no default and simply don't appear here.
- Ground truth when the docs page is ambiguous or a key isn't found there:
  the `crates/settings_content/src/*.rs` structs (`#[derive(... JsonSchema
  ...)]`) at the pinned commit, e.g. `crates/settings_content/src/agent.rs`,
  `.../theme.rs`, `.../language.rs`. Search GitHub code search scoped to
  `zed-industries/zed` for the struct/field name.
- Keymap actions: default bindings per platform live in
  `assets/keymaps/default-{linux,macos,windows}.json` and
  `assets/keymaps/{linux,macos}/vscode.json` (relevant when `base_keymap`
  overrides apply). Action registrations live in each crate's
  `actions!`/`#[action(namespace = ...)]` macros — search for the action
  name there if it's absent from every default keymap file.
- Last resort (binary execution): `cargo run -p schema_generator --
  theme|icon_theme` inside a Zed checkout generates the theme/icon-theme
  picker schemas only. It does not cover settings or keymap — those need the
  full running app's in-process JSON language server, which isn't practical
  to script.

**oh-my-pi / omp** (`oh-my-pi-config` entry)

- Upstream source is `github.com/can1357/oh-my-pi` (npm:
  `@oh-my-pi/pi-coding-agent`), packaged by the `llm-agents` flake input
  (`numtide/llm-agents.nix`) — resolve the deployed version from
  `packages/omp/hashes.json` at the `llm-agents` input's locked commit (see
  step 1 above), not from `main`.
- No standalone JSON Schema file exists for `config.yml`. Primary reference:
  `packages/coding-agent/src/config/settings-schema.ts` at the exact release
  tag —
  `https://raw.githubusercontent.com/can1357/oh-my-pi/v<version>/packages/coding-agent/src/config/settings-schema.ts`.
  This is the tool's own documented single source of truth: every setting
  path, type, default, and — for enums — the full valid `values` list.
- Docs cross-check at the same tag: `docs/settings.md`,
  `docs/config-usage.md`.
- Last resort (binary execution): `omp config list --json` (optionally
  against an isolated `PI_CODING_AGENT_DIR`, per Phase 3 above) lists
  effective values/types/descriptions, but omits defaults and enum choices —
  useful for confirming a key still resolves at runtime, not for enumerating
  valid values.

## Phase 5 — ask before touching anything

For every surviving drift candidate from Phase 3, use the `ask` tool (batch
related ones) showing: entry label, key path, current repo value, proposed
new value, and which file you'd edit. Unanswered/declined candidates stay
untouched.

Non-interactive/headless sessions have no `ask` tool available: present the
same information (entry label, key path, current repo value, proposed value,
target file) in the chat reply instead, batched into one list, and treat the
user's next reply as the answers.

## Phase 6 — apply approved changes

1. Locate the Nix definition site by grepping for the entry name/label inside
   `config/` (e.g. `grep -rn "<entry-name>" config/`) rather than assuming a
   path.
2. Edit the base/default value there, not a machine-specific override option
   (e.g. `cfg.oh-my-pi.settings`), unless the change is genuinely
   machine-specific — then target the right `homeConfigurations.<name>`
   module argument instead.
3. Re-run the Phase 1 `nix eval` for the changed entry and confirm the new
   `value` matches what was approved.

4. For every candidate the user declined or asked to leave unmanaged, append
   a line to the comment block at the bottom of the file you would have
   edited:

    ```nix
    # managed-config audit decisions (see .omp/commands/managed-config-audit.md)
    # ignore comment-slop rules for this block: these decisions must be recorded
    # in comments to survive across machines and agent sessions.
    # - <key path>: intentionally left unmanaged; skip in future audits.
    ```

    Keep one such block per file, appending new lines to it rather than
    duplicating the header. Future audits must check this block before
    re-flagging a key — treat it the same as a declined candidate and skip it
    without re-asking. This block is a deliberate, user-approved exception to
    the repo's comment-slop/minimal-comments rules — it is the only place
    these decisions survive across machines and agent sessions, so keep the
    "ignore comment-slop rules" line intact when appending.

## Phase 7 — commit to main

Follow `skill://commit` for staging/message conventions. User-invoked, so
committing is expected without asking again — but confirm
`git branch --show-current` is `main` first; this workflow only touches
`config/`, so switching to `main` should be safe. Stop and ask if `main`
isn't checked out and the working tree has unrelated pending changes. Do not
push.
