# Linux Compatibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make this dotfiles repo work on headless Ubuntu/Debian and Arch Linux servers without breaking existing macOS behavior.

**Architecture:** Inline OS guards using `[[ "$OSTYPE" == "darwin"* ]]` — the same pattern already used in `_shared.sh`, `bash_profile`, and `bootstrap.sh`. No new abstraction layers. Each macOS-specific call is either gated or replaced with a cross-platform equivalent.

**Tech Stack:** bash, tmux config, gitconfig — no new dependencies.

**Worktree:** `.worktrees/linux-compat` on branch `feature/linux-compat`

---

### Task 1: Fix tmux default-command (`tmux/tmux-conf`)

`reattach-to-user-namespace` is macOS-only. Without this fix, tmux cannot open new windows or panes on Linux.

**Files:**
- Modify: `tmux/tmux-conf:10` and `tmux/tmux-conf:12`

**Step 1: Open the file and locate the two lines**

`tmux/tmux-conf:10`:
```
set-environment -g PATH "/usr/local/bin:/bin:/usr/bin:/opt/c9/local/bin:/opt/homebrew/bin"
```

`tmux/tmux-conf:12`:
```
set-option -g default-command "reattach-to-user-namespace -l $SHELL"
```

**Step 2: Replace line 10 — add Linux Homebrew path**

Old:
```
set-environment -g PATH "/usr/local/bin:/bin:/usr/bin:/opt/c9/local/bin:/opt/homebrew/bin"
```
New:
```
set-environment -g PATH "/usr/local/bin:/bin:/usr/bin:/opt/c9/local/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin"
```

**Step 3: Replace line 12 — runtime OS check instead of hardcoded wrapper**

Old:
```
set-option -g default-command "reattach-to-user-namespace -l $SHELL"
```
New:
```
set-option -g default-command "if [ \"$(uname)\" = \"Darwin\" ]; then reattach-to-user-namespace -l $SHELL; else $SHELL; fi"
```

**Step 4: Verify no syntax errors**

```bash
bashcheck tmux/tmux-conf
```
Expected: no errors (note: tmux-conf is not a shell script so bashcheck may not apply — visually verify the edit looks correct)

**Step 5: Commit**

```bash
git add tmux/tmux-conf
git commit -m "Fix tmux default-command for Linux compatibility"
```

---

### Task 2: Remove dead `[gpg]` section from `gitconfig`

The hardcoded `/opt/homebrew/bin/gpg` path breaks git on Linux. GPG signing is already disabled (commented out), so the whole section is unused.

**Files:**
- Modify: `gitconfig:48-49`

**Step 1: Locate the section**

```
[gpg]
  program = /opt/homebrew/bin/gpg
```

**Step 2: Delete those two lines entirely**

The file around that area should go from:
```
[filter "omitsigningkey"]
  clean = sed -E '/signingkey = [A-Z0-9]+$/d'
[gpg]
  program = /opt/homebrew/bin/gpg
[pull]
	ff = only
```
To:
```
[filter "omitsigningkey"]
  clean = sed -E '/signingkey = [A-Z0-9]+$/d'
[pull]
	ff = only
```

**Step 3: Verify git still works**

```bash
git status
```
Expected: clean output, no errors.

**Step 4: Commit**

```bash
git add gitconfig
git commit -m "Remove hardcoded macOS GPG path from gitconfig"
```

---

### Task 3: Guard `notify` function for Linux (`lib/notify.sh`)

`osascript` doesn't exist on Linux. Without a guard, calling `notify` on Linux prints an error and returns 1, which can break scripts that call it.

**Files:**
- Modify: `lib/notify.sh:3-12`

**Step 1: Add early return at the top of the function**

Old (lines 3-12):
```bash
function notify ()
{

  local usage='Usage: notify [MESSAGE]'

  if [ ! $(which osascript) ]
  then
    echo "osascript needs to be installed and available"
    return 1
  fi
```

New:
```bash
function notify ()
{

  local usage='Usage: notify [MESSAGE]'

  [[ "$OSTYPE" != "darwin"* ]] && return 0

  if [ ! $(which osascript) ]
  then
    echo "osascript needs to be installed and available"
    return 1
  fi
```

**Step 2: Syntax check**

```bash
bashcheck lib/notify.sh
```
Expected: no errors.

**Step 3: Commit**

```bash
git add lib/notify.sh
git commit -m "Guard notify function — no-op on Linux"
```

---

