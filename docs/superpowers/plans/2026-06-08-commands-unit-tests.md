# Core Commands Unit Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write unit tests for core git, tmux, and npm helpers in `lib/commands.sh` and `lib/_shared.sh` ensuring all test files have at least 5 happy paths + 1 error path.

**Architecture:** We will create two new Bats test files (`tests/merge_command.bats` and `tests/eval_script.bats`) and expand three existing test files (`tests/co_command.bats`, `tests/commit_message.bats`, and `tests/npm_detection.bats`) using a subshell mocking approach for external dependencies.

**Tech Stack:** Bash, bats-core

---

### Task 1: Create tests/merge_command.bats

**Files:**
- Create: `tests/merge_command.bats`

- [ ] **Step 1: Write the failing tests**
  Create `tests/merge_command.bats` with unit tests for the `merge()` function.
  
  ```bash
  # tests/merge_command.bats
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  @test "merge: runs git merge with the provided arguments" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { echo \"git_merge \$*\"; }
      _dotfiles_git_status() { echo \"git_status\"; }
      merge \"my-feature\"
    "
    assert_success
    assert_line --index 0 "git_merge my-feature"
  }

  @test "merge: prints commit log and status if merge changes code" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { echo \"Updating 123456..789abc\"; }
      _dotfiles_git_log_commit() { echo \"git_log_commit\"; }
      _dotfiles_git_status() { echo \"git_status\"; }
      merge \"my-feature\"
    "
    assert_success
    assert_line --index 0 "git_log_commit"
    assert_line --index 1 "git_status"
  }

  @test "merge: prints only status if merge is already up to date" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { echo \"Already up to date.\"; }
      _dotfiles_git_log_commit() { echo \"git_log_commit_unexpected\"; }
      _dotfiles_git_status() { echo \"git_status\"; }
      merge \"my-feature\"
    "
    assert_success
    refute_output --partial "git_log_commit_unexpected"
    assert_output --partial "git_status"
  }

  @test "merge: handles multiple arguments correctly" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { echo \"git_merge \$*\"; }
      _dotfiles_git_status() { echo \"git_status\"; }
      merge \"main\" \"--no-ff\"
    "
    assert_success
    assert_line --index 0 "git_merge main --no-ff"
  }

  @test "merge: returns status of logging/status when merge succeeds or fails" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { echo \"Conflict!\"; return 12; }
      _dotfiles_git_log_commit() { return 0; }
      _dotfiles_git_status() { return 5; }
      merge \"my-feature\"
    "
    assert_status 5
  }
  ```

- [ ] **Step 2: Run tests to verify they pass**
  Run: `bats tests/merge_command.bats`
  Expected: PASS

- [ ] **Step 3: Run bashcheck linter on the new test file**
  Run: `bashcheck tests/merge_command.bats`
  Expected: PASS

- [ ] **Step 4: Commit**
  ```bash
  git add tests/merge_command.bats
  git commit -m "test: add merge command unit tests"
  ```

---

### Task 2: Create tests/eval_script.bats

**Files:**
- Create: `tests/eval_script.bats`

- [ ] **Step 1: Write the failing tests**
  Create `tests/eval_script.bats` with tests for the `_eval_script()` function.
  
  ```bash
  # tests/eval_script.bats
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  @test "_eval_script: when TMUX is not set, prints and evaluates the script" {
    run bash -c "
      unset TMUX
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"echo 'hello'\"
    "
    assert_success
    assert_line --index 0 "echo 'hello'"
    assert_line --index 1 ""
    assert_line --index 2 "hello"
  }

  @test "_eval_script: when TMUX is set, uses tmux send-keys to execute in target pane" {
    run bash -c "
      export TMUX=\"yes\"
      export TMUX_PANE=\"%1\"
      tmux() { echo \"tmux \$*\"; }
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"echo 'hello'\"
    "
    assert_success
    assert_output "tmux send-keys -t %1 echo 'hello' Enter"
  }

  @test "_eval_script: when TMUX is set, formats command with target pane and sends Enter" {
    run bash -c "
      export TMUX=\"yes\"
      export TMUX_PANE=\"%2\"
      tmux() { echo \"tmux \$*\"; }
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"git status\"
    "
    assert_success
    assert_output "tmux send-keys -t %2 git status Enter"
  }

  @test "_eval_script: executes multi-statement commands correctly under eval" {
    run bash -c "
      unset TMUX
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"VAL=abc && echo \$VAL\"
    "
    assert_success
    assert_line --index 2 "abc"
  }

  @test "_eval_script: propagates exit code of evaluated script in non-TMUX mode" {
    run bash -c "
      unset TMUX
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"false\"
    "
    assert_failure
  }

  @test "_eval_script: propagates failure of tmux command in TMUX mode" {
    run bash -c "
      export TMUX=\"yes\"
      export TMUX_PANE=\"%1\"
      tmux() { return 99; }
      . '\$REPO_ROOT/lib/_shared.sh'
      _eval_script \"echo 'hello'\"
    "
    assert_failure
    assert_status 99
  }
  ```

- [ ] **Step 2: Run tests to verify they pass**
  Run: `bats tests/eval_script.bats`
  Expected: PASS

- [ ] **Step 3: Run bashcheck linter on the new test file**
  Run: `bashcheck tests/eval_script.bats`
  Expected: PASS

- [ ] **Step 4: Commit**
  ```bash
  git add tests/eval_script.bats
  git commit -m "test: add eval_script helper unit tests"
  ```

