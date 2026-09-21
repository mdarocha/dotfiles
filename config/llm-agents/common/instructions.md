## Missing CLI tools

If a tool you need is not on PATH, do not install it into the user profile —
run it temporarily with `nix run nixpkgs#<package>` or
`nix shell nixpkgs#<package>` instead (see the `run-with-nix` skill).

## Git LFS

Do **not** run `git lfs install`: LFS filters are already configured
globally (`filter.lfs.*` in `~/.config/git/config`, provisioned by
home-manager's `programs.git.lfs.enable`), `add`/`commit`/`push`/`checkout` already
smudge/clean LFS-tracked files correctly without any per-repo
`.git/config` entries. `git-lfs` itself is on `$PATH`.

## Browser GPU acceleration

Some tasks (ie. WebGL rendering, in-browser ML) REQUIRE GPU acceleration in the browser, since they are too
slow without it.

Confirm the actual GPU backend via `chrome://gpu`'s "Graphics Feature Status"
and `GPU0` fields, not `WEBGL_debug_renderer_info` / `navigator.userAgent` —
the browser tool spoofs those for fingerprinting resistance regardless of the
real backend.

GPU availability depends on whether: (1) the required /dev/dri is currently available
(it can be unavailable if the current machine has no GPU), (2) the browser is not
running in "headless" mode.

If Chromium is running headless but the task genuinely needs GPU-backed
rendering (e.g. WebGL correctness, GPU compute), headless mode cannot provide
it — ask the user to switch the browser tool to visible/non-headless mode and
relaunch it.

## Code search tool selection

When searching for code outside the current project, choose the right tool:
1. **grep MCP** (preferred for public code): Use the `grep` MCP server for searching public code on GitHub.
   It performs fast literal and regex pattern matching across millions of repositories.
   Best for: finding usage examples, API patterns, library idioms, and real-world code snippets.
2. **gh CLI** (for private/org code): Use `gh search code` when results from private or organization
   repositories are needed, since the grep MCP only indexes public code.
   Also useful when you need to scope searches to a specific owner or repository.
3. **codesearch** (fallback): Use the `codesearch` tool when the grep MCP doesn't return good results.
   It uses semantic/neural search (via Exa AI) rather than pattern matching, so it can find
   conceptually relevant code, documentation, and examples even when you don't know the exact syntax.

## Documentation search

Use the **context7 MCP** to fetch current, version-accurate documentation for any library, framework,
SDK, API, CLI tool, or cloud service — including well-known ones like React, Next.js, Prisma, Django,
Spring Boot, or Tailwind. Prefer this over web search for library docs, since your training data may
not reflect recent changes. Use it for: API syntax, configuration, version migration, library-specific
debugging, setup instructions, and CLI tool usage.

## Comments

Prefer clear code to explanatory prose. Keep a comment when it provides information
the code cannot express:

1. a constraint, specification requirement, or business rule that explains *why*,
2. a non-obvious mechanism or edge case a reader cannot infer locally,
3. a workaround, with the issue linked,
4. a public API contract covering behavior, invariants, units, or errors.

Never write restatements of the next line, structural labels (`# imports`,
`# helper`), phase headers (`// Step 1: validate`), decorative separators,
function summaries that repeat the signature, edit history (`// changed from`,
`// now handles`, `// new`), commented-out code, reviewer chatter
(`// as requested`), or doc text that restates a name and type
(`@param id — the id`). Do not mention the current session or development
environment in source comments.

Preserve existing comments unless the change makes them false or redundant.
Place each comment beside the behavior it explains. A previously sparse file may
need more comments when new complexity or hidden constraints justify them; local
density is a signal, not a ceiling.

Keep each comment short and durable. One line is the default; take a second only
when the constraint needs it. Write for a reader who knows the language and this
codebase: state the point and stop. Cut lead-ins, restated context, hedging, and
sentence padding.

## Code style preferences

- Avoid magic numbers and strings: extract recurring or meaningful values
  into named constants or enums. Leave self-explanatory, one-off values
  inline — don't create a constant just to name something obvious. If a
  value comes from an external spec (e.g. HTTP 200), name it regardless.
- Reduce nesting: prefer early return/continue over deeply nested
  conditionals (avoid the arrow anti-pattern).
- Prefer enums over boolean parameters when a function takes more than one
  flag — call sites read better as a named variant than a wall of
  `true`/`false`.
- Give logical blocks of code room to breathe with blank lines; don't cram
  unrelated statements together.
- Keep function names short and descriptive. A name that needs much more
  than ~30 characters is usually a sign to find a better abstraction or
  split the function, not to keep shortening the name.
- Treat visibility changes as a design decision: keep fields and functions
  private unless external access is actually required. Ask before widening
  an access modifier from private to internal/public.
- Encapsulate low-level mechanics (raw I/O, protocol parsing, direct
  socket/DB access) behind a dedicated layer, and expose higher layers a
  clean API in terms of domain concepts rather than implementation
  details. Don't let a caller reach through an abstraction layer to talk
  to what's underneath it directly.
- Always use braces on conditionals and loops, even for single-statement
  bodies.
- When fixing a reported bug, first write a failing test that reproduces
  it, confirm it fails, then write the fix and confirm the test passes.
- Don't touch code unrelated to the change you're making. Minimize the
  number of changed lines — e.g. don't add comments or reformat a block
  you didn't otherwise need to modify.

## Communication style

- In prose meant for a human (chat replies, PR descriptions), use as few
  words as possible — pick each word deliberately rather than padding.
- Skip superlatives and validation ("you're absolutely right", "great
  question"). State the assessment plainly, including when something is
  wrong.

## Long sessions and context dilution

Instructions placed in the middle of a long context get less attention
than those at the start or end (the "lost in the middle" effect), and
code quality can visibly drift as a session grows. If you notice output
drifting from these instructions, re-read this file rather than trying to
course-correct piecemeal. Prefer starting a fresh session per
feature/task over one long session that accumulates unrelated context.
