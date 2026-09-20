#!/usr/bin/env bash
# Outline the prompts, slash commands, skills, and subagents in an agent session.
# Usage: session-outline.sh [--runtime claude-code|opencode] [session-id | path/to/session.jsonl]
# With no argument, uses the most recent session for the current directory.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

runtime=
arg=
while [[ $# -gt 0 ]]; do
  case $1 in
    --runtime) runtime=${2:-}; shift 2 ;;
    --runtime=*) runtime=${1#*=}; shift ;;
    -h|--help) sed -n '2,4p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) arg=$1; shift ;;
  esac
done

# Pick a runtime from the argument's shape when one wasn't named: opencode
# session ids are prefixed, Claude Code's are UUIDs or transcript paths.
if [[ -z $runtime ]]; then
  case $arg in
    ses_*) runtime=opencode ;;
    "")    runtime=$("$here/lib/detect.sh") ;;
    *)     runtime=claude-code ;;
  esac
fi

case $runtime in
  claude-code|opencode) ;;
  *) echo "Unknown runtime: $runtime (expected claude-code or opencode)" >&2; exit 2 ;;
esac

# shellcheck source=/dev/null
. "$here/lib/$runtime.sh"

# Render normalized "depth<TAB>kind<TAB>text<TAB>model" records. Prompts sit at
# the margin; skills and agents indent under them, once per nesting level.
render() {
  local depth kind text model indent
  while IFS=$'\t' read -r depth kind text model; do
    indent=''
    [[ ${depth:-0} -gt 0 ]] && indent=$(printf '%*s' $((depth * 6)) '')
    case $kind in
      PROMPT|CMD) printf '%s%-7s%s\n' "$indent" "$kind" "$text" ;;
      *)          printf '%s  %-7s%s%s\n' "$indent" "$kind" "$text" "${model:+ ($model)}" ;;
    esac
  done
}

backend_resolve "$arg"
echo "Runtime: $runtime"
backend_header
echo
backend_records | render
