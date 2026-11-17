#!/usr/bin/env bash
# Symlink the repo's mise config into place, backing up a pre-existing regular
# file to <dest>.backup first, or to <dest>.backup.N when that already exists
# (same convention as scripts/bootstrap/pre_dotfiles.sh).
# Usage: link_mise_config.sh <src> <dest>
set -euo pipefail

src="$1"
dest="$2"

mkdir -p "$(dirname "$dest")"
if [ -e "$dest" ] && [ ! -L "$dest" ]; then
  backup="$dest.backup"
  n=1
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="$dest.backup.$n"
    n=$((n + 1))
  done
  mv "$dest" "$backup"
  printf 'Backed up existing %s to %s\n' "$dest" "$backup"
fi
ln -sfn "$src" "$dest"
