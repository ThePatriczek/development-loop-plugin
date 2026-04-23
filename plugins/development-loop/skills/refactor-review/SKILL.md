---
name: refactor-review
description: This skill should be used when the development-loop state file has `phase: refactor-review`, or when the user says "review the refactor", "refactor review phase", "audit the structural changes". Lightweight QA skill that verifies the refactor phase improved structure without expanding scope or introducing behavior changes. Audited by an agent-type hook via the `refactor-review-agent`.
---

# REFACTOR REVIEW Phase

**Entry condition:** `phase: refactor-review`, refactor phase complete, tests green.
**Exit condition:** Refactor is scoped to this change only, tests still green, no behavior changes sneaked in, code actually clearer than before. `refactor_review_passed: true` set in state.

## Hard rules

- **Scope = this change.** Any file touched by the refactor must have been touched by the implementation. Files touched only during refactor → revert, defer to a separate loop.
- **Zero behavior change.** If the test results differ before / after refactor (different assertions passing), it's a behavior change — back to `tdd-red` with a new test.
- **Refactor must improve clarity.** If the diff produced the same behavior with equivalent or worse clarity, revert.

## Checklist

### 1. Scope

- [ ] Every file changed in the refactor was also changed in the implementation.
- [ ] No "while I'm here" refactors of unrelated code.
- [ ] No new behavior. Diff the behavioral surface — public APIs, return types, side effects — and confirm identical.

### 2. Test integrity

- [ ] Tests were re-run after each refactor micro-step, not just at the end.
- [ ] No tests were skipped, commented out, or loosened to accommodate the refactor.
- [ ] The full affected suite is green right now.

### 3. Actual improvement

- [ ] Renames track real meaning drift — the new names describe what the code now does, not what it used to do.
- [ ] Extractions correspond to a real second call site (Rule of Three satisfied).
- [ ] Shrunk functions / flattened nesting make the diff more readable, not merely different.
- [ ] Tightened types (where applicable) capture real constraints, not speculative ones.
- [ ] Removed helpers / abstractions ended up single-use.

### 4. Clean-code post-refactor sweep

- [ ] No comments restating what the refactored code does.
- [ ] No dead code introduced by partial renames.
- [ ] Import / module structure still respects the project's layering rules.

## Decision

- All items pass → set `refactor_review_passed: true`; `/development-loop next` enters `overall-review`.
- Any item fails → record the finding; loop back to `refactor` to fix or revert.

## Red flags

- A refactor that "improves consistency" without making any concrete reading easier.
- An extraction made in anticipation of a future call site that doesn't exist yet.
- Generic type parameters introduced "for future use."
- A rename that touches unrelated files.
- Skipped tests after the refactor.
