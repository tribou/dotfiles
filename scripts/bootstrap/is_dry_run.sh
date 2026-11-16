#!/usr/bin/env bash
# Exit 0 when the given `mise bootstrap` arguments ask for a dry run:
# --dry-run, -n, or -n combined with mise's other valueless short flags (-ny).
#
# Usage: is_dry_run.sh [mise bootstrap args]
for arg in "$@"; do
  [ "$arg" = --dry-run ] && exit 0
  [[ "$arg" =~ ^-[nyqvh]*n[nyqvh]*$ ]] && exit 0
done
exit 1
