# Architecture

Technical reference for the build-an-agent pipeline. Each skill is described by its inputs, outputs, model assignment, internal protocol, and dependency contract. The pipeline composes through file artifacts on disk — every subagent reads structured input from a known path and writes structured output to a known path, so subagents are independently testable and replaceable.

## High-level dataflow

```
                         user ask (one line)
                                 │
                                 ▼
                         ┌────────────────┐
                         │ agent-planner  │  spec → summary → priorities → workflow
                         │  (sonnet/opus) │  → 2 test pairs → plan
                         └────────┬───────┘
                                  │ plans/<name>.md
                                  ▼
                         ┌────────────────┐
                         │ agent-builder  │  validate → scaffold → write SKILL.md
                         │     (opus)     │  → write refs → verify
                         └────────┬───────┘
                                  │ .claude/skills/<name>/{SKILL.md, refs/*}
                                  ▼
                         ┌────────────────┐
                         │ agent-evaluate │  pick agents (audit / quality / both)
                         │    (sonnet)    │  → pick mode → dispatch in parallel
                         └────────┬───────┘
                ┌─────────────────┴─────────────────┐
                ▼                                   ▼
      ┌──────────────────┐              ┌──────────────────────┐
      │   agent-audit    │              │    agent-quality     │
      │     (sonnet)     │              │       (sonnet)       │
      │  orchestrator    │              │ skill vs vanilla cmp │
      └────────┬─────────┘              └──────────┬───────────┘
               │                                   │
               ▼                                   ▼
   wave 1: test, lint, optimise         quality-[n].json
   wave 2: grade, benchmark             (3-dim score + grade)
               │
               ▼
   evals-[n].json, grading.json,
   audit-[n].json, timing.json,
   benchmark.json, feedback.json
                                 │
                                 ▼
                         ┌────────────────┐
                         │   agent-fix    │  load artifacts → classify → plan
                         │    (sonnet)    │  → approve → patch SKILL.md & refs
                         └────────┬───────┘
                                  │ fix-report-[n].json + edited SKILL.md
                                  ▼
                       (optional re-run agent-audit)
```

## agent-planner

**Model**: `claude-haiku-4-5` for parsing/MCQ/template-fill, `claude-sonnet-4-6` for synthesis (summary, workflow, test prompts), `claude-opus-4-7` only when explicitly requested. Tagged per step.

**Protocol** (7 steps):
1. **What are you building?** — captures the optional `ask` and detects mode (`thinking` default, `flash`).
2. **Let's dive deeper** — runs the MCQ interview from `refs/interview/interview.md`. Up to 8 questions in `thinking` mode, 3 in `flash` (smart defaults for the rest). Signal-flagging after every answer; stops only when the spec is complete and no flags are open.
3. **Summary** — ≤150-word prose covering what the agent does, who it serves, when it activates, what it refuses, what makes it specialist. Voice rules in `refs/language.md` (imperatives, no hedging).
4. **Priorities** — ranks features into a P0/P1/P2 table (2–4 P0s, 2–4 P1s, up to 3 P2s). Features are derived from the spec — no inventing.
5. **Workflow** — ASCII diagram per `refs/workflow-template.md` showing the agent's own protocol (not the planner's). Sources Q5 (workflow shape) and Q6 (refusals as abort paths). Inline approval gate covering summary, priorities, and workflow together.
6. **Test prompts** — exactly two pairs (happy path + edge case). Each pair: prompt + expected output. Approval gate before execution; on approval, runs each prompt against the captured spec/persona/workflow context and appends the actual output. User can revise prompts or expected outputs and re-run.
7. **Emit plan** — renders the captured artifacts into `refs/plan-template.md` structure and writes `plans/<spec.name>.md` directly. Hands off to `agent-builder`.

**Caching contract**: SKILL.md and refs are cached on activation. Test-prompt generation in Step 6 marks the prefix (system prompt + persona) with `cache_control: ephemeral` so the variable user message sits after the breakpoint.

**Refs**: `principles.md`, `language.md`, `persona.md`, `persona-exemplars.md`, `plan-template.md`, `workflow-template.md`, `interview/interview.md`.

## agent-builder

