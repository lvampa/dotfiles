#!/bin/bash
# Status line: user:dir:branch:<session>% usage:<context>% context
# Segments are omitted when their data is missing, colon included.

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
user=$(whoami)
case "$cwd" in
  "$HOME"*) display_dir="~${cwd#"$HOME"}" ;;
  *)        display_dir="$cwd" ;;
esac
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

# Five-hour usage window, the session limit.
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor')

# Prefer the pre-calculated context percentage; fall back to computing it from tokens.
ctx_pct=$(echo "$input" | jq -r '
  if (.context_window.used_percentage != null) then
    (.context_window.used_percentage | floor)
  elif (.context_window.total_input_tokens != null and .context_window.context_window_size > 0) then
    ((.context_window.total_input_tokens / .context_window.context_window_size * 100) | floor)
  else
    empty
  end
')

# Mediterranean palette, 256-color.
dim='\033[2m'
olive='\033[38;5;107m'
aegean='\033[38;5;74m'
terracotta='\033[38;5;173m'
sand='\033[38;5;180m'
reset='\033[0m'

printf "${olive}%s:%s${reset}" "$user" "$display_dir"
[ -n "$branch" ]      && printf "${dim}:${reset}${aegean}%s${reset}" "$branch"
[ -n "$session_pct" ] && printf "${dim}:${reset}${terracotta}%s%% usage${reset}" "$session_pct"
[ -n "$ctx_pct" ]     && printf "${dim}:${reset}${sand}%s%% context${reset}" "$ctx_pct"
