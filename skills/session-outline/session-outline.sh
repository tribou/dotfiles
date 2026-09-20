#!/usr/bin/env bash
# Outline the prompts, slash commands, skills, and subagents in a Claude Code session.
# Usage: session-outline.sh [session-id | path/to/session.jsonl]
# With no argument, uses the most recent session for the current directory.
set -euo pipefail

proj=~/.claude/projects/$(pwd | sed 's#[/.]#-#g')
arg=${1:-}
if [[ -z $arg ]]; then
  file=$(ls -t "$proj"/*.jsonl | head -1)
elif [[ -f $arg ]]; then
  file=$arg
else
  file=$proj/$arg.jsonl
fi
dir=${file%.jsonl}

echo "Session: $(basename "$dir")"
[[ -f $dir/custom-title.json ]] && echo "Title:   $(jq -r .customTitle "$dir/custom-title.json")"
echo

outline() {
  local indent=$1 src=$2
  jq -r --arg ind "$indent" '
    def trunc: gsub("\\s+"; " ") | if length > 110 then .[0:110] + "..." else . end;
    if .type == "user" and (.isMeta | not) and (.message.content | type) == "string" then
      .message.content as $c
      | if ($c | test("<command-name>")) then
          ($c | capture("<command-name>(?<n>[^<]*)</command-name>").n) as $n
          | if $n == "/clear" then empty else
              $ind + "CMD    " + $n + " " + (($c | capture("<command-args>(?<a>[^<]*)</command-args>").a? // "") | trunc)
            end
        elif ($c | test("^<(local-command|system-reminder|task-notification)")) then empty
        else $ind + "PROMPT " + ($c | trunc) end
    elif .type == "assistant" then
      .message.content[]? | select(.type == "tool_use")
      | if .name == "Skill" then $ind + "  SKILL  " + .input.skill + (if .input.args then " -- " + (.input.args | trunc) else "" end)
        elif .name == "Agent" or .name == "Task" then
          $ind + "  AGENT  [" + (.input.subagent_type // "general-purpose") + "] " + (.input.description // "") + "\t" + .id
        else empty end
    else empty end
  ' "$src"
}

outline "" "$file" | while IFS=$'\t' read -r line tool_id; do
  echo "$line"
  [[ -z ${tool_id:-} || ! -d $dir/subagents ]] && continue
  # Find the subagent transcript spawned by this tool call and outline its own skills/agents.
  meta=$(grep -l "\"toolUseId\":\"$tool_id\"" "$dir"/subagents/*.meta.json 2>/dev/null | head -1 || true)
  [[ -n $meta ]] && outline "      " "${meta%.meta.json}.jsonl" | grep -v PROMPT | cut -f1 || true
done
