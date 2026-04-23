---
name: research-phase
description: This skill should be used when the development-loop state file has `phase: research`, or when the user says "enter research", "start research phase", "deep research this". Drives the deep RESEARCH phase — reuse-before-invent, grep-first, library-doc lookup, scope sizing, ambiguity resolution. No implementation code may be written until this phase exits. Automatically loaded by the `development-loop` orchestrator.
---

# RESEARCH Phase — DEEP

**Entry condition:** `phase: research` in state file.
**Exit condition:** Goal restated in one sentence; prior art searched; smallest slice defined; all ambiguities resolved or asked.

## Hard rules

- **No production code written in this phase.** Hook `PreToolUse` blocks `Write|Edit|MultiEdit` on non-test, non-doc paths.
- **No TDD yet.** Tests come in `tdd-red`. Writing a test now means you jumped the gun.
- **No guessing.** Every unknown is either researched or asked.
- **Reuse beats invent.** If an existing solution matches ≥80%, use it and stop.

## Checklist

### 1. Restate the goal

- [ ] Write the goal in **one sentence** at the top of the state file body.
- [ ] Name the user-visible outcome, not the technical mechanism. ("User can retry failed API calls," not "Add fetch wrapper.")
- [ ] If the goal mentions more than one user-visible outcome, split it. This phase owns exactly one.

### 2. Find prior art

- [ ] `Grep` for keywords from the goal across the repo. Start broad, narrow to matching files.
- [ ] `Glob` likely directories: modules named after the domain, utility folders, existing clients/wrappers.
- [ ] Read the matches before deciding. One file read beats five speculations.
- [ ] Check the git log for related work: `git log --oneline --all -- <file>` on candidate files.

### 3. Scope the slice

- [ ] Define the **smallest** vertical slice that delivers *some* of the goal end-to-end.
- [ ] Write it as a one-line acceptance criterion: "When X, then Y."
- [ ] List what is **explicitly not** in this slice. (Saves 80% of scope-creep bugs.)

### 4. Resolve ambiguities

- [ ] List every ambiguity you noticed. Format: "Q: … A: …" or "Q: … — STOP and ask user."
- [ ] Ambiguities with no answer → stop and ask the user. Do not advance to `next` until answered.
- [ ] "I assume …" is a red flag — replace with a question or a verified fact.

### 5. Library / framework knowledge

- [ ] If the slice touches a third-party library or API, verify current behavior via the `context7` MCP (`mcp__plugin_context7_context7__*`) or official docs. Training data is stale — verify.
- [ ] If the library docs are ambiguous or the API is new, note it explicitly and budget time for a spike.

### 6. Big-scope escape hatch

If the slice is large (multiple files, new subsystem, unfamiliar code area):

- [ ] Dispatch an `Explore` subagent with a specific question about the existing architecture. Read its report before defining the slice.
- [ ] Do NOT skip this for "quick fixes" in unfamiliar areas — that's where the worst bugs live.

## Writing allowed in this phase

Hooks permit writes to:

- `**/*.md` — plans, notes, doc updates
- `.claude/development-loop.local.md` — state file itself

Hooks block writes to any source file (`.ts`, `.tsx`, `.js`, `.py`, `.go`, `.rs`, `.java`, `.kt`, `.rb`, `.php`, `.c`, `.cpp`, `.cs`, etc.). If you need to add a note, use markdown.

## Exit this phase

Only advance when all of:

- Goal restated in one sentence.
- Prior art searched (grep + glob + at least one read of a relevant file, OR a documented "no prior art" finding).
- Slice defined with acceptance criterion + out-of-scope list.
- Zero open ambiguities (either resolved or deferred by user decision).

Run `/development-loop next` to enter `tdd-red`.

## Red flags

- "Let me just write this quickly" — research not done.
- Jumping to implementation after reading one file.
- Skipping the grep because "I already know this repo."
- "I'll figure out the library API as I go." Verify it now.
- Accepting a goal with two outcomes instead of splitting.

## Additional resources

- `references/deep-research-techniques.md` — concrete grep patterns, exploration heuristics, library-doc lookup recipes.
