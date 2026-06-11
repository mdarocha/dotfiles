---
name: verify
description: Verify that a code change actually does what it's supposed to by running the program and observing real behavior. Use when asked to verify a change, confirm a fix works, test something manually, check that a feature works, reproduce a bug, or validate local changes before committing or pushing. Triggers include "verify this", "does this actually work", "confirm the fix", "test it for real", "make sure it works", or any request to validate behavior rather than just read code.
---

# Verify a change by running it

Confirm a change does what it is supposed to by **exercising the real code path and
observing the actual behavior** — not by reading the diff, trusting the tests, or
reasoning about what *should* happen. A change is only verified once you have seen it
work with your own eyes (output, logs, exit code, UI, network response, etc.).

> This skill is about behavioral confirmation. If you only need to find bugs by reading
> code, that is a different task. If you only need to clean up code quality, use `simplify`.

## Step 1: Establish the expected behavior

Before running anything, pin down what "working" means:

- What is the change supposed to do? Read the diff, the task description, the issue/PR.
- What is the **observable** signal of success? A printed value, an HTTP 200, a file
  written, a passing assertion, a button that now responds, a log line, a changed exit code.
- What would failure look like? Know this so you don't mistake a silent no-op for success.

If the intended behavior is ambiguous, ask the user rather than guessing what to verify.

## Step 2: Find how to exercise the code path

Figure out the smallest, most direct way to trigger the changed behavior:

```bash
git diff                     # what actually changed
git diff --stat              # which files / surface area
git log --oneline -10        # recent context
```

Then pick the narrowest reproduction:

- **Library/function** — call it directly from a REPL, a one-off script, or a focused test.
- **CLI** — run the actual command with realistic arguments.
- **Server/service** — start it (see note below), then hit the relevant endpoint.
- **UI** — launch the app and drive the specific interaction that changed.

Prefer the real entry point over a mock. The point is to catch what tests miss.

> **Sandbox note:** if the task needs a running service (dev server, DB, test server),
> **start it yourself** in the current shell session. You cannot rely on the user starting
> it, and `localhost` inside the sandbox does not reach the host. Use `run-with-nix` if a
> required tool isn't installed.

## Step 3: Run it and observe

Run the reproduction and capture concrete evidence:

- Capture stdout/stderr, exit codes, response bodies, log output, or screenshots.
- Compare what you observed against the expected signal from Step 1 — explicitly.
- Exercise the failure/edge path too when feasible (bad input, empty case, error branch),
  not just the happy path.

If the project has a relevant automated test, run it as **corroboration** — but a green
test alone is not verification when the behavior can be observed directly.

## Step 4: Report honestly

State plainly what you did and what you saw:

- **Verified** — show the evidence (the command, the output, the observed result) and say
  it works. No hedging.
- **Not verified / failed** — show the actual output, describe the gap between expected and
  observed, and stop. Do not paper over a failure or claim success you didn't witness.
- **Couldn't verify** — if you were unable to exercise the path (missing dependency, no way
  to reproduce, needs credentials), say so directly and explain what's blocking it.

Never report a change as working unless you actually observed it working.
