# Loop State File — Specification

The development loop stores its state in a single file at the consumer repo root:

```
<project-root>/.claude/development-loop.local.md
```

## File format

YAML frontmatter (machine-readable) + Markdown body (human-readable).

```markdown
---
active: true
phase: tdd-red
goal: <one-sentence user-visible outcome>
iteration: 1
started_at: 2026-04-23T20:00:00Z
tests_written: false
tests_passing: false
research_review_passed: false
tdd_review_passed: false
implementation_review_passed: false
refactor_review_passed: false
review_passed: false
e2e_run: false
e2e_skipped: false
---

# Development Loop — Active

## Goal
<goal>

## Checklist
- [x] RESEARCH — prior art searched, slice defined
- [x] RESEARCH-REVIEW — artifact passed audit
- [ ] TDD-RED — failing test written
- [ ] TDD-GREEN — minimum code turns it green
- [ ] TDD-REVIEW — test asserts behavior, real-failure reverified
- [ ] IMPLEMENTATION — complete, tight diff
- [ ] IMPLEMENTATION-REVIEW — scope disciplined, no debug remnants
- [ ] REFACTOR — improvements on green
- [ ] REFACTOR-REVIEW — zero behavior change, clarity gained
- [ ] OVERALL-REVIEW — static analysis + security + E2E

## Review findings
(populated during review phases)
```

## Frontmatter fields

| Field | Type | Description | Invariant |
|---|---|---|---|
| `active` | bool | Is the loop enforcing? | When `false`, hooks no-op. `abort`/`done` set to false. |
| `phase` | enum | Current phase. | See enum below. |
| `goal` | string | One-sentence goal. | Set by `start`, immutable until `done`/`abort`. |
| `iteration` | int | LOOP count. | Starts at 1. Increments on LOOP back from `overall-review` → `research`. |
| `started_at` | ISO-8601 | UTC timestamp of `start`. | Immutable within a loop. |
| `tests_written` | bool | At least one failing test authored this iteration. | Set true when exiting `tdd-red`. |
| `tests_passing` | bool | All tests green. | Set true when exiting `tdd-green`; reset if subsequent phase breaks them. |
| `research_review_passed` | bool | Research artifact passed audit. | Set true when exiting `research-review`. |
| `tdd_review_passed` | bool | Test quality passed audit. | Set true when exiting `tdd-review`. |
| `implementation_review_passed` | bool | Implementation diff passed audit. | Set true when exiting `implementation-review`. |
| `refactor_review_passed` | bool | Refactor passed audit. | Set true when exiting `refactor-review`. |
| `review_passed` | bool | Overall-review gate passed. | Set true when exiting `overall-review` with zero blocking findings. |
| `e2e_run` | bool | E2E smoke test executed via Playwright MCP. | Set true during `overall-review`. |
| `e2e_skipped` | bool | E2E skipped (MCP unavailable or no UI surface). | Mutually exclusive with `e2e_run`. |

## Phase enum (10 values)

```
research
research-review
tdd-red
tdd-green
tdd-review
implementation
implementation-review
refactor
refactor-review
overall-review
```

Hooks parse `phase` by simple grep on the frontmatter — keep values lowercase, hyphen-separated, unquoted.

## Transition rules

`next` is the only action that changes `phase`. Sequence:

```
research          → research-review        (no prerequisite flag; audited by research-review phase itself)
research-review   → tdd-red                (requires research_review_passed = true)
tdd-red           → tdd-green              (requires tests_written = true)
tdd-green         → tdd-review             (requires tests_passing = true)
tdd-review        → implementation         (requires tdd_review_passed = true)
implementation    → implementation-review  (no prerequisite flag; audited by review phase itself)
implementation-review → refactor           (requires implementation_review_passed = true)
refactor          → refactor-review        (requires tests_passing = true)
refactor-review   → overall-review         (requires refactor_review_passed = true)
overall-review    → research (iteration++)   OR   done (archive state)
                                           (requires review_passed = true for done)
```

On LOOP back (`overall-review` → `research`, iteration++):

- Increment `iteration`.
- Reset ALL per-step review flags, `tests_written`, `tests_passing`, `review_passed`, `e2e_run`, `e2e_skipped` to `false`.
- Keep `goal`, `started_at`, `active`.

### Backward transitions

A review phase may fail, requiring a loop back to the preceding work phase. The orchestrator handles this via `/development-loop next-back` or by resetting the phase field directly:

```
research-review   (fail) → research
tdd-review        (fail) → tdd-red
implementation-review (fail) → implementation
refactor-review   (fail) → refactor
overall-review    (fail) → implementation  (or earlier, depending on the finding)
```

Backward transitions reset only the relevant failed review flag, keeping earlier-phase flags intact.

## Hook access

Hooks read the file with simple parsing:

```bash
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/development-loop.local.md"
[ -f "$STATE_FILE" ] || exit 0
active=$(awk -F': *' '/^active:/{print $2; exit}' "$STATE_FILE")
phase=$(awk -F': *' '/^phase:/{print $2; exit}' "$STATE_FILE")
[ "$active" = "true" ] || exit 0
```

The hook lib script `hooks/scripts/loop-state.sh` provides these helpers.

## Invariants

- Exactly one state file at a time per project.
- `active: true` implies hooks enforce.
- Missing file implies inactive.
- Phase always one of the enum values; unknown values treated as inactive (safe default).
- Never manually edit `phase` — always via the orchestrator so exit conditions are checked.
- The overall-review gate (`review_passed: true`) can only be reached via the overall-review phase and its agent; no other path sets that flag.

## Safety

- Never commit the state file — it belongs in the consumer repo's `.gitignore`.
- The state file contains no secrets; the goal string is the only free-form content — keep it short and non-sensitive.
