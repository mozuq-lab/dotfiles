#!/bin/bash
# Claude Code status line:
# [Model · effort] 📁 dir ⎇ branch | ctx NN% | session NN% (Xh Ym) | week NN% (Xd Yh)
#
# Colors (ANSI):
#   Model  — Opus: magenta / Sonnet: cyan / Haiku: green / Fable: bright blue (bold)
#   Effort — xhigh|max: red bold / high: yellow / others: default
#   Usage  — <50%: green / 50–79%: yellow / >=80%: red bold  (ctx / session / week each)
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$cwd")

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

now=$(date +%s)

# ANSI color codes (real ESC bytes via ANSI-C quoting)
RESET=$'\033[0m'
BOLD=$'\033[1m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BRIGHT_BLUE=$'\033[94m'

# Format an epoch reset time as remaining "Xd Yh" / "Xh Ym" / "Xm" (empty if past/invalid)
fmt_remaining() {
  local target=${1%.*}
  [ -z "$target" ] && return
  local secs=$(( target - now ))
  [ "$secs" -le 0 ] && return
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# Pick a color for a usage percentage (rounded int): <50 green, 50–79 yellow, >=80 red bold
usage_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then
    printf '%s' "$BOLD$RED"
  elif [ "$pct" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# Color for the model name, by family
model_color=""
case "$model" in
  *Opus*)   model_color="$MAGENTA" ;;
  *Sonnet*) model_color="$CYAN" ;;
  *Haiku*)  model_color="$GREEN" ;;
  *Fable*)  model_color="$BOLD$BRIGHT_BLUE" ;;
esac

# Color for the effort level: xhigh|max red bold, high yellow, others default
effort_color=""
case "$effort" in
  xhigh|max) effort_color="$BOLD$RED" ;;
  high)      effort_color="$YELLOW" ;;
esac

# Build the [model · effort] segment with per-part coloring
model_part="${model_color}${model}${RESET}"
model_seg="$model_part"
if [ -n "$effort" ]; then
  effort_part="${effort_color}${effort}${RESET}"
  model_seg="$model_part · $effort_part"
fi

out="[$model_seg] 📁 $dir_name"
[ -n "$branch" ] && out="$out ⎇ $branch"

if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  out="$out | $(usage_color "$pct")ctx ${pct}%${RESET}"
fi
if [ -n "$session_used" ]; then
  pct=$(printf '%.0f' "$session_used")
  seg="session ${pct}%"
  rem=$(fmt_remaining "$session_reset")
  [ -n "$rem" ] && seg="$seg ($rem)"
  out="$out | $(usage_color "$pct")${seg}${RESET}"
fi
if [ -n "$week_used" ]; then
  pct=$(printf '%.0f' "$week_used")
  seg="week ${pct}%"
  rem=$(fmt_remaining "$week_reset")
  [ -n "$rem" ] && seg="$seg ($rem)"
  out="$out | $(usage_color "$pct")${seg}${RESET}"
fi

printf '%s' "$out"
