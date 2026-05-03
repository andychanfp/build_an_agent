---
name: Principles
description: Quality gates applied to every file agent-build writes — SKILL.md and all ref files
type: reference
---

# Principles

## SKILL.md gates

Apply before writing `.claude/skills/<name>/SKILL.md`.

| Gate | Rule |
|------|------|
| Length | ≤500 lines. If over, extract content to a ref and link it. |
| Steps | Each step names one input artifact and one output artifact. |
| Steps | No step contains "and" joining two distinct actions. Split into separate steps. |
| Steps | Maximum 8 steps. Extract a sub-skill if more are needed. |
| Persona | All seven axes present and non-generic. If an axis reads identically across two roles, it is not doing work — sharpen it. |
| References | Every ref bullet in `## References` corresponds to a file in plan §6. Add no extras. |
| Triggers | `## Usage` lists at least one slash command or one natural-language trigger phrase. |
| Language | Every sentence passes `refs/language.md`. Run the forbidden-words check before writing. |
| Model | Frontmatter `model` is always set. Never omit it. |

## Ref file gates

Apply before writing each `refs/<file>.md`.

| Gate | Rule |
|------|------|
| Frontmatter | File opens with `---` frontmatter containing `name`, `description`, and `type: reference`. |
| Non-empty | At least one H2 section with ≥3 bullets, or a table with ≥3 rows. |
| Substantive | No placeholder text ("fill in here", "TBD", "example"). Exception: `[USER: fill in <specific item>]` is allowed for genuinely unknowable proprietary content. |
| Self-contained | Each rule or item is understandable without reading another file. |
| Accurate | Domain-standard refs (WCAG, Nielsen, RFC, HIG) match the canonical specification. Do not paraphrase in ways that change the rule. |
| Worked example | At least one concrete example, applied instance, or usage note per major section. |

## Common failure modes

| Failure | Symptom | Fix |
|---------|---------|-----|
| Step output not named | Step says "handle X" with no artifact | Add "produce `<artifact name>`" |
| Ref is a heading and two words | File has title + three-word description | Generate real content from plan §3 axis 3 |
| Persona axis is generic | "Values quality and collaboration" | Pull a specific heuristic or framework from the persona's domain |
| Extra refs added | SKILL.md `## References` lists files not in plan §6 | Remove extras; do not invent refs the plan did not specify |
| Step mixes two actions | "Read the file and validate it" | Split: Step N reads; Step N+1 validates |
| Trigger list is empty | `## Usage` has only the slash command | Add natural-language triggers from plan §2 |

## Line-count guidance

| File | Target | Hard limit |
|------|--------|-----------|
| SKILL.md | 80–200 lines | 500 lines |
| Each ref | 30–150 lines | 300 lines |

Files shorter than the target are acceptable if the content is complete. Files at the hard limit must be split.
