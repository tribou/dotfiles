#!/bin/bash
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
export GOPATH="$HOME/dev/go"
mkdir -p "$GOPATH/bin"

export PATH="$HOME/.local/bin:$PATH"
MISE_BIN="$(type -P mise 2>/dev/null || true)"
if [ -z "$MISE_BIN" ] && [ -x "$HOME/.local/bin/mise" ]
then
  MISE_BIN="$HOME/.local/bin/mise"
fi

if [ -z "$MISE_BIN" ]
then
  curl https://mise.run | sh
  MISE_BIN="$HOME/.local/bin/mise"
fi

eval "$("$MISE_BIN" activate bash)"
mise use -g go@latest
eval "$("$MISE_BIN" env bash)"

GO_BIN_DIR="${GOBIN:-$GOPATH/bin}"
if [ ! -x "$GO_BIN_DIR/gopls" ]
then
  go install golang.org/x/tools/gopls@latest
fi

# Initialize bats submodules if not already done
if [ ! -f "$DOTFILES/tests/test_helper/bats-core/bin/bats" ]; then
  git -C "$DOTFILES" submodule update --init --recursive tests/test_helper/
fi

echo "==> Linking dotfiles configs..."
mkdir -p ~/.config/nvim
ln -sf "$DOTFILES/tmux/tmux-conf" ~/.tmux.conf
ln -sf "$DOTFILES/init.vim" ~/.config/nvim/init.vim
ln -sf "$DOTFILES/default-node-packages" ~/.default-node-packages
ln -sf "$DOTFILES/default-gems" ~/.default-gems
ln -sf "$DOTFILES/default-python-packages" ~/.default-python-packages

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
nvim --headless +PlugInstall +qall 2>/dev/null

echo "==> Installing CoC extensions..."
# CoC installs extensions via npm into ~/.config/coc/extensions/node_modules/.
# Running CocUpdateSync headlessly hangs because the CoC Node.js service never
# fully initializes without a real terminal. Install directly with npm instead —
# this is exactly what CoC does internally when you run :CocInstall.
mkdir -p ~/.config/coc/extensions
cd ~/.config/coc/extensions
[ -f package.json ] || echo '{"dependencies":{}}' > package.json
npm install --install-strategy=shallow --ignore-scripts --no-bin-links \
  coc-tsserver coc-pairs coc-css coc-highlight coc-json coc-git \
  coc-snippets coc-eslint coc-emoji coc-solargraph coc-yaml coc-html \
  coc-lists coc-svg \
  2>/dev/null
cd - > /dev/null

echo "==> Bootstrap complete."
touch ~/.dotfiles-bootstrap-done
