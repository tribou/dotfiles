# Git Worktree Helper Commands Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `wtc`, `wt`, and `wtd` shell functions to `lib/commands.sh` for creating, switching, and deleting git worktrees stored in `.worktrees/`.

**Architecture:** Three shell functions added alongside existing git helpers (`gbd`, `gpsu`, etc.) in `lib/commands.sh`. `wtc` creates a branch+worktree and `cd`s in. `wt` uses fzf to pick and `cd` into a worktree. `wtd` removes a worktree and deletes its branch, reusing `_dotfiles_prompt_git_branch_delete` for force-delete prompting.

**Tech Stack:** bash, git worktree, fzf, bats (for tests)

---

### Task 1: Write failing tests for `wtc`

**Files:**
- Create: `tests/worktree_commands.bats`

**Step 1: Write the failing test file**

```bash
setup() {
  load 'test_helper/common_setup'
  common_setup

  # Create a temp git repo for worktree tests
  TEMP_REPO=$(mktemp -d)
  git -C "$TEMP_REPO" init -q
  git -C "$TEMP_REPO" commit --allow-empty -m "init"
  cd "$TEMP_REPO"
}

teardown() {
  rm -rf "$TEMP_REPO"
}

@test "wtc: errors with no argument" {
  run wtc
  assert_failure
  assert_output --partial "Usage"
}

@test "wtc: errors outside a git repo" {
  cd /tmp
  run wtc some-branch
  assert_failure
  assert_output --partial "git repository"
}

@test "wtc: creates worktree and branch" {
  run wtc my-feature
  assert_success
  assert [ -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  assert_output --partial "my-feature"
}

@test "wtc: adds .worktrees/ to .gitignore" {
  run wtc my-feature
  assert_success
  run grep -F '.worktrees/' .gitignore
  assert_success
}

@test "wtc: does not duplicate .worktrees/ in .gitignore on second call" {
  wtc my-feature
  git worktree remove .worktrees/my-feature
  git branch -D my-feature
  wtc other-feature
  run grep -cF '.worktrees/' .gitignore
  assert_output "1"
}

@test "wtc: errors if branch already exists" {
  git branch my-feature
  run wtc my-feature
  assert_failure
}

@test "wtd: removes worktree and branch" {
  wtc my-feature
  cd "$TEMP_REPO"
  run wtd my-feature
  assert_success
  assert [ ! -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  refute_output --partial "my-feature"
}

@test "wt, wtc, wtd: all functions are defined" {
  run bash -c 'type wtc'
  assert_success
  run bash -c 'type wt'
  assert_success
  run bash -c 'type wtd'
  assert_success
}
```

**Step 2: Run tests to verify they fail**

```bash
just test-unit 2>&1 | grep -A 3 "worktree"
```

Expected: test file not found or functions not defined errors.

**Step 3: Commit the test file**

```bash
git add tests/worktree_commands.bats
git commit -m "Add failing tests for wtc, wt, wtd worktree commands"
```

---

### Task 2: Implement `wtc`

**Files:**
- Modify: `lib/commands.sh` — add after the `gbd` function (around line 237)

**Step 1: Add `wtc` to `lib/commands.sh` after the `gbd` block**

Find the line `function gpsu ()` (currently ~line 238) and insert before it:

```bash
function wtc ()
{
  if [ -z "$1" ]
  then
    echo "Usage: wtc <branch-name>" >&2
    return 1
  fi

  local BRANCH="$1"
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
  local GITIGNORE="$REPO_ROOT/.gitignore"

  if ! grep -qF '.worktrees/' "$GITIGNORE" 2>/dev/null
  then
    echo '.worktrees/' >> "$GITIGNORE"
    echo "Added .worktrees/ to .gitignore"
  fi

  git worktree add -b "$BRANCH" "$WORKTREE_PATH" && cd "$WORKTREE_PATH"
}

```

**Step 2: Run bash syntax check**

```bash
bashcheck lib/commands.sh
```

Expected: no errors.

**Step 3: Run wtc-related tests**

```bash
just test-unit 2>&1 | grep -E "(wtc|worktree)"
```

