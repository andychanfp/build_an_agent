---
name: Nielsen Heuristics
description: The 10 heuristics with audit prompts per heuristic
type: reference
---

# Nielsen Heuristics

Audit every screen against all 10. For each heuristic, ask the audit prompts; if any answer is "no" or "unclear", record a finding that names the broken state and the user consequence.

## H1. Visibility of system status

The system tells the user what is happening, through appropriate feedback within reasonable time.

- Does every action that takes >1s show progress (spinner, skeleton, percentage)?
- After a destructive or important action, does the screen confirm what just happened?
- Are stale states (cached data, old prices, expired tokens) visibly marked as such?

**Example finding**: "Place Order tap shows no loading state. User taps again, double-charges."

## H2. Match between system and the real world

Use words, phrases, and concepts the user knows. Follow real-world conventions.

- Does the screen use user-language ("delivery time") not system-language ("ETA dispatch window")?
- Are icons recognisable without their labels?
- Do dates, currencies, and units match the user's locale?

**Example finding**: "ETA chip reads '32m'. New users on first order do not parse 'm' as minutes — show '32 min'."

## H3. User control and freedom

Users need a clearly marked exit from mistaken states. Support undo and redo.

- Is there a visible Back, Cancel, or Close on every screen the user can land on?
- Can the user undo a destructive action (delete, send, charge)?
- After a multi-step flow, can the user edit any prior step without restarting?

**Example finding**: "Address row is not tappable. User who picked the wrong address must abandon checkout to change it."

## H4. Consistency and standards

Follow platform conventions. Same word, same action, same place.

- Does the primary CTA match platform conventions (iOS bottom-fixed, Material FAB or bottom bar)?
- Do equivalent actions use the same label across screens (Save vs Done vs Confirm)?
- Do icons used for the same action match across the app?

**Example finding**: "Cart screen uses 'Confirm', this screen uses 'Place Order' for the same submit action — split-test risk and confusion."

## H5. Error prevention

Prevent errors before they happen. Confirm before high-cost actions.

- Are destructive or high-cost actions guarded by confirmation or a typed acknowledgement?
- Are inputs constrained at entry (date pickers, dropdowns, masks) instead of validated only on submit?
- Are dangerous defaults removed (pre-checked subscribe, opted-in tracking)?

**Example finding**: "Place Order has no confirmation. A misfire on a $90 order has no recovery path before charge."

## H6. Recognition rather than recall

Minimise memory load. Make options, actions, and information visible.

- Can the user complete the task without remembering data from a prior screen?
- Are recently used or saved options surfaced (saved address, last payment method)?
- Are field labels visible at all times, not only as placeholder text that disappears on focus?

**Example finding**: "Promo-code field uses placeholder-only label. After typing, the user cannot recall what the field was for."

## H7. Flexibility and efficiency of use

Accelerators for expert users. Allow tailoring for frequent actions.

- Are there shortcuts for repeat users (one-tap reorder, saved-card auto-select)?
- Can power users skip steps the new user needs (skip address picker if only one saved)?
- Can the user customise frequent settings (default tip, default delivery option)?

**Example finding**: "Returning user with one saved address still walks the address picker — adds two taps to every order."

## H8. Aesthetic and minimalist design

Interfaces should not contain irrelevant or rarely needed information.

- Does every element on the screen serve the primary user goal on this screen?
- Are competing CTAs reduced to one primary action per screen?
- Is decoration (illustration, gradient, badge) earning its space, or competing with the CTA?

**Example finding**: "Promo banner sits above Place Order at equal visual weight — splits attention from the primary action."

## H9. Help users recognise, diagnose, and recover from errors

Error messages in plain language, precisely indicate the problem, suggest a solution.

- Does every error name what failed in plain language?
- Does every error suggest a specific next action?
- Do errors point to the field that caused them (inline, not just a top banner)?

**Example finding**: "Payment failure shows 'Something went wrong'. User cannot tell whether to retry, change card, or contact support."

## H10. Help and documentation

Provide help that is easy to search, focused on the user's task, lists concrete steps.

- Is help reachable from the screen where the user gets stuck (not buried in Settings)?
- Are help articles task-shaped ("How to change my delivery address") not feature-shaped ("Address Book")?
- Does the screen surface contextual hints for first-time states?

**Example finding**: "Refund flow has no in-screen help. User must leave checkout to find a Help Centre link in the profile tab."

## Worked example: applying H1–H10 to a checkout-confirmation screen

| Heuristic | Audit | Finding |
|-----------|-------|---------|
| H1 | Loading state on Place Order? | None — blocker (double-charge risk) |
| H5 | Confirmation before charge? | None — major |
| H9 | Payment-failure copy? | "Something went wrong" — major (no recovery path) |
| H3 | Edit address mid-flow? | Address row not tappable — major |
| H6 | Saved address visible without recall? | Yes — pass |
