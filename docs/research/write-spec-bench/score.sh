#!/usr/bin/env bash
# Score run.sh outputs with the mechanical checks in scenarios.md.
# Usage: score.sh OUTDIR [ARMDIR...]   (default: every arm directory under OUTDIR)
# Writes OUTDIR/results.tsv (one row per check) and prints one summary row per arm and scenario.
set -uo pipefail

BENCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCEN="$BENCH/scenarios.md"

# Check lines for an ID: the bash blocks after its section's **Checks** label, limited to
# "# <ID>" sub-blocks when the section has them.
checks() {
  local id="$1" base="${1%%-*}"
  awk -v h="## $base - " 'index($0, h) == 1 {f=1; next} /^## /{f=0} f' "$SCEN" |
    awk '/^\*\*Checks/{c=1} c' |
    awk -v id="$id" '/^```bash/{b=1; next} /^```/{b=0; next}
      b && /^# S[0-9]/ {cur=$2; marked=1; next}
      b && NF {n++; line[n]=$0; tag[n]=cur}
      END {for (i = 1; i <= n; i++) if (!marked || tag[i] == id) print line[i]}'
}

# Run each check in one shell (a check may set OUT, as S9's does); print "<n>\t<exit>\t<check>".
run_checks() { # ID OUT REPO
  local id="$1" n=0 line s
  export OUT="$2" REPO="$3"
  while IFS= read -r line; do
    n=$((n + 1))
    eval "$line" > /dev/null 2>&1
    s=$?
    printf '%s\t%s\t%s\n' "$n" "$s" "$line"
  done < <(checks "$id")
}

outdir="$(cd "${1:?usage: score.sh OUTDIR [ARMDIR...]}" && pwd)"; shift
if [ $# -eq 0 ]; then
  mapfile -t arms < <(find "$outdir" -mindepth 1 -maxdepth 1 -type d ! -name repos -printf '%f\n' | sort)
else
  arms=("$@")
fi
tsv="$outdir/results.tsv"
printf 'arm\tid\trep\twords\tcheck\texit\tline\n' > "$tsv"
printf '%-16s %-10s %-6s %-11s %s\n' arm id pass words failing
for arm in "${arms[@]}"; do
  mapfile -t ids < <(find "$outdir/$arm" -name '*.r*.md' -printf '%f\n' | sed 's/\.r[0-9]*\.md$//' | sort -uV)
  for id in "${ids[@]}"; do
    reps=0 ok=0 fails="" wmin="" wmax=""
    for f in "$outdir/$arm/$id".r*.md; do
      rep="${f##*.r}"; rep="${rep%.md}"
      words=$(wc -w < "$f")
      reps=$((reps + 1))
      [ -z "$wmin" ] || [ "$words" -lt "$wmin" ] && wmin=$words
      [ -z "$wmax" ] || [ "$words" -gt "$wmax" ] && wmax=$words
      bad=""
      while IFS=$'\t' read -r n s line; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$arm" "$id" "$rep" "$words" "$n" "$s" "$line" >> "$tsv"
        [ "$s" = 0 ] || bad="$bad${bad:+,}#$n"
      done < <(run_checks "$id" "$f" "$outdir/repos/$arm/$id.r$rep")
      if [ -z "$bad" ]; then ok=$((ok + 1)); else fails="$fails r$rep:$bad"; fi
    done
    printf '%-16s %-10s %-6s %-11s %s\n' "$arm" "$id" "$ok/$reps" "$wmin-$wmax" "${fails# }"
  done
done
