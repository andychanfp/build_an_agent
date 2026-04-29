---
name: Principles
description: Core rules for writing effective, token-efficient agent skill files
type: reference
---

# Principles

## Structure
**Single responsibility**: Each section owns exactly one concern; split when scope creeps.
**Order within sections**: Goal first, steps second, verification last.
**References over inline**: Reusable patterns belong in `/refs`, not repeated in SKILL.md.

## Instructions
**Imperatives only**: Write "Do X" not "You should do X" or "It is important to X."
**Atomic steps**: One action per step. If "and" appears, split the step.
**Explicit outputs**: Every step ends with a verifiable artifact or state change.

## Compression
**Max signal per token**: If a word can be removed without losing meaning, remove it.
**Context-free sentences**: Each rule must be understood without reading surrounding rules.
**No hedging**: Omit "typically", "usually", "in most cases" — state the rule or omit it.

## Quality
**Testable criteria**: Define done as an observable outcome, not a process followed.
**Defaults before exceptions**: State the rule, then the exception on a new line. Example: "Use imperatives. Exception: rationale paragraphs may use declarative voice."
**Stable vocabulary**: Use the same term for the same concept throughout; never synonym-swap.