### Task 4: Fix `lib/commands.sh` — direct `pbcopy` and `restart-docker`

Two issues: a direct `pbcopy` call that bypasses the cross-platform wrapper, and `restart-docker` using `osascript`/`open`.

**Files:**
- Modify: `lib/commands.sh:248` and `lib/commands.sh:546-560` (the `restart-docker` function)

**Step 1: Fix line 248 — replace direct `pbcopy` with wrapper**

Locate this block (around line 243-249):
```bash
  # If in tmux, we can use send-keys
  if [ -n "$TMUX" ]
  then
    tmux send-keys -t "$TMUX_PANE" "$RESULT"
  else
    echo "$RESULT"
    printf '%s' "$RESULT" | pbcopy
  fi
```

Change the last line:
```bash
  # If in tmux, we can use send-keys
  if [ -n "$TMUX" ]
  then
    tmux send-keys -t "$TMUX_PANE" "$RESULT"
  else
    echo "$RESULT"
    printf '%s' "$RESULT" | copy_to_clipboard
  fi
```

**Step 2: Fix `restart-docker` — add OS guard at top of function**

Locate the `restart-docker` function (around line 546):
```bash
function restart-docker ()
{
  printf "Restarting Docker service..."
  # Restart Docker app
  osascript -e 'quit app "Docker"' && open -a Docker
```

Add the guard as the first line of the function body:
```bash
function restart-docker ()
{
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "restart-docker is not supported on Linux. Use: sudo systemctl restart docker"
    return 1
  fi
  printf "Restarting Docker service..."
  # Restart Docker app
  osascript -e 'quit app "Docker"' && open -a Docker
```

**Step 3: Syntax check**

```bash
bashcheck lib/commands.sh
```
Expected: no errors.

**Step 4: Run tests**

```bash
make test
```
Expected: `✅ All tests passed!` (Docker test TTY failure is pre-existing, ignore it)

**Step 5: Commit**

```bash
git add lib/commands.sh
git commit -m "Fix pbcopy and restart-docker for Linux compatibility"
```

---

### Task 5: Fix `bash_profile` — Homebrew, ANDROID_HOME, terraform completion

Three independent changes to the main shell config.

**Files:**
- Modify: `bash_profile:109`, `bash_profile:114-115`, `bash_profile:266`

**Step 1: Add Linux Homebrew path (after line 109)**

Old:
```bash
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
```
New:
```bash
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

**Step 2: Guard ANDROID_HOME with OS check (lines 114-115)**

Old:
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
```
New:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
else
  export ANDROID_HOME=$HOME/Android/Sdk
fi
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
```

**Step 3: Fix terraform completion (line 266)**

Old:
```bash
[ -s "/opt/homebrew/bin/terraform" ] && complete -C /opt/homebrew/bin/terraform terraform
```
New:
```bash
[ -s "$(command -v terraform)" ] && complete -C "$(command -v terraform)" terraform
```

**Step 4: Syntax check**

```bash
bashcheck bash_profile
```
Expected: no errors.

**Step 5: Commit**

```bash
git add bash_profile
git commit -m "Fix bash_profile for Linux: Homebrew path, ANDROID_HOME, terraform completion"
```

---

### Task 6: Fix `zshrc` — terraform completion

Same hardcoded terraform path as bash_profile.

**Files:**
- Modify: `zshrc:15`

**Step 1: Replace the terraform completion line**

Old:
```bash
[ -s "/opt/homebrew/bin/terraform" ] && complete -o nospace -C /opt/homebrew/bin/terraform terraform
```
New:
```bash
[ -s "$(command -v terraform)" ] && complete -o nospace -C "$(command -v terraform)" terraform
```

**Step 2: Syntax check**

```bash
bashcheck zshrc
```
Expected: no errors.

**Step 3: Commit**

```bash
git add zshrc
git commit -m "Fix zshrc terraform completion path for Linux"
```

---

### Task 7: Fix `bootstrap.sh` — package manager detection and Linux installs

The biggest change. Add package manager detection and parallel apt/pacman install blocks alongside the existing brew blocks.

**Files:**
- Modify: `bootstrap.sh:138-142` (ssh-add), `bootstrap.sh:348-475` (install-deps block)

**Step 1: Fix `ssh-add -K` (lines 141-142)**

Old:
```bash
[ -f "$HOME/.ssh/id_rsa" ] && (ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1 || ssh-add "$HOME/.ssh/id_rsa")
[ -f "$HOME/.ssh/id_ed25519" ] && (ssh-add -K "$HOME/.ssh/id_ed25519" > /dev/null 2>&1 || ssh-add "$HOME/.ssh/id_ed25519")
```
New:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add -K "$HOME/.ssh/id_ed25519" > /dev/null 2>&1
else
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa"
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519"
fi
```

