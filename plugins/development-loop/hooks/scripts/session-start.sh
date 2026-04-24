#!/usr/bin/env bash
# development-loop plugin — SessionStart hook
#
# Detects an active loop state file and prints a short status banner to stdout,
# which Claude Code injects into session context. Does nothing when no loop is active.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOOP_DIR="$ROOT/.development-loop"

# Fast exit: no loop dir at all — zero overhead when the plugin is installed but no loop is running.
[ -d "$LOOP_DIR" ] || exit 0

# Find the single active STATE.md. Option-1 invariant: at most one loop is active at a time.
STATE_FILE=""
shopt -s nullglob
for candidate in "$LOOP_DIR"/*/STATE.md; do
  if grep -qE '^active:[[:space:]]*true[[:space:]]*$' "$candidate"; then
    STATE_FILE="$candidate"
    break
  fi
done

[ -n "$STATE_FILE" ] || exit 0

# Parse YAML frontmatter (first `---`-delimited block) with sed — portable on
# BSD awk (macOS default) and GNU awk alike. Only accepts values from before
# the closing `---`.
get_field() {
  local field="$1"
  sed -n "/^---[[:space:]]*\$/,/^---[[:space:]]*\$/{
    /^${field}:[[:space:]]*/{
      s/^${field}:[[:space:]]*//
      p
      q
    }
  }" "$STATE_FILE"
}

phase=$(get_field "phase")
iteration=$(get_field "iteration")
goal=$(get_field "goal")
context=$(basename "$(dirname "$STATE_FILE")")

# Map phase -> authoritative agent name (for session context clarity).
case "$phase" in
  research)              agent="research-agent";;
  research-review)       agent="research-review-agent";;
  tdd-red|tdd-green)     agent="tdd-agent";;
  tdd-review)            agent="tdd-review-agent";;
  implementation)        agent="implementation-agent";;
  implementation-review) agent="implementation-review-agent";;
  refactor)              agent="refactor-agent";;
  refactor-review)       agent="refactor-review-agent";;
  overall-review)        agent="overall-review-agent";;
  *)                     agent="(unknown phase — run /development-loop status)";;
esac

cat <<BANNER
[development-loop] STRICT MODE — a loop is active in this project.
  context:   $context
  phase:     $phase
  iteration: $iteration
  goal:      $goal
  agent:     $agent
  state:     .development-loop/$context/STATE.md

Hooks will dispatch $agent on prompt submit, on file writes, and on stop.
Phase skill and agent are authoritative. Run /development-loop status for details,
or /development-loop abort to disable enforcement.
BANNER

exit 0
