# boring-engineering vs ponytail — single-shot benchmark

Model: `opencode/muse-spark-1.2-contributor-free` · 150 runs total · median-of-N per cell · interleaved arm order
Ruleset hashes: boring-engineering:8817193dfda4, ponytail:002119891a28, baseline:none, boring-engineering-v11:d75663a32ede, boring-engineering-v12:c911311b4b51

## Overall (medians per call unless noted)

| metric | boring-engineering | ponytail | baseline | boring-engineering-v11 | boring-engineering-v12 |
|---|---|---|---|---|---|
| runs | 30 | 30 | 30 | 30 | 30 |
| LOC of code block (median) | 8 | 4.5 | 10.5 | 7 | 4 |
| correctness pass rate | 97% | 80% | 53% | 100% | 100% |
| tokens per call (median, in+out+reasoning) | 1315.5 | 1214.5 | 1362.5 | 1135 | 1061.5 |
| latency ms (median) | 23859 | 20322.5 | 25687 | 17922 | 19020 |
| total cost USD (all runs) | $0.0000 | $0.0000 | $0.0000 | $0.0000 | $0.0000 |
| responses without code block | 0 | 0 | 0 | 0 | 0 |

## Per task (median LOC · pass rate)

| task | boring-engineering | ponytail | baseline | boring-engineering-v11 | boring-engineering-v12 |
|---|---|---|---|---|---|
| t1-slugify | 9 · 100% | 3 · 100% | 13 · 100% | 4 · 100% | 3 · 100% |
| t2-parsequery | 33 · 100% | 13 · 80% | 37 · 40% | 17 · 100% | 21 · 100% |
| t5-retry | 12 · 100% | 7 · 100% | 14 · 20% | 12 · 100% | 13 · 100% |
| t6-welcome-email | 7 · 80% | 3 · 60% | 9 · 0% | 7 · 100% | 3 · 100% |
| t3-reuse | 6 · 100% | 5 · 100% | 6 · 100% | 5 · 100% | 4 · 100% |
| t4-jpy | 4 · 100% | 4 · 40% | 3 · 60% | 4 · 100% | 4 · 100% |

## Methodology

- Single-shot generation via opencode CLI, tool-less `oneshot` agent, default temperature.
- Arms differ only in prepended ruleset text (baseline gets none); identical task prompts otherwise.
- LOC = non-empty lines of the largest fenced code block in the response.
- Correctness = generated solution executed against per-task node test files (exit 0 within 15s).
- Tokens/cost from gateway-reported usage events; latency = wall clock including CLI startup.
- Arm order rotated per (run, task) pair; sequential execution.
