#!/usr/bin/env bash
# pre-dotfiles hook (see mise.toml): create the directories dotfiles live in,
# keep ~/.ssh and ~/.gnupg private, and move a pre-existing regular file at any
# managed [dotfiles] target to <target>.backup (or .backup.N when that already
# exists). mise refuses to replace files it
# did not write (short of --force-dotfiles, which would discard them), so this
# keeps the old bootstrap's back-up-then-link behaviour.
#
# Prints "changed: ..." for every change so CI can assert a clean second run.
# With --dry-run, prints "would ..." instead and changes nothing (bootstrap.sh
# --dry-run uses it, since `mise bootstrap --dry-run` does not run hooks).
#
# Usage: pre_dotfiles.sh [--dry-run] [MISE_TOML]
set -euo pipefail

dry_run=0
if [ "${1:-}" = --dry-run ]; then
  dry_run=1
  shift
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
config="${1:-$repo/mise.toml}"

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

if [ "$dry_run" = 0 ]; then
  for dir in dev/bin dev/go/pkg dev/go/src/github.com/tribou .config/mise/conf.d \
    .local/bin .local/share/nvim/site/autoload .tmux; do
    mkdir -p "$HOME/$dir"
  done
fi

for dir in .ssh .gnupg; do
  if [ ! -d "$HOME/$dir" ]; then
    change "create ~/$dir" "created ~/$dir" mkdir -p "$HOME/$dir"
    [ "$dry_run" = 1 ] && continue
  fi
  if [ "$(stat -c %a "$HOME/$dir" 2>/dev/null || stat -f %Lp "$HOME/$dir")" != 700 ]; then
    change "make ~/$dir private" "made ~/$dir private" chmod 700 "$HOME/$dir"
  fi
done

# Whole-file targets are the quoted "~/..." keys of the [dotfiles] table.
awk '/^\[dotfiles\]/ { in_table = 1; next } /^\[/ { in_table = 0 } in_table && /^"~\// ' "$config" |
  awk -F'"' '{ print $2 }' |
  while IFS= read -r target; do
    path="$HOME/${target#\~/}"
    if [ -e "$path" ] && [ ! -L "$path" ]; then
      # Never overwrite an earlier backup: use .backup.1, .backup.2, ... instead.
      suffix=.backup
      n=1
      while [ -e "$path$suffix" ] || [ -L "$path$suffix" ]; do
        suffix=".backup.$n"
        n=$((n + 1))
      done
      change "back up $target to $target$suffix" "backed up $target to $target$suffix" \
        mv "$path" "$path$suffix"
    fi
  done
