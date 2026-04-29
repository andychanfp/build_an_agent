---
name: Error State Taxonomy
description: Full state list with example UIs and user impact per state
type: reference
---

# Error State Taxonomy

For every screen, walk this list. For each state, ask: does the design specify what the user sees? If not, record a finding naming the broken state and the user consequence.

## The seven states every screen needs

| State | Trigger | What the user must see | User impact if missing |
|-------|---------|------------------------|------------------------|
| Empty | No data exists yet (first session, cleared list) | Onboarding hint or zero-state CTA | User assumes the app is broken and bounces |
| Loading | Data is being fetched | Skeleton, spinner, or progress indicator within 200ms | User taps repeatedly, double-submits, or abandons |
| Error | Request failed (5xx, network, parse) | Plain-language cause + retry action + alternative path | User does not know whether to retry or escalate |
| Offline | Network unavailable | Offline indicator + which actions still work + queued-action notice | User loses work, repeats actions when back online |
| Permission | OS permission missing or denied (location, notifications, camera) | Explanation of why the app needs the permission + deep link to Settings | User toggles around and abandons; permanent permission denial |
| Rate-limit | Server throttles the user (too many requests, daily cap) | Reason + retry-after time + escalation path | User assumes the app is broken; support tickets |
| Partial-failure | Some sub-requests succeeded, some failed | What succeeded, what failed, what to do next per item | User cannot tell what state their account is in |

## State-by-state audit prompts

### Empty
- Is there a first-run state for every list, feed, and table?
- Does the empty state name what the user must do to populate it?
- Is the empty state distinguishable from the loading state at a glance?

### Loading
- Does every action that takes >200ms show a loading indicator?
- For long fetches (>2s), is progress shown (skeleton with shape, percentage, or step counter)?
- Is the primary CTA disabled while loading, to prevent double-submit?

### Error
- Does the error name the cause in plain language ("Card declined") not a system code ("ERR_4012")?
- Does it suggest one specific next action (Retry, Use a different card, Contact support)?
- Is the error placed where the failure occurred (inline on the field, not only a top banner)?

### Offline
- Does the screen show an offline indicator within 2s of losing connectivity?
- Are queued actions surfaced so the user knows their tap was not lost?
- Are read-only fallback views available for cached data?

### Permission
- For each OS permission requested, is there a pre-prompt explaining why?
- If the user denies, is there a soft-recovery state with a deep link to Settings?
- Does the screen degrade gracefully when permission is denied (not a blank screen)?

### Rate-limit
- Does the rate-limit message tell the user when they can try again?
- Is the limit explained ("3 password resets per hour") not anonymous ("Too many requests")?
- Is there an escalation path for users who hit a real wall (contact support, upgrade)?

### Partial-failure
- For batch actions (multi-select delete, bulk import), is per-item status shown?
- Is there a retry-failed-only action, not just retry-all?
- Are succeeded items locked from re-processing on retry?

## Worked example: applying the taxonomy to a checkout-confirmation screen

| State | Spec'd? | Finding |
|-------|---------|---------|
| Empty | n/a (always has data on this screen) | — |
| Loading | No — Place Order has no spinner | **Blocker**: user double-taps and risks double-charge |
| Error | No payment-failure state in PRD | **Blocker**: user does not know whether they were charged |
| Offline | Not addressed; PRD notes spotty commute network | **Major**: order may submit without confirmation |
| Permission | Notifications permission for order updates not requested | **Minor**: user misses delivery push |
| Rate-limit | Not addressed | **Minor**: edge case for repeat-attempt fraud blocks |
| Partial-failure | Not applicable to single-order submit | — |
