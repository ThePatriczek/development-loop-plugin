---
name: development-loop
description: This skill should be used when the user invokes "/development-loop" with an action ("start", "next", "status", "done", "abort"), or says "start development loop", "enter research phase", "advance to TDD", "next phase", "finish loop", "abort loop". Orchestrates a mandatory, ten-phase, checklist-driven development cycle (RESEARCH → RESEARCH-REVIEW → TDD-RED → TDD-GREEN → TDD-REVIEW → IMPLEMENTATION → IMPLEMENTATION-REVIEW → REFACTOR → REFACTOR-REVIEW → OVERALL-REVIEW → LOOP or DONE) with hook-based enforcement of clean-code, static-analysis, and security standards. Each work phase is followed by a dedicated review phase audited by its own agent. Invoking this skill MUST be treated as entering STRICT mode — no step may be skipped or reordered.
argument-hint: "[start <goal> | next | status | done | abort]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent
---

# Development Loop — Orchestrator

## Invocation contract (STRICT)

Invocation of this skill puts the repository into **strict development-loop mode**. While the loop is active:

- Hooks block writes that violate the current phase.
- Hooks block session-stop until the goal is met.
- Each phase has a dedicated skill and a dedicated agent. When a phase is active, the matching agent MUST be dispatched (hooks do this automatically) and it MUST load its phase skill as its authoritative contract.
- Every work phase (research, tdd, implementation, refactor) is followed by a dedicated review phase (research-review, tdd-review, implementation-review, refactor-review). The final gate is `overall-review`.
- Clean-code principles (see `references/clean-code-principles.md`) MUST be respected at every step.
- No step is skipped. No step is reordered. No "quick fix" bypasses the loop.

If the user's request is ambiguous, stop and ask before proceeding — never guess.

## Actions

The skill accepts one of five actions via `$ARGUMENTS`:

| Action | Effect |
|---|---|
| `start <goal>` | Create state file, enter `research` phase, load `research-phase` skill, show checklist. |
| `next` | Advance phase in sequence. Verify exit conditions of current phase before transitioning. |
| `status` | Read state file, print current phase + iteration + goal + checklist progress. |
| `done` | Verify all exit conditions for the full loop are met, archive state file. |
| `abort` | Delete state file after confirming with user. Warns that enforcement will stop. |

Parse `$ARGUMENTS` as: first token = action, remainder = goal (for `start` only). If `$ARGUMENTS` is empty, default to `status`.

## Phase sequence (10 phases)

```
research
  → research-review
    → tdd-red
      → tdd-green
        → tdd-review
          → implementation
            → implementation-review
              → refactor
                → refactor-review
                  → overall-review
                    → (LOOP back to research, or DONE)
```

Each phase has a dedicated skill and agent. Hooks dispatch the matching agent automatically; the agent loads its skill as the authoritative contract.

Exit conditions (verified before `next`):

| Phase | Skill loaded | Agent dispatched | Exit condition |
|---|---|---|---|
| `research` | `research-phase` | `research-agent` | Goal restated; prior art searched; smallest slice defined; ambiguities resolved. |
| `research-review` | `research-review` | `research-review-agent` | Goal is singular and test-sized; evidence recorded; zero ambiguities. |
| `tdd-red` | `tdd-phase` | `tdd-agent` | Failing test written; test runs and fails for the **expected** reason. |
| `tdd-green` | `tdd-phase` | `tdd-agent` | Test passes with minimum implementation; full affected suite green. |
| `tdd-review` | `tdd-review` | `tdd-review-agent` | Test asserts observable behavior at the right level; real-failure reverified. |
| `implementation` | `implementation-phase` | `implementation-agent` | Feature complete; no speculative code; diff tight. |
| `implementation-review` | `implementation-review` | `implementation-review-agent` | Scope disciplined; conventions followed; zero debug remnants; no new warnings. |
| `refactor` | `refactor-phase` | `refactor-agent` | Improvements applied on green; tests still green; no scope creep. |
| `refactor-review` | `refactor-review` | `refactor-review-agent` | Zero behavior change; scope limited; actual clarity gain. |
| `overall-review` | `overall-review` | `overall-review-agent` | Context-detected static analysis clean; security checklist passed; clean-code audit done; E2E run or explicitly skipped; `review_passed: true`. |

After `overall-review`, decide: **LOOP** (goal not fully met → back to `research` for next slice, `iteration++`, per-step `*_review_passed` flags reset) or **DONE**.

## State file

Location: `<project-root>/.claude/development-loop.local.md`

Format (YAML frontmatter + markdown body):

```yaml
---
active: true
phase: research
goal: <user-provided goal>
iteration: 1
started_at: <ISO-8601 UTC>
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

## Checklist progress
- [ ] RESEARCH
- [ ] RESEARCH-REVIEW
- [ ] TDD-RED
- [ ] TDD-GREEN
- [ ] TDD-REVIEW
- [ ] IMPLEMENTATION
- [ ] IMPLEMENTATION-REVIEW
- [ ] REFACTOR
- [ ] REFACTOR-REVIEW
- [ ] OVERALL-REVIEW
```

See `references/loop-state-spec.md` for the full schema and transition rules.

Create the `.claude/` directory if it does not exist. Always write the state file via the `Write` tool (not via `Bash`).

## Action: `start <goal>`

