#!/usr/bin/env bash
# Open COMMIT_MSG.md in Cursor and block until the user closes the tab.
# Used as git core.editor (git commit) and by the va-commit skill (--wait-only).
set -euo pipefail

find_cursor() {
  if command -v cursor >/dev/null 2>&1; then
    command -v cursor
    return
  fi
  local mac="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
  if [[ -x "$mac" ]]; then
    echo "$mac"
    return
  fi
  echo "va-commit: cursor CLI not found (install shell command from Cursor)" >&2
  exit 1
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

REPO_ROOT="$(repo_root)"
MSG_FILE="${REPO_ROOT}/COMMIT_MSG.md"
CURSOR="$(find_cursor)"

open_and_wait() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "va-commit: message file not found: $file" >&2
    exit 1
  fi
  "$CURSOR" --wait "$file"
}

# va-commit / agent: only wait for the user to finish editing COMMIT_MSG.md
if [[ "${1:-}" == "--wait-only" ]]; then
  shift
  open_and_wait "${1:-$MSG_FILE}"
  exit 0
fi

# git core.editor: $1 is .git/COMMIT_EDITMSG
COMMIT_EDITMSG="${1:?Usage: git-msg-editor.sh <commit_editmsg> | --wait-only [file]}"

# Seed COMMIT_MSG.md from git's template when there is no user message yet
if [[ ! -f "$MSG_FILE" ]] || ! awk '!/^#/ && !/^[[:space:]]*$/' "$MSG_FILE" | grep -q .; then
  awk '!/^#/ && !/^[[:space:]]*$/' "$COMMIT_EDITMSG" >"$MSG_FILE" 2>/dev/null || true
  if [[ ! -s "$MSG_FILE" ]]; then
    printf '%s\n' "feat(scope): short imperative summary" "" >"$MSG_FILE"
  fi
fi

open_and_wait "$MSG_FILE"

# Git reads COMMIT_EDITMSG; lines starting with # are ignored
cp "$MSG_FILE" "$COMMIT_EDITMSG"
