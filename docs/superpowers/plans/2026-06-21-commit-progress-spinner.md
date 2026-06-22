# `commit` — Animated Spinner While Claude Generates the Message Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a spinner to `commit` (`lib/commands.sh`) so the user gets visual feedback while `_dotfiles_commit_generate_message` waits on the `claude -p --model haiku` call, and let Ctrl-C cleanly cancel that wait instead of falling back to a manual commit editor.

**Architecture:** A new `_dotfiles_spinner_wait <pid> <label>` helper watches an already-backgrounded process: it polls with `kill -0`, animates a braille spinner on stderr when stderr is a tty (a static label line otherwise), and traps SIGINT to kill the watched process and return `130` on cancel. `_dotfiles_commit_generate_message` backgrounds its existing `git diff | head -c | claude` pipeline (redirecting only stdout to a temp file) and delegates the wait to this helper, propagating `130` distinctly from other failures. `commit` checks for that `130` and exits without falling back to `c`.

**Tech Stack:** Bash, bats-core (`run --separate-stderr` for stdout/stderr-split assertions), the `claude` CLI in print mode.

## Global Constraints

- All `_dotfiles_spinner_wait` output goes to stderr, never stdout — `_dotfiles_commit_generate_message` is captured via `generated=$(...)` in `commit()`, so any stray stdout would corrupt the generated commit message.
- Interrupt handling (Ctrl-C) is unconditional, independent of the tty check — the backgrounded pipeline runs in its own process group and does not receive the terminal's SIGINT itself.
- `trap 'interrupted=1' INT` is installed once at the top of `_dotfiles_spinner_wait`, before the tty check, and explicitly cleared (`trap - INT`) before every `return`. The trap only sets a flag — it never calls `return`/`exit` itself, because this function runs sourced into the user's live interactive shell, where `exit` inside a trap would close their terminal.
- tty detection checks **stderr**, not stdout: `[ -t 2 ]`.
- Normal (non-interrupted) completion returns the watched process's real exit status via `wait "$pid"`.
- Out of scope: a timeout for a hung `claude` call, spinners around `git add`/`git commit` (instant, no feedback needed), preserving/restoring a pre-existing `INT` trap.
- Bash syntax/lint checks use `bashcheck`, never `bash -n` directly.
- New behavior requires bats tests under `tests/` (TDD: failing test → implementation → passing test).

---

### Task 1: `_dotfiles_spinner_wait` helper

**Files:**
- Modify: `lib/commands.sh` (insert after `_dotfiles_commit_prompt`, currently lines 77-87, before `_dotfiles_commit_generate_message`, currently starting line 89)
- Test: Create `tests/spinner_wait.bats`

**Interfaces:**
- Produces: `_dotfiles_spinner_wait <pid> <label>` — watches the process `<pid>` (already started in the background by the caller). Returns the watched process's real exit status on normal completion. On SIGINT, kills `<pid>` and returns `130`. Writes only to stderr, nothing to stdout. Consumed by Task 2's `_dotfiles_commit_generate_message`.

