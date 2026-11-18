#!/bin/bash
set -euo pipefail

# Thin bootstrapper: install mise, link its global config, then hand off to
# `mise bootstrap`, which applies mise.toml (dotfiles, repos, hooks, the
# bootstrap task) and mise-config.toml (packages and tools). Extra arguments
# go to scripts/bootstrap/run.sh and on to `mise bootstrap` (e.g. --skip task).
# -n/--dry-run previews: no system packages, nothing applied, but it still
# installs mise, links its global config and, piped from curl, clones the repo.
# Piped from curl onto an existing clean checkout on main, it fast-forwards it.

REPO_URL="https://github.com/tribou/dotfiles.git"
REPO_DIR="$HOME/dev/dotfiles"

dry_run=0 # same test as scripts/bootstrap/run.sh
for arg in "$@"; do if [[ "$arg" =~ ^(--dry-run|-[yqvh]*n.*)$ ]]; then dry_run=1; fi; done

[ "$(uname -s)" != Darwin ] || xcode-select -p >/dev/null 2>&1 || # else git, clang and make are stubs
  { echo "bootstrap.sh: install the Xcode Command Line Tools first (xcode-select --install), then re-run." >&2; exit 1; }

# 1. Self-locate or self-clone (curl|bash has no script path, so it clones).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/mise.toml" ]; then
  cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  if [ "$dry_run" = 0 ] && [ "$(uname -s)" != "Darwin" ] && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl git ca-certificates
  fi
  mkdir -p "$HOME/dev"
  if [ ! -d "$REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
  elif [ "$dry_run" = 0 ] && [ "$(git -C "$REPO_DIR" branch --show-current)" = main ] &&
    [ -z "$(git -C "$REPO_DIR" status --porcelain --untracked-files=no)" ]; then # so curl|bash runs current code
    git -C "$REPO_DIR" pull --ff-only -q || echo "bootstrap.sh: could not fast-forward $REPO_DIR; running it as is" >&2
  else
    echo "bootstrap.sh: running $REPO_DIR as is (dry run, local changes, or not on main)" >&2
  fi
  cd "$REPO_DIR"
fi

./scripts/bootstrap/preflight.sh /opt/homebrew "$dry_run"

# 2. Linux prerequisites for installing mise and compiling tools.
if [ "$dry_run" = 0 ] && [ "$(uname -s)" != "Darwin" ]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential ca-certificates
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm curl git base-devel
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
  [ "$dry_run" = 0 ] || { echo "mise $current is older than the required $required; run $MISE_BIN self-update, then re-run" >&2; exit 1; }
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
./scripts/bootstrap/run.sh "$MISE_BIN" "$@"
./scripts/bootstrap/next_steps.sh /opt/homebrew/bin/bash "$dry_run"
