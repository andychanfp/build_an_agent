---
name: Language
description: Voice, tone, and terminology rules for plan documents produced by the agent-planner
type: reference
---

# Language

## Voice
- **Active only**: Write "The agent creates a plan", not "A plan is created."
- **Present tense**: State rules in present tense; use past tense only in examples.
- **Second person for instructions**: Address the reader as "you" in instructions; use "the agent" only when describing system behaviour.
- **Recommend, don't suggest**: Write "Use X" or "Do Y", never "You might want to consider X."

## Terminology
- **One term per concept**: Pick one word and use it throughout. Never swap "step" / "task" / "action" / "item" to mean the same thing.
- **Define on first use**: Introduce domain terms inline — "execution plan (a sequenced list of steps)" — then use the short form.
- **No imported jargon**: If a term needs more than 5 words to explain, replace it with plain English.
- **Prefer short words**: "use" not "utilize", "help" not "facilitate", "check" not "ensure", "because" not "due to the fact that", "to" not "in order to."

## Forbidden Words
Replace these on sight:

| Forbidden | Use instead |
|-----------|-------------|
| leverage | use |
| utilize | use |
| facilitate | help / enable |
| ensure | check / verify |
| various / several / some | state the exact number, or "all" |
| robust | specific quality (fast, reliable, tested) |
| seamless | remove — it adds nothing |
| in order to | to |
| at this point in time | now |
| going forward | from now on |
| it is important that | state the rule directly |

## Hedging
- **No soft qualifiers in rules**: Remove "might", "could", "may", "perhaps", "possibly", "generally", "typically", "usually", "in most cases."
- **Turn uncertainty into a conditional**: Write "If X is unknown, do Y" — not "You might need to handle X."
- **No throat-clearing**: Remove "Note that", "Keep in mind that", "It is worth mentioning." State the point.

## Length
- **One idea per sentence**: Split at "and" or "but" when two actions are joined.
- **20-word cap per rule line**: Count before publishing; rewrite if over.
- **No preamble**: Start sections with the first rule, not an introductory sentence.
- **No summaries**: Omit "In conclusion", "As shown above", "To summarise." The content speaks for itself.