# Static Analysis Checklist — Reference

Companion to the `overall-review` skill. Items here are the ones that tooling often misses or only partially detects — a human reviewer (or the review agent) must still verify.

## Complexity

### Cyclomatic complexity

Count the branches in each function (each `if`, `else`, `case`, `&&`, `||`, ternary, loop, and exception handler adds one). More than ~10 is a maintenance hazard.

**Fix:** extract conditionals into named helpers. Replace deeply nested conditionals with guard clauses / early returns.

### Nesting depth

No more than 3 levels of block nesting inside a single function. Deeper nesting is almost always a sign of mixed concerns.

**Fix:** early return on invalid / edge inputs; extract nested loops to named functions.

### Function size

More than ~20 lines is a smell. More than ~50 lines almost always hides multiple responsibilities.

**Fix:** extract. A function should fit on one screen without scrolling.

---

## Coupling and cohesion

### Import direction

Imports should respect the project's layering rules. Typical layers (from low to high): data → domain → presentation. Reverse imports (presentation imported by domain) indicate a boundary violation.

**Detection:** grep the diff for imports. Verify each crosses at most one layer and in the allowed direction.

### Module cohesion

Each module's exports should tell a single story. A module exporting a mix of unrelated utilities ("helpers") is a symptom of poor placement.

### Cross-module reach

Avoid reaching into another module's internals via path imports that bypass its public API.

---

## Dead code

### Unreferenced exports

If an export has no importer, either it is used by a test only (acceptable) or it is dead (delete).

**Detection:** tools differ per ecosystem, but a grep for the export name across the repo is a cheap fallback.

### Unreachable branches

A condition that can never be true (e.g., after a type narrow), a case after a `throw`, or a fall-through in an exhaustive switch.

### Disabled tests

Skipped tests, commented-out tests, or tests gated behind an always-false condition. Delete or fix — never leave.

### Commented-out code

Delete. The commit history is the archive.

---

## Error handling

### Empty catches

An empty `catch` / `rescue` / `except` block silently drops errors. Either the error is truly benign and should be logged, or it must propagate.

### Re-wrapping without context

Catching an error and re-throwing a different error without adding context or preserving the cause erases information needed for debugging.

### Mixing error styles in one codebase

If the surrounding code uses exceptions, a new function that returns an `Option` / `Result` / null introduces inconsistency. Match what exists.

### Error as happy path

Do not use exceptions for normal flow control (e.g., "throw NotFound, catch, return default"). Reserve errors for exceptional conditions.

---

## Side effects

### Side effects in constructors / module-level code

Code that runs at import time (DB connection, HTTP call, file I/O) makes the module untestable and creates startup-order bugs. Move to an explicit `init()` / `connect()` function.

### Hidden state

A function that reads or writes module-level mutable state is much harder to reason about than a pure function. Pass state explicitly when possible.

### Global singletons

Prefer dependency injection. If you must have a global, document it and restrict mutation to one place.

---

## Concurrency and performance

### N+1 queries

A loop that issues a database or HTTP query per iteration. Batch, join, or prefetch.

### Unbounded growth

A list / map / buffer that grows on each iteration without a bound in a long-running process leaks memory.

### Blocking I/O on hot paths

Synchronous I/O in request handlers, render loops, or UI threads causes latency spikes. Move to async / background.

### Race conditions

Any check-then-act pattern (read state, decide, write state) across concurrent actors needs a lock, a transaction, or an atomic operation.

---

## Type and contract discipline

### Over-broad types

Parameters or returns typed as language's universal "any-ish" type erase information the caller needs. Narrow to specific types / unions.

### Boolean parameter soup

Multiple boolean parameters (`doThing(true, false, true)`) make call sites unreadable. Replace with a named-parameters object or explicit tagged unions.

### Stringly-typed data

Passing a domain concept as a raw string (`"pending"`, `"approved"`) loses type safety. Prefer enums / tagged unions.

### Optional chains hiding real bugs

Long chains of optional operators (`a?.b?.c?.d`) often indicate that the type should be narrowed earlier. Distinguish "genuinely optional" from "we forgot to handle this."

---

## Readability

### Meaningful names

Identifiers that require a comment to explain are badly named. Rename the identifier; delete the comment.

### Magic numbers and strings

Any non-obvious literal deserves a named constant with a comment stating *why* that value.

### Comment hygiene

Remove comments that restate the code. Keep only comments that explain non-obvious *why* — constraints, invariants, references to external specs or incidents.

### Dead `TODO` / `FIXME`

If you are writing a TODO, file an issue now and reference it. A bare TODO rots into permanent noise.

---

## Review heuristic

Go through the diff three times:

1. **Correctness pass** — does it do what the test says?
2. **Contract pass** — are boundaries, errors, and side effects handled explicitly?
3. **Readability pass** — could a stranger, six months from now, understand this?

If all three pass cleanly, the static-analysis part of the review is done.
