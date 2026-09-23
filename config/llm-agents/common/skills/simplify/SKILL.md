---
name: simplify
description: Simplifies the current changes for reuse, clarity, efficiency, and appropriate abstraction without changing behavior. Use when asked to simplify, clean up, tidy, refactor, reduce duplication, or polish a diff before committing.
---

# Simplify current changes

Review the current diff and directly affected code for implementation quality. Keep
correctness, security, and feature review out of scope.

## Scope

Use the working-tree diff, including staged changes, to establish scope. Follow nearby
callers or shared helpers only when needed to simplify the changed implementation. Do
not turn a local cleanup into an unrelated refactor.

## Review

Look for:

- Existing helpers, utilities, or established patterns that make new code unnecessary.
- Redundant control flow, nesting, state, comments, imports, or abstractions.
- Clear waste such as repeated work, avoidable allocation, or unnecessarily broad data
  handling, when removing it keeps the code readable.
- Code at the wrong abstraction level: consolidate truly repeated logic, or make a
  single-use generic layer concrete.

Prefer the simplest approach that fits surrounding conventions. Retain abstractions only
when current code needs them.

## Apply

Make behavior-preserving edits directly and follow the repository's style and patterns.
Leave behavior changes and ambiguous design trade-offs for the user.

## Check and report

Inspect the final diff for unintended scope or behavior changes. Run the narrowest
repository-supported formatter, type check, test, or smoke check relevant to the edits;
do not run broad validation merely for a cleanup pass. Summarize the improvements and
any intentionally deferred trade-off.
