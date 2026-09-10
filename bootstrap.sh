#!/bin/bash
set -euo pipefail

# Thin bootstrapper: install mise, then hand off to the Ansible role.
# Everything else lives in roles/dotfiles/.

REPO_URL="https://github.com/tribou/dotfiles.git"
REPO_DIR="$HOME/dev/dotfiles"

# 1. Self-locate or self-clone (supports curl|bash).
if [ -f "$(dirname "${BASH_SOURCE[0]:-$0}")/playbook.yml" ]; then
  cd "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
else
  if [ "$(uname -s)" != "Darwin" ] && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl git ca-certificates
  fi
  mkdir -p "$HOME/dev"
  [ -d "$REPO_DIR/.git" ] || git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 2. Linux brew-bootstrap prerequisites (C toolchain before brew can build).
if [ "$(uname -s)" != "Darwin" ]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential ca-certificates
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --noconfirm curl git base-devel
  fi
fi

# 3. Install mise, apply its host packages, then install and verify tools.
MISE_BIN="$HOME/.local/bin/mise"

install_mise() {
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
}

if [ ! -x "$MISE_BIN" ] || ! "$MISE_BIN" bootstrap packages --help >/dev/null 2>&1; then
  install_mise
fi
if ! "$MISE_BIN" bootstrap packages --help >/dev/null 2>&1; then
  printf 'error: mise does not support bootstrap packages after reinstall\n' >&2
  exit 1
fi

mkdir -p "$HOME/.config/mise"
ln -sfn "$PWD/mise-config.toml" "$HOME/.config/mise/config.toml"
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) export PATH="/opt/homebrew/bin:$PATH" ;;
  Linux/*) export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" ;;
esac
"$MISE_BIN" bootstrap packages apply --yes
"$MISE_BIN" install --yes
MISE_BIN="$MISE_BIN" ./scripts/verify_mise_tools.sh
"$MISE_BIN" exec -- ansible-galaxy collection install -r requirements.yml
echo "==> Handing off to Ansible (mise exec -- ansible-playbook playbook.yml)"
# Pin ANSIBLE_CONFIG to this repo's own config so a stale/unrelated
# ANSIBLE_CONFIG in the invoking shell (highest precedence in Ansible's
# config search order) can't shadow this repo's inventory.
ANSIBLE_CONFIG="$PWD/ansible.cfg" "$MISE_BIN" exec -- ansible-playbook playbook.yml "$@"

cat <<'EOF'

Done. Open a new login shell (or: exec $SHELL -l) so mise/gpg-agent/brew/cargo
PATH take effect. (This restart requirement is unchanged from the old bootstrap.)
EOF
