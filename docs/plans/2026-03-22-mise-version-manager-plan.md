# mise Version Manager Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace rbenv (Ruby) and nvm (Node) with mise in dotfiles, preserving all auto-switching behavior.

**Architecture:** Remove the rbenv and nvm shell init blocks from `bash_profile`, replace with a single `eval "$(mise activate bash)"` line. Remove install blocks from `bootstrap.sh`, add a universal mise install block. Update `goss.yaml` to assert mise is present.

**Tech Stack:** bash, mise, bootstrap.sh, goss.yaml

**Worktree:** `.worktrees/mise-migration` (branch: `feature/mise-migration`)

---

## Task 1: Replace rbenv + nvm blocks in `bash_profile` with mise activation

**Files:**
- Modify: `bash_profile:151-165`

**Step 1: Remove rbenv block and nvm block, add mise**

In `bash_profile`, replace lines 151-165:

```bash
# ruby rbenv
[ -f "$HOME/.rbenv/bin/rbenv" ] && export PATH=$PATH:$HOME/.rbenv/bin
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

_dotfiles_debug_timing "$LINENO"

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && source "$NVM_DIR/nvm.sh" --no-use # This loads nvm
_dotfiles_debug_timing "$LINENO"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
_dotfiles_debug_timing "$LINENO"
[ "$(type -t nvm 2>/dev/null)" = "function" ] && export HAS_NVM=true || unset HAS_NVM
# _dotfiles_debug_timing "$LINENO"
[ -n "$HAS_NVM" ] && nvm use --delete-prefix default --silent
```

With:

```bash
# mise — manages Ruby, Node, and other runtime versions
[ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
[ -x "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate bash)"
```

**Step 2: Run unit tests to verify no regressions**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git commit -m "Replace rbenv + nvm shell init with mise activation"
```

---

## Task 2: Remove `use_node_version` / `read_node_version` and update PS1

**Files:**
- Modify: `bash_profile:170` (PS1)
- Modify: `bash_profile:303-340` (functions + PROMPT_COMMAND)

**Step 1: Update PS1 — remove `nvm current`**

Find line 170:
```bash
export PS1="\[\033[0;34m\]\W \$(declare -f nvm > /dev/null 2>&1 && nvm current) \$(get_git_location) > \[$(tput sgr0)\]"
```

Replace with:
```bash
export PS1="\[\033[0;34m\]\W \$(get_git_location) > \[$(tput sgr0)\]"
```

**Step 2: Remove `use_node_version` function, `read_node_version` function, and its PROMPT_COMMAND line**

Remove lines 303-340:
```bash
## Setup PROMPT_COMMAND
# Activate a version of Node that is read from a text file via NVM
function use_node_version()
{
  local TEXT_FILE_NAME="$1"
  local CURRENT_VERSION=$([ -n "$HAS_NVM" ] && nvm current)
  local PROJECT_VERSION=$([ -n "$HAS_NVM" ] && nvm version $(cat "$TEXT_FILE_NAME"))
  # If the project file version is different than the current version
  if [ "$CURRENT_VERSION" != "$PROJECT_VERSION" ]
  then
    [ -n "$HAS_NVM" ] && nvm use "$PROJECT_VERSION"
  fi
}

# Read the .nvmrc and switch nvm versions if exists upon dir changes
function read_node_version()
{
  # Only run if we actually changed directories
  if [ "$PWD" != "$READ_NODE_VERSION_PREV_PWD" ]
	then
    export READ_NODE_VERSION_PREV_PWD="$PWD";

    # If there's an .nvmrc here
    if [ -e ".nvmrc" ]
		then
      use_node_version ".nvmrc"
      return
    fi

    # If there's a .node-version here
    if [ -e ".node-version" ]
		then
      use_node_version ".node-version"
      return
    fi
  fi
}
[[ $PROMPT_COMMAND != *"read_node_version"* ]] && export PROMPT_COMMAND="$PROMPT_COMMAND read_node_version ;"
```

mise's shell hook (installed by `eval "$(mise activate bash)"`) replaces all of this automatically.

**Step 3: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 4: Commit**

```bash
git commit -m "Remove use_node_version/read_node_version — mise handles auto-switching natively"
```

---

## Task 3: Replace nvm + rbenv install blocks in `bootstrap.sh` with mise

**Files:**
- Modify: `bootstrap.sh:181-206` (nvm install)
- Modify: `bootstrap.sh:248-263` (rbenv install)

**Step 1: Remove nvm install block (lines 181-206)**

Remove:
```bash
    if [ ! -d "$HOME/.nvm" ]
    then
      _BOOTSTRAP_INSTALL="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash"
      echo "Installing nvm:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
    fi
    if [ ! -n "$(command -v nvm)" ]
    then
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh"  ] && source "$NVM_DIR/nvm.sh" # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    fi
    echo

    if [ -n "$(command -v nvm)" ] && [ ! -n "$(nvm ls 24 | grep 24)" ]
    then
      echo "Installing node 24:"
      echo
      nvm install 24
      nvm alias default 24
      nvm use 24
      npm-install-global
      echo
    fi
