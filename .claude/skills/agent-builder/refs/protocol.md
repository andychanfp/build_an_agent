---
name: Protocol
description: Step-by-step build protocol for agent-builder — validates a plan then writes SKILL.md and all ref files
type: reference
---

# Protocol

## Step 1/5 — Load and validate plan

Read the plan file. Check every required section is present and non-empty:

| Section | Required content |
|---------|-----------------|
| §1 Skill identity | YAML block with `name` and `description` |
| §2 Trigger conditions | At least one trigger |
| §3 Persona | All seven axes present |
| §4 Inputs and outputs | At least one input and one output |
| §5 Workflow | Diagram and protocol both present |

If any required section is missing or empty, stop. Emit:

> `Build halted: §<N> (<title>) is missing or empty.`

Do not write any files.

## Step 2/5 — Scaffold directories

Extract `<name>` from plan §1 YAML `name` field.

Run via Bash:

```bash
mkdir -p .claude/skills/<name>/refs
```

Do not prompt. If the directory already exists, continue.

## Step 3/5 — Write SKILL.md

Map plan sections to SKILL.md using this table:

| SKILL.md element | Source |
|-----------------|--------|
| Frontmatter `name` | Plan §1 YAML `name` |
| Frontmatter `description` | Plan §1 YAML `description` |
| Frontmatter `model` | `claude-sonnet-4-6` unless plan §1 specifies otherwise |
| `## Usage` / Invoke line | Slash command from plan §2 trigger conditions |
| `## Usage` / trigger list | All natural-language and context triggers from plan §2 |
| `## Inputs` table | Plan §4 Inputs |
| `## Outputs` table | Plan §4 Outputs |
| `## Persona` section | Plan §3 — all seven axes verbatim |
| `## Step-by-step protocol` | Plan §5 Protocol — numbered steps; tighten language per `language.md` |
| `## References` bullets | Plan §6 — one bullet per ref, `filename.md — one-line purpose` |

Follow `refs/skill-template.md` for section order and formatting.

Apply `refs/principles.md` quality gates before writing.

Write to `.claude/skills/<name>/SKILL.md`. Do not prompt.

## Step 4/5 — Write ref files

For each entry in plan §6, write one file to `.claude/skills/<name>/refs/<filename>`.

**Frontmatter format (required on every ref):**

```
---
name: <Title Case name>
description: <one-line purpose, copied from plan §6 bullet>
type: reference
---
```

**Content generation rules:**

| Ref type | How to generate |
|----------|----------------|
| Domain standard (WCAG, Nielsen's heuristics, RFC, accessibility specs) | Generate from domain knowledge. Include all canonical items — never stub. |
| Persona-derived (refusal phrasings, tone guides, decision heuristics) | Derive from plan §3 axes 4, 6, and 7. |
| Workflow-derived (checklists, taxonomies, state lists) | Derive from plan §5 workflow steps and plan §3 axis 3 (Knowledge & expertise). |
| Proprietary or custom process | Derive what can be inferred from the plan. Mark gaps with `[USER: fill in <specific item>]` — never leave silent stubs. |

**Minimum content per ref:**

- At least one H2 section
- At least 3 concrete items (bullets, table rows, numbered rules)
- At least one worked example or applied instance

Every ref must be self-contained: each rule understandable without reading another file.

## Step 5/5 — Verify and emit

For each file written:

1. Read it back.
2. Check it against `refs/principles.md`. If any gate fails, rewrite and re-check.

Emit a build report:

```
Build complete: .claude/skills/<name>/
  SKILL.md              <N> lines
  refs/<file1>.md       <N> lines
  refs/<file2>.md       <N> lines
  ...
```

Then hand off: "Ready for /agent-evaluate or /agent-quality."
