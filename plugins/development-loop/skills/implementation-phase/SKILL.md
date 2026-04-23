---
name: implementation-phase
description: This skill should be used when the development-loop state file has `phase: implementation`, or when the user says "implementation phase", "complete the feature", "flesh out the implementation". Drives the IMPLEMENTATION phase — tight, convention-following code that finishes the slice without scope creep or speculative abstractions. Automatically loaded by the `development-loop` orchestrator.
---

# IMPLEMENTATION Phase

**Entry condition:** `phase: implementation`, test is green.
**Exit condition:** Feature slice is complete; diff is tight; no speculative code; all tests still green.

## Hard rules

- **Convention over invention.** Match the style, structure, and naming already in the touched area. Inventing a new pattern is a process failure.
- **Tight diff.** Every line must earn its place. No drive-by changes — open a separate loop for those.
- **No speculative code.** No options, flags, or parameters unless a test exercises them.
- **Tests stay green.** Run them every meaningful step.
- **Writes allowed.** Hooks do not block writes in this phase, but `PostToolUse` reminds about phase progression.

## Checklist

### 1. Conventions

- [ ] Read the nearest existing file of the same kind before writing. Copy its structure — imports order, error handling, naming, file layout.
- [ ] Match error-handling style — if existing code throws, throw. If it returns `Result`, return `Result`. Don't introduce a third style.
- [ ] Match naming — camelCase vs snake_case, verb-first vs noun-first.
- [ ] Respect existing abstractions. If a shared helper exists, use it. If none exists, don't create one — inline the code.

### 2. Scope discipline

- [ ] Keep the diff contained to the slice. If you notice an unrelated bug or ugly code, write it down — don't fix it in this loop.
- [ ] No refactors yet. REFACTOR phase is for that. Mixing refactors with feature work hides regressions.
- [ ] Do not touch files outside the slice unless the test genuinely requires it.

### 3. Remove what you don't use

- [ ] If you added a parameter and ended up not needing it, remove it.
- [ ] If you added a helper and called it once, inline it. (Rule of Three — extract only on the third real call site.)
- [ ] If you added an interface / abstract type for a single implementor, remove it. (YAGNI.)

### 4. Clean-code quick pass

Before leaving the phase, re-read the diff for:

- [ ] Meaningful names — would a stranger understand what this variable / function is for?
- [ ] Small functions — any function longer than ~20 lines or doing more than one thing? Split.
- [ ] No magic numbers — named constant for anything non-obvious.
- [ ] No dead code — no commented-out blocks, no unreachable branches.
- [ ] No `// TODO` or `// FIXME` left behind — either do it or open an issue.
- [ ] No comments restating what the code does — keep only non-obvious "why" comments.

### 5. Re-run tests

- [ ] Full affected test suite is green.
- [ ] No new warnings from the compiler / type-checker / linter. Silencing a warning is a red flag — fix the root cause.

## Exit this phase

Run `/development-loop next` to enter `review`.

## Red flags

- "While I'm here, let me also fix X" — no. Next loop.
- Adding a configuration option "in case someone needs it later."
- Copy-pasting a block from a similar file and tweaking it, without reading why the original was structured that way.
- Adding a `try/catch` that swallows the error silently.
- Leaving a `console.log` / `println` / `print` behind.
- Making a function generic to handle "future cases" — handle the current case, extract on Rule of Three.
- Adding a new dependency to avoid writing 20 lines — check if the repo already has a helper for it.

## Interaction with other phases

- If you discover the test was wrong mid-implementation, loop back to `tdd-red`: `/development-loop abort` then restart with corrected framing, or (for minor fixes) just update the test, re-confirm red/green, continue.
- If you discover the slice was too big, split it: finish the smallest viable piece, run `/development-loop next` through to completion, then `start` a new loop for the remainder.
