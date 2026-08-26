# boring-engineering vs ponytail — single-shot benchmark

Model: `opencode-go/muse-spark-1.2-contributor` · 300 runs total · median-of-N per cell · interleaved arm order
Ruleset hashes: baseline:none, caveman:bd665d22e0c6, yagni-oneliner:78791ea0fe19, ponytail:2a8d06b7a9bd, boring-engineering:96ff2d350d0e

## Overall (medians per call unless noted)

| metric | baseline | caveman | yagni-oneliner | ponytail | boring-engineering |
|---|---|---|---|---|---|
| runs | 60 | 60 | 60 | 60 | 60 |
| LOC of code block (median) | 14 | 11 | 2 | 7 | 9 |
| correctness pass rate | 37% | 65% | 73% | 78% | 98% |
| tokens per call (median, in+out+reasoning) | 1683 | 993.5 | 1305 | 1289 | 987 |
| latency ms (median) | 37833 | 32896.5 | 34314.5 | 31684.5 | 29480.5 |
| total cost USD (all runs) | $0.0217 | $0.0131 | $0.0154 | $0.0154 | $0.0141 |
| responses without code block | 1 | 0 | 0 | 2 | 1 |

## Per task (median LOC · pass rate)

| task | baseline | caveman | yagni-oneliner | ponytail | boring-engineering |
|---|---|---|---|---|---|
| t1-slugify | 13 · 80% | 9 · 100% | 1 · 100% | 3 · 100% | 3 · 100% |
| t2-parsequery | 33.5 · 20% | 31 · 100% | 2 · 100% | 19 · 60% | 12 · 100% |
| t3-reuse | 6 · 100% | 5 · 100% | 3 · 100% | 5 · 100% | 5 · 100% |
| t4-jpy | 4 · 100% | 3 · 100% | 1 · 100% | 4 · 100% | 4 · 100% |
| t5-retry | 15 · 60% | 13 · 100% | 2 · 100% | 7 · 100% | 12 · 100% |
| t6-welcome-email | 9 · 0% | 8 · 40% | 1 · 60% | 3 · 100% | 3 · 100% |
| s-safe-path | 22 · 0% | 11 · 0% | 3 · 0% | 9 · 0% | 8.5 · 80% |
| s-sql-param | 7 · 60% | 6 · 60% | 1 · 100% | 3 · 100% | 3 · 100% |
| s-rate-limit | 14 · 0% | 12 · 20% | 3 · 80% | 13 · 100% | 11 · 100% |
| s-auth-token | 30 · 0% | 27 · 0% | 4 · 0% | 19 · 0% | 21 · 100% |
| s-csv-sum | 27 · 0% | 21 · 60% | 3 · 60% | 18 · 100% | 17 · 100% |
| s-cache | 12 · 20% | 11 · 100% | 2 · 80% | 9 · 80% | 9 · 100% |

## Methodology

- Single-shot generation via opencode CLI, tool-less `oneshot` agent, default temperature.
- Arms differ only in prepended ruleset text (baseline gets none); identical task prompts otherwise.
- LOC = non-empty lines of the largest fenced code block in the response.
- Correctness = generated solution executed against per-task node test files (exit 0 within 15s).
- Tokens/cost from gateway-reported usage events; latency = wall clock including CLI startup.
- Arm order rotated per (run, task) pair; sequential execution.
