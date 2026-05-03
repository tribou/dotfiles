# Neovim Plugin Install Ordering Fix

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix fresh-machine bootstrap failure where Neovim plugins are never installed because the vim-plug install block runs before `brew install neovim`.

**Architecture:** Move the existing vim-plug + `PlugInstall` block (bootstrap.sh:238-245) to after the brew install sections (~line 341), and add an explicit `command -v nvim` guard. No logic changes beyond reordering.

**Tech Stack:** bash, Neovim, vim-plug, goss (tests)

---

### Task 1: Move vim-plug install block to after brew installs

**Files:**
- Modify: `bootstrap.sh:238-245` (remove from here)
- Modify: `bootstrap.sh:341` (insert after this line)

**Step 1: Verify current state — confirm block is before brew**

Run: `grep -n "plug.vim\|brew install" bootstrap.sh | head -20`

Expected: vim-plug block lines (~238) appear before `brew install` lines (~280).

**Step 2: Remove the vim-plug block from its current location (lines 238-245)**

In `bootstrap.sh`, delete this block (currently after the `eslint_d` check):

```bash
  if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
  then
    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installing Neovim plugins"
    nvim --headless +"PlugInstall --sync" +qall
  fi
```

**Step 3: Insert updated block after the macOS brew cask section (after line 341 `fi`)**

Add after the macOS-only `fi` that closes the `if [[ "$OSTYPE" == "darwin"* ]]` brew cask block:

```bash
  # vim-plug + Neovim plugins — must run after brew installs neovim
  if command -v nvim &>/dev/null && [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
  then
    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installing Neovim plugins"
    nvim --headless +"PlugInstall --sync" +qall
  fi
```

**Step 4: Syntax-check bootstrap.sh**

Run: `bashcheck bootstrap.sh`

Expected: no errors

**Step 5: Commit**

```bash
git add bootstrap.sh
git commit -m "fix: install neovim plugins after brew installs neovim"
```

---

### Task 2: Verify goss tests already cover this

**Files:**
- Read: `goss.yaml:104-114`

**Step 1: Confirm goss assertions exist**

Run: `grep -n "plug.vim\|plugged" goss.yaml`

Expected output includes:
```
105:  /root/.local/share/nvim/site/autoload/plug.vim:
109:  /root/.local/share/nvim/plugged:
112:  /root/.local/share/nvim/plugged/CopilotChat.nvim:
```

If all three lines appear — no goss changes needed. The tests are already in place.

**Step 2: Run full test suite to confirm**

Run: `just test`

Expected: all tests pass, including the nvim plugin assertions.
