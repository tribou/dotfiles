#!/usr/bin/env bash
# Symlink the repo's mise config into place, backing up a pre-existing regular
# file to <dest>.backup first (same convention as roles/dotfiles/tasks/links.yml).
# Usage: link_mise_config.sh <src> <dest>
set -euo pipefail

src="$1"
dest="$2"

mkdir -p "$(dirname "$dest")"
if [ -e "$dest" ] && [ ! -L "$dest" ]; then
  mv "$dest" "$dest.backup"
  printf 'Backed up existing %s to %s.backup\n' "$dest" "$dest"
fi
ln -sfn "$src" "$dest"
