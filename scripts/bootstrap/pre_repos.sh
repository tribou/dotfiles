#!/usr/bin/env bash
# pre-repos hook (see mise.toml): clear known debris that would make a
# [bootstrap.repos] checkout look dirty, which stops mise's repos step.
#
# The only debris known so far: TPM run without TMUX_PLUGIN_MANAGER_PATH (the
# May 2026 regression in docs/superpowers/specs/2026-05-06-bootstrap-non-tmux-design.md)
# cloned plugins into its own checkout, ~/.tmux/plugins/tpm/<plugin>. A
# directory there counts as debris only when it is untracked by tpm, is a
# clean Git clone whose origin is exactly the URL TPM uses for a plugin listed
# in tmux/tmux-conf (https://git::@github.com/<owner>/<plugin>), and so holds
# nothing TPM can't re-download. It is removed when ~/.tmux/plugins already
# has that plugin, and otherwise moved there. Everything else is left for mise
# to report.
#
# Prints "changed: ..." for every change so CI can assert a clean second run.
# With --dry-run, prints "would ..." instead and changes nothing (bootstrap.sh
# --dry-run uses it, since `mise bootstrap --dry-run` does not run hooks).
#
# Usage: pre_repos.sh [--dry-run] [TMUX_CONF]
set -euo pipefail

dry_run=0
if [ "${1:-}" = --dry-run ]; then
  dry_run=1
  shift
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmux_conf="${1:-$repo/tmux/tmux-conf}"
plugins="$HOME/.tmux/plugins"
tpm="$plugins/tpm"

# change PLANNED DONE COMMAND...: run COMMAND and report DONE, or only report
# PLANNED in a dry run.
change() {
  local planned="$1" done="$2"
  shift 2
  if [ "$dry_run" = 1 ]; then
    echo "would $planned"
  else
    "$@"
    echo "changed: $done"
  fi
}

[ -d "$tpm/.git" ] || exit 0

# Plugin slugs (owner/name) from the `set -g @plugin '...'` lines.
sed -n "s/^set -g @plugin '\([^'/]*\/[^']*\)'.*/\1/p" "$tmux_conf" |
  while IFS= read -r slug; do
    name="${slug#*/}"
    stray="$tpm/$name"
    [ "$name" != tpm ] && [ -d "$stray/.git" ] || continue
    [ -z "$(git -C "$tpm" ls-files -- "$name")" ] || continue
    [ "$(git -C "$stray" remote get-url origin 2>/dev/null)" = "https://git::@github.com/$slug" ] || continue
    [ -z "$(git -C "$stray" status --porcelain)" ] || continue
    # shellcheck disable=SC2088 # display text, not paths
    from="~/.tmux/plugins/tpm/$name" to="~/.tmux/plugins/$name"
    if [ -e "$plugins/$name" ] || [ -L "$plugins/$name" ]; then
      change "remove stray $from" "removed stray $from" rm -rf "$stray"
    else
      change "move stray $from to $to" "moved stray $from to $to" mv "$stray" "$plugins/$name"
    fi
  done
