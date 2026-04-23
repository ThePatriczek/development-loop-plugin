---
name: tdd-review
description: This skill should be used when the development-loop state file has `phase: tdd-review`, or when the user says "review the tests", "tdd review phase", "audit test quality". Lightweight QA skill that verifies the RED→GREEN cycle produced a test with real value before entering implementation. Audited by an agent-type hook via the `tdd-review-agent`.
---

# TDD REVIEW Phase

**Entry condition:** `phase: tdd-review`, tdd-red and tdd-green completed, test passes.
**Exit condition:** The test asserts observable behavior at the right level, fails for the right reason when reverted, and is the minimum needed. `tdd_review_passed: true` set in state.

## Hard rules

- **Behavior, not implementation.** A test that mocks everything and asserts on internal calls has no value — send back to tdd-red to rewrite.
- **Real failure.** The test must demonstrably fail when the behavior is absent. "I ran it red once" is not enough — verify now by temporarily commenting out the change and re-running.
- **One behavior per test.** Multiple unrelated assertions → split.

## Checklist

### 1. Test level

- [ ] The test level matches the goal — unit for pure logic, integration for module contracts, E2E only for a critical user flow.
- [ ] The test is NOT at a higher level than necessary (no E2E where integration would do, no integration where unit would do). Cheaper is better.

### 2. Naming

- [ ] Test name reads as a sentence describing the behavior, not the mechanism. A reader should predict what the test asserts without reading the body.

### 3. Inputs

- [ ] Inputs are realistic — resemble actual usage, not placeholder values like `foo`, `bar`, `42` without meaning.
- [ ] Inputs exercise the behavior that matters, not edge cases for later loops.

### 4. Assertions

- [ ] Assertions target observable outcomes — return values, visible state, emitted events — not private method calls or implementation details.
- [ ] One logical assertion per test (multiple syntactic `expect` lines are fine when checking the same behavior).

### 5. Real failure verification

- [ ] Temporarily revert the production code change. Re-run the test. Confirm it fails with a message that clearly reports the missing behavior (not an import error, not a syntax error).
- [ ] Restore the production code.
- [ ] Re-run the affected suite. All green.

### 6. Mocking discipline

- [ ] Mocks are used only to isolate the unit under test from genuinely external side effects (network, filesystem, time).
- [ ] No "mock everything until it passes" — the test must exercise real logic.

## Decision

- All items pass → set `tdd_review_passed: true`; `/development-loop next` enters `implementation`.
- Any item fails → record the finding; loop back to `tdd-red` to fix or rewrite the test.

## Red flags

- Test passes on first run with no production change — it tests nothing.
- Test name uses the function name or file name as the subject.
- Assertions on spies / private methods instead of outputs.
- Inputs are all zeros / "foo" / placeholder with no semantic meaning.
- A unit test that secretly hits the network / filesystem / database.
