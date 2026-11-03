#!/usr/bin/env bash
# Must-survive keys: what a coding agent needs from each input, and a check that a rewrite kept it.
# Usage: fidelity.sh draft ID...               draft keys/<key>.json from the scenario's input (status "draft")
#        fidelity.sh check OUTDIR [ARMDIR...]  check each run.sh output against its key; writes <stem>.fid.json
#        fidelity.sh key ID                    print the key name an ID uses
# Options (before the subcommand): -m MODEL (default: opus for draft, sonnet for check), -j JOBS (default 4).
set -euo pipefail

BENCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS="$BENCH/keys"

# Key name for an ID: the issue number, or the scenario ID for an input written in scenarios.md.
key_for() {
  case "$1" in
    S5|S5r-stale|S5r-true) echo 42 ;; S5r-drift) echo S1 ;; S6) echo 211 ;; S7) echo 202 ;;
    S9) echo 170 ;; S11) echo 192 ;; S12-*) echo "${1#S12-}" ;; *) echo "$1" ;;
  esac
}

DRAFT_SCHEMA='{"type":"object","required":["items"],"properties":{"items":{"type":"array","items":{
  "type":"object","required":["id","type","need","text"],"properties":{
  "id":{"type":"string"},
  "type":{"enum":["identifier","requirement","constraint","non-goal","evidence","open"]},
  "need":{"enum":["must","may"]},
  "text":{"type":"string"},
  "exact":{"type":"string"}}}}}}'

# shellcheck disable=SC2016 # backticks are markdown, not expansions
DRAFT_SYS='You build answer keys that test whether a rewritten work item kept everything a coding agent needs from the original.

List the pieces of information in the original that an engineer would need to produce the same plan and code changes: at most 15 items, ranked by how much losing each would change what gets built or how it is checked, keeping only the top 15. Merge closely related details into one item. Skip background and motivation unless the item is the only statement of the problem. Ids are k1, k2, ... in order of appearance in the original. Types:
- identifier: a decided name, path, command, flag, variable, error string, or version. Set `exact` only when the item is one literal string as written, for a fixed-string search.
- requirement: a behavior or outcome that must hold when the work is done.
- constraint: a limit, compatibility need, or approach the requester settled.
- non-goal: something stated as out of scope.
- evidence: a reported fact, measurement, or claim about the current state, with its source if given.
- open: a question the original leaves open.
Set `need` to "must" when losing the item would change what gets built or how it is checked. Set it to "may" for background, motivation, a nice-to-have, a detail an agent could rederive, or an implementation the requester only suggested ("probably", "maybe", "could").
List nothing the original does not say. Keep each `text` under 20 words.'

CHECK_SCHEMA='{"type":"object","required":["items","added"],"properties":{
  "items":{"type":"array","items":{"type":"object","required":["id","status","quote"],"properties":{
    "id":{"type":"string"},"status":{"enum":["present","hedged","missing","contradicted"]},"quote":{"type":"string"}}}},
  "added":{"type":"array","items":{"type":"object","required":["text","quote"],"properties":{
    "text":{"type":"string"},"quote":{"type":"string"}}}}}}'

# shellcheck disable=SC2016 # backticks are markdown, not expansions
CHECK_SYS='You audit a rewritten work item against an answer key taken from its original.

For each key item, give one status and quote the rewrite line that decides it (empty quote when missing):
- present: the rewrite conveys the same fact, in any wording or section.
- hedged: the rewrite keeps the fact but as something to check or a condition ("if ... still ...", "reportedly", "Unknown:"), where the original stated it plainly.
- missing: the rewrite does not convey it.
- contradicted: the rewrite states something incompatible with it.
Then list under `added` each requirement, constraint, decision, or factual claim in the rewrite that the original does not support. Lines labeled `Unknown:`, `Assumption:`, or `Suggested:` are not additions. Paraphrase and restructuring are not additions.'

# Headless claude in a clean session; prints the result JSON or fails. It bills the claude.ai
# login, not an exported API key, unless WRITE_SPEC_BENCH_API_KEY=1.
ask() { # MODEL ARGS...
  local model="$1" env=(env) raw; shift
  [ "${WRITE_SPEC_BENCH_API_KEY:-}" = 1 ] || env+=(-u ANTHROPIC_API_KEY)
  raw="$("${env[@]}" claude -p --model "$model" --tools "" --safe-mode --no-session-persistence \
    --output-format json "$@")" || true
  if ! jq -e '.is_error | not' > /dev/null 2>&1 <<< "$raw"; then
    echo "FAIL: $(jq -r .result 2>/dev/null <<< "$raw" | head -c 200)" >&2
    return 1
  fi
  printf '%s\n' "$raw"
}

