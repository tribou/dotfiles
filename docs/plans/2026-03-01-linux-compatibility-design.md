# Linux Compatibility Design

**Date:** 2026-03-01
**Scope:** Server/headless Linux (no GUI, no clipboard, no notifications)
**Target distros:** Ubuntu/Debian (apt) + Arch (pacman)
**Approach:** Inline OS guards (`[[ "$OSTYPE" == "darwin"* ]]`) following existing repo patterns

---

## 1. `tmux/tmux-conf`

**PATH (line 10):** Add Linux Homebrew path:
```
set-environment -g PATH "/usr/local/bin:/bin:/usr/bin:/opt/c9/local/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin"
```

**`reattach-to-user-namespace` (line 12):** Replace hardcoded command with runtime OS check:
```
set-option -g default-command "if [ \"$(uname)\" = \"Darwin\" ]; then reattach-to-user-namespace -l $SHELL; else $SHELL; fi"
```

---

## 2. `bash_profile`

**Homebrew PATH (line 109):** Add Linux Homebrew alongside existing macOS check:
```bash
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

**`ANDROID_HOME` (line 114):** Wrap with OS check:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
else
  export ANDROID_HOME=$HOME/Android/Sdk
fi
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
```

**Terraform completion (line 266):** Replace hardcoded Homebrew path with `command -v`:
```bash
[ -s "$(command -v terraform)" ] && complete -C "$(command -v terraform)" terraform
```

Same fix applies to `zshrc:15`.

---

## 3. `lib/notify.sh`

Guard entire function body — no Linux equivalent for headless:
```bash
function notify () {
  [[ "$OSTYPE" != "darwin"* ]] && return 0
  # ... rest unchanged
```

---

## 4. `lib/commands.sh`

**Direct `pbcopy` call (line 248):** Replace with existing `copy_to_clipboard` wrapper (which already has `xclip` fallback):
```bash
printf '%s' "$RESULT" | copy_to_clipboard
```

**`restart-docker` (line 550):** Guard with OS check and print Linux instructions:
```bash
function restart-docker () {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "restart-docker is not supported on Linux. Use: sudo systemctl restart docker"
    return 1
  fi
  # ... rest unchanged
```

---

## 5. `gitconfig`

**Remove the `[gpg]` section entirely** (lines 48-49). GPG signing is disabled (`gpgsign` already commented out) so this block serves no purpose. Removing it also eliminates the hardcoded `/opt/homebrew/bin/gpg` path.

---

## 6. `bootstrap.sh --install-deps`

**Package manager detection** (add at top of `--install-deps` block):
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
```

**Linux package installs:** Gate the existing `brew install` blocks behind `[[ "$_PKG_MANAGER" == "brew" ]]`. Add parallel `apt` and `pacman` blocks with equivalent packages:

- Most packages have direct equivalents (`neovim`, `git`, `ripgrep`, `bat`, `jq`, `fzf`, `tmux`, `htop`, `tree`, `shellcheck`, `lazygit`, etc.)
- `reattach-to-user-namespace` — skip on Linux
- `lazydocker` / `lazygit` — install via their official release scripts (not in apt/pacman by default)
- All `brew install --cask` entries — skip on Linux (macOS GUI apps only)

**jenv Java home (line 389):** Wrap with OS check:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  jenv add "$(/usr/libexec/java_home)"
else
  [ -n "$(which java)" ] && jenv add "$(dirname $(dirname $(readlink -f $(which java))))"
fi
```

**`ssh-add -K` (lines 141-142):** Already has `|| ssh-add ...` fallback so non-fatal, but clean it up:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add -K "$HOME/.ssh/id_ed25519" > /dev/null 2>&1
else
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa"
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519"
fi
```

---

## Out of Scope

- Clipboard integration on Linux (headless — no `xclip` required)
- `notify` on Linux (no GUI notification system targeted)
- CI/testing for Linux (existing `.github/workflows/macos-tests.yml` unchanged)
