# Brew on Linux Design

## Problem

`batcat` (and other tools) fail to install on Ubuntu because `bat` is not available in older apt repositories. The script falls back silently and the `batcat`→`bat` symlink never gets created.

## Solution

Use Homebrew as the primary package manager on all platforms (macOS and Linux), installing it automatically if missing. Keep apt/pacman only for installing brew prerequisites.

---

## Section 1: Prerequisites + Brew Auto-Install + Detection

```bash
# Install brew prerequisites on Linux
if [[ "$OSTYPE" != "darwin"* ]]; then
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm curl git base-devel
  fi
fi

# Install brew if not present (macOS and Linux)
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Package manager detection — prefer brew everywhere
if command -v brew &>/dev/null; then
  _PKG_MANAGER="brew"
elif command -v apt-get &>/dev/null; then
  _PKG_MANAGER="apt"
elif command -v pacman &>/dev/null; then
  _PKG_MANAGER="pacman"
fi
```

---

## Section 2: Unified Brew Package List

```bash
if [ "$_PKG_MANAGER" = "brew" ]; then
  brew install \
    git \
    neovim \
    python \
    bash-completion \
    zlib \
    hashicorp/tap/terraform-ls \
    nmap \
    go \
    elixir \
    ansible \
    htop \
    gpg \
    editorconfig \
    watchman \
    tree \
    awscli \
    ssh-copy-id \
    git-extras \
    jq \
    dos2unix \
    tidy-html5 \
    fd \
    ripgrep \
    bat \
    rename \
    navi \
    shellcheck \
    tldr \
    lazydocker \
    lazygit \
    just \
    lynx \
    tree-sitter-cli \
    fzf \
    tmux

  # macOS-only packages (not available in Linuxbrew or macOS-specific)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install \
      alacritty \
      ngrok/ngrok/ngrok \
      reattach-to-user-namespace \
      tfenv \
      tor \
      vimpager \
      renameutils \
      tmux-mem-cpu-load

    brew install --cask \
      cmake \
      1password \
      1password-cli \
      appcleaner \
      balenaetcher \
      bruno \
      firefox \
      imageoptim \
      orbstack \
      steam \
      font-fira-code-nerd-font \
      font-hack-nerd-font \
      font-fontawesome
  fi
fi
```

Key changes from previous apt approach:
- `bat` installs as `bat` everywhere — no `batcat` symlink needed
- `fd` installs as `fd` everywhere — no `fdfind` symlink needed
- `lazygit` and `neovim` handled by brew, removing apt special-case installs
- `fzf` and `tmux` moved into the brew block
- `tor`, `vimpager`, `renameutils`, `tmux-mem-cpu-load` moved to macOS guard (not available in Linuxbrew)
- `cmake` cask uses bare name (deprecated `homebrew/cask/cmake` form removed)
- `_PKG_MANAGER` wrapper removed — brew is unconditional

---

## Section 3: Blocks to Remove

- Standalone fzf install (was lines 236-241)
- Standalone tmux install (was lines 321-326)
- "Brew not installed, skipping" exit block (was lines 254-257)
- Full apt package install block (was lines 370-417): lazygit, neovim, fdfind/batcat symlinks
- Full pacman package install block (was lines 419-454)
- Fonts brew block (was lines 305-318) — merged into macOS cask section
- tfenv brew block (was lines 260-274) — merged into macOS-only brew installs