**Model**: `claude-opus-4-7`. Output quality matters more than throughput at this step.

**Protocol** (5 steps):
1. **Load and validate plan** — checks all five required sections exist and are non-empty (Identity, Triggers, Persona, Inputs/Outputs, Workflow). Halts on the first missing section, writes nothing.
2. **Scaffold directories** — `mkdir -p .claude/skills/<name>/refs`. Idempotent.
3. **Write SKILL.md** — maps plan sections to SKILL.md per a fixed table. Frontmatter `name`/`description` come from plan §1; model defaults to `claude-sonnet-4-6` unless overridden. Persona is copied verbatim across all seven axes. Protocol steps are tightened against `refs/language.md`. Quality gates from `refs/principles.md` are checked before write.
4. **Write ref files** — one per entry in plan §6. Required frontmatter (`name`, `description`, `type: reference`). Content generation rules per ref type:
   - **Domain standards** (WCAG, Nielsen, RFC) → generate from domain knowledge, never stub
   - **Persona-derived** (refusal phrasings, tone) → derive from plan §3 axes 4, 6, 7
   - **Workflow-derived** (checklists, taxonomies) → derive from plan §5 + axis 3
   - **Proprietary/custom** → infer what the plan supports, mark gaps with explicit `[USER: fill in <item>]` placeholders — never silent stubs
   - Minimum: ≥1 H2, ≥3 concrete items, ≥1 worked example
5. **Verify and emit** — re-reads each written file, checks against `refs/principles.md`, rewrites on failure. Emits a build report with line counts. Hands off to `/agent-evaluate`.

**Refs**: `skill-template.md`, `principles.md`, `language.md`.

## agent-evaluate

**Model**: `claude-sonnet-4-6`. Pure orchestrator — no synthesis beyond report aggregation.

**Protocol** (5 steps):
1. **Resolve skill path** — accepts `skill_name` from args or prior context, verifies `<skill_path>/SKILL.md` exists, halts naming the missing file otherwise.
2. **Select agents** — single-select prompt: Both / Audit only / Quality only.
3. **Select mode** — Flash (top 3 findings, P0 only) or Comprehensive (exhaustive).
4. **Run selected agents** — invokes `agent-audit` and `agent-quality` via the Agent tool. **If both selected, both Agent tool calls fire in a single message** so they run concurrently. No serialisation — they share no state.
5. **Aggregate and emit** — one labelled section per agent (`## Audit findings`, `## Quality findings`). Flash truncates each section to 3 highest-severity items. Comprehensive includes all, sorted by severity then file order. Final `## Summary` with up to 5 bullets covering pass/fail per agent and the highest-priority fix per agent.

**Refs**: `sub-agent-contracts.md` (interfaces, args, expected output shape for `agent-audit` and `agent-quality`).

## agent-audit

**Model**: `claude-sonnet-4-6`. Orchestrator with two-wave dispatch logic.

**Protocol** (5 steps):
1. **Prepare run** — verifies SKILL.md exists; auto-creates `<skill_path>/refs/schemas.json` from the template if missing; scans `<skill_path>/run/` and creates `run-[n]/` with `n` = next integer.
2. **Select checks** — multi-select: `test`, `grade`, `lint`, `optimise`, `benchmark`, `recommend`. Auto-adds `test` if `grade` or `benchmark` is selected without it (with notification). `recommend` triggers Step 3 instead.
3. **Recommend (if requested)** — analyses SKILL.md across four dimensions:
   - **Maturity** — does schemas.json have populated assertions?
   - **Complexity** — does SKILL.md invoke shell, external tools, or file writes?
   - **Description quality** — is the description >60 words or vague?
   - **Cost sensitivity** — does it spawn parallel subagents or use vision?
   Emits a per-check recommendation with one-line reason, then asks "Run with this recommendation? (yes / customise)".
