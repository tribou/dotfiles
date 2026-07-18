#!/bin/bash
set -euo pipefail

# Thin bootstrapper: solve the chicken-and-egg of installing brew + ansible,
# then hand off to the Ansible role. Everything else lives in roles/dotfiles/.

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

# 3. Install brew (if missing), then ansible, then exec the playbook.
if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ "$(uname -s)" = "Darwin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

command -v ansible-playbook >/dev/null 2>&1 || brew install ansible

echo "==> Handing off to Ansible (ansible-playbook playbook.yml)"
# Pin ANSIBLE_CONFIG to this repo's own config so a stale/unrelated
# ANSIBLE_CONFIG in the invoking shell (highest precedence in Ansible's
# config search order) can't shadow this repo's inventory.
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook playbook.yml "$@"

cat <<'EOF'

Done. Open a new login shell (or: exec $SHELL -l) so mise/gpg-agent/brew/cargo
PATH take effect. (This restart requirement is unchanged from the old bootstrap.)
EOF
