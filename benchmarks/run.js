const { spawn, execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { largestBlock, countLoc } = require("./lib/loc");

const ROOT = __dirname;
const RESULTS = path.join(ROOT, "results");
const RAW = path.join(RESULTS, "raw.jsonl");
const SANDBOX = path.join(RESULTS, "sandbox");
const RUNNER = path.join(ROOT, "runner.cmd");
const DELAY_MS = 500;
const CALL_TIMEOUT_MS = parseInt(process.env.BENCH_TIMEOUT || '180000', 10);

function stripFrontmatter(md) {
  return md.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "").trim();
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function sha(s) {
  return crypto.createHash("sha256").update(s).digest("hex").slice(0, 12);
}

function loadArms() {
  const be = stripFrontmatter(fs.readFileSync(path.join(ROOT, "..", "SKILL.md"), "utf8"));
  const po = stripFrontmatter(fs.readFileSync(path.join(ROOT, "arms", "ponytail.md"), "utf8"));
  return [
    { id: "baseline", label: "baseline (no skill)", ruleset: "" },
    { id: "boring-engineering", label: "boring-engineering", ruleset: be },
    { id: "ponytail", label: "ponytail", ruleset: po },
  ];
}

function existingKeys() {
  if (!fs.existsSync(RAW)) return new Set();
  const set = new Set();
  for (const line of fs.readFileSync(RAW, "utf8").split("\n")) {
    if (!line.trim()) continue;
    try {
      set.add(JSON.parse(line).key);
    } catch {}
  }
  return set;
}

function appendResult(obj) {
  fs.appendFileSync(RAW, JSON.stringify(obj) + "\n");
}

function callOpencode(model, prompt) {
  return new Promise((resolve) => {
    const started = Date.now();
    const id = crypto.randomBytes(6).toString("hex");
    const promptFile = path.join(RESULTS, `prompt-${id}.txt`);
    const outFile = path.join(RESULTS, `events-${id}.json`);
    const errFile = path.join(RESULTS, `clierr-${id}.txt`);
    fs.writeFileSync(promptFile, prompt);
    console.log(`[spawn pid=?] prompt=${promptFile.length}ch`);
    const child = spawn("cmd.exe", ["/d", "/s", "/c", RUNNER], {
      cwd: ROOT,
      stdio: "ignore",
      env: {
        ...process.env,
        BE_MODEL: model,
        BE_PROMPT_FILE: promptFile,
        BE_OUT: outFile,
        BE_ERR: errFile,
      },
    });

    let done = false;
    const finish = (result) => {
      if (result.events === undefined) result.events = [];
      if (done) return;
      done = true;
      for (const f of [promptFile, errFile]) fs.rmSync(f, { force: true });
      resolve({ latencyMs: Date.now() - started, ...result });
    };
    const timer = setTimeout(() => {
      if (!done) {
        try {
          execSync(`taskkill /PID ${child.pid} /T /F`, { stdio: "ignore" });
        } catch {}
        finish({ ok: false, error: "timeout", events: [] });
      }
    }, CALL_TIMEOUT_MS);

    child.on("close", () => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      let events = [];
      if (fs.existsSync(outFile)) {
        for (const line of fs.readFileSync(outFile, "utf8").split("\n")) {
          if (!line.trim()) continue;
          try {
            events.push(JSON.parse(line));
          } catch {}
        }
      }
      fs.rmSync(outFile, { force: true });
      const errText = fs.existsSync(errFile) ? fs.readFileSync(errFile, "utf8") : "";
      fs.rmSync(errFile, { force: true });
      finish({ ok: events.length > 0, events, stderr: errText });
    });
  });
}

function summarizeEvents(events) {
  let text = "";
  let usage = null;
  for (const ev of events) {
    if (ev.type === "text" && ev.part && ev.part.text) text += ev.part.text;
    if (ev.type === "step_finish" && ev.part && ev.part.tokens) {
      usage = {
        input: ev.part.tokens.input || 0,
        output: ev.part.tokens.output || 0,
        reasoning: ev.part.tokens.reasoning || 0,
        cost: ev.part.cost || 0,
      };
    }
  }
  return { text, usage };
}

