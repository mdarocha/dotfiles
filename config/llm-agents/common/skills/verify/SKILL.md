---
name: verify
description: Run a changed program or feature and confirm its observable behavior. Use for requests to verify a change, confirm a fix, manually test a feature, reproduce a bug, or validate local changes before committing or pushing. Code review and test-only validation are separate tasks.
---

# Verify behavior by running the changed path

Verify behavior by exercising the relevant code path and observing its result. A diff review or automated test may provide useful context, but direct observation is the evidence for this skill.

## 1. Define the check

- Identify the intended behavior from the task and relevant change.
- Choose a concrete success signal and the corresponding failure signal: output, exit status, response, persisted state, log, or UI result.
- Resolve a genuinely ambiguous expected outcome before treating it as verified.

## 2. Exercise the smallest real path

Choose the narrowest realistic reproduction:

- Call a library function directly with a small script or REPL.
- Run the CLI with representative arguments.
- Start a service and make the relevant request.
- Launch the UI and perform the changed interaction.

Prefer the real entry point over mocks. Start any required local service in the current environment; select available tools and project conventions rather than assuming a particular runner or package manager.

## 3. Observe and compare

Capture output, exit code, response, state, logs, or a screenshot, then compare it to the defined signal. Exercise a meaningful error or boundary case when practical and relevant. Run a focused automated test as corroboration when one exists; direct observation remains necessary when the behavior can be exercised directly.

## 4. Report the outcome

- For a verified result, state the reproduction, evidence, and behavior confirmed.
- For a failed result, provide the actual result and the difference from expectation. Do not claim success.
- If verification is blocked, name the path and concrete prerequisite, such as unavailable credentials, dependency, or reproducible input.
