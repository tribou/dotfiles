#!/usr/bin/env bash
# Run write-spec scenarios as headless `claude -p` calls, one fresh session per rep.
# Usage: run.sh [-n REPS] [-j JOBS] [-m MODEL] ARM OUTDIR ID...   (run.sh --input ID prints the input)
#   ARM: red (no skill), green (working-tree skill), or skill@REV (skill files at a git revision)
#   ID:  a scenario ID from scenarios.md (S1, S12-187, S5r-stale, S9, ...)
# Writes OUTDIR/<arm>/<ID>.r<k>.md (the reply), .json (usage), and for repo runs .tools (tool calls)
# and .artifact (an ADR file the run wrote, which review and fidelity checks use in place of the reply).
# An existing .md is kept, so rerunning the same command fills in only missing or failed runs.
set -euo pipefail

BENCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$BENCH" rev-parse --show-toplevel)"
SCEN="$BENCH/scenarios.md"
BASE_SYS="You are a coding agent working in the user's terminal."

# Print scenario section for an ID's base (S12-187 -> "## S12 - ...").
section() {
  local base="${1%%-*}"
  awk -v h="## $base - " 'index($0, h) == 1 {f=1; print; next} /^## /{f=0} f' "$SCEN"
}

# Input text quoted (> ...) or fenced as ```text under **Input:**.
inline_input() {
  section "$1" | awk '/^\*\*Input:\*\*/{f=1;next} /^\*\*Checks/{f=0}
    f && /^```text/{t=1;next} f && t && /^```/{t=0;next} f && t {print}
    f && /^> /{sub(/^> /,""); print}'
}

issue() { jq -r '"Title: " + .title + "\n\nBody:\n" + .body' "$BENCH/inputs/$1.json"; }

render_input() {
  case "$1" in
    S1|S2|S4|S8|S5b) inline_input "$1" ;;
    S3) jq -r .title "$BENCH/inputs/141.json" ;;
    S5|S5r-stale|S5r-true) issue 42 ;;
    S5r-drift) inline_input S1 ;;
    S6) issue 211 ;;
    S7) issue 202 ;;
    S9) issue 170; printf '\nRecord the decision.\n' ;;
    S10) issue 192 | awk '/^## /{n++} n<=2' ;;
    S11) issue 192 ;;
    S12-187|S12-181|S12-180|S12-154) issue "${1#S12-}" ;;
    *) echo "run.sh: no input for $1 (S13/S14 inputs are not frozen yet)" >&2; return 1 ;;
  esac
}

# Repo-backed scenarios get a fresh copy per rep and tool access; others are tool-less calls.
repo_for() {
  case "$1" in
    S5r-stale) echo S5-stale ;; S5r-true) echo S5-true ;; S5r-drift) echo S1-repo ;; S9) echo empty ;;
    *) echo "" ;;
  esac
}

