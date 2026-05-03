#!/bin/bash
# run-evals.sh — drives `claude -p` for the description optimiser's trigger-rate measurement.
#
# Usage: run-evals.sh <queries.json> <skill_name> [runs_per_query]
#
# queries.json shape (array of objects):
#   [ { "query": "<user prompt>", "should_trigger": true }, ... ]
#
# Output: JSON array on stdout. One object per query:
#   { "query": "...", "should_trigger": bool, "triggers": int, "runs": int, "trigger_rate": float }
#
# A query passes if (should_trigger && trigger_rate > 0.5) || (!should_trigger && trigger_rate <= 0.5).
# The optimiser aggregates pass rates across train and validation sets.

set -euo pipefail

QUERIES_FILE="${1:?Usage: $0 <queries.json> <skill_name> [runs_per_query]}"
SKILL_NAME="${2:?Usage: $0 <queries.json> <skill_name> [runs_per_query]}"
RUNS="${3:-3}"

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: claude CLI not found in PATH." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq not found in PATH." >&2
  exit 1
fi

# check_triggered: returns 0 if the named skill was invoked during the run, 1 otherwise.
check_triggered() {
  local query="$1"
  claude -p "$query" --output-format json 2>/dev/null \
    | jq -e --arg skill "$SKILL_NAME" \
        'any(.messages[].content[]?; .type == "tool_use" and .name == "Skill" and .input.skill == $skill)' \
        >/dev/null 2>&1
}

count=$(jq length "$QUERIES_FILE")
results="[]"

for i in $(seq 0 $((count - 1))); do
  query=$(jq -r ".[$i].query" "$QUERIES_FILE")
  should_trigger=$(jq -r ".[$i].should_trigger" "$QUERIES_FILE")
  triggers=0

  for run in $(seq 1 "$RUNS"); do
    if check_triggered "$query"; then
      triggers=$((triggers + 1))
    fi
  done

  result=$(jq -n \
    --arg query "$query" \
    --argjson should_trigger "$should_trigger" \
    --argjson triggers "$triggers" \
    --argjson runs "$RUNS" \
    '{
      query: $query,
      should_trigger: $should_trigger,
      triggers: $triggers,
      runs: $runs,
      trigger_rate: (if $runs > 0 then ($triggers / $runs) else 0 end)
    }')

  results=$(echo "$results" | jq --argjson r "$result" '. + [$r]')
done

echo "$results"
