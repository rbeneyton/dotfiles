#!/usr/bin/env bash
# Claude Code status line: shows 5-hour and weekly (7-day) rate-limit windows,
# each with a usage bar, percent consumed, and time until the window resets.
# Data comes from Claude Code on stdin as JSON (rate_limits.{five_hour,seven_day}).

input=$(cat)

# ---- ANSI colors ----
RESET=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'

# Pick a color by percentage used: <50 green, <80 yellow, else red.
color_for() {
  local p=${1%.*}                      # integer part
  if   (( p < 50 )); then printf '%s' "$GREEN"
  elif (( p < 80 )); then printf '%s' "$YELLOW"
  else                    printf '%s' "$RED"
  fi
}

# 10-segment bar from a 0-100 percentage.
bar_for() {
  local p=${1%.*}; (( p > 100 )) && p=100; (( p < 0 )) && p=0
  local filled=$(( (p + 5) / 10 )) i out=""
  for ((i=0; i<10; i++)); do
    if (( i < filled )); then out+="█"; else out+="░"; fi
  done
  printf '%s' "$out"
}

# Humanize a token count: 47230 -> 47.2k, 200000 -> 200.0k, <1000 -> as-is.
humanize_tokens() {
  local t=$1
  if (( t >= 1000 )); then printf '%d.%dk' $(( t / 1000 )) $(( (t % 1000) / 100 ))
  else                     printf '%d' "$t"
  fi
}

# Humanize a "seconds from now" value: 4d3h / 2h13m / 45m / 30s.
countdown() {
  local s=$1
  (( s < 0 )) && s=0
  local d=$(( s/86400 )) h=$(( (s%86400)/3600 )) m=$(( (s%3600)/60 ))
  if   (( d > 0 )); then printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh%dm' "$h" "$m"
  elif (( m > 0 )); then printf '%dm' "$m"
  else                   printf '%ds' "$s"
  fi
}

now=$(date +%s)

# Render one window: label + bar + pct + reset countdown + absolute reset time.
render_window() {
  local label=$1 pct=$2 resets=$3
  if [[ -z "$pct" || "$pct" == "null" ]]; then
    printf '%s%s%s %sn/a%s' "$BOLD" "$label" "$RESET" "$DIM" "$RESET"
    return
  fi
  local c; c=$(color_for "$pct")
  local b; b=$(bar_for "$pct")
  local pint=${pct%.*}
  local tail=""
  if [[ -n "$resets" && "$resets" != "null" ]]; then
    local left=$(( resets - now ))
    local when; when=$(date -d "@$resets" +'%a %H:%M' 2>/dev/null)
    tail=" ${DIM}· resets in ${RESET}${c}$(countdown "$left")${RESET} ${DIM}(${when})${RESET}"
  fi
  printf '%s%s%s %s%s%s %s%3d%%%s%s' \
    "$BOLD" "$label" "$RESET" \
    "$c" "$b" "$RESET" \
    "$c" "$pint" "$RESET" "$tail"
}

# Render the model context window: label + bar + pct + tokens used/limit.
# Same color thresholds as the rate-limit windows (<50 green, <80 yellow, else red).
render_context() {
  local tokens=$1 limit=$2
  if [[ -z "$tokens" || "$tokens" == "null" ]] || (( limit <= 0 )); then
    printf '%sctx%s %sn/a%s' "$BOLD" "$RESET" "$DIM" "$RESET"
    return
  fi
  local pct=$(( tokens * 100 / limit )); (( pct > 100 )) && pct=100
  local c; c=$(color_for "$pct")
  local b; b=$(bar_for "$pct")
  printf '%sctx%s %s%s%s %s%3d%%%s %s(%s/%s)%s' \
    "$BOLD" "$RESET" \
    "$c" "$b" "$RESET" \
    "$c" "$pct" "$RESET" \
    "$DIM" "$(humanize_tokens "$tokens")" "$(humanize_tokens "$limit")" "$RESET"
}

p5=$(jq -r '.rate_limits.five_hour.used_percentage  // empty' <<<"$input")
r5=$(jq -r '.rate_limits.five_hour.resets_at        // empty' <<<"$input")
p7=$(jq -r '.rate_limits.seven_day.used_percentage  // empty' <<<"$input")
r7=$(jq -r '.rate_limits.seven_day.resets_at        // empty' <<<"$input")

# Context window occupancy: the latest assistant turn's usage in the transcript
# (non-cached input + cache read + cache creation ≈ tokens currently in context).
CTX_LIMIT=200000
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
ctx_tokens=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  ctx_tokens=$(tac "$transcript" 2>/dev/null \
    | jq -r 'select(.message.usage != null) | .message.usage
             | (.input_tokens + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))' \
        2>/dev/null \
    | head -1)
fi

# Opus indicator. Claude Code does not expose a separate Opus quota to the
# status line (only the combined 5h/7d windows above), so we surface the next
# best thing: whether Opus — the model that draws the weekly window down
# fastest — is the one currently active.
model_id=$(jq -r '.model.id // empty' <<<"$input")
model_name=$(jq -r '.model.display_name // empty' <<<"$input")
if [[ "$model_id" == *opus* || "$model_name" == *[Oo]pus* ]]; then
  # When Opus is active and the weekly window is past 80%, warn in red:
  # this is the worst time to keep running the model that drains 7d fastest.
  p7int=${p7%.*}
  if [[ -n "$p7int" && "$p7int" =~ ^[0-9]+$ ]] && (( p7int >= 80 )); then
    opus_seg="${RED}${BOLD}◆ Opus active — 7d ${p7int}%, ease off${RESET}"
  else
    opus_seg="${MAGENTA}${BOLD}◆ Opus active${RESET}${DIM} (draws 7d fastest)${RESET}"
  fi
else
  opus_seg="${DIM}◇ Opus idle${RESET}"
fi

sep="  ${DIM}│${RESET}  "
printf '%s%s%s%s%s%s%s\n' \
  "$(render_window "5h" "$p5" "$r5")" "$sep" \
  "$(render_window "7d" "$p7" "$r7")" "$sep" \
  "$(render_context "$ctx_tokens" "$CTX_LIMIT")" "$sep" \
  "$opus_seg"
