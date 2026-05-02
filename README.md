# Build-an-Agent

A closed-loop agentic workflow for designing, building, evaluating, and repairing specialist Claude Code skills. Each phase is a standalone skill — invoke them individually, or chain them end-to-end (`/agent-planner` → `/agent-builder` → `/agent-evaluate` → `/agent-fix`) to ship a vetted skill from a one-line ask.

## Install

1. **Clone** this repo to your machine.
2. **Open it in Claude Code** — the skills under `.claude/skills/` register automatically when Claude Code starts in this working directory. No manual registration needed.
3. **Verify** by listing skills (`/help` or invoke any of the slash commands below). All ten skills should be visible.
4. **Optional dependencies** (only required for `agent-audit-lint` and `agent-audit-optimiser`):
   - `node` + `npm` — needed for the `agentlinter` and `agnix` lint tools (auto-installed on first run via `agent-audit-lint/scripts/check-env.sh`)
   - `claude` CLI in `PATH` — needed for the description-trigger evals
   - `jq` — needed for the description-trigger evals

Missing optional tools are reported as skipped findings, never block the run.

## Use

The intended chain is:

```
/agent-planner   →  plans/<name>.md
/agent-builder   →  .claude/skills/<name>/{SKILL.md, refs/*}
/agent-evaluate  →  runs audit + quality, writes run/run-[n]/* artifacts
/agent-fix       →  patches SKILL.md and refs from the audit artifacts
```

Each step is also valid on its own. `/agent-evaluate` can be run against any pre-existing skill; `/agent-audit` can be run directly without going through `/agent-evaluate`; `/agent-fix` only needs a populated `run/` directory to operate.

## Skill catalog

### Core pipeline

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `agent-planner` | `/agent-planner [one-line ask]` | Interviews you (3–8 MCQs) about the agent you want, drafts a summary + persona + workflow + two test prompts, and writes a structured plan to `plans/<name>.md` for `agent-builder` to consume. |
| `agent-builder` | `/agent-builder <plan-path>` | Reads a plan from `plans/`, validates required sections, scaffolds `.claude/skills/<name>/`, writes `SKILL.md` and every named ref file, then hands off to `/agent-evaluate`. |
| `agent-evaluate` | `/agent-evaluate <skill-name>` | Orchestrator that asks which checks to run (audit, quality, both) and which mode (flash or comprehensive), then dispatches the relevant sub-orchestrators in parallel and merges their reports. |
| `agent-fix` | `/agent-fix <skill-name>` | Reads every audit artifact in the latest `run/run-[n]/`, classifies findings by source and severity, presents a fix plan for approval, and patches `SKILL.md` and ref files in place. Skips ambiguous findings into a separate human-review table. |

### agent-audit and its specialists

`/agent-audit` is itself an orchestrator that dispatches five specialist subagents. You can run any subset via the multi-select prompt at Step 2.

| Skill | Invoked by | Purpose |
|-------|-----------|---------|
| `agent-audit` | `/agent-audit <skill-name>` or `/agent-evaluate` | Orchestrator. Prepares the run directory, asks which checks to run, dispatches the specialists below in dependency order, collects their JSON outputs, and emits the final report. |
| `agent-audit-test` | `agent-audit` (Test selected) | Generates 3–5 test cases from the skill's SKILL.md, runs them as parallel eval subagents, and writes 3–5 verifiable assertions per case. Output: `evals-[n].json`. |
| `agent-audit-grade` | `agent-audit` (Grade selected) | Grades every assertion in `evals-[n].json` against `actual_output` — LLM judge for semantic checks, tool calls for mechanical checks, `human_review: true` left unresolved. Output: `grading.json`. |
| `agent-audit-lint` | `agent-audit` (Lint selected, comprehensive) | Runs `agentlinter` and `agnix` against the skill, then performs an LLM safety scan against the audit registry (destructive ops, secrets, code execution, prompt injection, shared-state mutation, network egress). Output: `audit-[n].json`. |
| `agent-audit-optimiser` | `agent-audit` (Optimise selected, comprehensive) | Measures the skill's description trigger rate, iterates up to 5 times to improve it, validates the winner, and writes the better description back to `SKILL.md` if it actually wins. Up to 144 `claude -p` calls — token-intensive. |
| `agent-audit-benchmark` | `agent-audit` (Benchmark selected) | Aggregates token cost and timing from `evals-[n].json` and `grading.json` — mean, stddev, pass rate. Outputs `timing.json` and `benchmark.json`. |

### Quality comparison

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `agent-quality` | `/agent-quality <skill-name>` or `/agent-evaluate` | Runs the same task two ways — once following the full SKILL.md protocol, once with vanilla `claude-opus-4-7` given a plain-prose prompt synthesised from the skill description. Scores three dimensions (Completeness, Structure, Actionability) and emits a graded recommendation: 🟢 skill better, 🟡 marginal, 🔴 Opus alone better. Output: `quality-[n].json`. |

### Example built skill

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `design-review` | `/design-review` (with screenshot + PRD) | Senior product designer that audits UI screens against Nielsen heuristics, error-state taxonomy, edge-case checklist, and WCAG 2.2. Severity-grouped findings + ranked top fixes. Included as a worked example of an end-to-end built skill. |

## Outputs and where they live

- **Plans** — `plans/<skill-name>.md` (one per agent designed)
- **Skills** — `.claude/skills/<skill-name>/SKILL.md` + `refs/*`
- **Audit artifacts** — `.claude/skills/<skill-name>/run/run-[n]/` (one directory per audit run, auto-incremented)
  - `evals-[n].json`, `grading.json`, `audit-[n].json`, `timing.json`, `benchmark.json`, `feedback.json`, `quality-[n].json`, `fix-report-[n].json`

## Modes

- **Flash** — top 3 findings per agent, P0 only. Use for fast triage.
- **Comprehensive** — exhaustive findings + lint + description optimiser + benchmark. Use before shipping a skill.

For `agent-planner` specifically:
- **Thinking** (default) — full 8-MCQ interview
- **Flash** — 3 MCQs, smart defaults for the rest

## Customising

Every skill is a plain file under `.claude/skills/<name>/`. Edit `SKILL.md` to change behaviour, edit the ref files under `refs/` to change the rules and templates the protocol consults. The pipeline is intentionally not closed — modify, replace, or add subagents without touching the orchestrators (just update the dispatch table in `agent-audit/SKILL.md` Step 4).

See `ARCHITECTURE.md` for the full technical breakdown — dataflow, dependency order, dispatch waves, and per-subagent contracts.
