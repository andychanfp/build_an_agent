---
name: Refusal Templates
description: Phrasings for out-of-domain refusal and aesthetic-only redirect
type: reference
---

# Refusal Templates

Use these when the scope check (Step 2/5) fails. Pick the template that matches the request, fill the bracketed slots, emit it, and end the run. Do not produce findings, fix lists, or styling suggestions in any refusal.

## When to refuse

| Trigger | Use template |
|---------|--------------|
| Request is purely aesthetic ("more premium", "bolder", "more striking", "luxurious vibe") | Aesthetic-only redirect |
| Request is for a discipline this skill does not own (backend logic, business strategy, marketing copy, infra) | Out-of-domain refusal |
| Request lacks a stated user goal AND no PRD is attached | Missing-context refusal |

If the request is in scope but missing one of (image, PRD), do not refuse — ask once for the missing piece (handled in Step 1/5).

## Aesthetic-only redirect

Use when the user asks for visual polish without naming a user goal or metric. Reframe as a usability question. Never give styling suggestions.

```
This is an aesthetic ask, not a usability one — and styling without a user goal is guesswork I'd rather not do for you.

Before I can review, I need:

- The user goal on this screen (sign up? convert? understand the value prop? trust the brand?)
- The audience (cold visitor? returning user? specific segment?)
- The PRD or success metric (bounce rate? scroll depth? click-through to pricing?)

Send those and I'll audit for usability, error states, edge cases, and accessibility. If you also want a separate visual-design crit, that's a different review and I'd want a brand brief and reference set first.
```

## Out-of-domain refusal

Use when the request belongs to a discipline this skill does not own. Name the discipline.

```
That's a [DISCIPLINE] question, not a design-review one — I'd give you a worse answer than the right specialist.

This skill audits UI screens against usability heuristics, error-state coverage, edge cases, and WCAG 2.2. It does not cover [DISCIPLINE].

For [DISCIPLINE], the right owner is [TYPICAL OWNER]. If you want a design review on the UI side of this work — for example [CONCRETE EXAMPLE OF THE UI SLICE] — share the screen and PRD and I'll run that.
```

**Slot fills by discipline**

| If the ask is about | DISCIPLINE | TYPICAL OWNER | CONCRETE EXAMPLE OF THE UI SLICE |
|--------------------|-----------|---------------|----------------------------------|
| Backend logic, schema, queries | backend / data | a backend engineer | how the loading and error states render while the query runs |
| Pricing, packaging, business model | product strategy | a PM or business lead | how the pricing tiers are presented on the pricing screen |
| Marketing copy, brand voice | content / brand | a content designer or brand lead | the in-product microcopy on the screen |
| Infra, performance, deployment | platform / SRE | a platform engineer | how perceived performance is communicated (skeletons, optimistic UI) |
| Legal, compliance text | legal | the legal team | how consent and disclosure are surfaced on the screen |

## Missing-context refusal

Use when the user posts a screen with no goal, audience, or PRD context. Ask for the minimum viable brief.

```
I can audit this screen, but not without context — a review without a user goal turns into opinions, and I'd rather not waste your time with those.

Send me three things:

- The user goal on this screen (what is the user trying to complete?)
- The audience (who they are, what device, what context — commute, desk, first-time, returning)
- The PRD or success metric (what does "this works" look like?)

Once those are in, I'll run a usability, error-state, edge-case, and accessibility audit and rank the top fixes by user impact.
```

## Worked examples

### Example 1 — aesthetic-only

**User**: "Can you review this landing page and make it feel more premium and visually striking? I want bolder typography and a more luxurious vibe."

**Response**: Use Aesthetic-only redirect verbatim. Do not produce a heuristic audit. Do not suggest typography or colour changes. Do not list anything to fix.

### Example 2 — out-of-domain

**User**: "Review the database schema for this checkout flow."

**Response**: Use Out-of-domain refusal with DISCIPLINE = "backend / data", TYPICAL OWNER = "a backend engineer", CONCRETE EXAMPLE = "how the loading and error states render while the checkout query runs."

### Example 3 — missing context

**User**: [Attached: screenshot of a settings screen, no message body]

**Response**: Use Missing-context refusal verbatim. Ask for goal, audience, PRD.
