#!/bin/bash
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
export GOPATH="${GOPATH:-$HOME/dev/go}"
export PATH="$HOME/.local/bin:$HOME/dev/go/bin:$HOME/.local/share/mise/shims:$PATH"

# Activate mise (tools already installed in image)
eval "$(mise activate bash)"
eval "$(mise env bash)"

# Initialize bats submodules if not already done
if [ ! -f "$DOTFILES/tests/test_helper/bats-core/bin/bats" ]; then
  git -C "$DOTFILES" submodule update --init --recursive tests/test_helper/
fi

# Idempotent symlinks (already in image, but safe for local dev outside Docker)
mkdir -p ~/.config/nvim ~/.config/mise
ln -sf "$DOTFILES/tmux/tmux-conf" ~/.tmux.conf
ln -sf "$DOTFILES/init.vim" ~/.config/nvim/init.vim
ln -sf "$DOTFILES/default-node-packages" ~/.default-node-packages
ln -sf "$DOTFILES/default-gems" ~/.default-gems
ln -sf "$DOTFILES/default-python-packages" ~/.default-python-packages
ln -sf "$DOTFILES/mise-config.toml" ~/.config/mise/config.toml

# Silence GNU parallel citation notice
mkdir -p ~/.parallel && touch ~/.parallel/will-cite

echo "==> Bootstrap complete."
touch ~/.dotfiles-bootstrap-done
