const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const RAW = path.join(ROOT, "results", "raw.jsonl");

function median(arr) {
  if (!arr.length) return null;
  const s = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

const rows = fs
  .readFileSync(RAW, "utf8")
  .replace(/^\uFEFF/, "")
  .split("\n")
  .filter((l) => l.trim())
  .map((l) => JSON.parse(l));

const arms = [...new Set(rows.map((r) => r.arm))];
const tasks = [...new Set(rows.map((r) => r.task))];

function stats(rs) {
  return {
    n: rs.length,
    locMed: median(rs.map((r) => r.loc).filter((v) => v != null)),
    passRate: rs.filter((r) => r.passed).length / rs.length,
    tokMed: median(
      rs.map((r) => (r.tokens_input ?? 0) + (r.tokens_output ?? 0) + (r.tokens_reasoning ?? 0))
    ),
    costSum: rs.reduce((a, r) => a + (r.cost_usd || 0), 0),
    latMed: median(rs.map((r) => r.latencyMs)),
    noCode: rs.filter((r) => r.reason === "no_code_block").length,
  };
}

const overall = {};
for (const arm of arms) overall[arm] = stats(rows.filter((r) => r.arm === arm));

let md = [];
md.push(`# boring-engineering vs ponytail — single-shot benchmark`);
md.push("");
md.push(`Model: \`${rows[0].model}\` · ${rows.length} runs total · median-of-N per cell · interleaved arm order`);
md.push(`Ruleset hashes: ${[...new Set(rows.map((r) => `${r.arm}:${r.ruleset_sha256_12 || "none"}`))].join(", ")}`);
md.push("");
md.push(`## Overall (medians per call unless noted)`);
md.push("");
md.push(`| metric | ${arms.join(" | ")} |`);
md.push(`|---|${arms.map(() => "---").join("|")}|`);
md.push(`| runs | ${arms.map((a) => overall[a].n).join(" | ")} |`);
md.push(`| LOC of code block (median) | ${arms.map((a) => overall[a].locMed).join(" | ")} |`);
md.push(`| correctness pass rate | ${arms.map((a) => (overall[a].passRate * 100).toFixed(0) + "%").join(" | ")} |`);
md.push(`| tokens per call (median, in+out+reasoning) | ${arms.map((a) => overall[a].tokMed).join(" | ")} |`);
md.push(`| latency ms (median) | ${arms.map((a) => overall[a].latMed).join(" | ")} |`);
md.push(`| total cost USD (all runs) | ${arms.map((a) => "$" + overall[a].costSum.toFixed(4)).join(" | ")} |`);
md.push(`| responses without code block | ${arms.map((a) => overall[a].noCode).join(" | ")} |`);

md.push("");
md.push(`## Per task (median LOC · pass rate)`);
md.push("");
md.push(`| task | ${arms.join(" | ")} |`);
md.push(`|---|${arms.map(() => "---").join("|")}|`);
for (const t of tasks) {
  const cells = arms.map((a) => {
    const s = stats(rows.filter((r) => r.arm === a && r.task === t));
    return `${s.locMed ?? "-"} · ${(s.passRate * 100).toFixed(0)}%`;
  });
  md.push(`| ${t} | ${cells.join(" | ")} |`);
}

md.push("");
md.push(`## Methodology`);
md.push("");
md.push("- Single-shot generation via opencode CLI, tool-less `oneshot` agent, default temperature.");
md.push("- Arms differ only in prepended ruleset text (baseline gets none); identical task prompts otherwise.");
md.push("- LOC = non-empty lines of the largest fenced code block in the response.");
md.push("- Correctness = generated solution executed against per-task node test files (exit 0 within 15s).");
md.push("- Tokens/cost from gateway-reported usage events; latency = wall clock including CLI startup.");
md.push("- Arm order rotated per (run, task) pair; sequential execution.");

fs.writeFileSync(path.join(ROOT, "results", "report.md"), md.join("\n") + "\n");
console.log(md.join("\n"));
