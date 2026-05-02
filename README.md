# Build-an-Agent

Designing a good Claude skill is harder than it looks. You have to know what makes a description trigger reliably, how to write a persona that actually shapes behaviour, which protocol steps the model will follow versus quietly skip, and how to tell whether the thing you built is any better than just asking Opus directly. Most people give up halfway and end up with a folder of half-working prompts.

This repo turns that into a workflow. You describe the agent you want in plain English; the pipeline interviews you, drafts a plan, builds the skill, audits it, scores it against vanilla Opus, and patches whatever broke. Every step is a skill itself — chain them, or run any one on its own.

## Example

`design-review.md` is a dogfood product: it went through the workflow of `agent-plan` -> `agent-build` -> `agent-audit` -> `agent-fix`. Feel free to run the skill on your own!

## Install

### Option 1 — Install script (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/andychanfp/build_an_agent/main/install.sh | bash
```

Installs all 11 skills into `~/.claude/skills/` — available globally in every Claude Code session, no repo clone needed. To update to the latest version, re-run the same command.

### Option 2 — Clone the repo

```bash
git clone https://github.com/andychanfp/build_an_agent.git
```

Open the cloned directory in Claude Code. Skills under `.claude/skills/` register automatically — nothing to configure. Use this if you want to browse the source, contribute, or run `design-review` as a worked example.

---

Type `/help` or any slash command below to confirm all 11 skills loaded.

**Optional** (only for `agent-audit-lint` and `agent-audit-optimise`): `node` + `npm` (auto-installs the `agentlinter` and `agnix` lint tools on first run), the `claude` CLI on your `PATH`, and `jq`. Missing tools get flagged as skipped findings — they never block a run.

## The happy path

```
/agent-plan      →  plans/<name>.md
/agent-build     →  .claude/skills/<name>/{SKILL.md, refs/*}
/agent-evaluate  →  audit + quality artifacts in run/run-[n]/
/agent-fix       →  patches SKILL.md and refs from those artifacts
```

You can also drop in mid-chain. `/agent-evaluate` works on any existing skill. `/agent-audit` and `/agent-quality` work standalone. `/agent-fix` only needs an audit run to chew on.

## What's in the box

### The pipeline

| Skill | Invocation | What it does |
|-------|-----------|--------------|
| `agent-plan` | `/agent-plan [ask]` | Interviews you with 3–8 MCQs, drafts a summary, persona, workflow, and two test prompts, and writes a structured plan to `plans/<name>.md`. |
| `agent-build` | `/agent-build <plan-path>` | Validates the plan, scaffolds `.claude/skills/<name>/`, writes `SKILL.md` plus every ref file, hands off to evaluation. |
| `agent-evaluate` | `/agent-evaluate <skill>` | Asks which checks to run (audit, quality, both) and which mode (flash or comprehensive), then dispatches them in parallel and merges the reports. |
| `agent-fix` | `/agent-fix <skill>` | Reads every artifact in the latest run, ranks findings by severity, shows you a fix plan, and patches `SKILL.md` and refs in place once you approve. Ambiguous findings get flagged for human review instead of guessed at. |

### Audit specialists

`/agent-audit` is itself an orchestrator — pick any subset from its checklist.

| Skill | What it does |
|-------|--------------|
| `agent-audit-test` | Generates 3–5 test cases from the skill, runs them as parallel evals, writes verifiable assertions per case. → `evals-[n].json` |
| `agent-audit-grade` | Grades every assertion: LLM judge for semantic checks, tool calls for mechanical ones, `human_review` flagged but never guessed. → `grading.json` |
| `agent-audit-lint` | Runs `agentlinter` and `agnix`, then an LLM safety scan against the audit registry (destructive ops, secrets, code execution, prompt injection, shared-state mutation, network egress). → `audit-[n].json` |
| `agent-audit-optimise` | Measures the skill's description trigger rate, iterates up to 5 times to improve it, validates the winner, writes it back if it actually wins. Up to 144 `claude -p` calls — token-heavy. |
| `agent-audit-benchmark` | Aggregates token cost and timing — mean, stddev, pass rate. → `timing.json`, `benchmark.json` |

### Quality check

| Skill | What it does |
|-------|--------------|
| `agent-quality` | Runs the same task twice — once following your full SKILL.md, once with vanilla `claude-opus-4-7` given a plain-prose prompt. Scores three dimensions and tells you 🟢 skill is worth it, 🟡 marginal, or 🔴 just use Opus. |

### Worked example

| Skill | What it does |
|-------|--------------|
| `design-review` | A senior product designer that audits UI screens against Nielsen, WCAG 2.2, error-state taxonomy, and an edge-case checklist. Included so you can see what an end-to-end built skill looks like. |

## Where things land

- **Plans** → `plans/<skill>.md`
- **Built skills** → `.claude/skills/<skill>/SKILL.md` + `refs/*`
- **Audit runs** → `.claude/skills/<skill>/run/run-[n]/` — one directory per run, auto-incremented, holding every JSON artifact (`evals`, `grading`, `audit`, `timing`, `benchmark`, `feedback`, `quality`, `fix-report`)

## Modes

- **Flash** — top 3 findings per agent, P0 only. For fast triage.
- **Comprehensive** — exhaustive findings, plus lint, optimiser, and benchmark. For shipping.

`agent-plan` has its own modes: **Thinking** (default, full 8-MCQ interview) or **Flash** (3 MCQs, smart defaults for the rest).

For dataflow, concurrency model, and per-subagent contracts, see `ARCHITECTURE.md`.
