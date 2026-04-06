# Brew on Linux Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Use Homebrew as the primary package manager on all platforms so tools like `bat` install correctly on Ubuntu.

**Architecture:** Replace the per-platform apt/pacman install blocks in `bootstrap.sh` with a single unified brew block. Add brew auto-install (with OS-specific prereqs) before package manager detection. Guard macOS-only packages with `$OSTYPE` checks.

**Tech Stack:** bash, Homebrew

---

### Task 1: Add Linux prereqs + brew auto-install

**Files:**
- Modify: `bootstrap.sh` (around line 243 — the `_PKG_MANAGER` detection block)

**Step 1: Replace the `_PKG_MANAGER` detection block**

Find this block (lines ~243-257):
```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    _PKG_MANAGER="brew"
  elif command -v apt-get &>/dev/null; then
    _PKG_MANAGER="apt"
  elif command -v pacman &>/dev/null; then
    _PKG_MANAGER="pacman"
  else
    echo "Unsupported package manager. Install packages manually."
    exit 1
  fi

  if [ "$_PKG_MANAGER" = "brew" ] && [ ! -s "$(which brew)" ]; then
    echo "Brew not installed. Skipping the rest of the installs"
    exit 0
  fi
```

Replace with:
```bash
  # Install brew prerequisites on Linux (needed before brew can install)
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

  # Brew is required — exit if still not available
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew installation failed. Install brew manually and re-run."
    exit 1
  fi

  _PKG_MANAGER="brew"
```

**Step 2: Verify syntax**

```bash
bashcheck bootstrap.sh
```
Expected: no errors

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "bootstrap: add brew auto-install for linux with prereqs"
```

---

### Task 2: Remove standalone fzf and tmux install blocks

**Files:**
- Modify: `bootstrap.sh`

**Step 1: Remove the standalone fzf install block** (~lines 236-241):
```bash
  if [ ! -s "$(which fzf)"  ]
  then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi
```
Delete it entirely — brew will handle fzf.

**Step 2: Remove the standalone tmux install block** (~lines 321-326):
```bash
  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ ! -s "$(which tmux)"  ]
    then
      echo "Installing tmux"
      brew install tmux
    fi
  fi
```
Delete it entirely — merged into the unified brew block.

**Step 3: Verify syntax**

```bash
bashcheck bootstrap.sh
```
Expected: no errors

**Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "bootstrap: remove standalone fzf and tmux installs"
```

---

### Task 3: Replace brew package list with unified cross-platform version

**Files:**
- Modify: `bootstrap.sh`

**Step 1: Replace the brew install block**

Find the existing brew block starting with:
```bash
  if [ "$_PKG_MANAGER" = "brew" ]; then
    brew install git \
```

And replace everything from that line through the end of the cask block (ending with `steam`) with:

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
      tor \
      gpg \
      editorconfig \
      watchman \
      tree \
      awscli \
      ssh-copy-id \
      git-extras \
      vimpager \
      jq \
      dos2unix \
      tidy-html5 \
      fd \
      ripgrep \
      bat \
      rename \
      navi \
      renameutils \
      shellcheck \
      tmux-mem-cpu-load \
      tldr \
      lazydocker \
      lazygit \
      just \
      lynx \
      tree-sitter-cli \
      fzf \
      tmux

    # macOS-only packages
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install \
        alacritty \
        ngrok/ngrok/ngrok \
        reattach-to-user-namespace \
        tfenv

      brew install --cask \
        homebrew/cask/cmake \
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

This replaces:
- The old brew install block
- The old tfenv block
- The old java/jenv blocks
- The old fonts block
- The old cask block

**Step 2: Verify syntax**

```bash
bashcheck bootstrap.sh
```
Expected: no errors

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "bootstrap: unify brew package list, guard macos-only packages"
```

---

### Task 4: Remove apt and pacman package install blocks

**Files:**
- Modify: `bootstrap.sh`

Note: apt/pacman are still used in the prereq block (Task 1) to install curl/git/build-essential
before brew. Only the package install blocks (which are now replaced by brew) get removed.

**Step 1: Remove the apt package install block**

Delete the entire `elif [ "$_PKG_MANAGER" = "apt" ]; then` block including:
- `sudo apt-get update` / `sudo apt-get install -y ...`
- fdfind/batcat symlink creation
- lazygit release download
- neovim release download

**Step 2: Remove the pacman package install block**

Delete the entire `elif [ "$_PKG_MANAGER" = "pacman" ]; then` block including:
- `sudo pacman -Syu ...`
- lazygit install via yay/release

**Step 3: Verify syntax**

```bash
bashcheck bootstrap.sh
```
Expected: no errors

**Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "bootstrap: remove apt and pacman package install blocks"
```

---

### Task 5: Verify final state

**Step 1: Check syntax one final time**

```bash
bashcheck bootstrap.sh
```
Expected: no errors

**Step 2: Run tests**

```bash
just test-unit
```
Expected: all pass

**Step 3: Review the full diff**

```bash
git diff main
```

Verify:
- No `batcat` or `fdfind` references remain (those were apt-only workarounds)
- No `_PKG_MANAGER="apt"` or `_PKG_MANAGER="pacman"` assignments remain
- The only apt/pacman usage is the prereq block (curl, git, build-essential)
- Brew install failure exits with a clear error message
- macOS-only packages are inside `[[ "$OSTYPE" == "darwin"* ]]` guard
- `bat`, `fd`, `fzf`, `tmux`, `lazygit`, `neovim` all in the unified brew block
