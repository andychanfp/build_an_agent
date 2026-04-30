---
name: Tool Setup
description: agentlinter and agnix install commands, CLI flags, and exit codes used in Step 6
type: reference
---

# Tool Setup

Step 6 invokes two external linters before scoring an audit. Each tool runs in a different environment and emits findings in different formats. This file holds the install commands, the canonical invocation, and the exit-code mapping the audit uses to assign severity.

## agentlinter

Linter for `CLAUDE.md`, `SKILL.md`, hooks, and other agent harness files. ESLint-style — 51 deterministic checks plus 7 opt-in extended checks.

### Install

| Method | Command | Notes |
|--------|---------|-------|
| npm (recommended) | `npm install -g agentlint-ai` | Requires Node.js ≥ 18 |
| Verify install | `agentlint --version` | Exits 0 with the version string |

### Canonical invocation

```bash
agentlint <skill_path> --format json
```

### Key flags

| Flag | Purpose |
|------|---------|
| `--format json` | Machine-readable output for parsing into `audit-[n].json` |
| `--strict` | Treat warnings as errors (use for comprehensive mode) |
| `--no-extended` | Skip the AI sub-agent checks; faster but less thorough |
| `--target claude-code` | Restrict rules to the Claude Code preset |

### Exit codes and severity mapping

| Exit code | Meaning | Severity in audit-[n].json |
|-----------|---------|---------------------------|
| 0 | Clean run, no findings | n/a |
| 1 | Errors found (strict mode triggered on warnings) | P0 for `error`, P1 for `warning` |
| 2 | Tool failure (config error, file not found) | Audit halts; emit error and stop |

### Output shape

agentlinter `--format json` emits an array of findings. Each finding has `rule` (id), `severity` (`error`/`warning`/`info`), `file`, `line`, `message`, and an optional `fix`. Map `error` → P0, `warning` → P1, `info` → P2.

**Worked example**: running `agentlint .claude/skills/design-review/ --format json` returns `[{"rule": "skill-name-mismatch", "severity": "error", "file": "SKILL.md", "line": 2, "message": "Frontmatter name does not match directory name"}]` → record as **P0** in `audit-[n].json` under the `agentlinter.findings` array.

## agnix

Linter and LSP for AI agent configurations. 415 rules across Claude Code, Codex CLI, Cursor, Copilot, and others. Validates `SKILL.md`, hooks, and MCP configs.

### Install

| Method | Command | Notes |
|--------|---------|-------|
| npm | `npm install -g agnix` | Default — same Node.js environment as agentlinter |
| Homebrew | `brew tap agent-sh/agnix && brew install agnix` | Native binary, no Node.js needed |
| Cargo | `cargo install agnix-cli` | Requires Rust toolchain |
| Verify install | `agnix --version` | Exits 0 with the version string |

### Canonical invocation

```bash
agnix --strict <skill_path> --format sarif
```

### Key flags

| Flag | Purpose |
|------|---------|
| `--strict` | Warnings count as errors (required for comprehensive mode) |
| `--format sarif` | SARIF output for CI ingestion and structured parsing |
| `--target claude-code` | Limit to Claude Code rules (recommended for `.claude/skills/`) |
| `--fix-safe` | Apply only HIGH-confidence autofixes — never use during audit; report only |
| `--dry-run --show-fixes` | Preview suggested fixes without modifying files |

### Exit codes and severity mapping

| Exit code | Meaning | Severity in audit-[n].json |
|-----------|---------|---------------------------|
| 0 | No findings or only info-level | n/a (info → P2) |
| 1 | Warnings found (strict mode) | P1 |
| 2 | Errors found | P0 |
| 3 | Tool failure | Audit halts; emit error and stop |

### Output shape

agnix `--format sarif` emits a SARIF 2.1.0 document. Each `result` object contains `ruleId`, `level` (`error`/`warning`/`note`), `locations[].physicalLocation.artifactLocation.uri`, `locations[].physicalLocation.region.startLine`, and `message.text`. Map `error` → P0, `warning` → P1, `note` → P2. Set `autofix_available: true` when `result.fixes` is non-empty.

**Worked example**: running `agnix --strict .claude/skills/agent-audit/ --format sarif` returns a SARIF doc with one `result`: `{"ruleId": "missing-progress-emission", "level": "warning", "locations": [{"physicalLocation": {"artifactLocation": {"uri": "SKILL.md"}, "region": {"startLine": 47}}}], "message": {"text": "Skill has 8 steps but no progress emission section"}}` → record as **P1** in `audit-[n].json` under the `agnix.findings` array.

## Environment matrix

| Tool | Runtime | Min version | Cold-install time | Cached-run time |
|------|---------|-------------|-------------------|-----------------|
| agentlinter | Node.js | 18 | ~10s | ~1s |
| agnix (npm) | Node.js | 18 | ~5s | <1s |
| agnix (brew) | native | — | ~30s (first time) | <1s |
| agnix (cargo) | Rust | 1.74 | ~60s (compile) | <1s |

If the target system has only Node.js, use the npm install path for both tools — single environment, fastest setup. If the target needs to run agnix without Node.js (CI containers, restricted environments), prefer the Homebrew binary or the Cargo build.

## Pre-flight check sequence

Before running either tool, the audit must verify both are installed and reachable. Use this exact sequence:

```bash
command -v agentlint || { echo "Install: npm install -g agentlint-ai"; exit 1; }
command -v agnix || { echo "Install: npm install -g agnix"; exit 1; }
agentlint --version
agnix --version
```

If either `command -v` check fails, the audit emits the install command and stops — it does not attempt to install the tool itself. Installation is a user decision.
