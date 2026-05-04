#!/usr/bin/env bash
# Tests for install.sh. Run from the repo root: bash test_install.sh
set -uo pipefail

PASS=0; FAIL=0
INSTALL_SCRIPT="$(cd "$(dirname "$0")" && pwd)/install.sh"
SKILLS=(agent-audit agent-audit-benchmark agent-audit-grade agent-audit-lint
        agent-audit-optimise agent-audit-test agent-build agent-evaluate
        agent-fix agent-plan agent-quality)

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { printf '\033[32mPASS\033[0m %s\n' "$1"; (( PASS++ )) || true; }
fail() { printf '\033[31mFAIL\033[0m %s — %s\n' "$1" "$2"; (( FAIL++ )) || true; }

# Build a tarball that mirrors what GitHub serves:
#   build_an_agent-main/.claude/skills/{skill}/SKILL.md
make_tarball() {
  local dest="$1" include_run="${2:-false}" omit_skill="${3:-}"
  local staging
  staging=$(mktemp -d)

  for skill in "${SKILLS[@]}"; do
    [[ "${skill}" == "${omit_skill}" ]] && continue
    local skill_dir="${staging}/build_an_agent-main/.claude/skills/${skill}"
    mkdir -p "${skill_dir}"
    echo "# ${skill}" > "${skill_dir}/SKILL.md"
    if [[ "${include_run}" == "true" ]]; then
      mkdir -p "${skill_dir}/run/run-1"
      echo "artifact" > "${skill_dir}/run/run-1/grading.json"
    fi
  done

  # design-review should always be present in the tarball to test exclusion
  local dr="${staging}/build_an_agent-main/.claude/skills/design-review"
  mkdir -p "${dr}"; echo "# design-review" > "${dr}/SKILL.md"

  tar -czf "${dest}" -C "${staging}" build_an_agent-main
  rm -rf "${staging}"
}

run_install() {
  local home="$1" tarball="$2"
  HOME="${home}" TARBALL_URL="file://${tarball}" bash "${INSTALL_SCRIPT}" 2>&1
}

# ── Tests ─────────────────────────────────────────────────────────────────────

test_happy_path() {
  local tmp; tmp=$(mktemp -d); mkdir -p "${tmp}/.claude"
  local tarball="${tmp}/repo.tar.gz"
  make_tarball "${tarball}"

  local output; output=$(run_install "${tmp}" "${tarball}")
  local exit_code=$?

  (( exit_code == 0 )) || { fail "happy_path" "exited ${exit_code}"; rm -rf "${tmp}"; return; }

  local missing=()
  for skill in "${SKILLS[@]}"; do
    [[ ! -f "${tmp}/.claude/skills/${skill}/SKILL.md" ]] && missing+=("${skill}")
  done
  (( ${#missing[@]} == 0 )) || { fail "happy_path" "missing skills: ${missing[*]}"; rm -rf "${tmp}"; return; }

  echo "${output}" | grep -q "11 skills installed" || { fail "happy_path" "success message missing"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "happy_path — all 11 skills installed, success message printed"
}

test_preflight_no_claude_dir() {
  local tmp; tmp=$(mktemp -d)  # no .claude dir

  local output; output=$(HOME="${tmp}" bash "${INSTALL_SCRIPT}" 2>&1)
  local exit_code=$?

  (( exit_code != 0 )) || { fail "preflight_no_claude_dir" "should have exited non-zero"; rm -rf "${tmp}"; return; }
  echo "${output}" | grep -qi "claude" || { fail "preflight_no_claude_dir" "error message missing"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "preflight_no_claude_dir — exits 1 with helpful message"
}

test_idempotent() {
  local tmp; tmp=$(mktemp -d); mkdir -p "${tmp}/.claude"
  local tarball="${tmp}/repo.tar.gz"
  make_tarball "${tarball}"

  run_install "${tmp}" "${tarball}" >/dev/null 2>&1
  local second_output; second_output=$(run_install "${tmp}" "${tarball}" 2>&1)
  local exit_code=$?

  (( exit_code == 0 )) || { fail "idempotent" "second run exited ${exit_code}"; rm -rf "${tmp}"; return; }
  echo "${second_output}" | grep -q "11 skills installed" || { fail "idempotent" "second run incomplete"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "idempotent — second run succeeds cleanly"
}

test_design_review_excluded() {
  local tmp; tmp=$(mktemp -d); mkdir -p "${tmp}/.claude"
  local tarball="${tmp}/repo.tar.gz"
  make_tarball "${tarball}"

  run_install "${tmp}" "${tarball}" >/dev/null 2>&1

  [[ ! -d "${tmp}/.claude/skills/design-review" ]] || { fail "design_review_excluded" "design-review was installed"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "design_review_excluded — design-review not installed"
}

test_run_dirs_stripped() {
  local tmp; tmp=$(mktemp -d); mkdir -p "${tmp}/.claude"
  local tarball="${tmp}/repo.tar.gz"
  make_tarball "${tarball}" true  # include_run=true

  run_install "${tmp}" "${tarball}" >/dev/null 2>&1

  local run_dirs
  run_dirs=$(find "${tmp}/.claude/skills" -type d -name "run" 2>/dev/null | wc -l | tr -d ' ')
  (( run_dirs == 0 )) || { fail "run_dirs_stripped" "found ${run_dirs} run/ dir(s) after install"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "run_dirs_stripped — no run/ artifact dirs installed"
}

test_missing_skill_fails_verification() {
  local tmp; tmp=$(mktemp -d); mkdir -p "${tmp}/.claude"
  local tarball="${tmp}/repo.tar.gz"
  make_tarball "${tarball}" false "agent-plan"  # omit agent-plan from tarball

  local output; output=$(run_install "${tmp}" "${tarball}" 2>&1)
  local exit_code=$?

  (( exit_code != 0 )) || { fail "missing_skill_fails_verification" "should have exited non-zero"; rm -rf "${tmp}"; return; }
  echo "${output}" | grep -qi "verif" || { fail "missing_skill_fails_verification" "no verification error in output"; rm -rf "${tmp}"; return; }

  rm -rf "${tmp}"
  pass "missing_skill_fails_verification — exits 1 when a skill is absent from download"
}

# ── Run all tests ─────────────────────────────────────────────────────────────

echo "Running install.sh tests..."
echo ""
test_happy_path
test_preflight_no_claude_dir
test_idempotent
test_design_review_excluded
test_run_dirs_stripped
test_missing_skill_fails_verification

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
(( FAIL == 0 ))
