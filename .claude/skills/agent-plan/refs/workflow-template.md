---
name: Workflow Template
description: ASCII conventions for workflow diagrams inside plan documents
type: reference
---

# Workflow Template

A workflow diagram shows three things:
1. **Steps** — actions the skill performs.
2. **Decisions** — points where the flow branches, by either the skill or the user.
3. **Termination** — endpoints where the workflow stops.

Anything else — comments, annotations, side notes — does not belong in the diagram.

## Shapes

**Step**: single-line border box. One action per box, verb-phrase starting with a verb, prefixed `[n]` where `n` is the step number.

```
┌──────────────────────┐
│ [1] Fetch PR diff    │
└──────────────────────┘
```

**Auto-decision**: diamond. Used when the skill itself decides based on data or state.

```
       ◇ scope ok? ◇
```

**Human gate**: double-line border box. Used when the user decides. Phrased as a question.

```
╔══════════════════════╗
║ <HUMAN: scope ok?>   ║
╚══════════════════════╝
```

**Termination**: solid diamond marker.

```
       ◆ END ◆
```

**Flow**: vertical line `│` then arrow `▼`. Always top-to-bottom. No diagonals. Branch labels (`yes`, `no`) sit on the edge.

## Composition rules

- **Numbering**: sequential along the primary execution path. Aborted paths (routing directly to `END`) are not numbered.
- **Multi-line boxes**: when content exceeds the box width, wrap continuation lines indented under the verb. Step number stays on the first line.
- **Branches off decisions**: every outgoing edge labeled. No unlabeled forks.
- **Branches off human gates**: same as decisions — when a gate has two outcomes, label both edges.
- **Termination**: every path must reach an `◆ END ◆`. Multiple `END` markers are allowed (one per terminal path). No dangling boxes.
- **Aborts**: a "no" or failure path routes directly to its own `END`, not back into the primary flow.
- **Width**: box interior 22 characters, total diagram width 60 characters. Wider diagrams break in narrow terminals.

## Skeleton

Minimum diagram with one of each shape:

```
┌──────────────────────┐
│ [1] <verb-phrase>    │
└──────────┬───────────┘
           │
           ▼
╔══════════════════════╗
║ <HUMAN: question?>   ║
╚══════════┬═══════════╝
           │
       ┌── no ──▶ ◆ END ◆
       │
       yes
       │
       ▼
┌──────────────────────┐
│ [2] <verb-phrase>    │
└──────────┬───────────┘
           │
           ▼
       ◇ condition? ◇
           │
       ┌── no ──▶ ◆ END ◆
       │
       yes
       │
       ▼
┌──────────────────────┐
│ [3] <verb-phrase>    │
└──────────┬───────────┘
           │
           ▼
       ◆ END ◆
```

## Exemplar

Workflow for a `pr-reviewer` skill:

```
┌──────────────────────┐
│ [1] Fetch PR diff    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ [2] Classify scope   │
└──────────┬───────────┘
           │
           ▼
╔══════════════════════╗
║ <HUMAN: scope ok?>   ║
╚══════════┬═══════════╝
           │
       ┌── no ──▶ ◆ END ◆
       │
       yes
       │
       ▼
┌──────────────────────┐
│ [3] Draft review     │
│     comments         │
└──────────┬───────────┘
           │
           ▼
╔══════════════════════╗
║ <HUMAN: post draft?> ║
╚══════════┬═══════════╝
           │
           ▼
┌──────────────────────┐
│ [4] Post comments    │
│     to PR            │
└──────────┬───────────┘
           │
           ▼
       ◆ END ◆
```