```

Replace with:
```bash
    if [ ! -x "$HOME/.local/bin/mise" ]
    then
      echo "Installing mise:"
      curl https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
      eval "$("$HOME/.local/bin/mise" activate bash)"
      echo
    fi

    if [ -x "$HOME/.local/bin/mise" ]
    then
      mise use -g node@lts
      mise use -g ruby@3
      echo
    fi
```

**Step 2: Remove rbenv install block (lines 248-263)**

Remove:
```bash
  if [ ! -d "$HOME/.rbenv/bin" ] && [ ! -s "$(which rbenv)"  ]
  then
    echo "Installing rbenv"
    curl -fsSL https://raw.githubusercontent.com/rbenv/rbenv-installer/HEAD/bin/rbenv-installer | bash
    eval "$(rbenv init -)"
  fi

  if [ -z "$(ls -A $HOME/.rbenv/versions/)" ]
  then
    echo "Installing latest ruby version"
    rbenv install "$(rbenv install -l | grep -v - | tail -1)"
    rbenv global "$(rbenv install -l | grep -v - | tail -1)"
    echo "Installing React Native ruby version"
    rbenv install 2.7.6
    rbenv global 2.7.6
  fi
```

(No replacement — mise install block above already handles Ruby.)

**Step 3: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 4: Commit**

```bash
git commit -m "Replace nvm + rbenv bootstrap installs with mise"
```

---

## Task 4: Add Ruby build deps to Ubuntu apt block in `bootstrap.sh`

**Files:**
- Modify: `bootstrap.sh:406-428` (apt-get install block)

**Step 1: Add Ruby build dependencies**

Find the `apt-get install -y` block (around line 406). Add to the list:

```bash
      libssl-dev \
      libreadline-dev \
      zlib1g-dev \
      libyaml-dev \
```

Place after `build-essential` (line 427), before `xdg-utils`.

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git commit -m "Add Ruby build deps to Ubuntu apt block for mise ruby compilation"
```

---

## Task 5: Update `goss.yaml` — add mise assertion, update nvm comment

**Files:**
- Modify: `goss.yaml:17-21`

**Step 1: Update node comment and add mise assertion**

Find lines 17-21:
```yaml
  # Node.js must be v24 (matches bootstrap.sh / nvm default)
  "node --version":
    exit-status: 0
    stdout:
      - /^v24\./
```

Replace with:
```yaml
  # Node.js must be v24 (matches bootstrap.sh / mise default: node@lts)
  "node --version":
    exit-status: 0
    stdout:
      - /^v24\./

  # mise must be installed and functional
  "mise --version":
    exit-status: 0
    stdout:
      - /mise/
```

**Step 2: Run unit tests**

Run: `just test-unit`
Expected: 49 tests, 0 failures

**Step 3: Commit**

```bash
git commit -m "Update goss.yaml: replace nvm assertion with mise"
```

---

## Task 6: Full integration test

**Step 1: Run full test suite (includes Docker)**

Run: `just test`

This rebuilds the Docker image, runs bootstrap.sh inside it, then runs goss assertions. This is the end-to-end validation that mise installs correctly and node/ruby are available.

Expected: All assertions passing including `mise --version` and `node --version`.

**Step 2: If tests pass, you're done**

The branch is ready for review. See the design doc at `docs/plans/2026-03-22-mise-version-manager-design.md` for background.
