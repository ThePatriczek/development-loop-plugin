#!/usr/bin/env bash
# development-loop plugin — SessionStart hook
#
# Detects an active loop state file and prints a short status banner to stdout,
# which Claude Code injects into session context. Does nothing when no loop is active.

set -euo pipefail

STATE_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/development-loop.local.md"

# Fast exit if no state file — zero overhead when the plugin is installed but no loop is running.
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

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

active=$(get_field "active")
phase=$(get_field "phase")
iteration=$(get_field "iteration")
goal=$(get_field "goal")

if [ "$active" != "true" ]; then
  exit 0
fi

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
  phase:     $phase
  iteration: $iteration
  goal:      $goal
  agent:     $agent

Hooks will dispatch $agent on prompt submit, on file writes, and on stop.
Phase skill and agent are authoritative. Run /development-loop status for details,
or /development-loop abort to disable enforcement.
BANNER

exit 0