# Write the system prompt for ARM to $2.
pack() {
  local arm="$1" out="$2" rev="" f
  printf '%s\n' "$BASE_SYS" > "$out"
  [ "$arm" = red ] && return 0
  [ "$arm" != green ] && rev="${arm#skill@}"
  printf '\nFollow the write-spec skill below. Its SKILL.md and every file it points to are included here, so read no file to learn the skill.\n' >> "$out"
  if [ -z "$rev" ]; then
    for f in "$ROOT"/skills/write-spec/*.md; do
      printf '\n<file name="%s">\n%s\n</file>\n' "$(basename "$f")" "$(cat "$f")" >> "$out"
    done
  else
    while read -r f; do
      printf '\n<file name="%s">\n%s\n</file>\n' "$(basename "$f")" "$(git -C "$ROOT" show "$rev:$f")" >> "$out"
    done < <(git -C "$ROOT" ls-tree --name-only "$rev" skills/write-spec/ | grep '\.md$')
  fi
}

run_one() { # ARM OUTDIR MODEL ID REP
  local arm="$1" outdir="$2" model="$3" id="$4" rep="$5"
  local dir="$outdir/${arm//@/-}" stem repo fixture prompt where tools
  stem="$dir/$id.r$rep"
  mkdir -p "$dir"
  [ -s "$stem.md" ] && { echo "skip $arm $id r$rep (exists)"; return 0; }
  fixture="$(repo_for "$id")"
  where="No tracker or repo is available."
  if [ -n "$fixture" ]; then
    repo="$outdir/repos/${arm//@/-}/$id.r$rep"
    rm -rf "$repo"; mkdir -p "$(dirname "$repo")"
    if [ "$fixture" = empty ]; then
      mkdir -p "$repo"; git -C "$repo" init -q; echo '# demo' > "$repo/README.md"
      where="No tracker is available. Your working directory is the git repository at $repo. Nobody is available to answer questions."
      tools="Read,Glob,Grep,Write,Bash"
    else
      cp -r "$outdir/repos/_fixtures/$fixture" "$repo"
      where="No tracker is available. Your working directory is the git repository at $repo; read it only as the skill allows. Nobody is available to answer questions."
      tools="Read,Glob,Grep"
    fi
  fi
  prompt="You are asked to write a work item. Output only the final artifact as markdown, as you would file it. $where Input:
$(render_input "$id")"
  if [ -z "$fixture" ]; then
    ask --tools "" --output-format json --system-prompt-file "$outdir/$arm.sys" -- "$prompt" > "$stem.raw" || true
  else
    (cd "$repo" && ask --tools "$tools" --permission-mode acceptEdits --output-format stream-json --verbose \
      --system-prompt-file "$outdir/$arm.sys" -- "$prompt") > "$stem.raw" || true
    jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | "\(.name) \(.input | tojson)"' "$stem.raw" > "$stem.tools"
  fi
  if ! jq -e 'select(.type=="result") | .is_error | not' "$stem.raw" > /dev/null 2>&1; then
    mv "$stem.raw" "$stem.err"
    echo "FAIL $arm $id r$rep: $(jq -r 'select(.type=="result") | .result' "$stem.err" 2>/dev/null | head -c 200)" >&2
    return 1
  fi
  jq -r 'select(.type=="result") | .result' "$stem.raw" > "$stem.md"
  # A run that writes its artifact to a file (an ADR) gets that file kept as the artifact under review.
  [ -n "$fixture" ] && compgen -G "$repo/docs/adr/*.md" > /dev/null && cat "$repo"/docs/adr/*.md > "$stem.artifact"
  jq 'select(.type=="result") | {usage, total_cost_usd, duration_ms, model: (.modelUsage | keys)}' "$stem.raw" > "$stem.json"
  rm -f "$stem.raw" "$stem.err"
  echo "done $arm $id r$rep ($(wc -w < "$stem.md") words)"
}

# Headless claude in a clean session. It bills the claude.ai login, not an exported API key,
# unless WRITE_SPEC_BENCH_API_KEY=1.
ask() {
  local env=(env)
  [ "${WRITE_SPEC_BENCH_API_KEY:-}" = 1 ] || env+=(-u ANTHROPIC_API_KEY)
  "${env[@]}" claude -p --model "$model" --safe-mode --no-session-persistence "$@"
}

main() {
  if [ "${1:-}" = __one ]; then shift; model="$3"; run_one "$@"; return; fi
  if [ "${1:-}" = --input ]; then render_input "$2"; return; fi
  local reps=3 jobs=4 arm outdir id rep o
  model=sonnet
  while getopts n:j:m: o; do
    case "$o" in n) reps="$OPTARG" ;; j) jobs="$OPTARG" ;; m) model="$OPTARG" ;; *) return 2 ;; esac
  done
  shift $((OPTIND - 1))
  [ $# -ge 3 ] || { sed -n '3,8p' "$0"; return 2; }
  arm="$1" outdir="$2"; shift 2
  mkdir -p "$outdir"
  outdir="$(cd "$outdir" && pwd)"
  for id in "$@"; do render_input "$id" > /dev/null; done
  pack "$arm" "$outdir/$arm.sys"
  [ -d "$outdir/repos/_fixtures" ] || bash "$BENCH/build-fixtures.sh" "$outdir/repos/_fixtures" > /dev/null
  for id in "$@"; do for rep in $(seq 1 "$reps"); do printf '%s\n' "$id" "$rep"; done; done |
    xargs -n 2 -P "$jobs" bash "$BENCH/run.sh" __one "$arm" "$outdir" "$model"
}

# The whole script is parsed before main runs, so editing this file mid-run is safe.
main "$@"; exit
