# Intercepting Extension Skills — Design

**Date:** 2026-04-24
**Status:** Approved, pending implementation plan
**Scope:** `plugins/development-loop`

## Problem

The `development-loop` plugin ships 9 phase agents with fixed, in-plugin phase skills (`research-phase`, `tdd-phase`, etc.). A consumer project has no supported way to attach project-specific rules (e.g., "check migrations during research", "run `bun typecheck` before exiting tdd-green", "verify RLS policies in overall-review") without forking the plugin or editing its files.

## Goal

Give each of the 10 phases an **optional, project-local extension slot**: a standard Claude Code skill that, if present in the consumer repo's `.claude/skills/`, is automatically preloaded into the matching phase agent's context at spawn time. If absent, the plugin behaves exactly as today — zero overhead.

## Non-goals

- No custom skill format, validation, starter templates, or scaffolding commands.
- No conflict-resolution logic between built-in and extension skill content; runtime + model handle it.
- No precedence rules encoded in the plugin. Extension skills are normal skills.
- No support for user-level (`~/.claude/skills/`) or plugin-level extensions — project-local only (by convention, not by enforcement; runtime resolution rules apply).

## Mechanism

Claude Code's subagent frontmatter supports a `skills:` field that preloads the full content of each listed skill into the agent's system prompt at spawn. Per the docs: *"If a listed skill is missing or disabled, Claude Code skips it and logs a warning to the debug log."*

That's the entire interception mechanism. No agent-body logic, no discovery code, no custom hooks. Declaring an extension slot in the agent frontmatter is sufficient — the runtime resolves and injects it if and only if it exists in the session's available skills.

## Contract

An extension skill is a **plain Claude Code skill** per the [official skills documentation](https://code.claude.com/docs/en/skills):

- Location in consumer repo: `.claude/skills/development-loop-<phase>/SKILL.md`
- Frontmatter and body follow the standard skill format.
- Content is entirely the consumer's choice — any instructions, checklists, reference pointers, or domain context they want injected into the corresponding phase agent.
- Semantics: **augment only.** The plugin does not enforce this mechanically; it's a documented expectation backed by the pre-loaded built-in skill's existing discipline framing.

## Phase → slot mapping

All 10 phases get an extension slot. Nine agents cover them (`tdd-agent` handles both `tdd-red` and `tdd-green`). The `skills:` frontmatter field on each agent lists **only the extension slot(s)** — built-in phase skills remain loaded dynamically by the agent body (unchanged).

| Agent | `skills:` frontmatter entries |
|---|---|
| research-agent | `development-loop-research` |
| research-review-agent | `development-loop-research-review` |
| tdd-agent | `development-loop-tdd-red`, `development-loop-tdd-green` |
| tdd-review-agent | `development-loop-tdd-review` |
| implementation-agent | `development-loop-implementation` |
| implementation-review-agent | `development-loop-implementation-review` |
| refactor-agent | `development-loop-refactor` |
| refactor-review-agent | `development-loop-refactor-review` |
| overall-review-agent | `development-loop-overall-review` |

**Naming convention (strict):** `development-loop-<phase>` where `<phase>` is one of the 10 phase identifiers used in the loop state machine.

## Changes to the plugin

1. **Agent frontmatter.** Add a `skills:` list to each of the 9 agent `.md` files with exactly the extension entries above. No other frontmatter change.
2. **README.** Add a short "Extending per project" section (5–10 lines) stating: the convention (`development-loop-<phase>`), the location (`.claude/skills/<name>/SKILL.md`), and a link to the official skills documentation. No template, no example body.
3. **No changes** to hooks, orchestrator skill, phase skills, or agent bodies. Built-in phase skill loading (via the agent body's "First action — load the skill" instruction using the Skill tool) is unchanged.

## Runtime behavior

1. CC spawns phase agent (via existing hook dispatch).
2. CC resolves each name in the agent's `skills:` list against the session's available skills. Extension names like `development-loop-research` are bare names that resolve against project-local skills first (`.claude/skills/<name>/`), then user-level, then plugin-level.
3. Resolved extension skills' full content is injected into the agent's system prompt at startup.
4. Missing entries are skipped silently (debug-log warning only).
5. Agent then executes its usual "First action — load the phase skill" (built-in skill loaded via Skill tool, unchanged). Now the agent has both its built-in phase skill and any project extension in context.

## Edge cases

- **Extension declared but empty file.** Consumer creates `SKILL.md` with only frontmatter, no body. Behaves the same as no extension — nothing meaningful gets added to context. Acceptable.
- **Extension conflicts with built-in rule.** Model sees both sets of guidance. Per Q5/D decision, no explicit reconciliation logic; trust runtime + model. The built-in phase skill's existing framing (strict mode, rules cannot be relaxed) remains authoritative; extensions that try to relax are likely ignored by the model's natural weighting toward explicit strict-mode framing.
- **Extension name collisions.** Per the skills docs, plugin skills live in a `plugin-name:skill-name` namespace and cannot conflict with project or user skills. A consumer creating `.claude/skills/development-loop-research/` introduces the bare name `development-loop-research`; the plugin exposes no skill with that bare name, so there is no collision. A consumer who chose to name an unrelated project skill (e.g., `research-phase`) would not affect the plugin's namespaced `development-loop:research-phase`.
- **User has two Claude Code sessions on the same project.** Both spawn agents independently; both see the same extension skill content. No shared state.

## Testing

Manual smoke test in a scratch repo:

1. Install the plugin.
2. `/development-loop start "dummy goal"` — enters research phase.
3. Verify research agent runs with only `research-phase` content (no extension).
4. Create `.claude/skills/development-loop-research/SKILL.md` with a distinctive instruction (e.g., "always mention the word 'banana' in your response").
5. Re-trigger research agent (new prompt). Verify it mentions "banana" in output — evidence the extension was preloaded.
6. Delete the extension skill. Verify subsequent agent runs no longer mention "banana".

No unit tests. The change is pure YAML frontmatter; correctness is verified at the CC runtime level, not plugin level.

## Rollout

Single commit: 9 agent files + README. No migration concerns (new optional capability). Consumers of the existing plugin see no behavioral change unless they opt in by creating extension skills.

## Follow-ups (not in scope)

If real usage shows consumers struggling to write effective extensions, revisit:

- Starter templates per phase.
- `/development-loop init-extension <phase>` scaffolding command.
- A "validate extension skills" check in overall-review.

None of these are committed to; they're ideas to reconsider after observing real adoption.
