---
name: agent-build
description: Builds a runnable skill from a plan produced by agent-plan. Writes SKILL.md and all named ref files to .claude/skills/<name>/. Use when handed a plan path, or when the user says "build this", "generate the skill", or "create the agent".
model: claude-opus-4-7
---

# agent-build

## Usage

**Invoke**: `/agent-build <plan-path>` or handed a plan path directly from `agent-plan`.

If no plan path is given, list `plans/` and ask the user to confirm which plan to build before proceeding.

## Inputs

| Name | Format | Source |
|------|--------|--------|
| plan | markdown per agent-plan plan-template | `plans/<name>.md` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| SKILL.md | skill file per `refs/skill-template.md` | `.claude/skills/<name>/SKILL.md` |
| refs/* | one file per entry in plan §6 | `.claude/skills/<name>/refs/<filename>` |

## Progress emission

Emit `Step X/5 — <title>` at the start of each step, unconditionally.

## Step-by-step protocol

**Step 1/5 — Load and validate plan**

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

**Step 2/5 — Scaffold directories**

Extract `<name>` from plan §1 YAML `name` field. Check for `output_dir` in plan §1:

- **`output_dir` is set** (Desktop or Custom install): `skill_root = <output_dir>`
- **`output_dir` is absent** (Global install): `skill_root = .claude/skills/<name>`

Run via Bash:

```bash
mkdir -p <skill_root>/refs
```

Do not prompt. If the directory already exists, continue.

**Step 3/5 — Write SKILL.md**

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

Write to `<skill_root>/SKILL.md`. Do not prompt.

**Step 4/5 — Write ref files**

For each entry in plan §6, write one file to `<skill_root>/refs/<filename>`.

Frontmatter format (required on every ref):

```
---
name: <Title Case name>
description: <one-line purpose, copied from plan §6 bullet>
type: reference
---
```

Content generation rules:

| Ref type | How to generate |
|----------|----------------|
| Domain standard (WCAG, Nielsen's heuristics, RFC, accessibility specs) | Generate from domain knowledge. Include all canonical items — never stub. |
| Persona-derived (refusal phrasings, tone guides, decision heuristics) | Derive from plan §3 axes 4, 6, and 7. |
| Workflow-derived (checklists, taxonomies, state lists) | Derive from plan §5 workflow steps and plan §3 axis 3 (Knowledge & expertise). |
| Proprietary or custom process | Derive what can be inferred from the plan. Mark gaps with `[USER: fill in <specific item>]` — never leave silent stubs. |

Minimum content per ref:

- At least one H2 section
- At least 3 concrete items (bullets, table rows, numbered rules)
- At least one worked example or applied instance

Every ref must be self-contained: each rule understandable without reading another file.

**Step 5/5 — Verify and emit**

For each file written, read it back and check it against `refs/principles.md`. If any gate fails, rewrite and re-check.

Emit a build report:

```
Build complete: <skill_root>/
  SKILL.md              <N> lines
  refs/<file1>.md       <N> lines
  refs/<file2>.md       <N> lines
  ...
```

Then hand off: "Ready for /agent-evaluate."

## Quality gates

Apply `refs/principles.md` before writing each file. Apply `refs/language.md` to all prose output.

## References

- `refs/skill-template.md` — required SKILL.md output structure
- `refs/principles.md` — quality rules applied before writing each output file
- `refs/language.md` — voice and terminology for all output prose
