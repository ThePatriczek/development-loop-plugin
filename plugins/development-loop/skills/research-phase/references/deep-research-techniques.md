# Deep Research Techniques — Reference

Companion to the `research-phase` skill. Concrete techniques for the five research checklist items.

---

## 1. Goal restatement

A good goal sentence:

- Names the user-visible outcome, not the technical mechanism.
- Is small enough that a single failing test can capture its absence.
- Does not contain "and" between two user-visible outcomes.
- Is written in present tense from the user's perspective.

**Good:** "A user can retry a failed API call automatically up to three times with exponential backoff."
**Bad:** "Add a `retryWithBackoff` wrapper." (mechanism, not outcome)
**Bad:** "Users can retry failed calls and see nicer error messages." (two outcomes — split)

When rewriting a vague goal, ask: *what can the user do after this change that they cannot do now?*

---

## 2. Grep-first reuse discovery

### Sweep order

1. **Keyword grep** — take two or three keywords from the goal and grep case-insensitively across the repo. Start broad, then narrow.
2. **Domain-directory glob** — look at directories whose names match the domain. Existing modules for `billing`, `auth`, `notifications` often already contain most of what a new feature needs.
3. **Config / manifest scan** — grep the project's package manifest for related dependencies. The project may already depend on a library that solves the problem.
4. **History scan** — `git log --all --oneline -- <candidate-file>` on files that look related. The commit messages often reveal why a given abstraction exists.

### Reading matches

For each promising match, open the file. Read the top-of-file comments, the exports, and one or two functions that seem closest to the goal. Decide: reuse / extend / greenfield.

### Cost discipline

Cap the research at roughly an hour for a small slice. If you cannot find prior art in that time, document "no prior art found after searching for X, Y, Z" and proceed as greenfield.

---

## 3. Slice sizing

### The "one failing test" rule

If you cannot imagine a single failing test that captures the user-visible outcome of this slice, the slice is too big or too vague. Split until you can.

### The "out of scope" list

Write an explicit list of things deliberately excluded from this slice. The list is part of the research artifact. It prevents scope drift during TDD and implementation.

**Example:**

> Slice: Users can retry failed GET calls up to three times with exponential backoff.
>
> Out of scope:
> - Retry for non-GET methods (separate slice — state-changing retries need idempotency analysis).
> - User-visible retry indicator (separate slice — UI work).
> - Configurable backoff schedule (separate slice — YAGNI for now).

---

## 4. Ambiguity resolution

### How to spot ambiguity

Read the goal and ask: "if I handed this to a stranger, would they make the same choice I'm about to make?"

Common ambiguity sources:

- **Quantifiers** — "some users," "often," "usually." How many? When?
- **Implicit contracts** — "retry on failure." On any failure, or only transient ones? What counts as transient?
- **Interactions** — "add X." Interaction with existing Y and Z is not specified.
- **Edge cases** — zero, one, many; empty input; null; timeout; partial failure.

### Resolving

For each ambiguity: resolve with evidence (existing code, docs, user decision) or escalate with a concrete question.

**Good escalation:** "Question: should retries apply to 4xx responses, or only 5xx / network errors? (I'd default to 5xx + network, per common practice.)"
**Bad escalation:** "Question: how should retries work?" (too vague to answer)

---

## 5. External-knowledge verification

### When it matters

Any time the slice touches:

- A third-party library's API.
- A platform feature (DNS, filesystem, OS IPC, etc.).
- A network protocol.
- A recent framework feature.

Training-data recall is frequently stale, wrong, or confabulated. Verify.

### How to verify

- **`context7` MCP** — fetches current library docs on demand. Preferred for widely-used libraries.
- **Official project docs** — the single source of truth. Always pick the version the project depends on, not `latest`.
- **Source inspection** — if docs are thin, read the library source for the specific function.
- **Specification** — for protocols (HTTP, OAuth, GraphQL, SQL), read the spec, not a blog post.

### Record the pointer

In the state file body, record where the information came from. A link / spec section / doc path is sufficient. This lets the tdd-review and overall-review agents re-verify.

---

## 6. Scope escape hatch — dispatching Explore

If the slice crosses an unfamiliar subsystem (multiple modules, unclear layering, new area of the codebase), dispatch an `Explore` subagent via the Agent tool before continuing research.

Prompt the subagent with:

- The exact goal sentence.
- The directories to explore.
- A request for: file map, data-flow summary, key abstractions, existing call sites.
- A report length cap (e.g., under 500 words).

Read the report. Update the slice definition. Then continue research.

**Skip-it red flag:** "I'll just read as I implement." That is how week-long surprises happen.

---

## Exit the phase cleanly

The research artifact in the state file body should contain, in order:

1. **Goal** — one sentence, user-visible outcome.
2. **Prior-art findings** — list of files / modules examined + decision (reuse / greenfield).
3. **Slice** — acceptance criterion in "When X, then Y" form.
4. **Out of scope** — explicit list of deferred items.
5. **Resolved ambiguities** — Q/A pairs.
6. **External sources** — pointers to verified documentation for any library / API touched.

When all six sections are present and concrete, the research-review-agent will pass.
