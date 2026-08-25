# Decision Tree — Quick Reference

Use this as a single-view reference for the full boring-engineering decision flow.

```
┌─────────────────────────────────────┐
│   Is this explicitly required by    │
│   the current task or requirement?  │
└─────────────────────────────────────┘
              │
       NO ────┤──── YES
       │             │
       ▼             ▼
  Don't build    Does it already
  it. Stop.      exist in the
                 codebase?
                    │
             YES ───┤─── NO
              │          │
              ▼          ▼
           Reuse    What is the simplest
           it.      correct implementation?
           Stop.         │
                         ▼
                    Implement it.
                         │
                         ▼
              Does this involve a new
              abstraction, utility,
              or base class?
                    │
             NO ────┤──── YES
              │              │
              ▼              ▼
            Done.    Does the logic appear
                     in multiple real places
                     RIGHT NOW?
                          │
                   NO ────┤──── YES
                    │              │
                    ▼              ▼
               Keep it      Would all those
               direct.       places want the
               Done.         same change?
                                  │
                          NO ─────┤──── YES
                           │               │
                           ▼               ▼
                      Keep it       Can it be named
                      direct.       clearly without
                      Done.         "and" / "or"?
                                         │
                                 NO ─────┤──── YES
                                  │               │
                                  ▼               ▼
                             Keep it        Abstract only
                             direct.        the shared
                             Done.          behavior.
                                            Done.
```

## Shorthand Rules

| Signal | Action |
|---|---|
| Not required | Don't build it |
| Already exists | Reuse it |
| One use case | Keep it direct |
| One known value | No config option |
| No current consumers | No abstraction |
| Type/mode flag needed | Two things, not one |
| Can't name it cleanly | Not a real abstraction |
| Multiple real consumers + shared change | Abstract it |

## Complexity Is Always Allowed For

Security · Error handling · Validation · Accessibility ·
Performance (measured) · Reliability · Project conventions ·
Explicit stakeholder requirements
