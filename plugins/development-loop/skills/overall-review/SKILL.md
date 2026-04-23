---
name: overall-review
description: This skill should be used when the development-loop state file has `phase: overall-review`, or when the user says "overall review", "final review", "pre-merge review", "deep review", "static analysis", "security review", "run the quality gates". Drives the final, DEEP gate — context-detected static analysis, security audit, clean-code audit, and optional Playwright MCP E2E smoke test. Runs AFTER per-step reviews (research-review, tdd-review, implementation-review, refactor-review) have all passed. Automatically loaded by the `development-loop` orchestrator; an agent-type hook enforces this skill is loaded before the phase's checks run.
---

# OVERALL REVIEW Phase — DEEP (final gate)

**Entry condition:** `phase: overall-review`, all per-step reviews passed, tests green, implementation + refactor complete.
**Exit condition:** Static analysis clean, security checklist passed, clean-code audit done, E2E run (or explicitly skipped), zero unresolved blocking findings. `review_passed: true` set in state.

## Hard rules

- **Reviewer mindset, not author.** Read the diff as if someone else wrote it. Defend nothing.
- **Context-detected, not generic.** Run the static analysis and quality gates **that this specific project already uses**. Do not invent new ones.
- **No findings ignored.** Every finding is either fixed, or explicitly deferred with a written reason.
- **E2E when available.** If a Playwright MCP is installed, run a golden-path smoke test. If not, mark as skipped — do not simulate.

## 0. Discover and load relevant skills (MANDATORY)

Before running any check, discover which skills the environment already configures for review and load them. An agent-type hook enforces this — skipping it causes the hook to block the phase.

### Project-level

- [ ] Read the repo's `CLAUDE.md` and every nested `CLAUDE.md` under the workspace tree. Look for sections named "Skill Loading Policy", "Review", "Quality gates", "Commit", "Deploy", "Skills". Load every skill those sections prescribe for pre-commit / pre-merge / pre-deploy.
- [ ] List `.claude/skills/*/SKILL.md`. For each, read frontmatter `description`. Load any whose triggers mention review, commit, security, lint, typecheck, quality, gate, boundaries, audit.

### User-level

- [ ] List `~/.claude/skills/*/SKILL.md` and the plugin-registered skills visible in the session. Load any whose description mentions review, security, static analysis, commit, or quality.

### Plugin-level

- [ ] In session, enumerate available skills registered by plugins. Trigger any whose domain overlaps with the diff.

### Rule of thumb

Do not re-implement in this skill what a project-specific skill already owns. This skill orchestrates — project skills do the actual checking for their domain.

## 1. Context-detected static analysis (MANDATORY)

Detect and run **only the tools the project already configures**. Do not install new ones. Do not assume a stack.

### Detection procedure

Walk the repo and identify the project's own quality gates, in this order of preference:

1. **Project-authored aggregate command.** If the repo's README, `CLAUDE.md`, or package manifest defines a single command intended as "the pre-merge gate" (names vary by ecosystem — look for keywords like `check`, `verify`, `ci`, `prebuild`, `lint-all`), run that. It encodes the project's own opinion about which gates are required.
2. **Per-tool scripts in the package manifest.** If the package manifest (e.g., a `package.json`, `pyproject.toml`, `Gemfile`, `Cargo.toml`, `go.mod`, `build.gradle`, `pom.xml`, etc.) declares scripts such as lint, typecheck, format-check, test — run them.
3. **Config files for tools not wired into scripts.** If the repo has configuration files for linters, type checkers, style checkers, or dependency-cruising tools but no script to run them, invoke those tools directly using whichever runner the project uses.
4. **Defer to a project skill.** If a project skill (e.g., one invoked from `CLAUDE.md`) owns the gate, delegate. Do not duplicate.

**Scope:** Where the tool supports it, run on changed files only (`git diff --name-only HEAD` against the branch base) to keep feedback fast. Full-repo runs only if the project configures it that way.

### What if nothing is configured?

If the project has no static-analysis tooling at all, do NOT introduce one in this loop. Record "no static-analysis tooling in repo" as a finding to address in a separate, dedicated loop. This phase's job is to run **what exists**, not to establish a new toolchain.

## 2. Security review (MANDATORY)

Review the diff against this checklist. Each item is stack-agnostic — apply the intent to whatever language / framework the diff uses.

### Input handling

- [ ] Every boundary input (user input, HTTP body, query parameter, environment variable, file contents, external API response) is validated before use.
- [ ] No dynamic code evaluation of untrusted strings — no runtime compilation of attacker-controlled text, no template rendering of untrusted input without escaping.
- [ ] Database queries are parameterized / use a safe query builder — never concatenated from untrusted strings. Check for any raw-query escape hatches.
- [ ] Path handling normalizes and rejects directory traversal; rejects absolute paths where relative are expected.
- [ ] Shell / subprocess calls avoid unquoted variable interpolation; prefer argv-style invocation over concatenated shell strings.
- [ ] Parsers (JSON, XML, YAML, etc.) handle malformed input without crashing and without enabling unsafe features (e.g., XML entity expansion, YAML deserialization of arbitrary types).

### Output handling

- [ ] User-controlled output is escaped for the rendering context (HTML, URL, JSON, shell, SQL).
- [ ] Error messages do not leak secrets, stack traces, or internal paths to the client.
- [ ] Logs do not include credentials, tokens, PII, or full request bodies with secrets.

### Authn / authz

- [ ] Every new endpoint / handler has an explicit authentication check. No "protected by convention."
- [ ] Authorization checks happen per-request, using the session / token, not trusted client state.
- [ ] New roles / permissions are added to the central policy, not inline.