4. **Dispatch subagents** — two waves respecting dependencies. Each wave fires all selected agents in a single message for concurrency.
   - **Wave 1 (independent)**: `agent-audit-test`, `agent-audit-lint`, `agent-audit-optimiser`
   - **Wave 2 (depends on Wave 1's `evals-[n].json`)**: `agent-audit-grade`, `agent-audit-benchmark`
   Status emitted per subagent as it completes; failures recorded but never block other subagents.
5. **Final report and human review** — reads every output file present in `run_dir`, builds a structured per-subagent report (omits sections for unselected/failed agents), and emits a `## Summary` block. For every assertion with `human_review: true` in `grading.json`, halts to collect a reviewer verdict. Records per-eval feedback strings into `feedback.json`.

**Refs**: `schemas.json` (eval template + `$assertions_doc` rules), `grading.json` (template), `audit-template.json` (lint output structure), `audit-registry.md` (safety patterns), `tool-setup.md` (lint tool install).

**Scripts**: `scripts/run-evals.sh` — fires `claude -p` subprocesses for trigger-rate evals; consumed by `agent-audit-optimiser`.

## agent-audit-test

**Model**: `claude-sonnet-4-6`. First subagent in the audit pipeline.

**Protocol** (3 steps):
1. **Generate test cases** — reads schemas.json. If non-empty `prompt` fields exist, reuses them. Otherwise synthesises 3–5 cases following the `$assertions_doc` rules in schemas.json. Each case names: `id`, `prompt` (one named SKILL.md claim, varied across formal/casual/direct/indirect/single/multi-step), `expected_output` (plain-language success). For vision skills (e.g. design-review), uses WebSearch to find a public UI screenshot URL and embeds it in the prompt — never leaves prompts image-dependent. Writes test cases back into schemas.json.
2. **Run evals in parallel subagents** — spawns one Agent subagent per test case **in a single message** so they run concurrently. Each subagent's prompt instructs it to act as a protocol executor (read the target SKILL.md and follow it directly — not invoke via Skill tool), include the full test prompt, and return verbatim output as text. Collects `actual_output` and `timing` (`total_tokens`, `duration_ms`) per case. On no output: records `actual_output: null`, `timing: null`, emits a warning, continues. Writes `evals-[n].json` in one write.
3. **Write assertions** — if every eval already has assertions, emits "skipping" and exits. Otherwise generates 3–5 verifiable assertions per case ("output includes a section headed Blocker", not "output is good"). Sets `human_review: true` only for assertions code/LLM cannot decide. For null `actual_output`, writes a single fail assertion `"eval did not return output"`. Writes assertions back into both `schemas.json` and `evals-[n].json`.

**Output**: `<run_dir>/evals-[n].json`, plus updates to `schemas.json` in place.

## agent-audit-grade

**Model**: `claude-sonnet-4-6`. Depends on `agent-audit-test`'s `evals-[n].json`.

**Protocol** (3 steps):
1. **Load inputs** — reads `evals-[n].json` and the `$grading_rules` from `grading.json` template. Stops naming the missing file if `evals-[n].json` is absent.
2. **Grade assertions** — for each case:
   - `actual_output` null → all assertions `passed: false`, `evidence: "actual_output is null"`, verdict: `fail`.
   - `human_review: true` → leave `passed: null`, `evidence: null`. Never guesses.
   - **Mechanical** assertions (file existence, count, JSON validity, exact match) → tool call to verify, record tool result as evidence.
   - **Semantic** assertions → LLM judge. PASS quotes the exact supporting text; FAIL names the specific absent or wrong element.
   - Verdict per case: `pass` if all assertions `passed === true`; `fail` if any `passed === false`; `pending` if no failures and at least one `human_review: true`.
3. **Write outputs** — builds `grading.json` (per-eval entries + `summary` block with `total_assertions`, `passed`, `failed`, `human_review_pending`, `pass_rate`). Updates `evals-[n].json` in place with the per-case verdict.

**Output**: `<run_dir>/grading.json`, plus verdict updates to `evals-[n].json`.

## agent-audit-lint

**Model**: `claude-sonnet-4-6`. Comprehensive mode only. Independent of test/grade.

**Protocol** (5 steps):
1. **Check environment** — runs `scripts/check-env.sh`. Returns JSON with `node`, `npm`, `agentlinter`, `agnix` availability. Each tool is independent — a missing one is flagged and skipped, never blocks the others.
2. **Run agentlinter** — if available, runs `agentlint <skill_path> --format json`. Maps exit codes (0 → no findings, 1 → parse findings, 2 → tool error, skipped). Severity mapping: error → P0, warning → P1, info → P2.
3. **Run agnix** — if available, runs `agnix --strict <skill_path> --format sarif --target claude-code`. Parses SARIF: `result.ruleId`, `level` (error → P0, warning → P1, note → P2), `physicalLocation`, `message.text`, `autofix_available` (true if `result.fixes` non-empty). Exit codes: 0/1/2 = findings by severity; 3 = tool error.
4. **LLM safety check** — always runs, regardless of tool availability. Walks every step, ref reference, and shell invocation in SKILL.md against six pattern categories from `audit-registry.md`:
   - Destructive filesystem ops
   - Secret and credential handling
   - Arbitrary code execution
   - Prompt injection and instruction override
   - System and shared state mutations
   - Network egress
   Each match: `pattern` (registry section + rule), `severity` (P0/P1/P2 per registry), `location` (file:step), `evidence` (quoted snippet), `consequence` (what breaks).
5. **Write audit-[n].json** — collects all findings, groups by severity (`p0_all`, `p1_all`, `p2_all`), caps to 3 per priority for the top-N display while preserving full counts in `verdict`. Computes `passed = (p0_count === 0)`. Omits the `description_optimizer` block (that's `agent-audit-optimiser`'s job).

**Output**: `<run_dir>/audit-[n].json`.

**Scripts**: `scripts/check-env.sh` — checks tool availability, attempts npm install for missing tools, returns JSON env status.

## agent-audit-optimiser

**Model**: `claude-sonnet-4-6`. Comprehensive mode only. Independent of test/grade. Token-intensive — up to **144 `claude -p` calls** per run (baseline 36 + 5 iterations × 12 + 2 × 24 validation).

**Graceful failure contract**: on any unrecoverable error at any step — restore `original_description` to SKILL.md if captured, emit a one-line `⚠ Optimiser skipped: <reason>`, write `description_optimizer` block with `skipped: true`, exit. Never blocks the pipeline.

**Protocol** (5 steps):
1. **Load inputs** — extracts `description` from SKILL.md frontmatter as `original_description`. Verifies `run-evals.sh`, `claude` CLI, and `jq` are available. Each missing dependency triggers the graceful failure contract.
2. **Generate queries and split** — generates exactly 20 trigger queries via LLM: ~10 `should_trigger: true` (varied phrasing) and ~10 `should_trigger: false` (near-misses sharing keywords but requiring a different skill). Splits 60/40: indices 0–11 → `optimizer-train.json`, indices 12–19 → `optimizer-val.json`.
3. **Baseline and train iterations** — writes `original_description` to SKILL.md, runs baseline on train set with **3 runs per query** (36 calls). If `baseline_train_pass_rate >= 0.9`, skips iterations. Otherwise iterates up to 5 times: propose candidate ≤1024 chars → write to SKILL.md → run train at **1 run per query** (12 calls) → record. Early-stop at `train_pass_rate >= 0.9`. Restores `original_description` after iterations.
4. **Validate winner** — writes `best_description` to SKILL.md, runs validation at 3 runs per query (24 calls). Restores original. Runs baseline validation at 3 runs per query (24 calls) for comparison. Sets `improved = (best_val_pass_rate > baseline_val_pass_rate)`. Writes winner to SKILL.md only if improved; ties broken by shorter description.
5. **Write outputs** — appends `description_optimizer` block to `audit-[n].json` (creates the file if `agent-audit-lint` was skipped). Records all metrics: original/final description, improved flag, iterations run, train/val pass rates per phase, selected iteration, full iteration log.

**Output**: SKILL.md updated in place (only if improved), `audit-[n].json` appended with `description_optimizer` block, `optimizer-queries.json` (20 queries reused across iterations).

## agent-audit-benchmark

**Model**: `claude-sonnet-4-6`. Depends on `agent-audit-test`'s `evals-[n].json` and (optionally) `agent-audit-grade`'s `grading.json`. Lowest-stakes subagent — never blocks the pipeline.

**Protocol** (3 steps):
1. **Load inputs** — attempts to read `evals_path` and `grading_path`. Either or both missing → defaults to empty/null, emits a warning, continues. Never stops.
2. **Aggregate timing** — collects evals where both `timing.total_tokens` and `timing.duration_ms` are non-null (`timed_evals`). Sums tokens and duration. Writes `timing.json` with `total_tokens`, `total_duration_ms`, `eval_count`, `evals_with_timing`.
3. **Compute stats and write benchmark** — `pass_rate` from `grading_summary.pass_rate` if available, else null. Mean computed if `evals_with_timing > 0`. Population stddev computed if `evals_with_timing >= 2`, else null. `partial = true` if any timing is missing or grading is null. Writes `benchmark.json` with `pass_rate`, `time_seconds: { mean, stddev }`, `tokens: { mean, stddev }`, `eval_count`, `evals_with_timing`, `partial`.

**Output**: `<run_dir>/timing.json`, `<run_dir>/benchmark.json`.

## agent-quality

**Model**: `claude-sonnet-4-6` orchestrator. Both comparison subagents run on `claude-opus-4-7`.

**Protocol** (5 steps):
1. **Resolve skill path and prepare run dir** — same pattern as agent-audit. Auto-increments `run-[n]/`.
2. **Construct comparison inputs** — synthesises a `vanilla_prompt` from the SKILL.md frontmatter description, Persona axes 1 (Role identity) and 2 (Values), and the Outputs table. Constraint: ≤120 words, plain prose only — **no step-by-step protocol, no numbered phases, no checklists** (those would collapse the comparison). If `test_input` not provided in args, synthesises one from the Usage section + first Inputs row.
3. **Run parallel comparison** — spawns two Agent subagents in a single message:
   - **Agent A (vanilla)**: `opus`. Prompt = `<vanilla_prompt>\n\n<test_input>`. Receives no SKILL.md.
   - **Agent B (skill)**: `opus`. Prompt = "Read `<skill_path>/SKILL.md` and execute its step-by-step protocol directly for the following input. Do not trigger the skill via the Skill tool. Input: `<test_input>`. Return the complete verbatim output."
   Collects verbatim outputs and timing metadata.
4. **Score and grade** — three independent dimensions on 1–10 each: **Completeness** (covers Outputs table sections), **Structure** (organisation, formatting), **Actionability** (specificity of findings). Grade rules:
   - 🟢 **Skill clearly better**: skill wins ≥2 dimensions by ≥2 points
   - 🔴 **Opus alone better**: vanilla wins ≥2 dimensions by ≥2 points
   - 🟡 **Marginal**: everything else
5. **Emit report** — inline in fixed order: test input used → vanilla output (verbatim, fenced) → skill output (verbatim, fenced) → 4-column scoring table → recommendation rationale → grade emoji on its own line.

**Output**: `<run_dir>/quality-[n].json`, inline side-by-side report.

**Refs**: `quality-template.json`.

## agent-fix

**Model**: `claude-sonnet-4-6`. Final step in the quality loop.

**Protocol** (7 steps):
1. **Resolve skill path and locate run directory** — same path resolution as audit. Auto-detects most recent `run-[n]` if not specified. Hard stops if no run directory exists, naming the command to produce one (`agent-audit`).
2. **Load audit artifacts** — reads every file present in `run_dir`. Emits an artifact status table. Hard stops only if **both** `grading.json` and `audit-[n].json` are missing (no graded output to fix from). `feedback.json` and `quality-[n].json` are optional.
3. **Classify findings** — per `refs/fix-strategy.md` source-to-section mapping:
   - `grading.json` failed assertions → `source = "grading"`, `severity = P1`. **Escalate to P0** if the same assertion fails across ≥2 test cases.
   - `audit-[n].json` items inherit severity. `source = "lint"` (agentlinter, agnix) or `"safety"` (safety_findings).
   - `feedback.json` items inherit severity, `source = "feedback"`.
   - `quality-[n].json`: only if `recommendation === "opus_alone_better"`, extract one finding per dimension where `vanilla - skill >= 2`. `source = "quality"`, `severity = P2`.
   For each finding, look up the target SKILL.md `section` from `refs/fix-strategy.md`. If the section cannot be determined → `ambiguous = true`. Deduplicate by section + compatible repair direction. Sort: P0 → P1 → P2; within severity: safety > grading > lint > feedback > quality.
4. **Generate fix plan** — table with `Fix ID | Finding IDs | Severity | Section | Fix action`. Ambiguous findings rendered separately under "Skipped — repair action could not be determined".
5. **Human approval gate** — single prompt: approve all / select by ID / abort. Filters to the approved set.
6. **Apply fixes with diff preview** — for each approved fix in severity order: read target file → identify exact text span → render `--- before` / `+++ after` diff → apply via Edit tool. Refuses any write outside `<skill_path>/`. On per-fix failure, continues to next fix — never aborts the run.
7. **Write fix-report and offer re-audit** — builds `fix-report-[n].json` per `refs/fix-report-template.json` (skill name, run number, timestamps, attempted/applied/failed/ambiguous lists, summary). Asks once: "Re-run agent-audit to verify the fixes? (yes / no)". On yes, invokes `agent-audit` as a subagent with the same `skill_path`.

**Output**: `<skill_path>/SKILL.md` patched in place, ref files patched in place, `<run_dir>/fix-report-[n].json`.

**Refs**: `fix-strategy.md` (source-to-section mapping + repair logic per source type), `fix-report-template.json`.

## design-review

Worked example of a built skill — included to demonstrate the end-to-end output of `agent-planner` → `agent-builder`. Not part of the pipeline itself.

**Model**: `claude-sonnet-4-6`.

**Protocol** (5 steps): receive image and PRD → scope check (refuses out-of-domain, names the discipline that owns the ask) → run four passes against `nielsen-heuristics.md`, `error-state-taxonomy.md`, `edge-case-checklist.md`, `wcag-2-2-cheatsheet.md` → group findings by severity (blocker / major / minor / nit) → emit review + 3–5 ranked top fixes.

## Cross-cutting concerns

### Concurrency model

Wherever multiple subagents have no data dependency, they fire in a single message so the harness runs them concurrently. Specifically:
- `agent-evaluate` Step 4 — audit + quality fire together if both selected
- `agent-audit` Step 4 Wave 1 — test + lint + optimise fire together
- `agent-audit-test` Step 2 — all eval cases run as parallel Agent subagents
- `agent-quality` Step 3 — vanilla and skill subagents fire together

### Run directory scheme

Every audit/quality run writes to `<skill_path>/run/run-[n]/` where `n` auto-increments. Subagents do not share state across runs — each `run-[n]/` is self-contained. `agent-fix` operates on the most recent `run-[n]/` by default but accepts an explicit `run_dir` arg to target older runs.

### Failure contracts

Three tiers of failure handling, applied per subagent:

1. **Hard stop** — when a required input file is missing (`SKILL.md`, `evals-[n].json` for grading, etc.). The subagent names the missing file and exits. The orchestrator records the failure in the final report.
2. **Continue with partial** — when a check fails or a tool is missing but the rest of the work is still valid. The subagent records `skipped: true` or `partial: true` in its output, emits a one-line warning, continues. Used by `agent-audit-lint` (per-tool independence), `agent-audit-benchmark` (always partial-tolerant).
3. **Graceful failure** — `agent-audit-optimiser` only. Any error at any step restores `SKILL.md` to its original state, writes a `skipped: true` block to `audit-[n].json`, and exits without re-raising. Optimiser is non-blocking by design.

### Caching

Skills and refs load on activation and are cached for the session. Volatile content (timestamps, run IDs) is kept out of SKILL.md and refs to preserve cache hits. `agent-planner` Step 6 explicitly structures generated test prompts to take advantage of prompt caching at the agent runtime — system prompt + persona before the cache breakpoint, variable user message after.

### Customising the pipeline

To add a new audit subagent: write the skill under `.claude/skills/<name>/`, add it to the dispatch table in `agent-audit/SKILL.md` Step 4 (correct wave per its dependency on `evals-[n].json`), and add it to the multi-select prompt in Step 2. To replace a subagent: edit its `SKILL.md` in place — the orchestrator dispatches by skill name, so as long as the input/output contract is preserved, the orchestrator does not need to change.
