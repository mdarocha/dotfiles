---
name: nix-inline-single-use-let
description: "Inline Nix let bindings that are used only once"
condition:
  - "(?m)\\blet\\b"
  - "(?m)^[ \\t]*[A-Za-z_][\\w'-]*[ \\t]*="
question: >-
  Answer yes only if this edit adds or keeps a `let` binding whose name is referenced exactly once in its
  scope and could be inlined at that use without hurting readability. Answer no when the name is used two or
  more times, when the binding is only `inherit` or a function argument, when the edit has no `let` binding
  at all (plain attrset or option assignments), or when the value is a long multi-line expression that
  would end up deeply nested at its one use. When unsure, answer no.
scope: ["tool:edit", "tool:write", "tool:ast_edit"]
interruptMode: never
globs:
  - "*.nix"
---

You added or kept a `let` binding in a Nix file that is used only once. Inline the value at its
single use and drop the binding. Move any comment that explains the value along with it.

Keep a binding only when the name is used two or more times, or when inlining would bury a long
multi-line value deep inside another expression. That exception is rare. If the `let ... in`
block ends up empty, remove it.

Do this now, in the same turn, and leave the surrounding code as it was.
