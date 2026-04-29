---
name: Edge Case Checklist
description: Long text, RTL, slow networks, malformed input, zero/max data, paste-bomb
type: reference
---

# Edge Case Checklist

Walk every screen against this list. For each row, ask the audit prompt and inspect the design or mockup. If the screen breaks or the design is silent, record a finding naming the broken state and the user consequence.

## The seven edge classes

| Class | Audit prompt | Common breakage |
|-------|-------------|-----------------|
| Long text | What happens if a label, name, address, or description is 5× longer than the mock? | Truncation hides critical detail; layout overflow; line wraps push CTAs off-screen |
| RTL (right-to-left) | Does the layout mirror correctly for Arabic/Hebrew? | Icons stay LTR, breadcrumbs reverse incorrectly, currency on wrong side |
| Slow networks | What does the screen show on 2G or after 5s with no response? | Infinite spinner; no offline indicator; user double-taps |
| Malformed input | What if the user pastes emoji, RTL chars, control chars, or a URL into a name field? | Layout break; XSS surface; silent rejection with no error |
| Zero data | First-run, cleared list, deleted history — what fills the space? | Blank screen the user reads as a bug |
| Max data | 10,000 items, 50 saved cards, a 200-line address — what happens? | Render lag; overflow; pagination missing |
| Paste-bomb | User pastes 10,000 characters into a 30-char field | Browser hang; silent truncation losing user intent |

## Long text

- Names: test 40+ chars (full legal names, hyphenated names, names with titles).
- Addresses: test 4+ lines (apartment + building + complex + city + postcode).
- Product titles: test 100+ chars (international product names, sub-titles).
- Currency: test 10-figure totals (₫, ₩, IDR amounts run into millions).

**Worked example**: A delivery-address row mocked at 32 chars truncates a real address ("Apartment 4B, Block 12, Greenwood Heights Residential Complex, North Avenue") to "Apartment 4B, Block 12, Green…". Driver delivers to wrong building. Finding: **major** — truncation hides the building identifier the driver needs.

## RTL (right-to-left)

- Text mirrors. Icons that imply direction (back arrow, forward chevron) mirror.
- Icons that do not imply direction (camera, settings) do not mirror.
- Numbers stay LTR ("12:30" not "03:21").
- Currency symbol moves to the side conventional for the locale.
- Tap targets and gesture zones mirror (swipe-to-delete from the correct edge).

**Worked example**: A back chevron pointing left in English remains pointing left in Arabic. Arabic users tap it expecting "forward" and lose their place. Finding: **major** — directional icon not mirrored.

## Slow networks

- After 1s with no response, show a loading state.
- After 5s with no response, show a "still working" message and offer Cancel.
- After 15s, show an error with retry and an alternative path.
- Critical actions (payment, send, submit) queue locally and replay when online.

**Worked example**: On commute (spotty 2G), Place Order taps. No spinner appears for 8s, then nothing changes. User taps three more times. Three orders submit when network recovers. Finding: **blocker** — loading state missing, no idempotency surfaced.

## Malformed input

- Strip or escape control characters in display.
- Reject zero-width characters in name and email fields with a clear error.
- Validate emoji handling: render or reject, never silently corrupt.
- Test paste from rich-text sources (Word, Google Docs) — strip formatting, keep content.

**Worked example**: User pastes their name from a contact card containing a zero-width space. Backend stores it; later search for the name fails. Finding: **major** — silent acceptance of invisible characters causes downstream lookup failure.

## Zero data

- First-time users: every list, feed, table, and chart has a designed zero-state.
- Returning users who cleared history: the cleared state matches the first-time state or names the action ("History cleared — recent searches will appear here").
- Loading vs empty: visually distinct so the user does not wait on a permanently empty screen.

**Worked example**: A new user opens the order-history tab. Screen renders blank with no content. User assumes the app is broken and bounces. Finding: **major** — missing zero-state for first-time history view.

## Max data

- Lists: lazy-load or paginate beyond 50 items.
- Saved entities (addresses, cards, favourites): test 50+, name how the user finds one (search, sort, recently used).
- Numeric overflow: totals, counts, durations all have a max display format ("999+", "10K", "23h 59m").

**Worked example**: Power user has 47 saved addresses. Address picker is a flat scroll list. Finding: **major** — selection time scales linearly with saved count; needs search or recently used.

## Paste-bomb

- Cap input length at the schema limit, with a visible counter past 80% usage.
- Reject paste over the limit with a clear error, not silent truncation.
- Test browser performance with 100K-character paste — should not hang the tab.

**Worked example**: Promo-code field accepts a 50,000-char paste. Page hangs for 4s while validating. Finding: **minor** — needs input cap and length validation before submit.

## Worked example: applying the checklist to a checkout-confirmation screen

| Class | Finding | Severity |
|-------|---------|----------|
| Long text | Address row truncates building identifier | major |
| Slow networks | No loading state on Place Order; no offline handling | blocker |
| Max data | Saved-address picker not addressed | minor |
| Malformed input | Promo-code field has no length cap | minor |
| Zero data | n/a (cart never empty on this screen) | — |
| RTL | App is iOS-only English in PRD | out of scope, flagged |
| Paste-bomb | Promo-code field has no paste cap | minor |
