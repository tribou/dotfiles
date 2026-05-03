# Mise Tool Version Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove Elixir from Homebrew (no longer managed globally — use per-project mise), and version-control remaining mise tool versions (node/ruby/go) via a symlinked `mise-config.toml`.

**Architecture:** Create `mise-config.toml` in the dotfiles repo and symlink it to `~/.config/mise/config.toml`. This makes all mise tool versions tracked in git. Remove `mise use -g` imperative calls from bootstrap.sh and replace with `mise install` (reads from config). Remove `elixir` from the Homebrew install list.

**Tech Stack:** bash, mise, Homebrew, goss (tests)

---

### Task 1: Create `mise-config.toml`

**Files:**
- Create: `mise-config.toml`

**Step 1: Create the file**

```toml
[tools]
node = "lts"
ruby = "3"
go = "latest"
erlang = "28"
elixir = "1.19.5-otp-28"

[settings]
legacy_version_file = true
```

**Step 2: Verify syntax is valid TOML**

Run: `cat mise-config.toml`
Expected: file prints cleanly with no issues

**Step 3: Commit**

```bash
git add mise-config.toml
git commit -m "Add mise-config.toml with pinned tool versions including erlang/elixir"
```

---

### Task 2: Symlink `mise-config.toml` in `bootstrap.sh`

**Files:**
- Modify: `bootstrap.sh:109-116` (after the alacritty config block, before `.config/nvim/coc-settings.json`)

**Step 1: Add the symlink block**

After the alacritty block (line ~112), add:

```bash
# .config/mise/config.toml
mkdir -p ~/.config/mise
backupFile ".config/mise/config.toml"
linkFileToHome "mise-config.toml" ".config/mise/config.toml"
```

**Step 2: Check bash syntax**

Run: `bashcheck bootstrap.sh`
Expected: no errors

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "Symlink mise-config.toml to ~/.config/mise/config.toml in bootstrap"
```

---

### Task 3: Replace `mise use -g` calls with `mise install` in `bootstrap.sh`

**Files:**
- Modify: `bootstrap.sh` (lines ~203-213)

**Step 1: Replace the mise install block**

Current code (lines ~203-213):
```bash
if [ -x "$MISE_BIN" ]
then
  eval "$("$MISE_BIN" activate bash)"
  mise use -g node@lts
  # Try precompiled ruby first (fast), fall back to source compilation
  if ! MISE_RUBY_COMPILE=0 mise use -g ruby@3 2>/dev/null; then
    echo "No precompiled ruby available for this platform, compiling from source..."
    mise use -g ruby@3
  fi
  mise use -g go@latest
  echo
fi
```

Replace with:
```bash
if [ -x "$MISE_BIN" ]
then
  eval "$("$MISE_BIN" activate bash)"
  # Install all tools from mise-config.toml (symlinked to ~/.config/mise/config.toml)
  mise install node go erlang elixir
  # Try precompiled ruby first (fast), fall back to source compilation
  if ! MISE_RUBY_COMPILE=0 mise install ruby 2>/dev/null; then
    echo "No precompiled ruby available for this platform, compiling from source..."
    mise install ruby
  fi
  echo
fi
```

**Step 2: Check bash syntax**

Run: `bashcheck bootstrap.sh`
Expected: no errors

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "Replace mise use -g calls with mise install (versions now in mise-config.toml)"
```

---

### Task 4: Remove `elixir` from Homebrew install list in `bootstrap.sh`

**Files:**
- Modify: `bootstrap.sh:283`

**Step 1: Remove the elixir line**

Find the `brew install` block (~line 275). Remove:
```
      elixir \
```

**Step 2: Check bash syntax**

Run: `bashcheck bootstrap.sh`
Expected: no errors

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "Remove elixir from Homebrew installs (now managed by mise)"
```

---

### Task 5: Add goss assertions for mise config symlink and elixir

**Files:**
- Modify: `goss.yaml`

**Step 1: Add symlink assertion**

In the `file:` section of `goss.yaml`, after the existing default-packages symlink entries (~line 73), add:

```yaml
  /root/.config/mise/config.toml:
    exists: true
    filetype: symlink
```

**Step 2: Add elixir version assertion**

In the `command:` section, after the `mise --version` entry (~line 26), add:

```yaml
  # Elixir must be available via mise (replacing homebrew elixir)
  "elixir --version":
    exit-status: 0
    stdout:
      - /Elixir 1\.19/
```

**Step 3: Run the tests**

Run: `just test-unit`
Expected: passes (elixir/erlang won't be in Docker env, so goss test for elixir may be skipped or fail in Docker — that's expected until the Docker image installs via mise)

**Step 4: Commit**

```bash
git add goss.yaml
git commit -m "Add goss assertions for mise config symlink and elixir version"
```

---

### Task 6: Verify end-to-end locally

**Step 1: Symlink the config manually (simulate bootstrap)**

```bash
mkdir -p ~/.config/mise
ln -sf "$(pwd)/mise-config.toml" ~/.config/mise/config.toml
```

**Step 2: Verify mise sees the tools**

Run: `mise ls --current`
Expected: shows erlang 28, elixir 1.19.5-otp-28, node lts, ruby 3, go latest

**Step 3: Install erlang and elixir**

Run: `mise install erlang elixir`
Expected: downloads and installs both

**Step 4: Verify elixir works**

Run: `elixir --version`
Expected: `Elixir 1.19.x (compiled with Erlang/OTP 28)`
