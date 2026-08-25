# Decision Framework — Deep Reference

This file is loaded on demand by `boring-engineering` when the agent needs detailed reasoning
behind the four-step decision process. For the quick-reference version, see `assets/decision-tree.md`.

---

## Why This Framework Exists

AI agents already know what KISS, YAGNI, and DRY mean. The failure mode is not ignorance of
the principles — it is applying them inconsistently, or not knowing exactly when a situation
calls for one over another.

This framework converts those principles into a concrete sequence of checks the agent runs
before and during implementation, with explicit branch conditions at each step.

---

## Step 1 — Requirement Filter (YAGNI)

**Principle:** You Aren't Gonna Need It.

**Check:** Is this explicitly required by the current task or a confirmed stakeholder requirement?

**Passes:**
- Functionality described directly in the task
- Behaviour implied by an explicit user story or acceptance criterion
- Security, validation, or error handling the task depends on

**Fails (do not build):**
- "It would be nice if…" additions
- Flexibility added "in case we need to swap this later"
- Configuration options with no current consumer
- Extension points for features that are not planned
- Generic infrastructure to support one concrete use case
- Abstractions for hypothetical future repetition

**Failure mode to avoid:** Scope creep disguised as good engineering. Adding plugin architecture to a feature that currently has one plugin is not forward-thinking — it is speculation dressed up as design.

---

## Step 2 — Reuse Check

**Check:** Does a solution already exist in the codebase?

**How to check:**
1. Search for functions, modules, or utilities that perform the same operation.
2. Check shared utility directories and existing service layers.
3. Prefer extending an existing solution over building a parallel one.

**Passes (reuse):**
- An existing function does the same thing, even if the naming is slightly different.
- An existing module handles this concern — add to it rather than creating a new one.

**Fails (build new):**
- Nothing exists that handles this.
- The existing solution is tightly coupled to a different context and extending it would create incorrect coupling.

**Failure mode to avoid:** Creating a second implementation of something that already exists because it was faster than searching. This is the most common source of meaningful duplication.

---

## Step 3 — Simplicity Check (KISS)

**Principle:** Keep It Simple.

**Check:** What is the simplest correct implementation?

**Prefer:**

| Instead of | Prefer |
|---|---|
| Manager / Handler / Provider class | Plain function |
| Interface + implementation for one consumer | Direct implementation |
| Event system with one listener | Direct function call |
| Utility extracted for single use | Inline logic |
| Custom infrastructure | Standard library |
| Deep nested folders | Flat module |
| Five files for twenty lines | One cohesive file |

**How to evaluate simplicity:**

Ask: could a reasonably experienced developer understand this without an explanation in under 60 seconds?

- Yes → acceptable complexity.
- No → simplify until yes, unless a legitimate exception applies.

**Failure mode to avoid:** Treating complexity as professionalism. Enterprise naming patterns (`AbstractBaseServiceFactory`), deep hierarchies, and layered indirection are not signals of quality — they are signals of speculative design. Simple code that correctly solves the problem is the professional choice.

---

## Step 4 — Abstraction Check (Practical DRY)

**Principle:** Don't Repeat Yourself — but prefer duplication over a wrong abstraction.

**Check:** Is a new abstraction, shared utility, or base class being introduced?

If yes, all three of the following must be true before abstracting:

### Condition A — Proven Repetition
The same logic must already exist in multiple real places in the codebase, not hypothetically.

- One use case → no abstraction.
- Two nearly identical implementations → still evaluate B and C before abstracting.
- Three or more identical implementations → strong signal for abstraction.

### Condition B — Shared Change Direction
All consumers of the abstraction must want the same change when the logic changes.

If consumer A and consumer B use similar code but would diverge under different future requirements, they are not the same abstraction — they are accidental similarity. Abstracting them creates coupling that makes both harder to change.

### Condition C — Clean Naming
The abstraction must be nameable with a single clear concept, without "and" or "or".

- `validateEmail` — clean. One concept.
- `validateEmailAndFormatUser` — two concepts. Not an abstraction, a procedure.
- `handleRequestOrFallback` — branching concern. Keep them separate.

If a name requires "and" or "or", the abstraction is doing two jobs. Split it or keep it direct.

**Failure mode to avoid:** DRY as a reflex. Seeing two similar-looking blocks of code and immediately extracting them is not good engineering — it is pattern-matching without judgment. Identical-looking code that represents different concepts will diverge. Coupling them makes that divergence painful.

---

## Abstraction Red Flags

These are signals that a proposed abstraction is wrong:

- It requires a `type`, `mode`, `strategy`, or `kind` parameter to branch behavior → it is two things pretending to be one.
- It has only one current consumer → it exists for a future that may not arrive.
- It is named after its implementation, not its concept (`DatabaseHelper`, `ApiUtils`, `CommonService`).
- Removing it would require rewriting its only consumer from scratch → it has created dependency, not reuse.
- It was created to avoid writing ten lines twice → the savings do not justify the coupling.

---

## When Complexity Is Always Justified

The following are never candidates for simplification. Do not reduce these in pursuit of KISS or YAGNI:

| Concern | Reason |
|---|---|
| Security and authentication | Correctness is a hard requirement |
| Input validation | Prevents data corruption and security vulnerabilities |
| Error handling and recovery | Reliability is a real requirement |
| Accessibility | Legal and ethical requirement |
| Performance (with measured evidence) | Evidence-based complexity is justified |
| Existing project architecture | Consistency is more valuable than local optimality |
| Explicit stakeholder requirements | Requirements are requirements |

---

## The Cost of Getting This Wrong

**Under-engineering** (not enough structure): logic in the wrong place, growing duplication that becomes painful, missing error handling, security gaps.

**Over-engineering** (too much structure): code that takes longer to read than to rewrite, abstractions that prevent rather than enable change, indirection that obscures what the code actually does, features that are never used.

The cost of over-engineering is often invisible until a requirement changes and the abstraction becomes a liability. The boring-engineering framework biases toward under-engineering deliberately — a direct implementation is almost always easier to refactor into a good abstraction than a premature abstraction is to simplify into a direct implementation.

Default to direct. Abstract when proven. Simplify before finishing.
