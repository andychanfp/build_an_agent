---
name: agent-plan
description: Plan a specialist AI agent before building. Outputs a plan for agent-build to consume. Use when the user wants to design or plan an agent, even if they don't explicitly say "skill" or "prompt". Invoked via "/agent-plan" or naturally via phrases like "plan an agent", "design a custom Claude", "think through a specialist prompt", "start a new agent".
model: claude-sonnet-4-6

---

# agent-plan

## Usage

**Invoke**: `/agent-plan <optional one-line ask>`

**Modes**:
- `mode: thinking` (default) — up to 8 MCQs, full coverage.
- `mode: flash` — 3 MCQs, smart defaults for the rest.

**What you get**: a captured spec, a written summary, two test prompts with expected and actual outputs, and a final plan in `plan-template.md` format ready for `agent-build`.

**Human checkpoints**: approval is requested inline after the workflow is drawn (covering summary, priorities, and workflow), and again inside Step 6 before the test prompts are executed. Either checkpoint can revise or abort.

**Progress markers**: every step opens with `Step X/7 — <title>` so you always know where the run is.

## Inputs

| Name | Format | Source |
|------|--------|--------|
| ask | one-line text, optional | user message at invocation |
| mode | `flash` | `thinking` | user message; defaults to `thinking` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| spec | filled table per `refs/interview/interview.md` | in-memory |
| summary | prose, ≤150 words | shown inline at Step 5 |
| priorities | P0–P2 feature table | shown inline at Step 5 |
| workflow | ASCII diagram per `refs/workflow-template.md` | shown inline at Step 5 |
| test prompts | 2 prompt/expected/actual triples | shown inline at Step 6 |
| plan | structured doc per `refs/plan-template.md` | handed to `agent-build` |

## Model loading

Load the cheapest model that can complete each step. Override only when a step demands deeper reasoning the user has explicitly asked for.

| Task type | Model | Why |
|-----------|-------|-----|
| Parsing input, running MCQs, signal flagging, template fill | `claude-haiku-4-5` | Deterministic, pattern-matching, no synthesis |
| Drafting summary, drawing workflow, generating test prompts | `claude-sonnet-4-6` | Synthesis from interview answers, structural reasoning |
| Specialist persona work the user explicitly flags as deep | `claude-opus-4-7` | Load on user request only — never by default |

The recommended model is tagged on each step below as `[model: …]`. The orchestrator must respect the tag.

## Progress emission

At the start of every step, emit one line to the user:

> `Step X/8 — <step title>`

Emit it unconditionally, including for steps that produce no other user-visible output. If a step is skipped (e.g. the opening interview question when an `ask` is set), emit the marker with `(skipped)` appended.

## Step-by-step protocol

**Step 1 — What are you building?** `[model: sonnet]`
Read the user's invocation. If an ask is present, store it as `ask`. If no ask, jump to Step 2's opening question. Detect mode from the message; default to `thinking`.

**Step 2 — Let's dive deeper** `[model: opus]`
Follow `refs/interview/interview.md` end-to-end. Skip the opening question if `ask` is set. Apply signal flagging after every answer. Stop when the spec table is filled and no flags are open.

**Step 3 — Here's what this agent looks like** `[model: opus]`
Write a ≤150-word summary covering: what the agent does, who it serves, when it activates, what it refuses, what makes it specialist. Use `refs/language.md` rules — imperatives, no hedging, plain English.

**Step 4 — This agent would prioritse the following:** `[model: sonnet]`
Derive the agent's features from the spec and rank them in a P0–P2 table:

| Priority | Meaning | Use for |
|----------|---------|---------|
| P0 | Critical — must ship in v1 | Core capabilities without which the agent has no value |
| P1 | Important — ship soon after | High-value features that round out the experience |
| P2 | Nice-to-have — defer | Useful but optional; safe to cut under time pressure |

Output one table with columns `Priority \| Feature \| Why`. Aim for 2–4 P0s, 2–4 P1s, and up to 3 P2s. Do not invent features the spec doesn't support. Hold the table for presentation in Step 5.

