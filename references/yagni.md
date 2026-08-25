# YAGNI — You Aren't Gonna Need It

> Implement only what is required now. Do not build for hypothetical futures.

## What It Means

YAGNI is the discipline of building exactly what the current requirement asks for — nothing more. It is a direct counter to speculative generalization: the habit of adding flexibility, configuration, or extensibility "just in case."

The cost of unused code is not zero. It takes time to write, time to read, time to maintain, and time to delete when the future turns out differently than expected.

## Decision Rules

Before adding a feature, parameter, or abstraction, ask:

- Is this required by the current task or an explicit requirement?
- Is there a concrete, confirmed future need — or is this speculation?
- If this were removed today, would anything break?

If the answer to the last question is "no" — do not add it.

## What to Avoid

- Configuration options for behavior that has only one known value
- Plugin systems when there is one plugin
- Extension points for features that are not planned
- Abstract base classes for a concept that has one implementation
- Generic interfaces "so it's easy to swap later"
- Optional parameters that are never passed
- Feature flags for features that don't exist yet
- Utility functions written speculatively

## What YAGNI Looks Like in Practice

- A function takes the exact parameters it needs, not a catch-all options object
- A module exports only what is currently consumed
- A data model has only the fields the application currently uses
- Infrastructure is sized for current load, not theoretical future scale

## Exceptions

YAGNI does not mean ignoring legitimate forward planning:

- Explicit requirements from stakeholders count as "needed now"
- Security and compliance requirements must be built even if not yet triggered
- Performance headroom backed by measured projections is acceptable
- Established project patterns should be followed even when they feel like overhead

The test is always: **is this required, or am I predicting a requirement?**
