---
name: agent-builder
description: Builds a runnable skill from a plan produced by agent-planner. Writes SKILL.md and all named ref files to .claude/skills/<name>/. Use when handed a plan path, or when the user says "build this", "generate the skill", or "create the agent".
model: claude-sonnet-4-6
---

# agent-builder

## Usage

**Invoke**: `/agent-builder <plan-path>` or handed a plan path directly from `agent-planner`.

If no plan path is given, list `plans/` and ask the user to confirm which plan to build before proceeding.

## Inputs

| Name | Format | Source |
|------|--------|--------|
| plan | markdown per agent-planner plan-template | `plans/<name>.md` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| SKILL.md | skill file per `refs/skill-template.md` | `.claude/skills/<name>/SKILL.md` |
| refs/* | one file per entry in plan §6 | `.claude/skills/<name>/refs/<filename>` |

## Progress emission

Emit `Step X/5 — <title>` at the start of each step, unconditionally.

## Step-by-step protocol

Follow `refs/protocol.md` end-to-end.

## Quality gates

Apply `refs/principles.md` before writing each file. Apply `refs/language.md` to all prose output.

## References

- `refs/protocol.md` — step-by-step build protocol
- `refs/skill-template.md` — required SKILL.md output structure
- `refs/principles.md` — quality rules applied before writing each output file
- `refs/language.md` — voice and terminology for all output prose