- [ ] **Step 1: Write the failing tests**

  Create `tests/spinner_wait.bats`:

  ```bash
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  @test "spinner_wait: returns 0 when the watched process exits 0, label printed to stderr" {
    run --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      sleep 0.2 &
      pid=\$!
      _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
    "
    assert_success
    assert_output ""
    echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
  }

  @test "spinner_wait: returns the watched process's nonzero exit status" {
    run -7 --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      (sleep 0.1; exit 7) &
      pid=\$!
      _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
    "
    assert_output ""
  }

  @test "spinner_wait: SIGINT kills the watched pid and returns 130 with no stdout output" {
    run -130 --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      sleep 5 &
      pid=\$!
      ( sleep 0.2; kill -INT \$\$ ) &
      _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
      status=\$?
      sleep 0.2
      if kill -0 \"\$pid\" 2>/dev/null; then
        echo 'pid_still_alive' >&2
      else
        echo 'pid_killed' >&2
      fi
      exit \"\$status\"
    "
    assert_output ""
    echo "$stderr" | grep -qF 'pid_killed'
  }
  ```

  Note: the `sleep 0.2` after `_dotfiles_spinner_wait` returns gives the killed process time to actually terminate before checking — `kill` is asynchronous, so checking `kill -0` immediately after sending the signal is racy and would usually report the pid as still alive.

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/spinner_wait.bats`
  Expected: all 3 tests FAIL with `_dotfiles_spinner_wait: command not found`

- [ ] **Step 3: Implement `_dotfiles_spinner_wait`**

  In `lib/commands.sh`, find this exact block (the end of `_dotfiles_commit_prompt`):

  ```bash
  function _dotfiles_commit_prompt ()
  {
    local ticket="$1"

    if [ -n "$ticket" ]
    then
      printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use plain imperative mood (e.g. "fix the thing"). Do not add a type or scope prefix like "feat:" or "fix(scope):" -- a ticket prefix will be added separately. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
    else
      printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use Conventional Commits style (e.g. "fix(scope): summary") when it fits, otherwise a plain imperative summary. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
    fi
  }

  function _dotfiles_commit_generate_message ()
  ```

  Replace it with:

  ```bash
  function _dotfiles_commit_prompt ()
  {
    local ticket="$1"

    if [ -n "$ticket" ]
    then
      printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use plain imperative mood (e.g. "fix the thing"). Do not add a type or scope prefix like "feat:" or "fix(scope):" -- a ticket prefix will be added separately. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
    else
      printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use Conventional Commits style (e.g. "fix(scope): summary") when it fits, otherwise a plain imperative summary. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
    fi
  }

  function _dotfiles_spinner_wait ()
  {
    local pid="$1"
    local label="$2"
    local interrupted=0
    local is_tty=0
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local frame_index=0

    trap 'interrupted=1' INT

    if [ -t 2 ]
    then
      is_tty=1
    else
      printf '%s\n' "$label" >&2
    fi

    while kill -0 "$pid" 2> /dev/null
    do
      if [ "$interrupted" -eq 1 ]
      then
        kill "$pid" 2> /dev/null
        [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2
        trap - INT
        return 130
      fi

      if [ "$is_tty" -eq 1 ]
      then
        printf '\r%s %s' "${frames[frame_index]}" "$label" >&2
        frame_index=$(( (frame_index + 1) % 10 ))
      fi

      sleep 0.1
    done

    [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2

    wait "$pid"
    local status=$?
    trap - INT
    return "$status"
  }

  function _dotfiles_commit_generate_message ()
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/spinner_wait.bats`
  Expected: all 3 tests PASS

- [ ] **Step 5: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/spinner_wait.bats`
  Expected: `All files passed`

- [ ] **Step 6: Commit**

  ```bash
  git add lib/commands.sh tests/spinner_wait.bats
  git commit -m "feat(commit): add spinner_wait helper for animated progress"
  ```

---

### Task 2: Wire the spinner into `_dotfiles_commit_generate_message`

**Files:**
- Modify: `lib/commands.sh` (currently lines 89-113)
- Modify: `tests/commit_generate_message.bats`

**Interfaces:**
- Consumes: `_dotfiles_spinner_wait` (Task 1)
- Produces: `_dotfiles_commit_generate_message "$ticket"` — unchanged success/empty-output contract, plus: returns `130` (instead of `1`) specifically when the wait was interrupted. Consumed by Task 3's `commit`.

- [ ] **Step 1: Update the existing tests for the new stderr label line**

  In `tests/commit_generate_message.bats`, find this exact block:

  ```bash
  @test "generate_message: returns claude's sanitized output on success" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo 'mock diff'; }
      claude() { echo 'fix(bootstrap): silence brew prompt'; }
      _dotfiles_commit_generate_message ''
    "
    assert_success
    assert_output "fix(bootstrap): silence brew prompt"
  }
  ```

  Replace it with:

  ```bash
  @test "generate_message: returns claude's sanitized output on success" {
    run --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo 'mock diff'; }
      claude() { echo 'fix(bootstrap): silence brew prompt'; }
      _dotfiles_commit_generate_message ''
    "
    assert_success
    assert_output "fix(bootstrap): silence brew prompt"
    echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
  }
  ```

  Find this exact block:

  ```bash
  @test "generate_message: fails when claude exits non-zero" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo 'mock diff'; }
      claude() { return 1; }
      _dotfiles_commit_generate_message ''
    "
    assert_failure
    assert_output ""
  }
  ```

  Replace it with:

  ```bash
  @test "generate_message: fails when claude exits non-zero" {
    run --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo 'mock diff'; }
      claude() { return 1; }
      _dotfiles_commit_generate_message ''
    "
    assert_failure
    assert_output ""
    echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
  }
  ```

  Find this exact block:

  ```bash
  @test "generate_message: fails when claude returns empty output" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo ''; }
      claude() { echo ''; }
      _dotfiles_commit_generate_message ''
    "
    assert_failure
    assert_output ""
  }
  ```

  Replace it with:

  ```bash
  @test "generate_message: fails when claude returns empty output" {
    run --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo ''; }
      claude() { echo ''; }
      _dotfiles_commit_generate_message ''
    "
    assert_failure
    assert_output ""
    echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
  }
  ```

  Find this exact block:

  ```bash
  @test "generate_message: caps the diff sent to claude at 100000 bytes" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { yes a | head -c 200000; }
      claude() { wc -c | tr -d ' '; }
      _dotfiles_commit_generate_message ''
    "
    assert_success
    assert_output "100000"
  }
  ```

  Replace it with:

  ```bash
  @test "generate_message: caps the diff sent to claude at 100000 bytes" {
    run --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { yes a | head -c 200000; }
      claude() { wc -c | tr -d ' '; }
      _dotfiles_commit_generate_message ''
    "
    assert_success
    assert_output "100000"
    echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
  }

  @test "generate_message: returns 130 and emits no stdout when interrupted" {
    run -130 --separate-stderr bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() { echo 'mock diff'; }
      claude() { sleep 1; echo 'should not be seen'; }
      ( sleep 0.2; kill -INT \$\$ ) &
      _dotfiles_commit_generate_message ''
    "
    assert_output ""
  }
  ```

  Note: `claude` here is a shell function, so it runs inside the pipeline's last-stage subshell; killing that subshell (what `_dotfiles_spinner_wait` does on interrupt) does not reach its `sleep 1` grandchild, which is why the mock uses a short 1-second sleep rather than something long — any orphaned process exits on its own almost immediately. In production `claude` is a single exec'd binary with no such grandchild, so this is a test-only artifact, not a behavior gap.

  Note: the `generate_message: fails when claude is not found on PATH` test is left unchanged — that path returns before any backgrounding/spinner happens, so no stderr label is emitted.

- [ ] **Step 2: Run the tests to verify the new/modified ones fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: the 2 prompt tests PASS; the PATH-missing test PASSES (unaffected); the success, non-zero, empty-output, and byte-cap tests FAIL on the new `grep -qF` stderr assertions (no spinner label is printed yet); the new interrupted test FAILS (status is `1`, not `130`, since interruption isn't implemented yet)

- [ ] **Step 3: Implement the change in `_dotfiles_commit_generate_message`**

  In `lib/commands.sh`, find this exact block:

  ```bash
  function _dotfiles_commit_generate_message ()
  {
    local ticket="$1"

    if ! command -v claude > /dev/null 2>&1
    then
      return 1
    fi

    local raw
    if ! raw=$(git diff --cached | head -c 100000 | claude -p --model haiku "$(_dotfiles_commit_prompt "$ticket")")
    then
      return 1
    fi

    local sanitized
    sanitized=$(_dotfiles_commit_sanitize_message "$raw")

    if [ -z "$sanitized" ]
    then
      return 1
    fi

    printf '%s' "$sanitized"
  }
  ```

  Replace it with:

  ```bash
  function _dotfiles_commit_generate_message ()
  {
    local ticket="$1"

    if ! command -v claude > /dev/null 2>&1
    then
      return 1
    fi

    local outfile
    outfile=$(mktemp)

    git diff --cached | head -c 100000 | claude -p --model haiku "$(_dotfiles_commit_prompt "$ticket")" > "$outfile" &
    local pid=$!

    _dotfiles_spinner_wait "$pid" "Asking Claude for a commit message..."
    local wait_status=$?

    if [ "$wait_status" -eq 130 ]
    then
      rm -f "$outfile"
      return 130
    fi

    if [ "$wait_status" -ne 0 ]
    then
      rm -f "$outfile"
      return 1
    fi

    local raw
    raw=$(cat "$outfile")
    rm -f "$outfile"

    local sanitized
    sanitized=$(_dotfiles_commit_sanitize_message "$raw")

    if [ -z "$sanitized" ]
    then
      return 1
    fi

    printf '%s' "$sanitized"
  }
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: all 8 tests PASS

- [ ] **Step 5: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/commit_generate_message.bats`
  Expected: `All files passed`

- [ ] **Step 6: Commit**

  ```bash
  git add lib/commands.sh tests/commit_generate_message.bats
  git commit -m "feat(commit): show a spinner while generating the commit message"
  ```

---

### Task 3: Propagate cancellation from `commit`

**Files:**
- Modify: `lib/commands.sh` (currently lines 115-151)
- Modify: `tests/commit_command.bats`
- Modify: `docs/DEVELOPMENT.md`

**Interfaces:**
- Consumes: `_dotfiles_commit_generate_message` (Task 2) — now distinguishes a `130` exit status from other failures.
- Produces: `commit` — same public contract, plus: when generation is canceled (Ctrl-C), prints `commit canceled` to stderr and returns `130` without calling `c` or `git commit`.

- [ ] **Step 1: Write the failing test**

  In `tests/commit_command.bats`, append after the last `@test` block (after `commit: removes the old non-AI alias`):

  ```bash

  @test "commit: propagates cancellation from generate_message without falling back to c" {
    run -130 bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() {
        if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
        if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
        if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
        echo \"git_unexpected_call:\$*\"
        return 0
      }
      _dotfiles_commit_generate_message() { return 130; }
      c() { echo 'c_invoked'; }
      commit
    "
    assert_output --partial "commit canceled"
    refute_output --partial "c_invoked"
    refute_output --partial "git_unexpected_call"
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: the new test FAILS — `commit` currently treats a `130` return the same as any other empty/failed generation (falls back to `c`, returns 0, not 130)

- [ ] **Step 3: Implement the change in `commit`**

  In `lib/commands.sh`, find this exact block:

  ```bash
  function commit ()
  {
    if [ -f "./.git/MERGE_HEAD" ]
    then
      # If committing a git merge, accept the default message
      # shellcheck disable=SC2119 # commit() never forwards args to c
      c
      return
    fi

    git add -A

    if git diff --cached --quiet
    then
      echo "nothing to commit"
      return 0
    fi

    local ticket
    ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)

    local generated
    generated=$(_dotfiles_commit_generate_message "$ticket")

    if [ -z "$generated" ]
    then
      echo "claude unavailable, falling back to manual commit" >&2
      # shellcheck disable=SC2119 # commit() never forwards args to c
      c
      return
    fi

    local message
    message=$(_dotfiles_commit_message "$ticket" "$generated")

    git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
  }
  ```

  Replace it with:

  ```bash
  function commit ()
  {
    if [ -f "./.git/MERGE_HEAD" ]
    then
      # If committing a git merge, accept the default message
      # shellcheck disable=SC2119 # commit() never forwards args to c
      c
      return
    fi

    git add -A

    if git diff --cached --quiet
    then
      echo "nothing to commit"
      return 0
    fi

    local ticket
    ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)

    local generated
    generated=$(_dotfiles_commit_generate_message "$ticket")
    local generate_status=$?

    if [ "$generate_status" -eq 130 ]
    then
      echo "commit canceled" >&2
      return 130
    fi

    if [ -z "$generated" ]
    then
      echo "claude unavailable, falling back to manual commit" >&2
      # shellcheck disable=SC2119 # commit() never forwards args to c
      c
      return
    fi

    local message
    message=$(_dotfiles_commit_message "$ticket" "$generated")

    git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
  }
  ```

- [ ] **Step 4: Run the tests to verify they all pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: all 7 tests PASS

- [ ] **Step 5: Document the cancellation behavior**

  In `docs/DEVELOPMENT.md`, find this exact line:

  ```markdown
  `commit` (no args) stages everything, asks Claude Haiku to draft the message, and commits — falling back to `c` (manual editor) if Haiku is unavailable or errors.
  ```

  Replace it with:

  ```markdown
  `commit` (no args) stages everything, asks Claude Haiku to draft the message, and commits — falling back to `c` (manual editor) if Haiku is unavailable or errors. A spinner shows progress while waiting; Ctrl-C cancels the commit (changes stay staged) instead of falling back to `c`.
  ```

- [ ] **Step 6: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/commit_command.bats`
  Expected: `All files passed`

- [ ] **Step 7: Commit**

  ```bash
  git add lib/commands.sh tests/commit_command.bats docs/DEVELOPMENT.md
  git commit -m "feat(commit): cancel cleanly on Ctrl-C instead of falling back to c"
  ```

---

### Task 4: Full suite verification

**Files:** none (verification only)

- [ ] **Step 1: Run bashcheck across all changed files**

  Run: `bashcheck lib/commands.sh tests/spinner_wait.bats tests/commit_generate_message.bats tests/commit_command.bats`
  Expected: `All files passed`

- [ ] **Step 2: Run the fast unit suite**

  Run: `just test-unit`
  Expected: all tests pass, including the 3 new `spinner_wait` tests, the updated/new `commit_generate_message` tests, and the new `commit_command` cancellation test

- [ ] **Step 3: Run the full Docker suite**

  Run: `just test`
  Expected: all bats integration tests and goss infrastructure checks pass

- [ ] **Step 4: Fix forward if anything fails**

  If any step above fails, fix the regression in the relevant task's files, re-run the failing command until it passes, then commit the fix with a message describing what broke (e.g. `git commit -m "fix(commit): correct spinner trap cleanup on early return"`). Do not skip ahead — Task 4 is the final gate before the feature is considered done.
