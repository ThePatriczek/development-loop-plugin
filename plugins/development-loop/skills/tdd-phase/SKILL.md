---
name: tdd-phase
description: This skill should be used when the development-loop state file has `phase: tdd-red` or `phase: tdd-green`, or when the user says "write failing test", "TDD red", "TDD green", "minimum code to green". Enforces the RED → GREEN cycle — failing test first at the right level, minimum implementation to pass, full affected suite green before exit. Automatically loaded by the `development-loop` orchestrator.
---

# TDD Phase — RED → GREEN

**Entry condition:** `phase: tdd-red` (then auto-transition to `tdd-green` after red passes).
**Exit condition (tdd-red):** A test exists and fails for the **expected** reason.
**Exit condition (tdd-green):** The test passes with minimum code; full affected suite is green.

## Hard rules

- **Red first.** No production code before a failing test.
- **Test at the right level.** Unit for pure logic, integration for module boundaries, E2E only for critical user flows.
- **Minimum code to green.** No extras. No "while I'm here."
- **Fail for the right reason.** A test that errors on a missing import is not "red" — it's broken.
- **Hook enforcement.** During `tdd-red`, `Write|Edit|MultiEdit` is blocked on non-test paths. During `tdd-green`, all writes allowed.

## RED checklist (`phase: tdd-red`)

### 1. Pick the test level

- [ ] Unit: pure function, single class, well-defined input/output. Cheapest, fastest.
- [ ] Integration: multiple units collaborating, real dependencies within a module. Use when unit tests can't exercise the contract that matters.
- [ ] E2E: user-visible flow across layers. Reserve for the **golden path** only — not for branch coverage.

Rule of thumb: test one level **below** the goal. Goal is API behavior → integration test. Goal is pure logic → unit test.

### 2. Write the failing test

- [ ] Give the test a name that reads as a sentence describing the behavior, not the mechanism.
  - Good: `retries_on_transient_network_error`
  - Bad: `test_retry_function_1`
- [ ] Use real, realistic inputs — not `"foo"`, `"bar"`, `42`. Make the failure message informative.
- [ ] Assert on **observable behavior**, not implementation detail. (No asserting on private method calls.)
- [ ] One logical assertion per test. Multiple `expect` lines are fine if they check the same behavior.

### 3. Run it and confirm it fails

- [ ] Run the test. Confirm red.
- [ ] Read the failure message. It must say "expected X, got Y" where Y is the absence of the feature. If it says "undefined is not a function" or "module not found," the test is broken, not failing — fix the test.

### 4. Exit RED

When the test fails for the expected reason, run `/development-loop next` to enter `tdd-green`.

## GREEN checklist (`phase: tdd-green`)

### 1. Write the minimum code

- [ ] Write the smallest amount of code that makes the test pass. "Return the expected value literally" is a valid first step if the test only checks one case.
- [ ] No extra branches, no extra parameters, no helpers yet.
- [ ] No speculative abstractions. If the test doesn't exercise it, don't write it.

### 2. Run the test

- [ ] Run the single test. Confirm green.
- [ ] Run the full affected test suite (module, package, or whatever scope the project uses). Confirm green.
- [ ] If an unrelated test broke, STOP — you broke something. Fix or revert before proceeding.

### 3. Exit GREEN

When all relevant tests pass, run `/development-loop next` to enter `implementation`.

## Red flags

- Writing implementation before the test compiles.
- Mocking everything until the test passes trivially (the test tests nothing).
- Adding "setup" helpers in the test to hide the thing that's hard to set up — that hardness is a design signal, not a nuisance.
- A test that passes on the first run with no changes — it tests nothing.
- Skipping the "run and see it fail" step because "obviously it will fail."
- A "unit test" that requires network / filesystem / database. It's an integration test — be honest about the cost.

## Hook enforcement specifics

Test file detection in `PreToolUse` hook — a path is considered a test file if it matches any of:

- `*.test.*`
- `*.spec.*`
- `**/test/**`
- `**/tests/**`
- `**/__tests__/**`
- `*_test.*`
- `*-test.*`

In `tdd-red`, only test files and markdown are writable. Trying to edit production code returns `exit 2` with a message pointing to this skill.

## Scope of the RED→GREEN cycle

One test per cycle. If the slice needs multiple tests, loop back to RESEARCH for the next slice. Attempting to batch tests muddies feedback and hides regressions.
