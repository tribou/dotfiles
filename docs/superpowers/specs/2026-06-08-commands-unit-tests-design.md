# Design: Unit Tests for Core Commands in lib/commands.sh

## Goal
Establish robust unit test coverage for the highest-value and highest-risk functions in `lib/commands.sh` and related shared helpers in `lib/_shared.sh` (specifically `merge()`, `co()`, `_eval_script()`, npm detection/execution helpers, and `_dotfiles_commit_message()`). Every target test file must have at least 5 happy path tests and at least 1 error path test.

## Proposed Changes

### 1. New Test Files

#### `tests/merge_command.bats` [NEW]
Tests for the `merge()` function in `lib/commands.sh`. We will mock the external `git` calls and internal helpers (`_dotfiles_git_log_commit` and `_dotfiles_git_status`).
* **Test cases:**
  1. `merge: runs git merge with the provided arguments` (Happy path)
  2. `merge: prints commit log and status if merge changes code` (Happy path - not already up to date)
  3. `merge: prints only status if merge is already up to date` (Happy path)
  4. `merge: handles multiple arguments correctly` (Happy path)
  5. `merge: exits with git merge's error code when the merge fails` (Error path)

#### `tests/eval_script.bats` [NEW]
Tests for the `_eval_script()` function in `lib/_shared.sh`. We will verify both the TMUX and non-TMUX execution branches.
* **Test cases:**
  1. `_eval_script: when TMUX is not set, prints and evaluates the script` (Happy path)
  2. `_eval_script: when TMUX is set, uses tmux send-keys to execute in target pane` (Happy path)
  3. `_eval_script: when TMUX is set, formats command with target pane and sends Enter` (Happy path)
  4. `_eval_script: executes multi-statement commands correctly under eval` (Happy path)
  5. `_eval_script: propagates exit code of evaluated script in non-TMUX mode` (Happy path)
  6. `_eval_script: propagates failure of tmux command in TMUX mode` (Error path)

### 2. Expanded Existing Test Files

#### `tests/co_command.bats` [MODIFY]
Add additional test coverage to meet the minimum test requirements.
* **New Test cases:**
  1. `co: checkouts branch directly without fzf when argument is provided` (Happy path)
  2. `co: propagates git checkout failure exit status and skips git status` (Error path)

#### `tests/commit_message.bats` [MODIFY]
Add test coverage for invalid environment states / edge cases.
* **New Test cases:**
  1. `commit message: fallback behaviour when ticket separator environment variable is empty or invalid` (Edge case/Error path)

#### `tests/npm_detection.bats` [MODIFY]
Add tests for the remaining npm/package manager helpers defined in `lib/commands.sh`.
* **New Test cases:**
  1. `npm-install: formats correctly for pnpm` (Happy path)
  2. `y: runs yarn when arguments are passed` (Happy path)
  3. `y: delegates to npm-install when no arguments are passed` (Happy path)
  4. `npm-run: formats correctly for npm run` (Happy path)
  5. `mise-run: uses mise run <task>` (Happy path)
  6. `nu: returns 1 and outputs error when package.json does not exist` (Error path)

## Verification
1. Run all unit tests via `just test-unit`.
2. Run `bashcheck` on the new test files to ensure they are shellcheck clean.
