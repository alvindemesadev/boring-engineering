# Agentic benchmark — Tier A (roadmap)

Single-shot (Tier S, in `../tasks/tasks.json`) is cheap and runs the code, but it is not how a coding agent is used. Ponytail is right about that, and so is `boring-engineering`'s own v1 honest note.

Tier A will be the headline. Every cell is a **headless agent session editing a fresh clone of a real template repo**, scored on the `git diff` it leaves behind — not the lines in its answer.

## How it will differ from Tier S

| | Tier S (this repo, single-shot) | Tier A (this directory, agentic) |
|---|---|---|
| unit | one prompt → one code block | one ticket → one `opencode --agent boring` session in a temp workspace |
| baseline | same oneshot agent, no skill | same headless agent, no skill (`--agent` without ruleset) |
| task | "write this function" | "edit this repo to add/fix X" (ticket + seeded repo) |
| LOC | largest fenced block | `git diff --numstat` added lines, comments included, tests excluded |
| safety | 6 surgical tasks, adversarial execution | same 6 plus the repo's own edge cases |

## Template repo

We will pin a small, popular JS/TS template (likely `tiangolo/full-stack-fastapi-template` @ `cd83fc1` for direct comparability, plus a JS-only alternative such as `vercel/next.js` starter for the JS audience). The harness clones it once to `benchmarks/agentic/fixtures/` and each cell gets `Copy-Item -Recurse` into `runs/<stamp>/<arm>__<task>__<run>/`.

## Arms (same 5 as Tier S)

`baseline` · `boring-engineering v1.1` · `ponytail` · `caveman` · `yagni-oneliner`

Each arm is injected as a **real skill file** (`--agent` with the ruleset on disk), not an appended prompt line — mirroring how users actually install the skill. Isolation per arm via fresh process + fresh repo copy, like ponytail's `--setting-sources project,local` + `--plugin-dir`.

## Tickets (draft, 8-12 for Tier A LOC)

We will reuse the *intent* of our Tier S traps but as tickets that require touching multiple files, so reuse and platform shortcuts matter:

- **Reuse:** "Add `priceWithTax` to the store — `src/utils/formatMoney` already exists, reuse it."
- **Native:** "Add CSV export for the items table — use stdlib, not a CSV lib."
- **Abstraction:** "Add JPY display — siblings `formatUsd`/`formatEur` exist, don't abstract them together."
- **YAGNI:** "Add retry to `apiClient` — one caller today, no need for a `RetryPolicy` class."
- **Factory:** "Send welcome email on signup — one mailer, one email, no factory."

Plus 3–4 template-native tickets (e.g., duplicate item, bulk-delete, archive) where over-build has no room — the honest benchmark must show convergence.

## Running Tier A

```powershell
# 0) one-time: clone template at pinned commit (or set $env:TEMPLATE_DIR)
git clone https://github.com/fastapi/full-stack-fastapi-template ./fixtures/full-stack-fastapi-template
pushd ./fixtures/full-stack-fastapi-template; git checkout cd83fc1; popd

# 1) prove the scorers without an API
powershell -File ./run.ps1 -SelfTest

# 2) full run (example, 8 tickets × 5 arms × 4 runs × isolated workspaces)
powershell -File ./run.ps1 -Tasks t-csv,t-dropzone,t-reuse,t-jpy,t-retry,t-email,t-archive,t-search -Arms baseline,boring,ponytail,caveman,yagni -Runs 4 -Workers 4

# 3) rescore offline after a metric tweak, no API
powershell -File ./run.ps1 -Rescore runs/20260828-xxxx
```

Workspaces are kept under `runs/<stamp>/` and gitignored, so any metric change can be recomputed with `-Rescore` without paying the API twice.

## What Tier A can and cannot show

- **Can** show whether boring keeps code minimal *without* dropping a guard or shipping a stub, on real multi-file edits, with variance.
- **Cannot** claim production-readiness from ~8 tickets, and a deterministic safety check is a floor, not a proof.

This directory is scaffolded in v1.1. The first Tier A run will replace `../results/2026-08-28-boring-v1.1.md`'s headline when it lands.
