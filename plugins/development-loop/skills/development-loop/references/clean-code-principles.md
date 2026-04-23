# Clean Code Principles — Reference

This reference expands the compact list in the `development-loop` orchestrator skill. Every phase applies these — they are not style, they are correctness. Violations create bugs today or bugs next quarter.

---

## KISS — Keep It Simple

The simplest solution that meets the requirement is the correct one. Complexity is always a cost — paid in review time, in bug surface, in future-maintainer confusion.

**Heuristic:** If you cannot explain the design to another engineer in two sentences, it is too complex.

**Anti-pattern:** Adding a layer of indirection "for flexibility." The flexibility almost never materializes.

---

## YAGNI — You Aren't Gonna Need It

Do not build for imagined future requirements. Build for the concrete requirement in front of you. Future requirements arrive with specifics you could not predict; the speculative abstraction built for them rarely fits.

**Heuristic:** If no current test or user story requires it, delete it.

**Anti-pattern:** Config options, feature flags, or strategy patterns added because "someone might want to swap this later."

---

## DRY — Don't Repeat Yourself

Every piece of knowledge should have a single, authoritative representation. Duplication is a smell because a change to one copy requires finding and changing the others.

**Apply with care:** Two pieces of code that look similar today may diverge tomorrow. Premature DRY creates coupling between unrelated concerns. See Rule of Three.

---

## Rule of Three

Extract a shared abstraction only when three concrete call sites already exist. Two similar blocks may be coincidence; three means a pattern.

**Heuristic:** On the second occurrence, tolerate duplication. On the third, extract.

---

## SOLID

Five heuristics that, taken together, guide object-oriented design. They apply equally to modules and functions in non-OO languages.

### SRP — Single Responsibility Principle

A unit should have one reason to change. If a class responds to "the payment API changed" AND "the receipt format changed," split it.

### OCP — Open/Closed Principle

Open for extension, closed for modification. You should be able to add new behavior without editing existing code — typically by substituting a new implementation of a shared interface.

### LSP — Liskov Substitution Principle

Subtypes must be usable anywhere their base type is expected, without surprising callers. A subclass that throws on a method the base class doesn't throw on violates LSP.

### ISP — Interface Segregation Principle

Clients should not depend on methods they don't use. Prefer many small, purpose-specific interfaces over one large catch-all.

### DIP — Dependency Inversion Principle

High-level modules should not depend on low-level modules — both should depend on abstractions. Practically: inject concrete implementations at the boundary, keep the core free of infrastructure concerns.

---

## Law of Demeter

A unit should only talk to its immediate neighbors. Reaching through objects (`a.b.c.d.doThing()`) couples your code to the structure of things you shouldn't know about.

**Heuristic:** Count the dots. More than one is a smell.

---

## Separation of Concerns

Each module should own one concern. Parsing, validation, persistence, presentation — none of these should be entangled.

**Anti-pattern:** A "helper" that does three unrelated things because they happened to be needed together once.

---

## High Cohesion, Low Coupling

**High cohesion:** the things in a module belong together — change one, you likely change the others.
**Low coupling:** modules know as little as possible about each other's internals.

Cohesion and coupling trade off against size. Prefer small, cohesive units that communicate via narrow interfaces.

---

## Composition over Inheritance

Prefer assembling behavior from small collaborators over deep inheritance hierarchies. Inheritance creates rigid is-a relationships; composition creates flexible has-a relationships you can rewire.

---

## Tell, Don't Ask

Behavior belongs with the data it operates on. If you find yourself pulling data out of an object to decide what to do, the decision probably belongs inside the object.

---

## Command-Query Separation (CQS)

A method either performs an action (command) or returns a value (query) — not both. Queries should be free of side effects and safely callable multiple times.

---

## Principle of Least Astonishment

Code should behave the way a reasonable reader expects. Surprising names, surprising side effects, surprising return types — all are invitations to bugs.

---

## Fail Fast

Detect invalid state at the earliest boundary and crash loudly. Silently continuing with bad data produces bugs that manifest far from the cause.

**Apply at boundaries:** parse-don't-validate, assert invariants at entry, return early on invalid input.

---

## Boy Scout Rule

Leave the code cleaner than you found it — scoped to your current change. Fix the tiny inconsistency you touched. Do NOT drag unrelated cleanup into the loop.

---

## Occam's Razor

Prefer the simpler explanation / design that fits the evidence. Complexity in design must justify itself with concrete benefit, not imagined elegance.

---

## Information Hiding

Expose the smallest surface necessary. Implementation details should not leak across module boundaries. The less a caller knows, the freer the callee is to evolve.

---

## Immutability

Prefer values that do not change over time. Mutable state is the source of most concurrency bugs and most "why did this variable change?" debugging sessions. Mutate only when profiling says you must.

---

## Pure Functions

A function that depends only on its inputs and produces no side effects is cheap to test, reason about, and reuse. Keep the pure core pure; push side effects to the edges.

---

## Meaningful Names

Names are documentation. A good name eliminates the need for a comment.

- **Variables:** describe what the value represents, not its type or lifecycle.
- **Functions:** describe what they do, using a verb.
- **Booleans:** phrase as a predicate (`isReady`, `hasExpired`).
- **No single letters** except for well-established idioms (`i` in a tight numeric loop, `x/y` for coordinates).
- **No abbreviations** unless they are universal in the domain.

---

## Small Functions / Do One Thing

A function should do one thing, well, and at one level of abstraction. If you need to describe it with "and," split it.

**Heuristic:** More than ~20 lines, or more than 3 levels of nesting, is a smell.

---

## No Magic Numbers

Any non-obvious number or string literal deserves a name. `0.3` in pricing code is a bug waiting to happen; `DISCOUNT_RATE` is readable.

---

## No Dead Code

Delete unreached branches, unused exports, commented-out blocks. Version control is your history; dead code in the live codebase is only noise.

---

## No Premature Optimization

Write the clearest correct version first. Optimize only when profiling identifies a real bottleneck. Unmeasured "optimizations" usually make code worse with no benefit.

---

## No Premature Abstraction

Inline first, extract only when a real second (or third) call site appears. Abstractions built without concrete use cases almost always fail to fit the cases that eventually arrive.

---

## Applying these in the loop

- **research / research-review:** KISS and YAGNI shape the slice. Do not research for features that aren't in the slice.
- **tdd / tdd-review:** Meaningful names show up in test names; pure-function thinking helps isolate the unit under test.
- **implementation / implementation-review:** SRP, LSP, composition, tell-don't-ask, fail-fast, Principle of Least Astonishment all apply.
- **refactor / refactor-review:** Rule of Three governs extraction; information hiding governs what becomes a public API; Boy Scout Rule is scoped to this change.
- **overall-review:** every principle above is a checklist item. The static-analysis checklist operationalizes many of them.

Violations are not style — they are bugs that a reviewer must call out.