1. Refuse if `.claude/development-loop.local.md` exists and `active: true` — tell the user to `abort` or `done` first.
2. Require a goal. If missing, ask the user for one concrete sentence.
3. Write the state file with `phase: research`, `iteration: 1`, current UTC timestamp, all flags false.
4. **Load the `research-phase` skill** (via Skill tool) and relay its checklist to the user.
5. Remind the user that hooks are now blocking. No writes will be permitted outside allowed paths until `tdd-red` starts writing tests.

## Action: `next`

1. Read state file. If missing or `active: false`, refuse and tell the user to `start` first.
2. Determine current phase and verify its exit conditions (see table above). If any condition is unmet, refuse and list the missing items.
3. Transition the `phase` field to the next in sequence. Update relevant flags (e.g., `tests_written: true` when leaving `tdd-red`).
4. If the new phase is `research` after `refactor`, increment `iteration`.
5. **Load the matching phase skill** via the Skill tool.
6. Print the new phase's checklist and what is allowed / blocked in this phase.

## Action: `status`

1. Read state file. If missing, print "no active loop" and stop.
2. Print: phase, iteration, goal, flags, time since `started_at`, and the checklist with ticked items where flags indicate completion.
3. Remind which phase skill is authoritative right now.

## Action: `done`

1. Verify the state is at `overall-review` with `review_passed: true` and all per-step review flags set. If not, refuse and list what is missing.
2. Archive the state file by moving it to `.claude/development-loop.archive/<goal-slug>-<iteration>.md` (use `Bash` with `mkdir -p` + `mv`).
3. Confirm to the user that enforcement is off.

## Action: `abort`

1. Ask the user to confirm (this disables enforcement mid-flight).
2. Delete `.claude/development-loop.local.md`.
3. Warn the user that the next `start` begins a fresh iteration.

## Clean-code principles (MANDATORY every phase)

Pushed at every step — treat violations as bugs, not style:

- **KISS** — simplest thing that works
- **YAGNI** — no speculative features / options / flags
- **DRY** — fold duplication *only* when it already hurts (Rule of Three)
- **SOLID** — SRP, OCP, LSP, ISP, DIP
- **Law of Demeter** — don't reach through objects
- **Separation of Concerns** — one reason to change per unit
- **High Cohesion / Low Coupling**
- **Composition over Inheritance**
- **Tell, Don't Ask** — behavior lives with data
- **Command-Query Separation** — a method mutates or returns, not both
- **Principle of Least Astonishment** — boring beats clever
- **Fail Fast** — assert at boundaries, crash early
- **Boy Scout Rule** — leave it cleaner than you found it (scoped to the change)
- **Information Hiding** — minimize surface area
- **Immutability** — mutate only when measured to matter
- **Pure Functions** where possible
- **Meaningful Names** — no single-letter, no abbreviations unless idiomatic
- **Small Functions** / **Do One Thing**
- **No Magic Numbers** — name constants
- **No Dead Code** — delete, don't comment-out
- **No Premature Optimization** — measure first
- **No Premature Abstraction** — inline until a real second call site exists

Full, worked explanations with anti-examples in `references/clean-code-principles.md`.

## Red flags — STOP and rethink

- Writing code before a failing test exists (in `research` or `tdd-red`).
- Adding an abstraction used exactly once.
- "Just in case" branches, guards, or feature flags.
- Comments restating what the code does.
- Touching unrelated code in the same change (scope creep).
- Silencing a lint/type error instead of fixing the root cause.
- "I'll clean it up later" — later never comes.
- Disabling the hooks to get unblocked — treat this as a process failure, not a solution.

## How hooks enforce this skill

When the state file has `active: true`:

| Hook | Type | Enforcement |
|---|---|---|
| `SessionStart` | command | Reports active loop + current phase in session context. |
| `UserPromptSubmit` | agent | Reads state and dispatches the matching phase agent. The agent loads its phase skill and injects concrete guidance for the main session. |
| `PreToolUse` (Write/Edit/MultiEdit) | agent | Phase agent evaluates whether the write is allowed given the current phase and blocks it if not. |
| `Stop` | agent | `overall-review-agent` verifies the loop can safely stop (active:false, or at `overall-review` with `review_passed: true`). |

All hook logic is gated on the existence of the state file — no state file, no enforcement.

## Phase skills and agents

Each phase has both a skill (the contract) and an agent (the enforcer). The agent's first action is always to load its phase skill via the Skill tool.

| Phase | Skill | Agent |
|---|---|---|
| `research` | `research-phase` | `research-agent` |
| `research-review` | `research-review` | `research-review-agent` |
| `tdd-red` / `tdd-green` | `tdd-phase` | `tdd-agent` |
| `tdd-review` | `tdd-review` | `tdd-review-agent` |
| `implementation` | `implementation-phase` | `implementation-agent` |
| `implementation-review` | `implementation-review` | `implementation-review-agent` |
| `refactor` | `refactor-phase` | `refactor-agent` |
| `refactor-review` | `refactor-review` | `refactor-review-agent` |
| `overall-review` | `overall-review` | `overall-review-agent` |

## Definition of done (per loop, not per phase)

Loop is done only when **all** of these hold:

- Goal fully met (user confirmation or explicit acceptance criteria met).
- All tests green.
- `review_passed: true` in state file.
- Diff is tight and minimal.
- Project quality gates pass (delegate to project-specific skills — e.g., `commit-deploy` in hc-solutions).

## Additional resources

- `references/clean-code-principles.md` — full principles with anti-examples.
- `references/loop-state-spec.md` — state file schema, phase transition rules, invariants.
