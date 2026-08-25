# KISS — Keep It Simple

> Prefer the simplest solution that is clear, maintainable, and correct.

## What It Means

KISS is not about writing fewer lines. It is about avoiding **unnecessary complexity** — layers, patterns, and abstractions that exist without a clear, present justification.

Simple code is easier to read, easier to debug, easier to change, and less likely to contain hidden bugs.

## Decision Rules

Before adding complexity, ask:

- Does this complexity solve a problem that actually exists right now?
- Would a junior developer understand this in under 60 seconds?
- Am I adding this layer because the problem requires it, or because it feels more professional?

If the answer to the last question is "feels more professional" — remove it.

## What to Avoid

- Wrapping simple operations in unnecessary classes or services
- Adding indirection (managers, handlers, providers) for code that is used in one place
- Using a design pattern when a plain function would work
- Splitting a 20-line module into five files because it "might grow"
- Naming things with enterprise vocabulary (`AbstractBaseServiceFactory`) for trivial behavior

## What Simple Looks Like

- Functions that do one thing and are named after what they do
- Flat structure over deep nesting
- Direct calls over event systems when there is only one listener
- Inline logic over extracted utilities when the logic is only used once
- Standard library over custom infrastructure

## Exceptions

KISS does not mean ignoring legitimate complexity. These are always valid reasons to add complexity:

- Security requirements
- Error handling and recovery
- Performance constraints with measured evidence
- Existing project architecture and conventions
- Accessibility requirements
- Reliability and fault tolerance

Do not use KISS as an excuse to skip necessary safeguards.
