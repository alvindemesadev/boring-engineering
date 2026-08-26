# boring-engineering vs ponytail — single-shot benchmark

Model: `opencode/muse-spark-1.2-contributor-free` · 295 runs total · median-of-N per cell · interleaved arm order
Ruleset hashes: boring-engineering:8817193dfda4, ponytail:002119891a28, baseline:none, boring-engineering-v11:d75663a32ede, boring-engineering-v12:c911311b4b51, caveman:bd665d22e0c6, yagni-oneliner:78791ea0fe19, ponytail:2a8d06b7a9bd, boring-engineering:96ff2d350d0e

## Overall (medians per call unless noted)

| metric | boring-engineering | ponytail | baseline | boring-engineering-v11 | boring-engineering-v12 | caveman | yagni-oneliner |
|---|---|---|---|---|---|---|---|
| runs | 49 | 50 | 49 | 30 | 30 | 43 | 44 |
| LOC of code block (median) | 9 | 5 | 12 | 7 | 4 | 9 | 2 |
| correctness pass rate | 92% | 72% | 41% | 100% | 100% | 67% | 61% |
| tokens per call (median, in+out+reasoning) | 1067 | 1168.5 | 1371 | 1135 | 1061.5 | 928 | 1103 |
| latency ms (median) | 21180 | 21242.5 | 25886 | 17922 | 19020 | 17621 | 22454 |
| total cost USD (all runs) | $0.0000 | $0.0000 | $0.0000 | $0.0000 | $0.0000 | $0.0000 | $0.0000 |
| responses without code block | 3 | 4 | 3 | 0 | 0 | 3 | 5 |

## Per task (median LOC · pass rate)

| task | boring-engineering | ponytail | baseline | boring-engineering-v11 | boring-engineering-v12 | caveman | yagni-oneliner |
|---|---|---|---|---|---|---|---|
| t1-slugify | 9 · 100% | 3 · 100% | 13 · 100% | 4 · 100% | 3 · 100% | 9 · 100% | 1.5 · 100% |
| t2-parsequery | 33 · 100% | 13 · 80% | 37 · 40% | 17 · 100% | 21 · 100% | 28 · 100% | 4 · 50% |
| t5-retry | 12 · 100% | 7 · 100% | 14 · 20% | 12 · 100% | 13 · 100% | 14 · 100% | 4.5 · 50% |
| t6-welcome-email | 7 · 80% | 3 · 60% | 9 · 0% | 7 · 100% | 3 · 100% | 8 · 0% | 1 · 50% |
| t3-reuse | 6 · 100% | 5 · 100% | 6 · 100% | 5 · 100% | 4 · 100% | 5 · 100% | 2 · 100% |
| t4-jpy | 4 · 100% | 4 · 40% | 3 · 60% | 4 · 100% | 4 · 100% | 3 · 100% | 2 · 75% |
| s-sql-param | 3 · 100% | 3 · 100% | 7 · 25% | - · NaN% | - · NaN% | 6 · 75% | 1 · 100% |
| s-rate-limit | 11 · 75% | 11 · 50% | 18 · 25% | - · NaN% | - · NaN% | 12 · 25% | 1 · 50% |
| s-auth-token | 21 · 75% | 20 · 0% | 32 · 0% | - · NaN% | - · NaN% | 26 · 0% | 3 · 0% |
| s-csv-sum | 18 · 100% | 17 · 100% | 23 · 0% | - · NaN% | - · NaN% | 21 · 100% | 1 · 67% |
| s-cache | 9 · 100% | 9 · 100% | 12 · 67% | - · NaN% | - · NaN% | 10 · 67% | 2 · 67% |
| s-safe-path | - · 0% | - · 0% | - · 0% | - · NaN% | - · NaN% | - · 0% | - · 0% |

## Methodology

- Single-shot generation via opencode CLI, tool-less `oneshot` agent, default temperature.
- Arms differ only in prepended ruleset text (baseline gets none); identical task prompts otherwise.
- LOC = non-empty lines of the largest fenced code block in the response.
- Correctness = generated solution executed against per-task node test files (exit 0 within 15s).
- Tokens/cost from gateway-reported usage events; latency = wall clock including CLI startup.
- Arm order rotated per (run, task) pair; sequential execution.
