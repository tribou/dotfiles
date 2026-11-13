#!/bin/bash
set -euo pipefail

# Thin bootstrapper: install mise, link its global config, then hand off to
# `mise bootstrap`, which applies mise.toml (dotfiles, repos, hooks, the
# bootstrap task) and mise-config.toml (packages and tools). Extra arguments
# pass through to `mise bootstrap` (e.g. --skip task, --dry-run).

REPO_URL="https://github.com/tribou/dotfiles.git"
REPO_DIR="$HOME/dev/dotfiles"

# 1. Self-locate or self-clone (supports curl|bash).
if [ -f "$(dirname "${BASH_SOURCE[0]:-$0}")/mise.toml" ]; then
  cd "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
else
  if [ "$(uname -s)" != "Darwin" ] && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl git ca-certificates
  fi
  mkdir -p "$HOME/dev"
  [ -d "$REPO_DIR/.git" ] || git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 2. Linux prerequisites for installing mise and compiling tools.
if [ "$(uname -s)" != "Darwin" ]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential ca-certificates
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --noconfirm curl git base-devel
  fi
fi

# 3. Install mise, or update one older than the config's min_version.
MISE_BIN="$HOME/.local/bin/mise"
if [ ! -x "$MISE_BIN" ]; then
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
fi
required="$(awk -F'"' '/^min_version/ { print $2; exit }' mise-config.toml)"
current="$("$MISE_BIN" version | awk '{ print $1 }')"
if [ "$(printf '%s\n%s\n' "$required" "$current" | sort -V | head -1)" != "$required" ]; then
  "$MISE_BIN" self-update --yes
fi

# 4. Link the global config first: the packages step reads it before the
#    dotfiles step would link it.
./scripts/link_mise_config.sh "$PWD/mise-config.toml" "$HOME/.config/mise/config.toml"
export PATH="$HOME/.local/bin:$PATH"
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) export PATH="/opt/homebrew/bin:$PATH" ;;
  Linux/*) export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" ;;
esac

# 5. Converge.
"$MISE_BIN" trust "$PWD/mise.toml"
"$MISE_BIN" -C "$PWD" bootstrap --yes "$@"

cat <<'EOF'

Done. Open a new login shell (or: exec $SHELL -l) so mise/gpg-agent/brew/cargo
PATH take effect.
EOF
