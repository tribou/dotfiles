#!/usr/bin/env bash
# Outline the prompts, slash commands, skills, and subagents in a Claude Code session.
# Usage: session-outline.sh [session-id | path/to/session.jsonl]
# With no argument, uses the most recent session for the current directory.
set -euo pipefail

proj=~/.claude/projects/$(pwd | sed 's#[/.]#-#g')
arg=${1:-}
if [[ -z $arg ]]; then
  # Newest *.jsonl by mtime, without parsing ls output.
  file=
  for candidate in "$proj"/*.jsonl; do
    [[ -f $candidate ]] || continue
    [[ -z $file || $candidate -nt $file ]] && file=$candidate
  done
  [[ -n $file ]] || { echo "No session transcripts found in $proj" >&2; exit 1; }
elif [[ -f $arg ]]; then
  file=$arg
else
  file=$proj/$arg.jsonl
fi
dir=${file%.jsonl}

# Distinct models a transcript's assistant turns ran on, in first-seen order.
# A session that switched models mid-run reports all of them.
transcript_models() {
  jq -r 'select(.type == "assistant") | .message.model // empty' "$1" \
    | awk '!seen[$0]++' | paste -sd, -
}

echo "Session: $(basename "$dir")"
[[ -f $dir/custom-title.json ]] && echo "Title:   $(jq -r .customTitle "$dir/custom-title.json")"
models=$(transcript_models "$file")
[[ -n $models ]] && echo "Models:  $models"
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
          $ind + "  AGENT  [" + (.input.subagent_type // "general-purpose") + "] " + (.input.description // "")
          + "\t" + .id + "\t" + (.input.model // "")
        else empty end
    else empty end
  ' "$src"
}

# Append each agent's model to its line, preferring what its transcript actually
# ran on over the alias the spawn recorded or the Agent call requested.
# Emits "line<TAB>agent-transcript" so the caller can recurse into the agent.
annotate() {
  local line tool_id requested meta sub model
  while IFS=$'\t' read -r line tool_id requested; do
    meta=; sub=; model=${requested:-}
    if [[ -n ${tool_id:-} && -d $dir/subagents ]]; then
      meta=$(grep -l "\"toolUseId\":\"$tool_id\"" "$dir"/subagents/*.meta.json 2>/dev/null | head -1 || true)
    fi
    if [[ -n $meta ]]; then
      sub=${meta%.meta.json}.jsonl
      model=$(transcript_models "$sub")
      [[ -n $model ]] || model=$(jq -r '.model // empty' "$meta")
      [[ -n $model ]] || model=${requested:-}
    fi
    [[ -n $model ]] && line="$line ($model)"
    printf '%s\t%s\n' "$line" "$sub"
  done
}

outline "" "$file" | annotate | while IFS=$'\t' read -r line sub; do
  echo "$line"
  # Outline the subagent's own skills and agents beneath the line that spawned it.
  [[ -n ${sub:-} ]] || continue
  outline "      " "$sub" | annotate | grep -v PROMPT | cut -f1 || true
done
