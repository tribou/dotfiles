# Beads fzf Show Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `_dotfiles_beads_show` to `lib/fzf.sh` — an interactive fzf picker over `bd list --all` with a live preview pane — and expose it as `bdr` and `bds` aliases.

**Architecture:** Single function in `lib/fzf.sh` (auto-sourced by `lib/index.sh`). Pipes `bd list --all` into fzf with `--preview 'bd show <id>'`. On selection, extracts the issue ID (second token) and calls `bd show`. Silent exit on cancel. Two aliases point to the same function.

**Tech Stack:** bash, fzf, bd (beads), bats-core for tests

---

### Task 1: Write failing tests

**Files:**
- Modify: `tests/fzf_lib.bats`

- [ ] **Step 1: Append the following four tests to `tests/fzf_lib.bats`**

```bash
@test "_dotfiles_beads_show is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    declare -f _dotfiles_beads_show > /dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "bdr alias is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    alias bdr 2>/dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "bds alias is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    alias bds 2>/dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "_dotfiles_beads_show calls bd show with the selected issue ID" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    bd() {
      if [[ \"\$1\" == 'list' ]]; then
        echo '○ dotfiles-ynp ● P2 Add fzf command'
      elif [[ \"\$1\" == 'show' ]]; then
        echo \"showing: \$2\"
      fi
    }
    fzf() { cat; }
    _dotfiles_beads_show
  "
  assert_success
  assert_output --partial "showing: dotfiles-ynp"
}

@test "_dotfiles_beads_show exits silently when fzf returns no selection" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    bd() { echo 'bd called unexpectedly'; }
    fzf() { return 1; }
    _dotfiles_beads_show
    echo 'exited_ok'
  "
  assert_success
  assert_output "exited_ok"
}
```

Note on the `fzf() { cat; }` mock: `cat` passes stdin through unchanged, so `bd list --all` output flows through and the last line is selected as if fzf picked it. This reliably exercises the ID-extraction and `bd show` call path without requiring an interactive terminal.

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
./tests/test_helper/bats-core/bin/bats tests/fzf_lib.bats
```

Expected: the four new tests fail (function not found / alias not found), existing tests still pass.

---

### Task 2: Implement the function and aliases

**Files:**
- Modify: `lib/fzf.sh`

- [ ] **Step 1: Append the function and aliases to `lib/fzf.sh`**

Add at the end of the file:

```bash
# _dotfiles_beads_show - interactive beads issue browser with fzf
# Aliases: bdr (beads read), bds (beads show)
function _dotfiles_beads_show() {
  local issue_id
  issue_id=$(bd list --all | fzf --ansi --reverse \
    --preview 'bd show $(echo {} | awk '"'"'{print $2}'"'"')' \
    --preview-window right:60% | awk '{print $2}')
  [[ -n "$issue_id" ]] && bd show "$issue_id"
}
alias bdr='_dotfiles_beads_show'
alias bds='_dotfiles_beads_show'
```

- [ ] **Step 2: Run the tests to confirm they all pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/fzf_lib.bats
```

Expected: all tests pass, including the four new ones.

- [ ] **Step 3: Run the full unit test suite**

```bash
just test-unit
```

Expected: all tests pass with no regressions.

- [ ] **Step 4: Manual smoke test**

Run `bdr` in your shell (after re-sourcing or opening a new terminal):

1. Confirm fzf list appears with ANSI colors and issues visible.
2. Arrow through items — confirm preview pane on the right updates with `bd show` output.
3. Press Enter on an issue — confirm `bd show <id>` output is printed to terminal.
4. Run `bdr` again and press Esc — confirm silent exit with no output.
5. Run `bds` — confirm identical behavior to `bdr`.

- [ ] **Step 5: Commit**

```bash
git add lib/fzf.sh tests/fzf_lib.bats
git commit -m "feat: add bdr/bds fzf beads show command"
```

---

### Task 3: Close the bead

- [ ] **Step 1: Mark the bead complete**

```bash
bd close dotfiles-ynp
```

- [ ] **Step 2: Push**

```bash
git pull --rebase
bd dolt push
git push
git status
```

Expected: `git status` shows "Your branch is up to date with 'origin/main'."