**Step 5 — The agent will go through this flow** `[model: haiku]`
Render the agent's execution flow as an ASCII diagram per `refs/workflow-template.md`. The diagram must show the agent's own steps, human gates, and termination — not this skill's protocol. Source the steps from interview Q5 (workflow shape) and Q6 (refusals as abort paths). Present the summary, the priority table, and the workflow together, then ask inline:

> "Approve summary, priorities, and workflow? (1) approve  (2) revise summary  (3) revise priorities  (4) revise workflow  (5) abort"

- `approve` → Step 6
- `revise summary` → return to the relevant interview row, then re-draft
- `revise priorities` → re-rank the table with the user's correction
- `revise workflow` → redraw with the user's correction
- `abort` → exit, discard spec

**Step 6 — This agent would likely do this** `[model: sonnet]`
Produce exactly two test pairs. For each pair, output two numbered fields only:
- `(1) prompt`: the user message that would be sent to the agent.
- `(2) expected output`: the response the agent should produce (shape and key content, not verbatim).

The two pairs:
- **Pair A — happy path**: a typical request the agent should handle well.
- **Pair B — edge case**: a request that stresses scope, refusal, or a known limitation.

After presenting both pairs, request approval inline before executing — the run is gated on this answer:

> "Approve and run these test prompts? (1) approve & run  (2) revise A  (3) revise B  (4) abort"

- `approve & run` → for each pair, run `(1) prompt` against the agent using the captured spec, summary, priorities, and workflow as context, then append `(3) actual output` under the existing `(1)` and `(2)` lines. Show all three lines per pair. If the user wants to adjust (rewrite the prompt, change the expected output, or re-run), accept the edit and re-execute the affected pair until they accept. Then proceed to Step 7.
- `revise A` / `revise B` → regenerate the named pair's `(1)` and `(2)`, then re-prompt for approval. Do not execute until approved.
- `abort` → exit, discard spec.

Never run the prompts before receiving `approve & run`.

**Step 7 — Where should I save this?** `[model: haiku]`
Ask the user where to save the plan and skill files:

> "Where should I save the plan and skill files?
> (1) Global — hidden `.claude` folder (default)
> (2) Desktop — creates a folder named after the agent on your Desktop
> (3) Custom folder — you name it"

- `1` / `Global` → set `output_dir = null` (use default paths)
- `2` / `Desktop` → set `output_dir = ~/Desktop/<spec.name>/`
- `3` / `Custom` → ask: "What should the folder be named?" then set `output_dir = ~/Desktop/<folder-name>/`

Store `output_dir` in spec. If `output_dir` is set, run `mkdir -p <output_dir>` via Bash before proceeding. Proceed to Step 8.

**Step 8 — Emit the plan** `[model: sonnet]`
Render the captured spec into `refs/plan-template.md` structure. Include the approved summary, approved priority table, approved workflow diagram, the approved test pairs with their prompts, expected outputs, and actual outputs, and `output_dir` (null if Global). Determine the plan file path:

- **Global** (`output_dir` is null): write to `plans/<spec.name>.md`
- **Desktop / Custom** (`output_dir` is set): write to `<output_dir>/<spec.name>-plan.md`

Write the result using the Write tool — do not ask for approval, do not preview the file, do not request a filename. If a file at that path already exists, overwrite it. After writing, emit one line with the absolute path of the written file, then hand off to `agent-build`.

## Caching

This skill and its refs load on activation and are cached for the session. Keep volatile content (timestamps, run IDs, user names) out of SKILL.md and refs to preserve cache hits.

When generating the test prompts in Step 6, structure each prompt for prompt caching at the agent runtime:

- Place the agent's system prompt and persona in the cached prefix.
- Place the variable user message after the cache breakpoint.
- Mark the prefix with `cache_control: {"type": "ephemeral"}` when emitting Anthropic API calls.

## References

Loaded on demand during the protocol:

- `refs/principles.md` — rules for writing good agent skills
- `refs/language.md` — voice, terminology, forbidden words
- `refs/persona.md` — seven-axis persona structure
- `refs/persona-exemplars.md` — filled persona examples
- `refs/plan-template.md` — required plan output structure
- `refs/workflow-template.md` — ASCII workflow conventions
- `refs/interview/interview.md` — MCQ interview protocol
