# DRY — Don't Repeat Yourself (Practical)

> Avoid unnecessary duplication — but prefer duplication over a premature abstraction.

## What It Means

DRY is about avoiding **meaningful** duplication: the kind where the same logic exists in multiple places and a change to one requires a matching change to all others.

It is not about eliminating every repeated line of code. Some duplication is accidental similarity, not shared logic — and abstracting it creates coupling that makes future changes harder, not easier.

## The Real Rule

Abstract when:
- The same **logic** (not just similar-looking code) appears in **multiple proven places**
- A change to the logic would need to be applied in all those places
- The abstraction has a single, clear name and responsibility

Do not abstract when:
- Two pieces of code look similar but represent different concepts
- There is only one use case so far
- The abstraction would require parameters or flags to handle variations
- You are anticipating future repetition that has not happened yet

## Decision Rules

Before creating a shared abstraction, ask:

- Does this logic actually appear more than once right now?
- If I change the shared behavior, do all call sites actually want that change?
- Can I name this abstraction without using "and" or "or"?
- Am I extracting because of proven need, or because it feels cleaner?

If the answer to the last question is "feels cleaner" — leave it duplicated until the need is proven.

## The Wrong Way to Apply DRY

```
// Two functions that look similar but are independent concepts
function formatUserDisplayName(user) { ... }
function formatProductLabel(product) { ... }

// Wrong: abstracting them because they both "format a string"
function formatLabel(entity, type) { ... }  // now coupled, harder to change independently
```

## The Right Way to Apply DRY

```
// The same validation logic used in three separate form handlers
// Correct: extract it once, with a clear name
function validateEmailFormat(email) { ... }
```

## Exceptions

- Small, truly incidental duplication (two-line helpers) is often fine to leave as-is
- Duplication across module or service boundaries is sometimes intentional to preserve independence
- Test code has more tolerance for duplication — clarity matters more than DRY in tests