Expected: `wtc` tests pass, `wt`/`wtd` tests still fail.

**Step 4: Commit**

```bash
git add lib/commands.sh
git commit -m "Add wtc: create git worktree in .worktrees/"
```

---

### Task 3: Implement `wt`

**Files:**
- Modify: `lib/commands.sh` — add after `wtc`

**Step 1: Add `wt` after `wtc`**

```bash
function wt ()
{
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local RESULT
  RESULT=$(git worktree list | tail -n +2 | fzf --preview-window wrap --color)

  if [ -n "$RESULT" ]
  then
    cd "$(echo "$RESULT" | awk '{print $1}')"
  fi
}

```

Note: `git worktree list` output format is:
```
/path/to/repo           abc1234 [main]
/path/to/repo/.worktrees/AB-123/feature  def5678 [AB-123/feature]
```
`tail -n +2` skips the main worktree (always listed first). `awk '{print $1}'` extracts the path.

**Step 2: Run bash syntax check**

```bash
bashcheck lib/commands.sh
```

Expected: no errors.

**Step 3: Run all worktree tests**

```bash
just test-unit 2>&1 | grep -E "(wt |worktree|PASS|FAIL)"
```

Expected: function-defined test passes; fzf-interactive tests are skipped/not testing `wt` interactively (that's fine).

**Step 4: Commit**

```bash
git add lib/commands.sh
git commit -m "Add wt: fzf switch between git worktrees"
```

---

### Task 4: Implement `wtd`

**Files:**
- Modify: `lib/commands.sh` — add after `wt`

**Step 1: Add `wtd` after `wt`**

```bash
function wtd ()
{
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local WORKTREE_PATH BRANCH

  if [ -n "$1" ]
  then
    BRANCH="$1"
    WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
  else
    local RESULT
    RESULT=$(git worktree list | tail -n +2 | fzf --preview-window wrap --color)
    if [ -z "$RESULT" ]
    then
      return 0
    fi
    WORKTREE_PATH=$(echo "$RESULT" | awk '{print $1}')
    BRANCH=$(echo "$RESULT" | sed -E 's/.*\[([^]]+)\].*/\1/')
  fi

  local SCRIPT="git worktree remove \"$WORKTREE_PATH\" && { git branch -d \"$BRANCH\" || _dotfiles_prompt_git_branch_delete \"$BRANCH\"; }"
  _eval_script "$SCRIPT"
}

```

**Step 2: Run bash syntax check**

```bash
bashcheck lib/commands.sh
```

Expected: no errors.

**Step 3: Run all worktree tests**

```bash
just test-unit 2>&1 | grep -E "(worktree|PASS|FAIL)"
```

Expected: all worktree tests pass.

**Step 4: Commit**

```bash
git add lib/commands.sh
git commit -m "Add wtd: delete git worktree and branch"
```

---

### Task 5: Add `.worktrees/` to repo's own `.gitignore`

The repo itself should ignore `.worktrees/` so that if anyone runs `wtc` inside the dotfiles repo, the worktree directories aren't tracked.

**Files:**
- Modify: `.gitignore` (repo root)

**Step 1: Check if `.gitignore` exists and append**

```bash
grep -F '.worktrees/' .gitignore || echo '.worktrees/' >> .gitignore
```

**Step 2: Verify**

```bash
git status
```

Expected: `.gitignore` shows as modified (or unchanged if already present).

**Step 3: Commit**

```bash
git add .gitignore
git commit -m "Ignore .worktrees/ directory"
```

---

### Task 6: Run full test suite

**Step 1: Run unit tests**

```bash
just test-unit
```

Expected: all tests pass including new `worktree_commands.bats`.

**Step 2: Smoke test manually**

```bash
# In any git repo (not dotfiles itself to avoid noise):
cd /tmp && git init test-wt-repo && cd test-wt-repo && git commit --allow-empty -m "init"
wtc feature/test-branch      # should create worktree and cd into it
wt                            # should show fzf with the worktree
wtd feature/test-branch       # should remove worktree and branch
```

**Step 3: Clean up temp repo**

```bash
rm -rf /tmp/test-wt-repo
```
