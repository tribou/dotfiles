#!/usr/bin/env bash
# Collect a scored run into the review page's data file.
# Usage: review.sh OUTDIR [NAME [ARMDIR...]]   (run score.sh, and optionally fidelity.sh check, first)
# Writes OUTDIR/review/data/run.json and copies review.html to OUTDIR/review/index.html;
# publish that index.html with data/run.json as its data file.
set -euo pipefail

BENCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCEN="$BENCH/scenarios.md"

# Artifact type each scenario is meant to produce, for grouping.
kind_for() {
  case "$1" in
    S2) echo "Tiny task" ;; S7) echo Bug ;; S8) echo Investigation ;; S9) echo ADR ;;
    S10) echo "Project brief" ;; *) echo Issue ;;
  esac
}

section() {
  local base="${1%%-*}"
  awk -v h="## $base - " 'index($0, h) == 1 {f=1; print; next} /^## /{f=0} f' "$SCEN"
}

main() {
  local outdir name dir arm f id stem rep tmp
  outdir="$(cd "${1:?usage: review.sh OUTDIR [NAME [ARMDIR...]]}" && pwd)"
  name="${2:-$(basename "$outdir")}"
  [ -s "$outdir/results.tsv" ] || { echo "review.sh: run score.sh $outdir first" >&2; return 1; }
  dir="$outdir/review"; mkdir -p "$dir/data"
  tmp="$(mktemp -d)"
  shift $(( $# < 2 ? $# : 2 ))
  local arms=("$@")
  [ ${#arms[@]} -gt 0 ] || mapfile -t arms < <(find "$outdir" -mindepth 1 -maxdepth 1 -type d ! -name repos ! -name review -printf '%f\n' | sort)
  for arm in "${arms[@]}"; do
    for f in "$outdir/$arm"/*.r*.md; do
      [ -e "$f" ] || continue
      stem="${f%.md}"; id="$(basename "$stem")"; id="${id%.r*}"; rep="${stem##*.r}"
      jq -n --arg arm "$arm" --arg id "$id" --argjson rep "$rep" \
        --arg kind "$(kind_for "${id%%-*}")" \
        --arg title "$(section "$id" | head -1 | sed 's/^## [^ ]* - //')" \
        --arg judge "$(section "$id" | grep '^Judge' | sed 's/^Judge[^:]*: *//' | head -3)" \
        --arg key "$(bash "$BENCH/fidelity.sh" key "$id")" \
        --arg input "$(bash "$BENCH/run.sh" --input "$id")" \
        --rawfile output "$( [ -s "$stem.artifact" ] && echo "$stem.artifact" || echo "$f")" \
        --arg reply "$( [ -s "$stem.artifact" ] && cat "$f" || true)" \
        --arg tools "$(cat "$stem.tools" 2>/dev/null || true)" \
        --argjson fid "$(cat "$stem.fid.json" 2>/dev/null || echo null)" \
        --argjson checks "$(awk -F'\t' -v a="$arm" -v i="$id" -v r="$rep" '$1==a && $2==i && $3==r' "$outdir/results.tsv" |
          jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {n: (.[4] | tonumber), pass: (.[5] == "0"), line: .[6]})')" \
        '{arm: $arm, id: $id, rep: $rep, kind: $kind, title: $title, judge: $judge, key: $key,
          input: $input, output: $output, reply: $reply, tools: $tools, checks: $checks, fid: $fid,
          inWords: ($input | [splits("\\s+")] | map(select(length > 0)) | length),
          outWords: ($output | [splits("\\s+")] | map(select(length > 0)) | length)}' > "$tmp/$arm.$id.$rep.json"
    done
  done
  jq -s --arg name "$name" --arg at "$(date -u +%FT%TZ)" \
    --arg rev "$(git -C "$BENCH" rev-parse --short HEAD)$(git -C "$BENCH" diff --quiet HEAD -- :/skills/write-spec 2>/dev/null || echo '+dirty')" \
    --argjson keys "$(cat "$BENCH"/keys/*.json 2>/dev/null | jq -s . || echo '[]')" \
    '{run: $name, generated: $at, skillRev: $rev, runs: ., keys: $keys}' "$tmp"/*.json > "$dir/data/run.json"
  rm -rf "$tmp"
  cp "$BENCH/review.html" "$dir/index.html"
  echo "$dir/index.html ($(jq '.runs | length' "$dir/data/run.json") runs, $(jq '.keys | length' "$dir/data/run.json") keys)"
}

# The whole script is parsed before main runs, so editing this file mid-run is safe.
main "$@"; exit
