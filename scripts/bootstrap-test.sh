#!/bin/bash
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Linking dotfiles configs..."
mkdir -p ~/.config/nvim
ln -sf "$DOTFILES/tmux/tmux-conf" ~/.tmux.conf
ln -sf "$DOTFILES/init.vim" ~/.config/nvim/init.vim

echo "==> Installing TPM..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "==> Installing tmux plugins..."
# Clone plugins directly — TPM's install_plugins requires a live tmux session
# which is unreliable in a headless CI container. Direct clones are equivalent
# for asserting plugin presence; interactive TPM testing is via `just dev`.
_clone_plugin() {
  local name="$1" repo="$2"
  local dest="$HOME/.tmux/plugins/$name"
  if [ ! -d "$dest" ]; then
    git clone --depth 1 "https://github.com/$repo.git" "$dest"
  fi
}
_clone_plugin "tmux-sensible"        "tmux-plugins/tmux-sensible"
_clone_plugin "tmux-resurrect"       "tmux-plugins/tmux-resurrect"
_clone_plugin "tmux-mem-cpu-load"    "thewtex/tmux-mem-cpu-load"
_clone_plugin "tmux-copycat"         "tmux-plugins/tmux-copycat"
_clone_plugin "tmux-open"            "tmux-plugins/tmux-open"
_clone_plugin "tmux-yank"            "tmux-plugins/tmux-yank"
_clone_plugin "tmux-prefix-highlight" "tmux-plugins/tmux-prefix-highlight"

echo "==> Installing vim-plug..."
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "==> Installing Neovim plugins..."
nvim --headless +PlugInstall +qall 2>&1

echo "==> Bootstrap complete."
touch ~/.dotfiles-bootstrap-done
