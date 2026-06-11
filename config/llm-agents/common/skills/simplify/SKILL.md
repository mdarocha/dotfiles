---
name: simplify
description: Review the changed code for reuse, simplification, efficiency, and altitude improvements, then apply the fixes. Quality only — it does not hunt for correctness bugs. Use when asked to simplify, clean up, tidy, refactor, or polish the current changes, or to reduce duplication and dead complexity before committing. Triggers include "simplify this", "clean this up", "can this be simpler", "tidy the diff", "reduce duplication", or "polish before I commit".
---

# Simplify the current changes

Review the code changed in this session and improve its **quality**, then apply the
improvements directly. This is a cleanup pass, not a bug hunt — do not go looking for
correctness defects (use a dedicated review/verify pass for that). Preserve behavior.

## Scope

Limit the review to what changed, plus the immediate code it touches:

```bash
git diff                     # unstaged changes
git diff --staged            # staged changes
git diff --stat              # surface area at a glance
```

Do not refactor unrelated code or expand the blast radius. Every edit should make the
*current* change cleaner, not kick off a wider rewrite.

## What to look for

Evaluate the changed code against four lenses:

1. **Reuse** — Is this reimplementing something that already exists? Look for an existing
   helper, utility, library function, or pattern in the codebase that does the same job.
   Don't reinvent; call the thing that's already there.

2. **Simplification** — Can the same result be expressed more plainly?
   - Collapse redundant branches, flatten needless nesting, remove dead code and unused
     variables/imports.
   - Replace a manual loop with a clear standard-library construct where it reads better.
   - Drop premature abstraction (an interface/wrapper/config knob with a single caller).
   - Remove comments that just restate the code.

3. **Efficiency** — Fix clearly wasteful work without micro-optimizing: redundant
   recomputation, repeated lookups in a loop, an O(n²) pattern over a hot path, fetching
   or allocating more than needed. Only when it doesn't hurt readability.

4. **Altitude** — Is the code at the right level of abstraction? Pull repeated logic up
   into one place; push overly-generic machinery down to the one concrete case that needs
   it. Match the abstraction level of the surrounding code.

## How to apply

- Make the edits directly. Match the surrounding code's style, naming, and idioms — the
  result should read like the existing code, not like a different author.
- **Behavior must stay identical.** If a change would alter behavior, that's out of scope
  for this skill — note it for the user instead of applying it.
- Group related cleanups; don't leave the tree half-refactored.
- If a suggested change is genuinely ambiguous or a judgment call (e.g. a trade-off between
  brevity and clarity), surface it to the user rather than forcing it.

## After applying

- Re-read the resulting diff to confirm it's coherent and behavior-preserving.
- Run the project's formatter/linter and a quick build or test if available, so the cleanup
  doesn't leave the tree broken.
- Briefly summarize what you changed and why, grouped by the lens (reuse / simplification /
  efficiency / altitude). Note anything you deliberately left alone.
