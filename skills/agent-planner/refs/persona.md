---
name: Persona
description: PRISM-lite framework for defining specialist agent personas
type: reference
---

# Persona

A PRISM-lite subset for defining the specialist an agent embodies. Apply
when an agent's plan names a persona.

## Related refs

- `persona-exemplars.md` — three worked exemplars (designer, PM, engineer)
  showing role-specific differentiation across all seven axes. Load when
  actively constructing a new persona; skip when validating or refining
  an existing one.

## Axes

Every persona must define all seven axes in the order below. If an axis
cannot be filled with role-specific content, the persona is too generic
and should be sharpened or rejected.

1. **Role identity**: Real job title, seniority, domain. ~50 tokens or fewer.
   No flattery, no superlatives.
2. **Values**: Abstract principles the persona cares about. State as
   principles, not behaviors. (Behaviors go in axis 4.)
3. **Knowledge & expertise**: Specific domains, frameworks, or technologies
   the persona has working fluency in. Concrete enough to constrain output.
4. **Anti-patterns**: Behaviors the persona refuses to perform. Stated as
   "never X" with reasoning where useful.
5. **Decision-making**: How the persona makes recommendations. Must reflect
   the role — a PM and an engineer recommend differently.
6. **Pushback style**: How the persona disagrees. What evidence or
   framing they bring when they push back.
7. **Communication texture**: Sentence rhythm, vocabulary register, where
   they use specifics vs. abstractions. Not personality archetypes.

## Anchoring failures

- **Personality archetypes**: "Grumpy senior engineer", "passionate
  designer", "cautious PM". These activate fiction tropes, not expertise.
- **Vague hybrids**: "Product engineer who also does marketing". Hybrids
  are allowed only when they name a real specialty with an actual talent
  market ("design engineer", "data scientist").
- **Neutral advisors**: "No strong opinions", "balanced view". Personas
  must take positions; stakes drive output quality.
- **Generic axes**: If decision-making, pushback style, or texture reads
  the same across two personas, the axis isn't doing work. Sharpen or cut.
- **Flattery**: "World-class", "expert", "best-in-class". Activates
  marketing text in training data, not domain knowledge.

  ## When the planner builds a persona

1. Identify the role with the user.
2. Load `persona-exemplars.md` for anchoring patterns.
3. Build the persona, do not walk with the user on this
4. Generate a synthesise of the persona to use for the plan template