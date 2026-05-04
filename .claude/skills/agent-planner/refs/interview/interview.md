---
name: Interview
description: MCQ-driven question protocol the agent-planner uses to extract a complete, specialised agent specification in 8 questions or fewer
type: reference
---

# Interview

## Modes

**Flash** — ask Q1, Q4, Q5 only. Fill the rest with smart defaults. Use when the user says "quick", "draft", "fast", or sets `mode: flash`.
**Thinking** — ask up to 8 questions. Default mode.

## Opening

Skip if the user has already stated a clear ask.

Otherwise ask exactly one open question, with a generated example matching the user's likely domain:

> "What do you want to build? Example: '{a one-line agent description matching the user's likely domain}'."

Generate the example fresh each time. Never reuse a fixed string.

## Questions (MCQ, max 8)

Every question is multiple-choice with an "Other" option. Ask one at a time. Skip a question when its answer is already implied by an earlier one.

| # | Question | Options | Maps to |
|---|----------|---------|---------|
| 1 | What domain does this agent work in? | engineering / design / data / writing / Other | persona archetype |
| 2 | When should it activate? | slash command / keyword in prompt / file type match / Other | triggers |
| 3 | What does it consume? | a file or diff / a prompt or spec / prior conversation / Other | inputs |
| 4 | What does it produce? | code / a document / a decision or recommendation / Other | outputs |
| 5 | Workflow shape and gates? | single-shot, no gate / single-shot, gated before output / multi-step, gated mid-flow / Other | workflow + gates |
| 6 | What must it refuse? | destructive ops / out-of-domain asks / ambiguous scope / Other | refusal scope |
| 7 | What expertise must it have that a generalist lacks? | named framework / domain rules / proprietary process / Other | specialisation |
| 8 | What dependencies does it need? (multi-select) | none / MCP server(s) / external API(s) / shell tools / Other | tools + refs |

Q7 and Q8 accept open text inside "Other" — Q7's answer seeds the persona's knowledge axis; Q8's answer seeds the tools and refs sections.

## Signal flagging

After every answer, scan for these signals. Flag once per signal, never twice.

| Signal | Trigger | Response |
|--------|---------|----------|
| Vague | Answer contains "various", "etc", "general", "stuff" | Quote the word; ask for one concrete instance |
| Unbounded | Answer claims "any", "all", "every" without limit | Ask for the boundary case |
| Conflicting | Two answers contradict (e.g. Q1=generalist, Q7=specialist refusal) | Quote both; ask which holds |
| Overlapping | Spec matches an existing skill in the registry | Name the skill; ask for the differentiator |

## Spec capture

Fill this table from the answers. No prose, no extra fields.

| Field | Source | Required |
|-------|--------|----------|
| name | derived from ask | yes |
| description | one line, ≤80 chars | yes |
| persona | Q1 + Q7 | conditional — see detection rule below |
| triggers | Q2 | yes |
| inputs | Q3 | yes |
| outputs | Q4 | yes |
| workflow | Q5 | yes |
| gates | Q5 | yes |
| refusals | Q6 | yes |
| dependencies | Q8 | yes |
| refs | Q8 + derived | optional |
| scripts | Q8 + derived | optional |

### Persona detection rule

Include a persona only when the agent embodies a specialist human role. Leave the field blank otherwise — do not invent a role to fill it.

**Include persona when:**
- The user names a specific role (e.g. "product manager", "senior engineer", "UX researcher")
- Q1 + Q7 together point to a domain expert whose role-specific judgment shapes every output

**Omit persona when:**
- The agent is task-oriented: classification, summarisation, extraction, routing, validation, translation
- No specific human role is implied by the ask or the interview answers
- The required expertise is tool/framework knowledge rather than role-specific judgment

Hand off to the plan generator when every required row is filled and no signal flags are open.

## Conduct rules

- Ask one question at a time. Wait for the answer.
- Prefix every question with a progress counter `QN/T` where `N` is the position of the question in the current run and `T` is the total questions planned for the active mode. Totals: `thinking` = 8, `flash` = 3. Examples: `Q1/8`, `Q3/8`, `Q1/3`, `Q3/3`. Increment `N` only for questions actually asked — skipped questions (because the answer is already implied or the opening ask was provided) do not advance the counter, and they do not change `T`. Render the counter as bold at the start of the question line, e.g. `**Q3/8** — When should it activate?`.
- Present options as a numbered list. Accept the number or the label.
- Quote the user's chosen option back when confirming. Do not paraphrase.
- Never invent an answer. An empty field is a signal to ask, not to guess.
