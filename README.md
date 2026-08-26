# boring-engineering

> Build exactly what the current problem requires. No less, no more.

An AI agent skill that turns KISS, YAGNI, and practical DRY into a concrete decision system — so your coding agent stops overengineering by default.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Agent Skills Spec](https://img.shields.io/badge/Agent_Skills-compatible-blue)](https://agentskills.io)
[![Compatible with](https://img.shields.io/badge/works_with-40%2B_agents-green)](#setup)

---

## The Problem

AI agents already know what KISS, YAGNI, and DRY mean. What they consistently fail at is knowing **when** to apply them.

Left alone, agents tend to:
- Add abstractions before there's a second use case
- Build plugin systems for features with one consumer
- Create `BaseServiceFactory` for a function that needs 10 lines
- Future-proof code for requirements that never arrive

`boring-engineering` fixes this by giving the agent a concrete **4-step decision system** it runs before and during every implementation — not just a reminder to "keep it simple."

---

## How It Works

The skill loads in three stages (Agent Skills progressive disclosure):

**Stage 1 — Discovery (~100 tokens)**
At startup, the agent reads only the `name` and `description` from `SKILL.md` frontmatter. This is how it knows the skill exists without loading the full content.

**Stage 2 — Activation**
When you ask the agent to implement, refactor, or review code, it recognises the task matches this skill and loads the full `SKILL.md` body into context.

**Stage 3 — Deep Reference (on demand)**
If the agent needs to reason through a complex decision, it loads `references/decision-framework.md` or `assets/decision-tree.md` — only when the instructions point to them. These files never inflate context unnecessarily.

### The 4-Step Decision System

Every time the agent writes or modifies code, it runs through:

```
Step 1 — Requirement Filter (YAGNI)
  Is this explicitly required? → NO: don't build it. YES: continue.

Step 2 — Reuse Check
  Does something already exist? → YES: reuse it. NO: continue.

Step 3 — Simplicity Check (KISS)
  What is the simplest correct solution? → Implement that.

Step 4 — Abstraction Check (Practical DRY)
  Is a new abstraction justified by proven repetition? → NO: keep it direct.
```

Full decision tree: [`assets/decision-tree.md`](./assets/decision-tree.md)
Deep reasoning: [`references/decision-framework.md`](./references/decision-framework.md)

---

## Setup

### Option 1 — Clone the repo

```bash
git clone https://github.com/alvindemesadev/boring-engineering.git
```

Then copy the skill into your agent's skills directory (see per-tool instructions below).

### Option 2 — Copy just the SKILL.md

If you only want the core skill without the reference files:

```bash
curl -O https://raw.githubusercontent.com/alvindemesadev/boring-engineering/main/SKILL.md
```

---

### Compatibility

This skill uses the [Agent Skills open spec](https://agentskills.io) — a standard supported by 40+ tools as of 2026. One `SKILL.md`, any compatible agent.

| Agent | Skills directory |
|---|---|
| Claude Code | `.claude/skills/boring-engineering/` |
| Kiro (AWS) | `.kiro/skills/boring-engineering/` |
| Cursor | `.cursor/skills/boring-engineering/` |
| GitHub Copilot | `.github/skills/boring-engineering/` |
| OpenAI Codex | `.codex/skills/boring-engineering/` |
| Gemini CLI | `.gemini/skills/boring-engineering/` |
| OpenCode | `.opencode/skills/boring-engineering/` |
| Windsurf | `.windsurf/skills/boring-engineering/` |
| Goose (Block) | `.goose/skills/boring-engineering/` |
| Roo Code | `.roo/skills/boring-engineering/` |
| Amp | `.amp/skills/boring-engineering/` |
| Any other compatible tool | Check your tool's docs for the skills directory |

> Consult your specific tool's documentation to confirm the exact path — most follow the `.toolname/skills/` convention but some vary.

### Install into your agent

#### Claude Code

```bash
mkdir -p .claude/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .claude/skills/boring-engineering/SKILL.md

# Optional: copy reference files for on-demand loading
cp -r /path/to/boring-engineering/references .claude/skills/boring-engineering/
cp -r /path/to/boring-engineering/assets .claude/skills/boring-engineering/
```

#### Kiro

```bash
mkdir -p .kiro/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .kiro/skills/boring-engineering/SKILL.md

# Optional: reference files
cp -r /path/to/boring-engineering/references .kiro/skills/boring-engineering/
cp -r /path/to/boring-engineering/assets .kiro/skills/boring-engineering/
```

#### Cursor

```bash
mkdir -p .cursor/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .cursor/skills/boring-engineering/SKILL.md
```

#### OpenAI Codex

```bash
mkdir -p .codex/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .codex/skills/boring-engineering/SKILL.md
```

#### Gemini CLI

```bash
mkdir -p .gemini/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .gemini/skills/boring-engineering/SKILL.md
```

#### OpenCode

```bash
mkdir -p .opencode/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .opencode/skills/boring-engineering/SKILL.md
```

#### Any other Agent Skills-compatible tool

```bash
mkdir -p .<toolname>/skills/boring-engineering
cp /path/to/boring-engineering/SKILL.md .<toolname>/skills/boring-engineering/SKILL.md
```

---

## How to Use

Once installed, the skill activates **automatically** — no slash command or explicit invocation needed.

### It activates when you:

| What you say | What triggers |
|---|---|
| "Implement a user auth endpoint" | Feature implementation |
| "Refactor this service class" | Refactoring task |
| "Should I abstract this into a utility?" | Abstraction decision |
| "Is this too complex?" | Complexity review |
| "How should I structure this module?" | Architecture decision |
| "Review this code" | Code review |

### It stays silent when you:

- Ask about deployment or CI/CD
- Debug a runtime error unrelated to code structure
- Configure infrastructure

### What the agent does differently

**Without the skill — agent receives:** "Add a notification system"

```
Creates:
- NotificationService (abstract)
- EmailNotificationProvider
- PushNotificationProvider
- NotificationFactory
- NotificationRegistry
- INotificationStrategy (interface)
```

**With the skill — agent runs the 4-step filter:**

1. What's required? → Send an email notification on signup
2. Anything reusable? → No existing notification code
3. Simplest correct solution? → One function, one transport
4. Abstraction needed? → One use case, no proven repetition → keep direct

```js
// notifications.js
export async function sendSignupEmail(user) {
  await mailer.send({
    to: user.email,
    subject: 'Welcome',
    html: welcomeTemplate(user),
  });
}
```

---

## Example

More before/after comparisons:

- [`examples/bad-abstractions.md`](./examples/bad-abstractions.md) — patterns to avoid
- [`examples/good-abstractions.md`](./examples/good-abstractions.md) — patterns to follow
- [`examples/before-after.md`](./examples/before-after.md) — real refactoring comparisons

---

## Repo Structure

```
boring-engineering/
├── SKILL.md                          # The skill — this is what you install
├── README.md
├── LICENSE
│
├── assets/
│   └── decision-tree.md              # Full decision flow in one view (loaded on demand)
│
├── references/
│   ├── decision-framework.md         # Deep reasoning for each decision step
│   ├── kiss.md                       # KISS principle + decision rules
│   ├── yagni.md                      # YAGNI principle + decision rules
│   └── dry.md                        # Practical DRY + when NOT to abstract
│
└── examples/
    ├── bad-abstractions.md           # Patterns to avoid
    ├── good-abstractions.md          # Patterns to follow
    └── before-after.md              # Real refactoring comparisons
```

---

## Principles

### KISS — Keep It Simple
Prefer the simplest solution that is clear, maintainable, and correct. No unnecessary layers, patterns, or indirection. → [`references/kiss.md`](./references/kiss.md)

### YAGNI — You Aren't Gonna Need It
Implement only what is required now. No configuration options, extension points, or abstractions for hypothetical futures. → [`references/yagni.md`](./references/yagni.md)

### Practical DRY — Don't Repeat Yourself
Avoid meaningful duplication — but prefer duplication over a premature abstraction. Abstract only when the same logic exists in multiple real places and would need the same change. → [`references/dry.md`](./references/dry.md)

---

## Benchmark — v1.1 (12 tickets × 5 arms × 5 tries) — **fresh unbiased GO, 300/300**

Honest 2-tier design inspired by ponytail's [agentic benchmark](https://github.com/DietrichGebert/ponytail/blob/main/benchmarks/results/2026-06-18-agentic.md) — not a copy, same rigor (real file to reuse, 5 arms, fresh sandbox per cell, `n=5`). This is the **unbiased 300-cell re-run** on `opencode-go/muse-spark-1.2-contributor` (GO plan) — fully interleaved, no additive bias, no throttling.

| vs baseline (300 runs, GO) | LOC | Tokens | Correct |
|---|--:|--:|--:|
| **boring v1.1** | **-36%** (14 → 9) | **-41%** | **98%** (59/60) |
| ponytail | -50% (14 → 7) | -23% | 78% |
| yagni-1liner | **-86%** (14 → 2) | -22% | 73% |
| caveman | -21% (14 → 11) | -41% | 65% |
| baseline | — | — | 37% |

**Safety (6 tasks, 30 runs/arm, GO):** boring **97% safe (29/30)** vs ponytail 63% vs yagni 57% vs caveman 44% vs baseline 30% — the guards yagni/ponytail cut on `auth-token`/`safe-path` are the lines boring keeps. Full per-task tables, setup, and honest limitations → [`benchmarks/results/2026-08-28-boring-v1.1.md`](./benchmarks/results/2026-08-28-boring-v1.1.md).

**Tier A — agentic (`git diff` on real repo)** is scaffolded in [`benchmarks/agentic/`](./benchmarks/agentic/) and will replace this headline when it lands. Tier S is generation size; Tier A is diff size.

---

## What This Skill Won't Remove

Simplicity is the default. These are always respected and never simplified away:

- Security and authentication
- Input validation and error handling
- Accessibility compliance
- Performance (with measured evidence)
- Reliability and fault tolerance
- Existing project architecture and conventions
- Explicit stakeholder requirements

---

## License

MIT © [Alvin de Mesa](./LICENSE)
