---
description: Audit Nix-managed config files against their live, tool-edited state and .backup snapshots; propose repo updates for durable drift, then commit approved changes to main.
---

# Managed configuration audit

Some config files are owned by the tool's own UI and only deep-merged with Nix
defaults — see `overlays/hm/managed-config/default.nix` (the
`mdarocha.managedConfigFiles` option) and `overlays/hm/managed-config/config-merge.nix`
(merge/backup logic). Those files drift at runtime: the tool writes settings
Nix never declared. This audit finds that drift and, with approval, folds
anything durable back into the repo.

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
echo "$CONFIGURATION"
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
grep -n 'HOME_MANAGER_BACKUP_EXT' flake-modules/apps.nix overlays/hm/managed-config/default.nix
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
`overlays/hm/managed-config/config-merge.nix`'s `_config_diff_warn` uses:

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

## Phase 4 — ask before touching anything

For every surviving candidate, use the `ask` tool (batch related ones)
showing: entry label, key path, current repo value, proposed new value, and
which file you'd edit. Unanswered/declined candidates stay untouched.

Non-interactive/headless sessions have no `ask` tool available: present the
same information (entry label, key path, current repo value, proposed value,
target file) in the chat reply instead, batched into one list, and treat the
user's next reply as the answers.

## Phase 5 — apply approved changes

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
   a short comment block at the bottom of the file you would have edited:

    ```nix
    # managed-config audit decisions (see .omp/commands/managed-config-audit.md)
    # - <key path>: intentionally left unmanaged; skip in future audits.
    ```

    Keep one such block per file, appending new lines to it rather than
    duplicating the header. Future audits must check this block before
    re-flagging a key — treat it the same as a declined candidate and skip it
    without re-asking.

## Phase 6 — commit to main

Follow `skill://commit` for staging/message conventions. User-invoked, so
committing is expected without asking again — but confirm
`git branch --show-current` is `main` first; this workflow only touches
`config/`, so switching to `main` should be safe. Stop and ask if `main`
isn't checked out and the working tree has unrelated pending changes. Do not
push.