---

### Task 3: Expand tests/co_command.bats

**Files:**
- Modify: `tests/co_command.bats`

- [ ] **Step 1: Write the failing tests**
  Add these two new tests to the end of `tests/co_command.bats`:
  
  ```bash
  @test "co: checkouts branch directly without fzf when argument is provided" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      fzf() { echo 'should-not-be-called'; exit 1; }
      git() { echo \"git \$*\"; }
      _dotfiles_git_status() { echo \"git_status\"; }
      co \"my-branch\"
    "
    assert_success
    assert_line --index 0 "git checkout my-branch"
    assert_line --index 1 "git_status"
  }

  @test "co: propagates git checkout failure exit status and skips git status" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      git() { return 42; }
      _dotfiles_git_status() { echo \"should-not-run\"; return 0; }
      co \"invalid-branch\"
    "
    assert_failure
    assert_status 42
    refute_output --partial "should-not-run"
  }
  ```

- [ ] **Step 2: Run tests to verify they pass**
  Run: `bats tests/co_command.bats`
  Expected: PASS

- [ ] **Step 3: Run bashcheck linter on the test file**
  Run: `bashcheck tests/co_command.bats`
  Expected: PASS

- [ ] **Step 4: Commit**
  ```bash
  git add tests/co_command.bats
  git commit -m "test: expand co command unit tests"
  ```

---

### Task 4: Expand tests/commit_message.bats

**Files:**
- Modify: `tests/commit_message.bats`

- [ ] **Step 1: Write the failing tests**
  Add this new test to the end of `tests/commit_message.bats`:
  
  ```bash
  @test "custom empty separator formats correctly" {
    DOTFILES_COMMIT_SEPARATOR=""
    run _dotfiles_commit_message "123" "test commit message"
    assert_output "123: test commit message"
  }
  ```

- [ ] **Step 2: Run tests to verify they pass**
  Run: `bats tests/commit_message.bats`
  Expected: PASS

- [ ] **Step 3: Run bashcheck linter on the test file**
  Run: `bashcheck tests/commit_message.bats`
  Expected: PASS

- [ ] **Step 4: Commit**
  ```bash
  git add tests/commit_message.bats
  git commit -m "test: expand commit message helper unit tests"
  ```

---

### Task 5: Expand tests/npm_detection.bats

**Files:**
- Modify: `tests/npm_detection.bats`

- [ ] **Step 1: Write the failing tests**
  Add these new tests to the end of `tests/npm_detection.bats`:
  
  ```bash
  @test "npm-install: formats correctly for pnpm" {
    touch "\$TEST_DIR/pnpm-lock.yaml"
    run bash -c "
      cd '\$TEST_DIR'
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      _eval_script() { echo \"eval_script \$*\"; }
      eval() { echo \"eval \$*\"; }
      npm-install
    "
    assert_success
    assert_output "eval_script pnpm install"
  }

  @test "npm-install: runs pnpm install with arguments" {
    touch "\$TEST_DIR/pnpm-lock.yaml"
    run bash -c "
      cd '\$TEST_DIR'
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      eval() { echo \"eval \$*\"; }
      npm-install \"lodash\" \"-D\"
    "
    assert_success
    assert_line --index 0 "pnpm install lodash -D"
    assert_line --index 2 "eval pnpm install lodash -D"
  }

  @test "y: runs yarn when arguments are passed" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      eval() { echo \"eval \$*\"; }
      y \"add\" \"react\"
    "
    assert_success
    assert_line --index 0 "yarn add react"
    assert_line --index 2 "eval yarn add react"
  }

  @test "y: delegates to npm-install when no arguments are passed" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      npm-install() { echo \"npm-install called\"; }
      y
    "
    assert_success
    assert_output "npm-install called"
  }

  @test "npm-run: formats correctly for npm run" {
    touch "\$TEST_DIR/package.json"
    run bash -c "
      cd '\$TEST_DIR'
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      eval() { echo \"eval \$*\"; }
      npm-run \"test\"
    "
    assert_success
    assert_line --index 0 "npm run --silent test"
    assert_line --index 2 "eval npm run --silent test"
  }

  @test "mise-run: uses mise run <task>" {
    run bash -c "
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      eval() { echo \"eval \$*\"; }
      mise-run \"build\"
    "
    assert_success
    assert_line --index 0 "mise run build"
    assert_line --index 2 "eval mise run build"
  }

  @test "nu: returns 1 and outputs error when package.json does not exist" {
    run bash -c "
      cd '\$TEST_DIR'
      . '\$REPO_ROOT/lib/_shared.sh'
      . '\$REPO_ROOT/lib/commands.sh'
      nu
    "
    assert_failure
    assert_output "No package.json to upgrade"
  }
  ```

- [ ] **Step 2: Run tests to verify they pass**
  Run: `bats tests/npm_detection.bats`
  Expected: PASS

- [ ] **Step 3: Run bashcheck linter on the test file**
  Run: `bashcheck tests/npm_detection.bats`
  Expected: PASS

- [ ] **Step 4: Commit**
  ```bash
  git add tests/npm_detection.bats
  git commit -m "test: expand npm and package manager helper unit tests"
  ```

---

### Task 6: Full verification

- [ ] **Step 1: Run full unit test suite**
  Run: `just test-unit`
  Expected: PASS

- [ ] **Step 2: Commit**
  ```bash
  git commit --allow-empty -m "test: all unit tests for core functions verified and passing"
  ```
