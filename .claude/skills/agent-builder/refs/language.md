---
name: Language
description: Voice, tone, and terminology rules for all prose agent-builder writes into SKILL.md and ref files
type: reference
---

# Language

## Voice

- **Active only**: Write "The agent reads the plan", not "The plan is read."
- **Present tense**: State rules in present tense; use past tense only in examples.
- **Imperatives for instructions**: Write "Read the file", not "You should read the file."
- **Third person for system behaviour**: Use "the agent" when describing what the skill does; use "you" only in direct user-facing instructions.

## Terminology

- **One term per concept**: Pick one word and use it throughout. Never swap "step" / "task" / "action" / "item" to mean the same thing.
- **Define on first use**: Introduce domain terms inline — "error state (a UI condition with no valid data to display)" — then use the short form.
- **No imported jargon**: Replace any term that needs more than 5 words to explain with plain English.
- **Prefer short words**: "use" not "utilize", "help" not "facilitate", "check" not "ensure", "because" not "due to the fact that", "to" not "in order to."

## Forbidden words

Replace on sight:

| Forbidden | Use instead |
|-----------|-------------|
| leverage | use |
| utilize | use |
| facilitate | help / enable |
| ensure | check / verify |
| various / several / some | state the exact number, or "all" |
| robust | specific quality (fast, reliable, tested) |
| seamless | remove — adds nothing |
| in order to | to |
| at this point in time | now |
| going forward | from now on |
| it is important that | state the rule directly |
| comprehensive | name what is covered |
| powerful | name the specific capability |

## Hedging

- **No soft qualifiers in rules**: Remove "might", "could", "may", "perhaps", "possibly", "generally", "typically", "usually", "in most cases."
- **Turn uncertainty into a conditional**: Write "If X is unknown, do Y" — not "You might need to handle X."
- **No throat-clearing**: Remove "Note that", "Keep in mind that", "It is worth mentioning." State the point.

## Length

- **One idea per sentence**: Split at "and" or "but" when two actions are joined.
- **20-word cap per rule line**: Count before writing; rewrite if over.
- **No preamble**: Start sections with the first rule, not an introductory sentence.
- **No summaries**: Omit "In conclusion", "As shown above", "To summarise." The content speaks for itself.

## Ref file voice

Refs are instructions and reference material, not documentation. Apply all rules above. Additional rules:

- **Bullets over paragraphs**: Prefer a bulleted list of rules over a paragraph explaining them.
- **Tables for comparisons**: Use a table when two or more items share the same attributes.
- **Examples are concrete**: Examples name specific inputs, outputs, and states — not generic placeholders.