draft_one() { # MODEL ID
  local model="$1" id="$2" key out raw
  key="$(key_for "$id")"; out="$KEYS/$key.json"
  [ -e "$out" ] && { echo "keep $out (exists)"; return 0; }
  raw="$(ask "$model" --json-schema "$DRAFT_SCHEMA" --system-prompt "$DRAFT_SYS" -- "Original work item:
$(bash "$BENCH/run.sh" --input "$id")")" || { echo "FAIL draft $id" >&2; return 1; }
  jq --arg key "$key" --arg src "$id" '{key: $key, source: $src, status: "draft", items: .structured_output.items}' \
    <<< "$raw" > "$out"
  echo "drafted $out ($(jq '.items | length' "$out") items)"
}

check_one() { # MODEL STEM   (STEM = OUTDIR/<arm>/<ID>.r<k>)
  local model="$1" stem="$2" id key file raw art="$2.md"
  [ -s "$stem.artifact" ] && art="$stem.artifact"
  id="$(basename "$stem")"; id="${id%.r*}"
  key="$(key_for "$id")"; file="$KEYS/$key.json"
  [ -e "$file" ] || return 0
  [ -s "$stem.fid.json" ] && return 0
  raw="$(ask "$model" --json-schema "$CHECK_SCHEMA" --system-prompt "$CHECK_SYS" -- "<original>
$(bash "$BENCH/run.sh" --input "$id")
</original>
<key>
$(jq -c '.items[] | {id, type, text}' "$file")
</key>
<rewrite>
$(cat "$art")
</rewrite>")" || { echo "FAIL check $stem" >&2; return 1; }
  printf '%s\n' "$raw" > "$stem.fid.raw"
  # An exact identifier absent from the rewrite is missing whatever the model says.
  jq -n --slurpfile rr "$stem.fid.raw" --slurpfile k "$file" --rawfile out "$art" '
    $rr[0] as $r
    | ($k[0].items | map({key: .id, value: .}) | from_entries) as $ki
    | {key: $k[0].key, keyStatus: $k[0].status, cost: $r.total_cost_usd,
       items: [$r.structured_output.items[] | ($ki[.id] // {}) as $item
         | . + {need: ($item.need // "?"), text: ($item.text // "")}
         | if ($item.exact // "") != "" and ($out | contains($item.exact) | not)
           then .status = "missing" | .quote = "(exact string absent)" else . end],
       added: $r.structured_output.added}' > "$stem.fid.json" || { rm -f "$stem.fid.json"; return 1; }
  rm -f "$stem.fid.raw"
  echo "checked $stem: $(jq -r '[.items[] | select(.need == "must" and (.status == "missing" or .status == "contradicted")) | .id] | if length == 0 then "all must-items kept" else "LOST " + join(",") end' "$stem.fid.json"), $(jq '.added | length' "$stem.fid.json") added"
}

main() {
  local model="" jobs=4 cmd outdir arm o arms
  while getopts m:j: o; do
    case "$o" in m) model="$OPTARG" ;; j) jobs="$OPTARG" ;; *) return 2 ;; esac
  done
  shift $((OPTIND - 1))
  cmd="${1:-}"; shift || true
  case "$cmd" in
    key) key_for "$1" ;;
    draft)
      mkdir -p "$KEYS"
      for id in "$@"; do draft_one "${model:-opus}" "$id"; done ;;
    check)
      outdir="$(cd "${1:?usage: fidelity.sh check OUTDIR [ARMDIR...]}" && pwd)"; shift
      if [ $# -eq 0 ]; then
        mapfile -t arms < <(find "$outdir" -mindepth 1 -maxdepth 1 -type d ! -name repos -printf '%f\n' | sort)
      else
        arms=("$@")
      fi
      for arm in "${arms[@]}"; do
        find "$outdir/$arm" -name '*.r*.md' | sed 's/\.md$//' | sort -V
      done | xargs -I{} -P "$jobs" bash "$BENCH/fidelity.sh" __check "${model:-sonnet}" {} ;;
    __check) check_one "$@" ;;
    *) sed -n '3,6p' "$0"; return 2 ;;
  esac
}

# The whole script is parsed before main runs, so editing this file mid-run is safe.
main "$@"; exit
