---
name: Ship Report Template
description: Required output structure for the agent-ship final report shown inline after a completed run
type: reference
---

# Ship Report Template

Render one ship report per run. Fill every section from in-memory data — do not re-read files unless a value is missing.

---

## Ship report — `<skill_name>`

### Agent summary

> _2–3 sentences derived from the plan summary: what the agent does, who it serves, when it activates, and what it refuses._

---

### Features

| Priority | Feature | Why |
|----------|---------|-----|
| P0 | _feature_ | _reason_ |
| P1 | _feature_ | _reason_ |
| P2 | _feature_ | _reason_ |

_Source: P0–P2 table from plan §4._

---

### Issues found

_N issues found during flash audit (agent-audit-test, run-1) — or "No issues found."_

| Eval | Assertion | Verdict |
|------|-----------|---------|
| eval-N | _assertion text (truncated to 80 chars)_ | FAIL |

_Only list failed assertions (passed === false). Omit passing assertions. If no failures, write "No issues found."_

---

### Issues fixed

_N fixes applied by agent-fix — or "No fixes needed."_

| Fix | Section | Action |
|-----|---------|--------|
| F1 | _SKILL.md section_ | _one-line description of what changed_ |

_Source: fix-report-1.json `fixes_applied`. If fix phase was skipped, write "No fixes needed."_

---

**Skill:** `.claude/skills/<skill_name>/SKILL.md`
**Plan:** `plans/<skill_name>.md`
**Invoke:** `/<skill_name>`
