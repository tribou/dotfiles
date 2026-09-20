# shellcheck shell=bash
# Claude Code backend: one JSONL append-log per session, with subagent
# transcripts in a sibling subagents/ directory linked by tool-use id.
# rec_sep (the record field separator) is assigned by session-outline.sh,
# which is the only thing that sources this file.
# shellcheck disable=SC2154

# Claude Code slugs a working directory by replacing every character that is
# not alphanumeric, not just the separators, so mirror that here.
cc_root=${SESSION_OUTLINE_CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}
cc_proj=$cc_root/$(pwd | sed 's#[^A-Za-z0-9]#-#g')

backend_resolve() {
  local arg=$1 candidate
  if [[ -z $arg ]]; then
    cc_file=
    for candidate in "$cc_proj"/*.jsonl; do
      [[ -f $candidate ]] || continue
      [[ -z $cc_file || $candidate -nt $cc_file ]] && cc_file=$candidate
    done
    [[ -n $cc_file ]] || { echo "No Claude Code sessions found in $cc_proj" >&2; exit 1; }
  elif [[ -f $arg ]]; then
    cc_file=$arg
  else
    require_plain_id "$arg"
    cc_file=$cc_proj/$arg.jsonl
  fi
  cc_dir=${cc_file%.jsonl}
}

# Distinct models a transcript's assistant turns ran on, in first-seen order.
cc_models() {
  jq -Rr 'fromjson? // empty | select(.type == "assistant") | .message.model // empty' "$1" \
    | awk '!seen[$0]++' | paste -sd, -
}

backend_header() {
  local models
  echo "Session: $(basename "$cc_dir")"
  [[ -f $cc_dir/custom-title.json ]] && echo "Title:   $(jq -r .customTitle "$cc_dir/custom-title.json")"
  models=$(cc_models "$cc_file")
  [[ -n $models ]] && echo "Models:  $models"
  return 0
}

# Emit "depth<TAB>kind<TAB>text<TAB>tool_id<TAB>requested_model" for one transcript.
cc_scan() {
  jq -Rr --arg depth "$1" '
    def trunc: gsub("\\s+"; " ") | if length > 110 then .[0:110] + "..." else . end;
    fromjson? // empty
    | if .type == "user" and (.isMeta | not) and (.message.content | type) == "string" then
      .message.content as $c
      | if ($c | test("<command-name>")) then
          ($c | capture("<command-name>(?<n>[^<]*)</command-name>").n) as $n
          | if $n == "/clear" then empty else
              [$depth, "CMD", ($n + " " + (($c | capture("<command-args>(?<a>[^<]*)</command-args>").a? // "") | trunc)), "", ""]
            end
        elif ($c | test("^<(local-command|system-reminder|task-notification)")) then empty
        else [$depth, "PROMPT", ($c | trunc), "", ""] end
    elif .type == "assistant" then
      .message.content[]? | select(.type == "tool_use")
      | if .name == "Skill" then
          [$depth, "SKILL", (.input.skill + (if .input.args then " -- " + (.input.args | trunc) else "" end)), "", ""]
        elif .name == "Agent" or .name == "Task" then
          [$depth, "AGENT", ("[" + (.input.subagent_type // "general-purpose") + "] " + (.input.description // "")),
           .id, (.input.model // "")]
        else empty end
    else empty end
    | map(tostring | gsub("[\\t\\n\\r\u001f]"; " ")) | join("\u001f")
  ' "$2"
}

# Resolve each agent's model, preferring what its transcript actually ran on
# over the alias recorded at spawn or the model the call requested.
cc_emit() {
  local depth kind text tool_id requested meta sub model
  while IFS=$rec_sep read -r depth kind text tool_id requested; do
    meta=; sub=; model=${requested:-}
    if [[ -n ${tool_id:-} && -d $cc_dir/subagents ]]; then
      meta=$(grep -l "\"toolUseId\":\"$tool_id\"" "$cc_dir"/subagents/*.meta.json 2>/dev/null | head -1 || true)
    fi
    if [[ -n $meta ]]; then
      sub=${meta%.meta.json}.jsonl
      model=$(cc_models "$sub")
      [[ -n $model ]] || model=$(jq -r '.model // empty' "$meta")
      [[ -n $model ]] || model=${requested:-}
    fi
    printf '%s%s%s%s%s%s%s\n' "$depth" "$rec_sep" "$kind" "$rec_sep" "$text" "$rec_sep" "$model"
    [[ -n $sub ]] || continue
    # A subagent linked back into its own ancestry would recurse forever.
    [[ $depth -lt 10 ]] || continue
    cc_scan "$((depth + 1))" "$sub" | cc_emit | awk -F"$rec_sep" '$2 != "PROMPT"' || true
  done
}

backend_records() { cc_scan 0 "$cc_file" | cc_emit; }
