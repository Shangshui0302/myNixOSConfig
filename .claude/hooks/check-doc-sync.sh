#!/usr/bin/env bash
# PreToolUse gate: block `git commit` when .nix config changed but wiki/memory not synced.
# stdin: PreToolUse hook JSON. Deny only on actual `git commit` calls.
set -uo pipefail

# --- Parse the command from stdin (python3; jq is not installed on this machine) ---
COMMAND="$(python3 -c 'import sys, json; print(json.load(sys.stdin)["tool_input"]["command"])')"

# --- Guard 1: only act on real `git commit` invocations.
# The `if` field fails open on unparseable commands, so re-check here.
# Matches "git commit", "git commit -m ...", "git commit --amend" but not "git commit-tree".
if ! grep -qE 'git[[:space:]]+commit([[:space:]]|$)' <<<"$COMMAND"; then
  exit 0   # not a commit -> no decision; normal permission flow applies
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# --- Guard 2: pending changes = staged + unstaged tracked files ---
CHANGED="$({
  git -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null
  git -C "$PROJECT_DIR" diff --name-only 2>/dev/null
} | sort -u)"

NIX_CHANGED=0
DOCS_CHANGED=0
while IFS= read -r f; do
  case "$f" in
    *.nix)           NIX_CHANGED=1 ;;
    wiki/*|memory/*) DOCS_CHANGED=1 ;;
  esac
done <<<"$CHANGED"

# --- Deny if config changed but docs did not ---
if [ "$NIX_CHANGED" -eq 1 ] && [ "$DOCS_CHANGED" -eq 0 ]; then
  python3 -c '
import json
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PreToolUse",
  "permissionDecision": "deny",
  "permissionDecisionReason": (
    "Commit blocked by docs-sync hook: .nix config files changed but no wiki/ or "
    "memory/ file was updated. Run /wiki-maintainer (or update wiki/*.md and "
    "memory/*.md) to sync the documentation before committing."
  )
}}))'
fi

exit 0
