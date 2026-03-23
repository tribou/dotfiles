# mise Default Packages Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `default-node-packages`, `default-gems`, and `default-python-packages` dotfiles so mise auto-installs global packages after each runtime installation, replacing manual install blocks in `bootstrap.sh`.

**Architecture:** Create three new dotfiles in the repo root, symlink them into `~` via `bootstrap.sh`'s existing `linkFileToHome` pattern, remove the now-redundant manual gem and pip install blocks, and add goss symlink assertions.

**Tech Stack:** bash, mise, goss

**Worktree:** `.worktrees/mise-default-packages` (branch: `feature/mise-default-packages`)

---

## Task 1: Create `default-node-packages`

**Files:**
- Create: `default-node-packages`

**Step 1: Create the file**

Create `/Users/tribou/dev/dotfiles/.worktrees/mise-default-packages/default-node-packages` with this exact content (one package per line, no version pins):

```
eas-cli
eslint_d
editorconfig
intelephense
js-yaml
jsonlint
neovim
prettier
react-devtools
nodemon
tern
tslint
typescript
bash-language-server
flow-bin
vue-language-server
vscode-css-languageserver-bin
vscode-html-languageserver-bin
```

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git add default-node-packages
git commit -m "Add default-node-packages for mise auto-install"
```

---

## Task 2: Create `default-gems`

**Files:**
- Create: `default-gems`

**Step 1: Create the file**

Create `/Users/tribou/dev/dotfiles/.worktrees/mise-default-packages/default-gems` with this exact content:

```
neovim
solargraph
```

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git add default-gems
git commit -m "Add default-gems for mise auto-install"
```

---

## Task 3: Create `default-python-packages`

**Files:**
- Create: `default-python-packages`

**Step 1: Create the file**

Create `/Users/tribou/dev/dotfiles/.worktrees/mise-default-packages/default-python-packages` with this exact content:

```
pynvim
```

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git add default-python-packages
git commit -m "Add default-python-packages for mise auto-install"
```

---

## Task 4: Add symlinks in `bootstrap.sh` and remove manual install blocks

**Files:**
- Modify: `bootstrap.sh:60-79` (symlink section — add three new linkFileToHome calls)
- Modify: `bootstrap.sh:238-249` (gem install block — remove entirely)
- Modify: `bootstrap.sh:477-482` (pip install block — remove entirely)

**Step 1: Add symlink calls**

In `bootstrap.sh`, after the existing `.tmux.conf` symlink block (around line 78), add:

```bash
# mise default packages
linkFileToHome "default-node-packages" ".default-node-packages"
linkFileToHome "default-gems" ".default-gems"
linkFileToHome "default-python-packages" ".default-python-packages"
```

**Step 2: Remove the gem install block**

Find and remove this block (lines 238-249):
```bash
  if  [ -s "$(which gem)"  ] && [ -z "$(gem list -i "^neovim$")" ]
  then
    _BOOTSTRAP_INSTALL="gem install neovim solargraph --no-document"
    echo "Installing gems:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    echo
  else
    echo "gem not available or neovim already installed. Skipping..."
    echo
  fi
```

**Step 3: Remove the pynvim pip install block**

Find and remove this block (lines 477-482):
```bash
  # pynvim (Neovim Python support)
  if [ -s "$(which python3)" ] && ! python3 -c "import pynvim" &>/dev/null
  then
    echo "Installing pynvim"
    pip3 install --user pynvim
  fi
```

**Step 4: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 5: Commit**

```bash
git commit -am "Add mise default package symlinks; remove manual gem/pip install blocks"
```

---

## Task 5: Add goss symlink assertions

**Files:**
- Modify: `goss.yaml` (file assertions section)

**Step 1: Add three symlink assertions**

In `goss.yaml`, in the `file:` section (after the existing vim file assertions), add:

```yaml
  # mise default packages files must be symlinked
  /root/.default-node-packages:
    exists: true
    filetype: symlink
  /root/.default-gems:
    exists: true
    filetype: symlink
  /root/.default-python-packages:
    exists: true
    filetype: symlink
```

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git commit -am "Add goss assertions for mise default package symlinks"
```

---

## Task 6: Full integration test

**Step 1: Run full Docker test suite**

Run: `just test`

This rebuilds the Docker image, runs `bootstrap.sh` inside it, then validates goss assertions.

Expected: All assertions passing, including the three new symlink assertions.

Note: goss checks `filetype: symlink` — the `bootstrap-test.sh` CI script does NOT call `bootstrap.sh`, so the symlinks won't be created by it. The symlink assertions need to be added to `bootstrap-test.sh` OR the goss file assertions should use `exists: true` only (without `filetype: symlink`).

Check `scripts/bootstrap-test.sh` — if it doesn't call `linkFileToHome`, change the goss assertions to just `exists: true` and add the symlink creation to `bootstrap-test.sh` instead.

**Step 2: If tests pass, done.**
