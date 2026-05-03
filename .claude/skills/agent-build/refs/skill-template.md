---
name: Skill Template
description: Required structure and section order for every SKILL.md file produced by agent-build
type: reference
---

# Skill Template

## Section order

| Section | Required |
|---------|----------|
| Frontmatter | yes |
| Usage | yes |
| Inputs | yes |
| Outputs | yes |
| Persona | yes |
| Model loading | if steps use different models |
| Progress emission | if more than 3 steps |
| Step-by-step protocol | yes |
| Caching | if steps load large or reusable context |
| References | if plan §6 is non-empty |

Sections must appear in this order. Do not reorder. Do not add sections not listed here.

## Frontmatter

```yaml
---
name: kebab-case-name
description: One line. What this skill does and when to invoke it. ≤80 words.
model: claude-sonnet-4-6
---
```

- `name`: kebab-case; matches the directory name under `.claude/skills/`
- `description`: specific enough to trigger on the right task; narrow enough to avoid false positives; ≤80 words
- `model`: always set; default `claude-sonnet-4-6`; use `claude-opus-4-7` only when every step requires deep synthesis

## Usage

```markdown
## Usage

**Invoke**: `/skill-name <args>` — describe what to pass.

- Slash command `/skill-name`
- Natural-language: "phrase one", "phrase two"
- Context: file type or artifact that signals relevance
```

- List every trigger from plan §2.
- At least one slash command or natural-language phrase is required.

## Inputs

```markdown
## Inputs

| Name | Format | Source |
|------|--------|--------|
| input_name | format | where it comes from |
```

One row per input. `Source` must be concrete: `user message`, `attached file`, `prior context`, `plans/<name>.md`.

## Outputs

```markdown
## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| output_name | format | where it goes |
```

One row per output. `Destination` must be concrete: `shown inline`, `.claude/skills/<name>/SKILL.md`, `handed to <next-skill>`.

## Persona

```markdown
## Persona

1. **Role identity**: ...
2. **Values**: ...
3. **Knowledge & expertise**: ...
4. **Anti-patterns**: ...
5. **Decision-making**: ...
6. **Pushback style**: ...
7. **Communication texture**: ...
```

Copy all seven axes from plan §3 verbatim. Do not summarise or compress any axis.

## Model loading (optional)

Include when steps use different models. Omit when one model handles all steps.

```markdown
## Model loading

| Task type | Model | Why |
|-----------|-------|-----|
| Parsing, pattern-matching, template fill | `claude-haiku-4-5` | Deterministic; no synthesis |
| Drafting, synthesis, structural reasoning | `claude-sonnet-4-6` | Default workhorse |
| Deep persona or domain reasoning | `claude-opus-4-7` | Load on user request only |

Tag each step `[model: …]`. The orchestrator must respect the tag.
```

## Progress emission (include when more than 3 steps)

```markdown
## Progress emission

Emit `Step X/N — <title>` at the start of each step, unconditionally.
```

## Step-by-step protocol

```markdown
## Step-by-step protocol

**Step 1 — <title>** `[model: sonnet]`
<What the agent reads. What action it takes. What artifact it produces — name it explicitly.>

**Step 2 — <title>** `[model: haiku]`
...
```

Rules:
- Number from 1. Never skip a number.
- Each step names its input artifact and its output artifact.
- Steps that load a ref name it explicitly: "Follow `refs/checklist.md`."
- Tag each step `[model: …]` when a Model loading section is present.
- No step joins two distinct actions with "and". Split into separate steps.
- Maximum 8 steps. Extract a sub-skill if more are needed.
- Steps may use prose, bullets, tables, or inline approval prompts. Do not force a single format.

## Caching (optional)

Include when the skill loads large stable context (persona, long refs, multi-turn prompts) that can be reused across turns.

```markdown
## Caching

This skill and its refs load on activation and are cached for the session. Keep volatile content (timestamps, run IDs, user names) out of SKILL.md and refs to preserve cache hits.
```

Add step-specific notes if a step structures Anthropic API calls:
- Place stable content (system prompt, persona, refs) in the cached prefix.
- Place variable content (user input, current file) after the cache breakpoint.
- Mark the prefix with `cache_control: {"type": "ephemeral"}`.

## References

```markdown
## References

- `refs/<filename>.md` — one-line purpose
```

One bullet per ref. Purpose matches what the ref actually contains.
