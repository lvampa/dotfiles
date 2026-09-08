#!/bin/bash
# PreToolUse hook for Write, Edit, MultiEdit, and NotebookEdit.
# Denies writes outside the project and the additionalDirectories in
# ~/.claude/settings.json, so one list governs both reads and writes.

input=$(cat)
target=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$target" ] && exit 0

cwd=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd=$PWD

# realpath on macOS fails for paths that do not exist yet, so resolve the
# deepest existing ancestor and append the rest.
canonical() {
  local path=$1 rest=""
  while [ ! -e "$path" ]; do
    rest="/$(basename "$path")$rest"
    path=$(dirname "$path")
  done
  printf '%s%s\n' "$(realpath "$path")" "$rest"
}

case "$target" in
  /*) ;;
  *)  target="$cwd/$target" ;;
esac
target=$(canonical "$target")

roots=("${CLAUDE_PROJECT_DIR:-$cwd}")
while IFS= read -r dir; do
  [ -n "$dir" ] && roots+=("${dir/#\~/$HOME}")
done < <(jq -r '.permissions.additionalDirectories[]? // empty' "$HOME/.claude/settings.json" 2>/dev/null)

for root in "${roots[@]}"; do
  root=$(canonical "$root")
  [[ "$target" == "$root" || "$target" == "$root/"* ]] && exit 0
done

jq -n --arg t "$target" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Writes are limited to the project and permissions.additionalDirectories. Refused: " + $t)
  }
}'
