#!/usr/bin/env bash
set -euo pipefail

MISE_BIN="${MISE_BIN:-$(command -v mise)}"

case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) export PATH="/opt/homebrew/bin:$PATH" ;;
  Linux/*) export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" ;;
esac

"$MISE_BIN" bootstrap packages status --missing

run() {
  printf '==> %s\n' "$*"
  "$MISE_BIN" exec -- "$@"
}

run ansible-playbook --version
run nvim --version
run python --version
run python -c 'import pynvim'
run jq --version
run fd --version
run rg --version
run bat --version
run shellcheck --version
run lazydocker --version
run lazygit --version
run just --version
run tree-sitter --version
run fzf --version
run delta --version
run gh --version
run glow --version
run zoxide --version
run tmux -V
run prettier --version
run solargraph --version
