#!/bin/bash
set -euo pipefail

PERF_LOG="$(dirname "$0")/../tests/.perf_log.jsonl"

if [ ! -f "$PERF_LOG" ] || [ ! -s "$PERF_LOG" ]; then
  echo "No performance logs found in $PERF_LOG. Run 'just test-unit' to capture latency metrics first!"
  exit 0
fi

echo -e "\033[1;35m🚀 Dotfiles Performance History\033[0m"
echo "=================================================="

draw_bar() {
  local val=$1
  local max=$2
  local scale=30
  [ "$max" -eq 0 ] && max=1
  local width=$(( (val * scale) / max ))
  [ "$width" -lt 1 ] && width=1
  [ "$width" -gt "$scale" ] && width=$scale
  
  local bar=""
  for ((i=0; i<width; i++)); do
    bar="${bar}█"
  done
  echo -n "$bar"
}

for metric in "startup_ms" "prompt_nongit_ms" "prompt_git_ms"; do
  echo
  case "$metric" in
    "startup_ms") echo -e "\033[1;36mMetric: Terminal Startup Time (lower is better)\033[0m" ;;
    "prompt_nongit_ms") echo -e "\033[1;36mMetric: Non-Git Prompt Render Time (lower is better)\033[0m" ;;
    "prompt_git_ms") echo -e "\033[1;36mMetric: Git Prompt Render Time (lower is better)\033[0m" ;;
  esac
  echo "--------------------------------------------------"
  
  max_val=$(grep "\"metric\": \"$metric\"" "$PERF_LOG" | jq -r '.value' | sort -rn | head -n 1 || echo 1)
  [ -z "$max_val" ] && max_val=1
  
  grep "\"metric\": \"$metric\"" "$PERF_LOG" | tail -n 10 | while read -r line; do
    commit=$(echo "$line" | jq -r '.commit')
    val=$(echo "$line" | jq -r '.value')
    timestamp=$(echo "$line" | jq -r '.timestamp' | cut -d'T' -f2 | cut -d':' -f1,2)
    
    printf "  [%s @ %s] %5sms  " "$commit" "$timestamp" "$val"
    draw_bar "$val" "$max_val"
    echo
  done
done
echo
