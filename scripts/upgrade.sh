#!/usr/bin/env bash
# The `upgrade` mise task (`just upgrade`): upgrade the OS, mise packages and
# tools, bootstrap repos, then re-converge and update editor/tmux plugins.
# Optional self-updaters (rustup, claude, opencode, beads) never abort the run.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

step() { printf '==> %s\n' "$*"; }
optional() { "$@" || printf 'warning: %s failed; continuing\n' "$*" >&2; }

# Full OS upgrade, beyond the packages mise declares.
if command -v pacman >/dev/null 2>&1; then
  step "pacman upgrade"
  sudo pacman -Syu --noconfirm
elif command -v apt-get >/dev/null 2>&1; then
  step "apt upgrade"
  sudo apt-get update
  sudo apt-get upgrade -y
fi

step "mise bootstrap packages"
"$MISE_BIN" -C "$DOTFILES_REPO" bootstrap packages upgrade --yes
step "mise tools"
"$MISE_BIN" upgrade --yes
step "bootstrap repos (TPM, vim-plug)"
"$MISE_BIN" -C "$DOTFILES_REPO" bootstrap repos update
step "converge"
"$MISE_BIN" -C "$DOTFILES_REPO" bootstrap --yes

step "pynvim"
python -m pip install --upgrade pynvim
if command -v rustup >/dev/null 2>&1; then
  step "rustup"
  optional rustup self update
  optional rustup update
fi
step "Neovim plugins"
nvim --headless "+PlugUpdate --sync" +qall
step "tmux plugins"
tmux new-session -d -s _upgrade_tpm
tmux set-environment -t _upgrade_tpm -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
"$HOME/.tmux/plugins/tpm/bin/update_plugins" all
tmux kill-session -t _upgrade_tpm 2>/dev/null || true

for cli in claude opencode; do
  if command -v "$cli" >/dev/null 2>&1; then
    step "$cli"
    optional "$cli" upgrade
  fi
done
if command -v bd >/dev/null 2>&1; then
  step "beads"
  optional bd -C "$DOTFILES_REPO" dolt pull
fi
