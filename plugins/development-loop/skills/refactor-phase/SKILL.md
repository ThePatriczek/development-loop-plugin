---
name: refactor-phase
description: This skill should be used when the development-loop state file has `phase: refactor`, or when the user says "refactor phase", "clean up the code", "safe refactor on green". Drives the REFACTOR phase — structural improvements on green only, rename-to-fit, extract-on-Rule-of-Three, no scope creep. Automatically loaded by the `development-loop` orchestrator.
---

# REFACTOR Phase

**Entry condition:** `phase: refactor`, tests green, review passed.
**Exit condition:** Structure improved for **this change only**, tests still green, no new scope introduced.

## Hard rules

- **Refactor on green, never on red.** Every micro-step ends with tests passing.
- **Scope = this change.** Improve the code the loop touched. The rest of the repo is not in this loop.
- **Revert over argue.** If a refactor makes tests flaky or unclear, revert without debate.
- **No new behavior.** Behavior changes belong in a new loop's `tdd-red`.

## 0. Discover and load relevant skills

As in `review-phase`, check the environment for project/user/global skills that apply to refactoring or style:

- [ ] Read `CLAUDE.md` for refactor / style / layering conventions. Follow them.
- [ ] List `.claude/skills/*` and `~/.claude/skills/*` — load any whose description mentions layering, architecture, decoupling, conventions, design patterns.
- [ ] Plugin-registered skills whose domain matches the touched code (e.g., `database-layer`, `tailwind-constants-only`, `frontend-design`) — load them now so their opinions apply.

## Checklist

### 1. Re-read the diff

- [ ] Read the diff top to bottom with fresh eyes. The question for every line: "is this the clearest expression of what it does?"

### 2. Rename to match reality

- [ ] Names drifted during implementation? Update them now. Variables, functions, types, files.
- [ ] Rename via the tooling the project uses (IDE, `ts-morph`, codemods) — never hand-edit across many files for renames.
- [ ] Run tests after each batch of renames.

### 3. Extract — only on Rule of Three

- [ ] Duplication introduced by this change? Check: does a real second call site exist? If yes → extract. If the "duplication" is two lines in one place, leave it.
- [ ] Never extract "for future use." The future call site either exists or doesn't.

### 4. Shrink functions and files

- [ ] Any function > ~20 lines or doing > 1 thing? Split.
- [ ] Any nested block > 3 levels deep? Flatten with early returns or helper functions.
- [ ] Any file doing > 1 thing? Consider splitting — but only if the split doesn't create import cycles or noise.

### 5. Tighten types / contracts

- [ ] Narrow types: replace `any` / `unknown` / `object` with specific types.
- [ ] Replace boolean flags with explicit unions ("when true do X, else Y" → two explicit functions or a union tag).
- [ ] Replace positional arguments > 3 with a named-parameters object.

### 6. Remove what you cooled on

- [ ] Helpers that ended up with a single call site? Inline.
- [ ] Abstractions that ended up with a single implementor? Delete.
- [ ] Comments that restate what the code now obviously does? Delete.

### 7. Re-run tests after every refactor step

- [ ] Never refactor on red. If a refactor breaks a test, revert that step and try smaller.
- [ ] After the last refactor step, re-run the full affected suite and confirm green.

## Exit this phase

Decide:

- **Goal fully met** → `/development-loop done` (writes final progress summary, deletes state).
- **Goal has more to it** → `/development-loop next` (loops back to `research`, `iteration++`, flags reset).

## Red flags

- Refactoring files the diff never touched.
- A refactor batch bigger than 10 lines without running tests.
- "This function could be more generic" — generics added speculatively are noise. Only when a real second call site appears.
- Mixing a behavior change with a refactor ("while renaming, I also fixed the bug"). Separate them.
- Leaving tests "temporarily skipped" after a refactor. Never.
- Refactoring to match a pattern used elsewhere in the repo when the current code already reads clearly. Consistency is a weak argument against clarity.

## End of loop — definition of done

The full loop is done only when:

- Goal is fully delivered — user-visible outcome exists, user can confirm.
- All tests green.
- `review_passed: true`.
- Diff is minimal and tight.
- Project quality gates (delegated to project-specific skills like `commit-deploy`) pass.
- No `TODO` / `FIXME` introduced by this loop left unaddressed.

Only then run `/development-loop done`.
