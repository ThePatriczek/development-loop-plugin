---
name: research-review
description: This skill should be used when the development-loop state file has `phase: research-review`, or when the user says "review research", "research review phase", "audit the research output". Lightweight QA skill that verifies the RESEARCH phase produced a usable artifact before entering TDD. Audited by an agent-type hook via the `research-review-agent`.
---

# RESEARCH REVIEW Phase

**Entry condition:** `phase: research-review`, preceded by a completed `research` phase.
**Exit condition:** The research artifact is concrete, scoped, and unambiguous enough that a TDD cycle can start without guesswork. `research_review_passed: true` set in state.

## Hard rules

- **Audit only, do not extend.** This phase verifies research is done — it does not redo the research. Missing items → back to `research`.
- **Zero ambiguities.** A single open assumption sends the loop back to `research`.
- **One slice only.** If the artifact describes more than one user-visible outcome, split — back to `research` with the smaller slice.

## Checklist

### 1. Goal statement

- [ ] Exactly one sentence stating the user-visible outcome.
- [ ] Mentions a user action or observable behavior, not an internal mechanism.
- [ ] Is small enough that the reviewer can imagine a single failing test that captures it.

### 2. Prior-art evidence

- [ ] The state file body records at least one grep / glob / read the research phase performed — names of files examined, keywords searched.
- [ ] A decision is recorded: either "reuse X" or "no prior art — greenfield".
- [ ] "I already knew the answer" is not acceptable evidence. If no searches happened, back to `research`.

### 3. Slice definition

- [ ] One concrete acceptance criterion in the form "When X, then Y".
- [ ] Explicit out-of-scope list of things deliberately not in this slice.
- [ ] The slice is small enough to fit in a single RED → GREEN cycle.

### 4. Ambiguities

- [ ] Every ambiguity raised in research has a recorded answer or a deliberate user decision.
- [ ] Zero open "I assume …" statements remain.

### 5. External-knowledge freshness

- [ ] If the slice touches a library / external API, the state file records a pointer to verified documentation (MCP docs tool, official spec, etc.). Training-data recall alone is not acceptable.

## Decision

- All items pass → set `research_review_passed: true` in state; `/development-loop next` enters `tdd-red`.
- Any item fails → record the failure in the state file's `Review findings`, set phase back to `research` via `/development-loop next-back` (handled by orchestrator), loop until clean.

## Red flags

- Goal sentence contains "and" between two user-visible outcomes.
- No record of any grep / glob / read.
- Acceptance criterion vaguer than "When X, then Y".
- Ambiguities recorded but not resolved.
- "Scope will become clear as we implement" — unacceptable.