async function checkSolution(task, code, dir) {
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ type: "module" }));
  for (const [name, content] of Object.entries(task.files || {})) {
    const p = path.join(dir, name);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, content);
  }
  const solPath = path.join(dir, task.solutionFile);
  fs.mkdirSync(path.dirname(solPath), { recursive: true });
  fs.writeFileSync(solPath, code);
  fs.writeFileSync(path.join(dir, "test.js"), task.test);

  return new Promise((resolve) => {
    const child = spawn(process.execPath, ["test.js"], { cwd: dir });
    let out = "";
    let finished = false;
    const t = setTimeout(() => {
      if (!finished) {
        finished = true;
        child.kill("SIGKILL");
        resolve({ passed: false, reason: "test-timeout", log: out });
      }
    }, 15000);
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (out += d));
    child.on("close", (code2) => {
      if (finished) return;
      finished = true;
      clearTimeout(t);
      resolve({ passed: code2 === 0, reason: code2 === 0 ? "pass" : "test-fail", log: out.slice(-2000) });
    });
  });
}

async function main() {
  const cfg = JSON.parse(fs.readFileSync(path.join(ROOT, "tasks", "tasks.json"), "utf8"));
  const arms = loadArms();
  const tasks = cfg.tasks;
  const runs = cfg.runsPerCell;
  const model = cfg.model;
  fs.mkdirSync(RESULTS, { recursive: true });
  fs.mkdirSync(SANDBOX, { recursive: true });

  const seen = existingKeys();
  const queue = [];
  for (let r = 0; r < runs; r++) {
    tasks.forEach((task, ti) => {
      // rotate arm order deterministically per (run, task)
      const order = [...arms.keys()].map((i) => arms[(i + r + ti) % arms.length]);
      for (const arm of order) queue.push({ arm, task, run: r });
    });
  }

  // dedupe safety + optional smoke-test limit
  let plan = queue.filter((c) => !seen.has(`${c.arm.id}|${c.task.id}|${c.run}`));
  if (process.env.BENCH_LIMIT) plan = plan.slice(0, parseInt(process.env.BENCH_LIMIT, 10));
  console.log(`Plan: ${queue.length} cells, ${plan.length} to run (${seen.size} already done). Model: ${model}`);
  console.log(`Arm ruleset sizes: ${arms.map((a) => `${a.id}=${a.ruleset.length}ch`).join(", ")}`);

  for (const cell of plan) {
    const key = `${cell.arm.id}|${cell.task.id}|${cell.run}`;
    const prompt = cell.arm.ruleset
      ? `${cell.arm.ruleset}\n\n---\n\n${cell.task.prompt}`
      : cell.task.prompt;

    process.stdout.write(`[${new Date().toISOString()}] ${key} ... `);
    let res = await callOpencode(model, prompt);
    if (!res.ok || !summarizeEvents(res.events).text.trim()) {
      await sleep(1500);
      res = await callOpencode(model, prompt);
    }
    const { text, usage } = summarizeEvents(res.events);

    const base = {
      key,
      arm: cell.arm.id,
      task: cell.task.id,
      run: cell.run,
      model,
      latencyMs: res.latencyMs,
      tokens_input: usage ? usage.input : null,
      tokens_output: usage ? usage.output : null,
      tokens_reasoning: usage ? usage.reasoning : null,
      cost_usd: usage ? usage.cost : null,
      ruleset_sha256_12: cell.arm.ruleset ? sha(cell.arm.ruleset) : "",
      response_chars: text.length,
      response: text,
    };

    const block = largestBlock(text);
    if (!block) {
      appendResult({ ...base, loc: null, passed: false, reason: "no_code_block" });
      console.log(`NO CODE BLOCK (${text.length} chars, ${res.latencyMs}ms)`);
      continue;
    }
    const loc = countLoc(block);
    const dir = path.join(SANDBOX, key.replace(/[|]/g, "__"));
    const check = await checkSolution(cell.task, block, dir);
    appendResult({ ...base, loc, passed: check.passed, reason: check.reason });
    console.log(
      `loc=${loc} pass=${check.passed} ${check.reason} lat=${(res.latencyMs / 1000).toFixed(1)}s cost=$${usage ? usage.cost.toFixed(5) : "?"}`
    );
    await sleep(DELAY_MS);
  }
  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
