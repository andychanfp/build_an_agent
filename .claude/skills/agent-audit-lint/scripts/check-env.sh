#!/usr/bin/env bash
# check-env.sh — checks node/npm/agentlinter/agnix availability for agent-audit-lint.
# Attempts npm install for missing tools if npm is available.
# Outputs a JSON status object to stdout.

set -euo pipefail

node_ok=false
npm_ok=false
agentlint_ok=false
agentlint_version=""
agentlint_skipped=false
agentlint_skip_reason=""
agnix_ok=false
agnix_version=""
agnix_skipped=false
agnix_skip_reason=""

# ── node ──────────────────────────────────────────────────────────────────────
if command -v node >/dev/null 2>&1; then
  node_ok=true
fi

# ── npm ───────────────────────────────────────────────────────────────────────
if command -v npm >/dev/null 2>&1; then
  npm_ok=true
fi

# ── agentlinter ───────────────────────────────────────────────────────────────
if command -v agentlint >/dev/null 2>&1; then
  agentlint_ok=true
  agentlint_version=$(agentlint --version 2>/dev/null || echo "unknown")
else
  if [ "$npm_ok" = true ]; then
    echo "agentlint not found — attempting: npm install -g agentlint-ai" >&2
    if npm install -g agentlint-ai >/dev/null 2>&1; then
      if command -v agentlint >/dev/null 2>&1; then
        agentlint_ok=true
        agentlint_version=$(agentlint --version 2>/dev/null || echo "unknown")
      else
        agentlint_skipped=true
        agentlint_skip_reason="npm install succeeded but agentlint not in PATH after install"
      fi
    else
      agentlint_skipped=true
      agentlint_skip_reason="npm install -g agentlint-ai failed — check npm permissions or run manually"
    fi
  else
    agentlint_skipped=true
    agentlint_skip_reason="npm not found — install Node.js >= 18 from https://nodejs.org, then run: npm install -g agentlint-ai"
  fi
fi

# ── agnix ─────────────────────────────────────────────────────────────────────
if command -v agnix >/dev/null 2>&1; then
  agnix_ok=true
  agnix_version=$(agnix --version 2>/dev/null || echo "unknown")
else
  if [ "$npm_ok" = true ]; then
    echo "agnix not found — attempting: npm install -g agnix" >&2
    if npm install -g agnix >/dev/null 2>&1; then
      if command -v agnix >/dev/null 2>&1; then
        agnix_ok=true
        agnix_version=$(agnix --version 2>/dev/null || echo "unknown")
      else
        agnix_skipped=true
        agnix_skip_reason="npm install succeeded but agnix not in PATH after install"
      fi
    else
      agnix_skipped=true
      agnix_skip_reason="npm install -g agnix failed — alternatives: brew tap agent-sh/agnix && brew install agnix  |  cargo install agnix-cli"
    fi
  else
    agnix_skipped=true
    agnix_skip_reason="npm not found — alternatives: brew tap agent-sh/agnix && brew install agnix  |  cargo install agnix-cli  |  install Node.js >= 18 then: npm install -g agnix"
  fi
fi

# ── emit JSON ─────────────────────────────────────────────────────────────────
cat <<EOF
{
  "node": $node_ok,
  "npm": $npm_ok,
  "agentlinter": {
    "available": $agentlint_ok,
    "version": "$agentlint_version",
    "skipped": $agentlint_skipped,
    "skip_reason": "$agentlint_skip_reason"
  },
  "agnix": {
    "available": $agnix_ok,
    "version": "$agnix_version",
    "skipped": $agnix_skipped,
    "skip_reason": "$agnix_skip_reason"
  }
}
EOF
