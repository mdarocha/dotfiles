## Missing CLI tools

If a tool you need is not on PATH, do not install it into the user profile —
run it temporarily with `nix run nixpkgs#<package>` or
`nix shell nixpkgs#<package>` instead (see the `run-with-nix` skill).

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
- Inline variables used in only one place. Keep a named binding only when
  it's reused or when the expression would be hard to read inline.
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