### Secrets & dependencies

- [ ] No hardcoded secrets. Scan the diff for common secret patterns (cloud provider access keys, chat/webhook tokens, private-key headers, platform tokens, payment-provider keys, generic long-literal `key=`/`token=` assignments). See `references/security-review.md` for the pattern set.
- [ ] New dependencies audited: run whichever vulnerability-audit command the project uses.
- [ ] New dependency licenses are compatible with the project's.

### Crypto & auth tokens

- [ ] No custom crypto. Use the platform library.
- [ ] Token comparisons use constant-time comparison where secrets are involved.
- [ ] Session-auth cookies have the appropriate hardening flags for their context.
- [ ] Session / bearer tokens have expiration and rotation.

### Business-logic traps

- [ ] Race conditions: check-then-act sequences protected by locks / transactions / atomic ops.
- [ ] Integer overflow / underflow for money, quantity, timestamps.
- [ ] Off-by-one errors in pagination, slicing, range checks.

Full detail and anti-examples: `references/security-review.md`.

## 3. Static-analysis checklist (MANDATORY, code-level)

Items not caught by linters — a human reviewer must still verify:

- [ ] Cyclomatic complexity: no function with more than ~10 branches. Extract.
- [ ] Nesting: no more than 3 levels of nesting. Refactor with early returns / guard clauses.
- [ ] Coupling: a new module's imports fit the layering rules (data → domain → presentation, never reverse) as documented by the project.
- [ ] Cohesion: each module's exports tell a single story.
- [ ] Dead code: no unreferenced exports, no unreachable branches, no disabled tests.
- [ ] Error paths: every error-handler has a purposeful action — no swallowing, no re-wrapping without adding context.
- [ ] Side effects in constructors / module-level code: flag and move to explicit init.
- [ ] No N+1 queries introduced (database, HTTP).
- [ ] No unbounded memory / list growth in long-running loops.

Full detail: `references/static-analysis-checklist.md`.

## 4. Clean-code audit (MANDATORY)

Re-read the diff one final time for:

- [ ] Names reveal intent. A stranger understands each identifier without the surrounding context.
- [ ] Functions do one thing. If you describe a function with "and," split it.
- [ ] No comments restating code. Keep only comments that explain **why**, not **what**.
- [ ] No scope creep — nothing in the diff that isn't required by this slice.
- [ ] No `TODO`, `FIXME`, debug prints, or debugger statements left behind.
- [ ] Follows the conventions of the nearest existing file of the same kind.

Violations → back to `implementation` via `/development-loop next` rollback (abort + restart at implementation, or direct edit and re-review).

## 5. E2E smoke test — Playwright MCP (conditional)

**Goal:** Confirm the golden user-visible path still works end-to-end.

### Precondition detection

- [ ] Check whether Playwright MCP tools are available in this session. Look for MCP tools under a `playwright` namespace (concrete naming depends on the user's MCP configuration).
- [ ] If the tools are NOT present, set `e2e_skipped: true` in state, add a reviewer note ("Playwright MCP unavailable — E2E skipped"), and proceed to exit. Do not try to install Playwright ad-hoc in this loop.
- [ ] If the diff has no user-visible surface (pure backend, pure library, pure CLI with no UI), set `e2e_skipped: true` with reason "no UI surface in diff".

### E2E procedure (when MCP available)

If Playwright MCP is available AND the diff touches UI:

- [ ] Identify the golden path for the feature — the single user flow most representative of the change (derive it from the goal sentence).
- [ ] Start or point at a running dev server. Do NOT assume a production URL. If no local dev server is documented in the repo's README / `CLAUDE.md`, stop and ask the user.
- [ ] Use Playwright MCP tools to: navigate to the route, snapshot the starting state, interact (click / type / fill) to exercise the goal, snapshot the resulting state, and read the browser console.
- [ ] Record observations: pass / fail, any console errors, any visual regressions.
- [ ] On failure: mark review as failed, return to `implementation` (via abort+restart or user decision).
- [ ] On pass: set `e2e_run: true`.

### Scope

Keep the E2E to the **golden path only**. Branch coverage, edge cases, and negative paths are the job of the project's own E2E suite — this is a smoke test.

## 6. Record findings

Append findings to the state file body under a `Review findings` section with two sub-sections: `Blocking` and `Non-blocking (deferred, new loop)`. Each entry should cite file + line + short description + fix needed / reason deferred.

Blocking findings must be fixed before exit. Non-blocking findings are documented in a new loop or issue — do not silently accept them.

## Exit this phase

Only advance when **all** of:

- All prescribed project skills have been loaded and run.
- All detected static-analysis tools ran cleanly (or their findings are fixed).
- Security checklist is complete.
- Clean-code audit is complete.
- E2E has either run and passed, or is explicitly `e2e_skipped` with a reason.
- Zero blocking findings remain.

Set `review_passed: true` in state. Main session then decides: `/development-loop done` (goal met) or `/development-loop next` (LOOP back to research for the next slice).

## Red flags

- "It's fine, trust me" — if you cannot point to a clean gate run, it isn't fine.
- Adding a new linter / tool / framework in this phase. Out of scope.
- Disabling a lint rule to make the gate pass. Fix the root cause.
- Skipping security checklist because "it's just a tiny change." Biggest-impact vulns come from tiny changes.
- Running E2E against production to save time. Never.
- Marking E2E skipped to move faster when the MCP is actually present and the diff has UI.

## Additional resources

- `references/static-analysis-checklist.md` — full code-level review items.
- `references/security-review.md` — full checklist with anti-examples per category, including secret-pattern regexes.
