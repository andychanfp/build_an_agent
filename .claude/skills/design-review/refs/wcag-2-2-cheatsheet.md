---
name: WCAG 2.2 Cheatsheet
description: Contrast ratios, target sizes, focus-order, keyboard-nav rules
type: reference
---

# WCAG 2.2 Cheatsheet

The minimum WCAG 2.2 Level AA rules every screen must pass. For each row, ask the audit prompt; if any answer is "no" or "unclear", record a finding naming the broken state and the user consequence.

## Contrast (SC 1.4.3, 1.4.6, 1.4.11)

| Element | Minimum ratio | Notes |
|---------|--------------|-------|
| Normal text (<18pt or <14pt bold) | 4.5:1 | Against background it sits on |
| Large text (≥18pt or ≥14pt bold) | 3:1 | |
| UI components and graphical objects | 3:1 | Icons, focus indicators, form-field borders |
| Incidental text (decorative, disabled, logo) | exempt | Truly disabled controls only |

**Audit prompt**: For every text and icon, sample colour against background. Use the lowest-contrast surface (e.g. white text over a photo's brightest patch).

**Worked example**: Place Order CTA uses white text (#FFFFFF) on brand orange (#FFA62B). Ratio = 2.1:1. **Major** — fails AA for normal text.

## Target size (SC 2.5.8, new in WCAG 2.2)

| Surface | Minimum target | Spacing |
|---------|---------------|---------|
| Touch targets | 24×24 CSS pixels | with offset, OR 44×44 if no spacing — match platform: iOS HIG 44pt, Material 48dp |
| Inline text links in a paragraph | exempt | |
| Targets controlled by the user agent | exempt | |

**Audit prompt**: Measure tap-target hit areas, not just visual size. A 16px icon with 24px padding around it counts as a 64px target.

**Worked example**: Edit-pencil icon next to address row is 16×16 with no padding. **Minor** — fails 24×24, fails platform conventions; user mis-taps the row instead.

## Focus order and visible focus (SC 2.4.3, 2.4.7, 2.4.11)

- Focus moves in an order that preserves meaning and operability.
- Focus indicator is visible — never `outline: none` without a replacement.
- Focused element is not fully obscured by author-created content (sticky headers, cookie banners).
- Focus indicator has a 2:1 contrast against adjacent colours and is at least 2 CSS pixels thick.

**Audit prompt**: Tab through the screen with no mouse. Can you see where focus is? Is the order top-to-bottom, left-to-right, matching the visual layout?

**Worked example**: After tabbing past the address row, focus lands on a hidden modal dismiss button — focus moves off-screen. **Major** — keyboard user becomes lost.

## Keyboard navigation (SC 2.1.1, 2.1.2)

- Every interactive control is reachable and operable with a keyboard.
- No keyboard trap — focus can always move out of any component.
- Custom controls (sliders, dropdowns, modals) implement expected key behaviours (Esc closes, arrows navigate, Enter activates).

**Audit prompt**: Operate every control on the screen using only Tab, Shift+Tab, Enter, Space, Esc, and arrow keys.

**Worked example**: A custom payment-method dropdown opens on Enter but cannot be closed without clicking. **Blocker** — keyboard user trapped.

## Screen-reader semantics (SC 1.3.1, 4.1.2)

- Form fields have programmatic labels (not placeholder-only).
- Buttons announce their purpose, not their visual icon ("Edit address", not "pencil").
- Headings are used in order (h1 → h2 → h3, no skipping).
- ARIA roles match the actual behaviour (a `role="button"` on a div must be focusable and activate on Enter/Space).
- Live regions announce dynamic changes (toast, error, loading completion).

**Audit prompt**: Read the screen with VoiceOver / TalkBack / NVDA. Does it announce every meaningful element with the right role and label?

**Worked example**: Promo-code field uses placeholder "Enter code" with no `<label>`. Screen reader announces "edit text, blank". **Major** — non-sighted user does not know what to type.

## Motion and timing (SC 2.2.1, 2.2.2, 2.3.3)

- Auto-advancing carousels, animations, and timeouts can be paused, stopped, or extended.
- Sessions warn before timeout and offer extension.
- Motion (parallax, auto-rotate) respects `prefers-reduced-motion`.

**Audit prompt**: Is there any animation, auto-rotate, or timeout? Can the user stop it?

**Worked example**: Cart screen warns "Session expires in 1 minute" with no extend button. **Major** — user mid-checkout times out and loses cart.

## Forms and errors (SC 3.3.1, 3.3.2, 3.3.3, 3.3.4)

- Required fields marked visibly and programmatically (`aria-required`).
- Errors announced inline next to the field, not only at the top.
- Error message names the field and the fix ("Enter a valid postcode, e.g. SW1A 1AA").
- Destructive submissions are reversible or confirmed (3.3.4).

**Audit prompt**: Submit the form with bad input. Where is the error? Does it name the field? Does it suggest the fix?

**Worked example**: Address form returns "Invalid input" in a top toast that disappears in 4s. **Major** — user does not know which field, does not see the message in time.

## Worked example: applying WCAG 2.2 to a checkout-confirmation screen

| Rule | Audit | Finding | Severity |
|------|-------|---------|----------|
| 1.4.3 contrast | White on orange CTA | 2.1:1 — fails AA | major |
| 2.5.8 target size | Edit-pencil 16×16 with no pad | fails 24×24 minimum | minor |
| 2.4.7 focus visible | Tab to Place Order shows no outline | invisible focus | blocker (keyboard users) |
| 4.1.2 labels | Promo-code placeholder-only | screen reader announces "blank" | major |
| 3.3.4 confirmation | No confirm before charge | no error prevention | blocker |
