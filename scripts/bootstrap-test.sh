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
tmux new-session -d -s bootstrap 2>/dev/null || true
~/.tmux/plugins/tpm/bin/install_plugins
tmux kill-session -t bootstrap 2>/dev/null || true

echo "==> Installing vim-plug..."
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "==> Installing Neovim plugins..."
nvim --headless +PlugInstall +qall 2>&1

echo "==> Bootstrap complete."
touch ~/.dotfiles-bootstrap-done
