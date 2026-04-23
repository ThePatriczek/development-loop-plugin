# Security Review — Reference

Companion to the `overall-review` skill. Structured to follow the same section order as the skill's security checklist, with anti-patterns described in prose and detection recipes. Stack-agnostic — apply the intent of each item to whatever language / framework the diff uses.

---

## Input handling

### Boundary input validation

Every value originating outside the trust boundary must be validated before use. Boundaries include: HTTP request bodies / query params / headers, environment variables, files, external API responses, command-line arguments, stdin, message-queue payloads.

**Detection:** for each new request handler / CLI command / consumer, read the entry point. Confirm parsing + validation happens before business logic. "Parse, don't validate" patterns (converting into a narrow type that encodes constraints) are preferred over ad-hoc validation scattered through the code.

**Anti-pattern:** assuming a field has a particular shape because "the frontend always sends it that way."

---

### Dynamic code evaluation of untrusted input

Do not compile or evaluate strings derived from user input at runtime. Any mechanism that turns text into executable code is an injection vector: runtime eval / compile primitives, dynamic function constructors, template interpreters in string mode, deserializers that instantiate arbitrary types, etc.

**Detection:** grep the diff for the language's eval-family primitives and deserializers. Any match is suspect.

**Anti-pattern:** using a templating engine with raw interpolation of user-supplied values into HTML / SQL / shell / config strings.

---

### SQL and NoSQL injection

Database queries must be parameterized or use a safe query builder. Concatenating user input into query strings is injection.

**Detection:** grep the diff for string concatenation adjacent to query methods. Audit any "raw query" escape hatches in the ORM.

**Anti-pattern:** building a WHERE clause from user-controlled filter values with string concatenation.

---

### Path traversal

File paths derived from input must be normalized and checked against a whitelist / containment boundary before use. Directory-traversal segments must be rejected or resolved away; absolute paths must be rejected where relative are expected.

**Detection:** grep the diff for file operations (read, write, open, stat) where the path comes from input.

**Anti-pattern:** joining a base directory with an attacker-controlled filename and opening the result without normalization.

---

### Command injection

Shell / subprocess calls with input values must avoid unquoted interpolation. Prefer argv-style spawning (the variant of the subprocess API that takes the program and its arguments as separate parameters) over string-concatenated shell invocation.

**Detection:** grep for shell-invocation calls in the diff. Confirm each uses the argv form.

**Anti-pattern:** constructing a shell command by concatenating user input into a string and passing it to a one-argument shell-runner.

---

### Parser safety

JSON / XML / YAML parsers must handle malformed input without crashing, and must not enable unsafe features by default (XML entity expansion, YAML arbitrary object instantiation).

**Detection:** check parser configuration for safe defaults. Wrap parse calls in error handling that does not leak parser internals to the client.

---

## Output handling

### Output escaping for the rendering context

User-controlled output must be escaped for the destination context: HTML entities for HTML, URL encoding for URLs, JSON escaping for JSON, shell quoting for shell commands, parameter binding for SQL.

**Detection:** for any new output path, follow the data from source to sink. Confirm the last step before rendering escapes for the sink's context.

**Anti-pattern:** using a raw-HTML render primitive with user-supplied content. Frameworks usually provide a safe default — check that any escape hatch is deliberate and sanitized.

---

### Error message leakage

Error messages shown to clients must not contain secrets, internal paths, stack traces, or database error details. These are gold for attackers.

**Detection:** grep new error responses. Verify the client-facing string is a sanitized summary.

---

### Log hygiene

Logs must not include credentials, tokens, PII, or full request bodies when those bodies may contain secrets. Scrub at the logging middleware, not at each call site.

---

## Authn / authz

### Explicit authentication per endpoint

Every new endpoint / handler must have an explicit authentication check — no assumption that "the surrounding code handles it."

**Detection:** for each new route, read the handler top to bottom. Confirm authentication is checked before business logic.

---

### Per-request authorization

Authorization checks must run per request, using the authenticated identity — not a value from the client (hidden form field, cookie without integrity, query param).

**Anti-pattern:** trusting a role value that arrived in the request body without a server-side lookup.

---

### Central policy

New roles / permissions should be added to the central policy module, not inlined as string checks scattered through handlers.

---

## Secrets and dependencies

### Secret scanning

Scan the diff for hardcoded secrets using regex patterns such as (but not limited to):

- Cloud provider access keys (e.g., prefixed key formats used by major clouds).
- Private-key PEM headers.
- Platform personal-access-token prefixes.
- Chat / webhook tokens with recognizable prefixes.
- Payment-provider live / test secret keys.
- Generic long-literal assignments to identifiers named like `api_key`, `token`, `secret`.

Run a scanner against the diff. A real secret in the diff is always blocking.

---

### Dependency audit

Every added / upgraded dependency must be checked with whichever vulnerability-audit command the project uses. Audit output with high- or critical-severity advisories is blocking unless the project has a documented exception process.

---

### License compatibility

A new dependency's license must be compatible with the project's distribution terms. Copyleft licenses in a proprietary codebase are blocking.

---

## Crypto and auth tokens

### No custom crypto

Use the platform-provided crypto library. Do not roll your own hashing, encryption, or signing.

**Anti-pattern:** inventing a "simple" obfuscation scheme and using it as if it were encryption.

---

### Constant-time comparison

When comparing secrets (tokens, HMAC signatures, password hashes), use a constant-time comparator. Byte-by-byte short-circuit comparisons leak length / prefix information to a timing attacker.

---

### Session cookie hardening

Cookies used for authentication must have the hardening flags appropriate to the context (marking as HTTP-only, transport-secure, and with a same-site policy) set explicitly.

---

### Token lifecycle

Bearer / session tokens must have expiration and a rotation path. "Never expires" tokens are a standing liability.

---

## Business-logic traps

### Race conditions on check-then-act

Any flow that reads state, makes a decision, and writes based on that decision is unsafe when other actors can interleave between the check and the write. Wrap in a transaction, use an atomic compare-and-swap, or hold a lock.

---

### Integer overflow / underflow

Any arithmetic on values that can approach platform limits (money stored in base units, timestamps, counters, pagination offsets) needs overflow awareness. Some languages wrap silently; others throw; others use arbitrary precision. Know which and write tests for the boundary.

---

### Off-by-one in slicing / pagination

Pagination logic that confuses `>` with `>=`, or an offset with an index, tends to leak one record across pages or drop one per page. Write a test case at both boundaries.

---

### TOCTOU (time of check / time of use)

Any state read to make a decision, followed by an action based on that decision, is suspect when other actors can change the state between read and action. Applies to files, databases, shared memory, tokens.

---

## Threat-model oriented review

For any non-trivial feature, ask:

1. **Who is the attacker?** External user, authenticated but malicious user, compromised dependency, insider, operator.
2. **What is the asset?** Data, privilege, compute, reputation, availability.
3. **What new surface does this diff expose?** Endpoints, parsers, writes to shared state, trust boundaries crossed.
4. **What invariant did we assume?** Explicit or implicit — write it down and test for its violation.

If any question has no clear answer, the review is not done — back to the slice's owner.
