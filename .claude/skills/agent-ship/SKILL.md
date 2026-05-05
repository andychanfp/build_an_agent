---
name: agent-ship
description: Plan, build, audit, and fix a new agent in one automated run — no approval gates after the initial ask. Use when the user wants to create an agent end-to-end in one step, or says "ship an agent", "build this end-to-end", "one-shot build", "create and deploy an agent", "build an agent start to finish".
model: claude-sonnet-4-6
---

# agent-ship

## Usage

**Invoke**: `/agent-ship <one-line description of the agent>`

- Slash command `/agent-ship`
- Natural-language: "ship an agent", "build this end-to-end", "one-shot build", "create and deploy an agent", "build an agent start to finish"

**What you get**: a working skill in `.claude/skills/<name>/`, audited and auto-patched, in one run. No approval gates after the initial ask.

## On activation

Before Step 1, pre-read every file listed in the References section using the Read tool. Load them all in a single parallel batch. This prevents permission interruptions during the run.

## Inputs

| Name | Format | Source |
|------|--------|--------|
| ask | one-line description of the agent to build | user message at invocation |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| plan | markdown per plan-template | `plans/<name>.md` |
| SKILL.md | built skill file | `.claude/skills/<name>/SKILL.md` |
| refs/* | ref files | `.claude/skills/<name>/refs/` |
| evals-1.json | flash audit test results | `.claude/skills/<name>/run/run-1/` |
| grading.json | synthesized pass/fail for agent-fix | `.claude/skills/<name>/run/run-1/` |
| fix-report-1.json | record of applied fixes | `.claude/skills/<name>/run/run-1/` |
| ship-report | markdown summary | shown inline |

## Progress emission

Emit `Step X/5 — <title>` at the start of each step, unconditionally.

## Step-by-step protocol

**Step 1/5 — Capture ask**

Read the ask from invocation args. If no ask is present, ask once: "Describe the agent in one line." Store as `ask`. Do not ask follow-up questions. Produce `ask`.

**Step 2/5 — Draft and write plan**

Derive a complete plan inline from `ask` — no MCQs, no approval gate:

1. Infer `name`: kebab-case slug from the ask (e.g. "a PR reviewer" → `pr-reviewer`).
2. Draft `description`: one-line trigger, ≤80 words. State what the agent does and when to invoke it.
3. Draft `summary`: ≤150 words. Cover what the agent does, who it serves, when it activates, what it refuses. Apply voice rules from `.claude/skills/agent-plan/refs/language.md` — imperatives, no hedging.
4. Derive P0–P2 features from the ask. Aim for 2–4 P0s (core, must-ship), 2–4 P1s (high-value, round-out), up to 3 P2s (defer). Table: `Priority | Feature | Why`.
5. Draft workflow: ASCII diagram per `.claude/skills/agent-plan/refs/workflow-template.md`. Show the agent's own steps, any human gates, and refusal paths. This must describe the *target agent's* flow, not this skill's.
6. Infer inputs and outputs: what the target agent receives and what it produces.
7. List any ref files the target skill will need (e.g. taxonomy, heuristics, rubric). Do not list SKILL.md itself.
8. Decide whether to include a Persona section: include it only if the ask names a specialist human role (e.g. "senior designer", "product manager"). If included, fill all seven axes per `.claude/skills/agent-plan/refs/persona.md`. If the ask describes a task-oriented agent (classification, extraction, routing), omit the Persona section entirely.

Write the plan to `plans/<name>.md` using the structure in `.claude/skills/agent-plan/refs/plan-template.md`. Do not preview or confirm. Produce `plan_path = plans/<name>.md`, `skill_name = <name>`.

**Step 3/5 — Build**

Invoke agent-build as a subagent via the Agent tool. Prompt:

> "Run agent-build for the plan at `<plan_path>`. Read the plan file, scaffold the directories, write SKILL.md and all ref files, then verify each file against principles. Follow the agent-build protocol step-by-step without prompting for confirmation."

Wait for the subagent to complete. Verify `.claude/skills/<skill_name>/SKILL.md` exists. If missing, emit `Build failed — .claude/skills/<skill_name>/SKILL.md not found.` and stop. Produce `skill_path = .claude/skills/<skill_name>/`.

**Step 4/5 — Audit (flash)**

Set up the run directory:

```bash
mkdir -p <skill_path>/run/run-1
```

If `<skill_path>/refs/schemas.json` is missing, copy the template: read `.claude/skills/agent-audit/refs/schemas.json`, set its `skill_name` field to `<skill_name>`, and write to `<skill_path>/refs/schemas.json`.

Produce `run_dir = <skill_path>/run/run-1/`, `run_number = 1`.

**Test**: invoke agent-audit-test as a subagent:

> "Run agent-audit-test with these args: skill_path=`<skill_path>`, run_dir=`<run_dir>`, schemas_path=`<skill_path>/refs/schemas.json`, mode=`flash`. Follow the agent-audit-test protocol step-by-step. Do not prompt for confirmation."

Wait for the subagent to complete. Confirm `<run_dir>/evals-1.json` exists. If missing, emit `Audit failed — evals-1.json not written by agent-audit-test.` and skip the fix phase in Step 5. Produce `evals_path = <run_dir>/evals-1.json`.

**Synthesize grading.json**: read `evals_path`. For each eval, collect its assertions array. Build a `grading.json` document with this structure:

- `skill_name`: `<skill_name>`
- `run`: `1`
- `evals`: one entry per eval — `id`, `verdict` (copied from evals-1.json), `assertions` (each with `text`, `passed`, `evidence`, `human_review` copied from evals-1.json)
- `summary`: compute `total_assertions` (count all), `passed` (count where `passed === true`), `failed` (count where `passed === false`), `human_review_pending` (count where `human_review === true`), `pass_rate` (`passed / total_assertions`, as a percentage string)

Write to `<run_dir>/grading.json`. Produce `grading_path = <run_dir>/grading.json`. Store `failed_count` (number of assertions where `passed === false`) in memory.

**Step 5/5 — Fix and ship**

If `failed_count` is 0, skip the fix invocation. Set `fix_output = null`.

If `failed_count` > 0, invoke agent-fix as a subagent:

> "Run agent-fix for skill `<skill_name>`. The run directory is `<run_dir>`. At Step 5 (human approval gate), automatically select option 1 (approve all) — do not wait for user input. At Step 7 (re-audit offer), select no — do not re-run agent-audit."

Wait for the subagent to complete. Collect `fix_output` (the fix-report-1.json contents or the subagent's inline summary).

Emit the ship report using the structure in `refs/ship-report-template.md`:

- **Agent summary**: 2–3 sentences from the plan summary (what the agent does, who it serves, when it activates, key refusals).
- **Features**: the full P0–P2 table from plan §4.
- **Issues found**: list each assertion where `passed === false` from `evals-1.json` — eval id, truncated assertion text (≤80 chars), verdict. If none, write "No issues found."
- **Issues fixed**: list each fix from `fix_output` — fix id, targeted SKILL.md section, one-line action. If fix phase was skipped or `fix_output` is null, write "No fixes needed."

## References

- `refs/ship-report-template.md` — required structure for the final ship report
- `.claude/skills/agent-plan/refs/plan-template.md` — required plan output structure
- `.claude/skills/agent-plan/refs/workflow-template.md` — ASCII workflow diagram conventions
- `.claude/skills/agent-plan/refs/persona.md` — seven-axis persona structure (loaded only if ask implies a specialist human role)
- `.claude/skills/agent-plan/refs/language.md` — voice and terminology rules for plan prose
- `.claude/skills/agent-audit/refs/schemas.json` — eval test case template (read to seed schemas.json if missing)
