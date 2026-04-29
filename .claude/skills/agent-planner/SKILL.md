---
name: agent-planner
description: Plan a specialist AI agent before building. Outputs a plan for agent-builder to consume. Use when the user wants to design or plan an agent, even if they don't explicitly say "skill" or "prompt". Invoked via "/agent-planner" or naturally via phrases like "plan an agent", "design a custom Claude", "think through a specialist prompt", "start a new agent".
---

# agent-planner

## Usage

**Invoke**: `/agent-planner <optional one-line ask>`

**Modes**:
- `mode: thinking` (default) — up to 8 MCQs, full coverage.
- `mode: flash` — 3 MCQs, smart defaults for the rest.

**What you get**: a captured spec, a written summary, two test prompts with expected outputs, and a final plan in `plan-template.md` format ready for `agent-builder`.

**Human checkpoints**: approval is requested inline after the workflow is drawn (covering summary, priorities, and workflow), and again after the test prompts. Either checkpoint can revise or abort.

**Progress markers**: every step opens with `Step X/8 — <title>` so you always know where the run is.

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
| test prompts | 2 prompt/output pairs | shown at Step 7 checkpoint |
| plan | structured doc per `refs/plan-template.md` | handed to `agent-builder` |

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

**Step 1 — Receive input** `[model: sonnet]`
Read the user's invocation. If an ask is present, store it as `ask`. If no ask, jump to Step 2's opening question. Detect mode from the message; default to `thinking`.

**Step 2 — Run the interview** `[model: opus]`
Follow `refs/interview/interview.md` end-to-end. Skip the opening question if `ask` is set. Apply signal flagging after every answer. Stop when the spec table is filled and no flags are open.

**Step 3 — Draft the summary** `[model: opus]`
Write a ≤150-word summary covering: what the agent does, who it serves, when it activates, what it refuses, what makes it specialist. Use `refs/language.md` rules — imperatives, no hedging, plain English.

**Step 4 — Recommend feature priorities** `[model: sonnet]`
Derive the agent's features from the spec and rank them in a P0–P2 table:

| Priority | Meaning | Use for |
|----------|---------|---------|
| P0 | Critical — must ship in v1 | Core capabilities without which the agent has no value |
| P1 | Important — ship soon after | High-value features that round out the experience |
| P2 | Nice-to-have — defer | Useful but optional; safe to cut under time pressure |

Output one table with columns `Priority \| Feature \| Why`. Aim for 2–4 P0s, 2–4 P1s, and up to 3 P2s. Do not invent features the spec doesn't support. Hold the table for presentation in Step 5.

**Step 5 — Draw the workflow and confirm** `[model: haiku]`
Render the agent's execution flow as an ASCII diagram per `refs/workflow-template.md`. The diagram must show the agent's own steps, human gates, and termination — not this skill's protocol. Source the steps from interview Q5 (workflow shape) and Q6 (refusals as abort paths). Present the summary, the priority table, and the workflow together, then ask inline:

> "Approve summary, priorities, and workflow? (1) approve  (2) revise summary  (3) revise priorities  (4) revise workflow  (5) abort"

- `approve` → Step 6
- `revise summary` → return to the relevant interview row, then re-draft
- `revise priorities` → re-rank the table with the user's correction
- `revise workflow` → redraw with the user's correction
- `abort` → exit, discard spec

**Step 6 — Generate test prompts** `[model: sonnet]`
Produce exactly two prompt/expected-output pairs:
- **Pair A — happy path**: a typical request the agent should handle well.
- **Pair B — edge case**: a request that stresses scope, refusal, or a known limitation.

For each pair, write:
- `prompt`: the user message that would be sent to the agent.
- `expected output`: the response the agent should produce (shape and key content, not verbatim).

**Step 7 — Human checkpoint: test prompts**
Present both pairs. Ask one question:

> "Approve these test prompts? (1) approve  (2) revise A  (3) revise B  (4) abort"

- `approve` → Step 8
- `revise` → regenerate the named pair
- `abort` → exit, discard spec

**Step 8 — Emit the plan** `[model: sonnet]`
Render the captured spec into `refs/plan-template.md` structure. Include the approved summary, approved priority table, approved workflow diagram, and approved test prompts. Hand off to `agent-builder`.

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
