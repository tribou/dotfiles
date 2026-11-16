#!/usr/bin/env bash
# pre-dotfiles hook (see mise.toml): create the directories dotfiles live in,
# keep ~/.ssh and ~/.gnupg private, and move a pre-existing regular file at any
# managed [dotfiles] target to <target>.backup. mise refuses to replace files it
# did not write (short of --force-dotfiles, which would discard them), so this
# keeps the old bootstrap's back-up-then-link behaviour.
#
# Prints "changed: ..." for every change so CI can assert a clean second run.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
config="${1:-$repo/mise.toml}"

for dir in dev/bin dev/go/pkg dev/go/src/github.com/tribou .config/mise/conf.d \
  .local/bin .local/share/nvim/site/autoload .tmux; do
  mkdir -p "$HOME/$dir"
done

for dir in .ssh .gnupg; do
  if [ ! -d "$HOME/$dir" ]; then
    mkdir -p "$HOME/$dir"
    echo "changed: created ~/$dir"
  fi
  if [ "$(stat -c %a "$HOME/$dir" 2>/dev/null || stat -f %Lp "$HOME/$dir")" != 700 ]; then
    chmod 700 "$HOME/$dir"
    echo "changed: made ~/$dir private"
  fi
done

# Whole-file targets are the quoted "~/..." keys of the [dotfiles] table.
awk '/^\[dotfiles\]/ { in_table = 1; next } /^\[/ { in_table = 0 } in_table && /^"~\// ' "$config" |
  awk -F'"' '{ print $2 }' |
  while IFS= read -r target; do
    path="$HOME/${target#\~/}"
    if [ -e "$path" ] && [ ! -L "$path" ]; then
      mv -f "$path" "$path.backup"
      echo "changed: backed up $target to $target.backup"
    fi
  done