**Step 2: Add package manager detection block**

Replace the existing brew bail-out (lines 348-352):
```bash
  if [ ! -s "$(which brew)" ]
  then
    echo "Brew not installed. Skipping the rest of the installs"
    exit 0
  fi
```
With:
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

**Step 3: Gate brew-specific tfenv/java/jenv/font/tmux/brew-install blocks**

Wrap each brew-only block (from line ~354 to ~411) with:
```bash
if [ "$_PKG_MANAGER" = "brew" ]; then
  # ... existing brew block ...
fi
```

Specifically, these blocks need gating:
- tfenv install (lines ~354-367)
- java install (lines ~369-376)
- jenv install (lines ~378-392) — also fix the `java_home` line inside:
  ```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    jenv add "$(/usr/libexec/java_home)"
  else
    [ -n "$(which java)" ] && jenv add "$(dirname $(dirname $(readlink -f $(which java))))"
  fi
  ```
- fonts install (lines ~394-405)
- tmux install via brew (lines ~407-411)

**Step 4: Replace the big `brew install` block with OS-gated blocks**

Replace lines ~413-450 (`brew install git neovim ...`) with:

```bash
  if [ "$_PKG_MANAGER" = "brew" ]; then
    brew install git \
      alacritty \
      neovim \
      bash-completion \
      zlib \
      hashicorp/tap/terraform-ls \
      homebrew/core/nmap \
      homebrew/core/go \
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
      node@20 \
      navi \
      ngrok/ngrok/ngrok \
      renameutils \
      shellcheck \
      tmux-mem-cpu-load \
      reattach-to-user-namespace \
      tldr \
      lazydocker \
      lazygit \
      just

  elif [ "$_PKG_MANAGER" = "apt" ]; then
    sudo apt-get update
    sudo apt-get install -y \
      git \
      neovim \
      bash-completion \
      nmap \
      golang \
      htop \
      gnupg \
      tree \
      awscli \
      ssh-copy-id \
      jq \
      dos2unix \
      tidy \
      fd-find \
      ripgrep \
      bat \
      rename \
      shellcheck \
      tldr \
      just
    # lazygit — not in apt, install via release script
    if [ ! -s "$(which lazygit)" ]; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin
    fi

  elif [ "$_PKG_MANAGER" = "pacman" ]; then
    sudo pacman -Syu --noconfirm \
      git \
      neovim \
      bash-completion \
      nmap \
      go \
      htop \
      gnupg \
      tree \
      aws-cli \
      openssh \
      jq \
      dos2unix \
      tidy \
      fd \
      ripgrep \
      bat \
      perl-rename \
      shellcheck \
      tldr \
      just
    # lazygit — available in AUR; install via yay if present, else release script
    if [ ! -s "$(which lazygit)" ]; then
      if command -v yay &>/dev/null; then
        yay -S --noconfirm lazygit
      else
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin
      fi
    fi
  fi
```

**Step 5: Gate `brew install --cask` block (lines ~452-470) behind brew check**

Wrap the entire cask block:
```bash
  if [ "$_PKG_MANAGER" = "brew" ]; then
    brew install --cask \
      homebrew/cask/cmake \
      iterm2 \
      warp \
      # ... rest of casks unchanged
  fi
```

**Step 6: Syntax check bootstrap.sh**

```bash
bashcheck bootstrap.sh
```
Expected: no errors.

**Step 7: Run tests**

```bash
make test
```
Expected: `✅ All tests passed!`

**Step 8: Commit**

```bash
git add bootstrap.sh
git commit -m "Add Linux package manager support to bootstrap.sh"
```

---

### Task 8: Final verification

**Step 1: Run full test suite**

```bash
make test
```
Expected: `✅ All tests passed!`

**Step 2: Verify bash_profile sources without errors**

```bash
bash -n bash_profile
```
Expected: no output (no syntax errors).

**Step 3: Verify all modified shell files pass bashcheck**

```bash
bashcheck bash_profile lib/notify.sh lib/commands.sh bootstrap.sh zshrc
```
Expected: no errors.

**Step 4: Check git log looks clean**

```bash
git log --oneline feature/linux-compat ^main
```
Expected: 7 commits, one per task.
