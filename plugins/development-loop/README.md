# development-loop

A Claude Code plugin that enforces a **strict, ten-phase, checklist-driven development loop** on every code change via agent-type hooks.

```
RESEARCH
  → RESEARCH-REVIEW
    → TDD-RED
      → TDD-GREEN
        → TDD-REVIEW
          → IMPLEMENTATION
            → IMPLEMENTATION-REVIEW
              → REFACTOR
                → REFACTOR-REVIEW
                  → OVERALL-REVIEW
                    → (LOOP back to RESEARCH, or DONE)
```

No phase is skipped. No step is reordered. Every write is validated against the current phase by the matching phase agent.

## What makes this "heavy"

- **Activation-based enforcement** — hooks kick in only when the loop is explicitly started. Outside the loop, zero overhead.
- **Agent per phase** — every phase has a dedicated agent that MUST load its phase skill as its first action and enforce its checklist.
- **Review at every step** — each work phase (research, tdd, implementation, refactor) is followed by a dedicated review phase with its own auditing agent and skill.
- **Deep overall review** — final gate runs context-detected static analysis (the project's own quality commands), a security checklist, a clean-code audit, and (when available) a Playwright MCP E2E smoke test.
- **Clean-code enforcement** — KISS, YAGNI, DRY, SOLID, Law of Demeter, and ~20 more principles referenced every phase.
- **Agent-based PreToolUse, UserPromptSubmit, Stop hooks** — hooks dispatch the matching phase agent for judgment-based decisions.
- **Blocking stop-guard** — refuses to end a session while the loop is active and the goal is not met.

## Components

### Skills

| Name | Purpose |
|---|---|
| `development-loop` | Orchestrator. User-invokable. Manages state, routes to phase skills / agents. |
| `research-phase` | Deep research — grep, reuse, library docs, scope sizing. |
| `research-review` | Audit the research artifact (goal, evidence, slice, ambiguities). |
| `tdd-phase` | RED → GREEN discipline. Failing test first, then minimum code. |
| `tdd-review` | Audit test quality (level, naming, inputs, real-failure reverification, mocking). |
| `implementation-phase` | Minimal, convention-following implementation. |
| `implementation-review` | Audit scope discipline, dead weight, code quality, safety signals. |
| `refactor-phase` | Safe refactor on green only. |
| `refactor-review` | Audit scope, test integrity, actual clarity improvement. |
| `overall-review` | Final DEEP gate — static analysis + security + clean-code + E2E. |

### Agents

| Name | Dispatched when |
|---|---|
| `research-agent` | phase = research |
| `research-review-agent` | phase = research-review |
| `tdd-agent` | phase = tdd-red or tdd-green |
| `tdd-review-agent` | phase = tdd-review |
| `implementation-agent` | phase = implementation |
| `implementation-review-agent` | phase = implementation-review |
| `refactor-agent` | phase = refactor |
| `refactor-review-agent` | phase = refactor-review |
| `overall-review-agent` | phase = overall-review |

### Hooks

| Hook | Type | Purpose |
|---|---|---|
| `SessionStart` | command | Detects active loop, prints status banner to session context. Cheap, no-op outside a loop. |
| `UserPromptSubmit` | agent | Dispatches the matching phase agent. The agent loads its phase skill and injects concrete guidance as additionalContext. |
| `PreToolUse` (Write / Edit / MultiEdit) | agent | Phase agent evaluates whether the write is allowed given the current phase. Blocks forbidden writes. |
| `Stop` | agent | Stop-guard. Refuses to stop unless the loop is inactive, or at `overall-review` with `review_passed: true`. |

All hook logic is gated on the state file. No state file → zero overhead.

## Installation

### Local (for testing)

```bash
claude --plugin-dir ~/Work/development-loop-plugin
```

### Marketplace

Add the repo to a marketplace and install via `/plugin`.

## Usage

Inside any repository you want to work on:

```
/development-loop start "Add retry logic to API client with exponential backoff"
```

The orchestrator will:

1. Create `.development-loop/<context-slug>/STATE.md` with `active: true, phase: research, goal: ...` (the slug is derived from the goal)
2. Load the `research-phase` skill and display its checklist
3. On every subsequent prompt / write / stop, hooks dispatch the matching phase agent

Advance phases:

```
/development-loop next        # advance to the next phase (verifies exit conditions first)
/development-loop status      # show current phase + checklist
/development-loop done        # close loop (only when overall-review has passed)
/development-loop abort       # abandon loop
```

## State file

The loop stores its state at `<project-root>/.development-loop/<context-slug>/STATE.md` (the slug is derived from the `goal` string — lowercase, hyphenated, max 40 chars):

```yaml
---
active: true
phase: tdd-red
goal: Add retry logic to API client with exponential backoff
iteration: 1
started_at: 2026-04-23T20:00:00Z
tests_written: false
tests_passing: false
research_review_passed: true
tdd_review_passed: false
implementation_review_passed: false
refactor_review_passed: false
review_passed: false
e2e_run: false
e2e_skipped: false
---
```

Add `.development-loop/` to the consumer repo's `.gitignore`.

Archives of completed iterations live at `.development-loop/<context-slug>/archive/iteration-<N>.md`.

**Why `.development-loop/` and not `.claude/`?** The `.claude/` directory is often permission-restricted or reserved for Claude Code's own config. A dedicated top-level dir avoids write conflicts and keeps loop state cleanly separated from tool config.

## Disabling enforcement temporarily

Delete the active `.development-loop/<context-slug>/STATE.md`, or run `/development-loop abort`.

## Extending per project

Each phase has an optional, project-local extension slot. Create a standard Claude Code skill at `.claude/skills/development-loop-<phase>/SKILL.md` in your consumer repo and it will be preloaded into the matching phase agent's context automatically. If the skill does not exist, the agent behaves as shipped — zero overhead.

Extension slot names (one per phase):

`development-loop-research`, `development-loop-research-review`, `development-loop-tdd-red`, `development-loop-tdd-green`, `development-loop-tdd-review`, `development-loop-implementation`, `development-loop-implementation-review`, `development-loop-refactor`, `development-loop-refactor-review`, `development-loop-overall-review`.

The extension is a normal skill — see the [official skills documentation](https://code.claude.com/docs/en/skills) for the format. Use it for project-specific rules that should augment (not replace) the built-in phase discipline.

## Philosophy

This plugin is opinionated on purpose. Skipping the checklist is the default failure mode of every AI-assisted dev workflow — this plugin makes skipping impossible without a conscious override.

Every phase's work is immediately audited by a dedicated review phase with its own agent. The overall-review at the end is the pre-merge gate. The structure ensures that what ships passes both per-step rigor and system-level rigor.

## License

MIT.
