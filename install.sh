#!/usr/bin/env bash
set -euo pipefail

REPO="andychanfp/build_an_agent"
BRANCH="main"
TARBALL_URL="${TARBALL_URL:-https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz}"
SKILLS_DEST="${HOME}/.claude/skills"
SKILLS=(
  agent-audit
  agent-audit-benchmark
  agent-audit-grade
  agent-audit-lint
  agent-audit-optimise
  agent-audit-test
  agent-build
  agent-evaluate
  agent-fix
  agent-plan
  agent-quality
)

# ── Helpers ──────────────────────────────────────────────────────────────────

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

die() { red "error: $*"; exit 1; }

# ── Preflight ─────────────────────────────────────────────────────────────────

if [[ ! -d "${HOME}/.claude" ]]; then
  die "~/.claude not found. Is Claude Code installed? See https://claude.ai/download"
fi

command -v curl >/dev/null 2>&1 || die "curl is required but not found"

# ── Download ──────────────────────────────────────────────────────────────────

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

bold "Downloading build_an_agent..."
curl -fsSL "${TARBALL_URL}" -o "${TMP_DIR}/repo.tar.gz" \
  || die "Download failed. Check your internet connection and try again."

tar -xzf "${TMP_DIR}/repo.tar.gz" -C "${TMP_DIR}" \
  || die "Failed to extract download. The file may be corrupt — try again."
REPO_DIR="${TMP_DIR}/build_an_agent-${BRANCH}"
[[ -d "${REPO_DIR}" ]] || die "Unexpected archive layout (expected build_an_agent-${BRANCH}/). Please report this at https://github.com/${REPO}/issues"

# ── Install ───────────────────────────────────────────────────────────────────

mkdir -p "${SKILLS_DEST}"

installed=0
for skill in "${SKILLS[@]}"; do
  src="${REPO_DIR}/.claude/skills/${skill}"
  dst="${SKILLS_DEST}/${skill}"

  if [[ ! -d "${src}" ]]; then
    red "  warning: skill '${skill}' not found in download — skipping"
    continue
  fi

  rm -rf "${dst}"
  cp -r "${src}" "${dst}"

  # Strip any run/ artifact directories that may have been committed
  rm -rf "${dst}/run"

  printf '  installed: %s\n' "${skill}"
  (( installed++ )) || true
done

# ── Verify ────────────────────────────────────────────────────────────────────

failed=()
for skill in "${SKILLS[@]}"; do
  [[ ! -f "${SKILLS_DEST}/${skill}/SKILL.md" ]] && failed+=("${skill}")
done

if [[ ${#failed[@]} -gt 0 ]]; then
  red "\nVerification failed for: ${failed[*]}"
  die "Install incomplete. Try running the script again."
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
green "✓ ${installed} skills installed to ${SKILLS_DEST}"
echo ""
bold "Next step:"
echo "  Open any Claude Code session and type /agent-plan to start building."
