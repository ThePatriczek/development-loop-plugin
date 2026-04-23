---
name: implementation-review
description: This skill should be used when the development-loop state file has `phase: implementation-review`, or when the user says "review implementation", "implementation review phase", "audit the diff of this slice". Lightweight QA skill that verifies implementation is tight, convention-following, and scope-disciplined before entering refactor. Audited by an agent-type hook via the `implementation-review-agent`.
---

# IMPLEMENTATION REVIEW Phase

**Entry condition:** `phase: implementation-review`, implementation complete, tests green.
**Exit condition:** Diff is tight, conventions followed, zero scope creep, no speculative code, no debug remnants. `implementation_review_passed: true` set in state.

## Hard rules

- **Tight diff only.** Every added / changed line earns its place. If you can delete it without breaking the test, delete it.
- **No scope creep.** Unrelated edits belong in a new loop — they do not pass this review.
- **No speculation.** Parameters, options, abstractions, or branches not exercised by the test are removed.

## Checklist

### 1. Convention conformity

- [ ] Code matches the style and structure of the nearest existing file of the same kind — naming, imports order, error handling, layout.
- [ ] No new pattern introduced where an existing one would have worked.
- [ ] Error-handling style matches the surrounding code (same "throw vs return" discipline, same wrapping convention).

### 2. Scope discipline

- [ ] Every changed file is required for the slice's acceptance criterion.
- [ ] No files touched that the slice does not need.
- [ ] Any drive-by refactor, rename, or "while I'm here" cleanup is reverted and recorded as a non-blocking finding for a separate loop.

### 3. Dead weight

- [ ] Parameters added but unused → remove.
- [ ] Helpers extracted with a single call site → inline.
- [ ] Abstractions / interfaces / types with a single implementor → delete.
- [ ] Branches / options not exercised by any test → delete.

### 4. Code quality

- [ ] Names reveal intent without surrounding context.
- [ ] No function longer than ~20 lines or doing more than one thing.
- [ ] No magic numbers — named constant for anything non-obvious.
- [ ] No commented-out blocks, no unreachable branches, no `TODO` / `FIXME` that wasn't deliberately filed.
- [ ] Comments explain **why**, not **what** — delete comments that restate code.

### 5. Safety signals

- [ ] Zero new compiler / type-checker / linter warnings produced by this diff (silencing a warning is a red flag — fix root cause).
- [ ] No debug prints, debugger statements, or verbose logging left behind.
- [ ] Tests still green — run the affected suite one more time.

## Decision

- All items pass → set `implementation_review_passed: true`; `/development-loop next` enters `refactor`.
- Any item fails → record the finding; loop back to `implementation` to fix.

## Red flags

- A test was modified during implementation without going back to `tdd-red`.
- New dependency added to avoid writing a small amount of code.
- Swallowed errors (empty `catch`, `ignore`, silent `rescue`).
- Console / debug output left behind.
- Mixed refactor + feature change — separate them.
