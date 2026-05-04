---
name: Plan Template
description: Required structure for plan documents consumed by the agent-builder
type: reference
---

# Plan Template

Every plan output must follow this structure. Sections appear in this
order. Required sections cannot be empty. Optional sections may be omitted.

For workflow diagram conventions, see `workflow-template.md`.
For persona structure, see `persona.md`.

## 1. Skill identity (required)

YAML frontmatter for the generated SKILL.md.

- `name`: kebab-case identifier
- `description`: one line, ~80 words or fewer, covers what the skill does
  and when to consult it
- `type`: skill type if applicable

## 2. Trigger conditions (required)

When Claude should consult this skill. List concrete conditions, not
generalities.

- User phrases that should activate it
- Task shapes or contexts that match
- File types or artifacts that signal relevance

## 3. Persona (conditional)

Include this section only when the agent embodies a specialist human role
(e.g. the user named "product manager", "senior engineer", "UX researcher",
or Q1 + Q7 point to role-specific judgment). Omit it entirely for
task-oriented agents (classification, summarisation, extraction, routing,
validation) where no human role is implied.

When included, all seven axes from `persona.md` must be filled with
role-specific content:

1. Role identity
2. Values
3. Knowledge & expertise
4. Anti-patterns
5. Decision-making
6. Pushback style
7. Communication texture

## 4. Inputs and outputs (required)

- **Inputs**: what the skill receives (files, prompts, prior context).
  Name format and source for each.
- **Outputs**: what the skill produces (artifacts, structured data, side
  effects). Name format and destination for each.

## 5. Workflow (required)

The skill's protocol, in two parts:

- **Diagram**: ASCII workflow per `workflow-template.md`.
- **Protocol**: numbered prose steps. Each step states its purpose, the
  action taken, and the resulting output.

Diagram and prose must describe the same flow. If they diverge, sharpen
both until they match.

## 6. Reference files (optional)

Refs the skill will need. One bullet per ref:

- `<filename.md>` — one-line purpose

## 7. Scripts (optional)

Helper scripts to bundle. One bullet per script:

- `<filename.py>` — one-line purpose