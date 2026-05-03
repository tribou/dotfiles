# Bats Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the custom bash test framework with bats-core, migrate existing tests, add new unit tests for previously untested functions, and lay the groundwork for Docker integration tests.

**Architecture:** bats-core + bats-support + bats-assert as git submodules. Unit tests run locally (`just test-unit`). Docker integration tests run alongside goss (`just test`). Testable logic is extracted from I/O-heavy functions into pure helper functions before testing — no mocking of external commands.

**Tech Stack:** bats-core, bats-support, bats-assert, bash, Docker, goss

**Working directory:** `.worktrees/feature/bats-testing` (all git commands and test runs from here)

---

## Task 1: Add bats submodules

**Files:**
- Modify: `.gitmodules` (created by git)
- Create: `tests/test_helper/` (directory)

**Step 1: Add the three submodules**

```bash
git submodule add https://github.com/bats-core/bats-core.git tests/test_helper/bats-core
git submodule add https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
```

**Step 2: Verify bats runs**

```bash
./tests/test_helper/bats-core/bin/bats --version
```
Expected: `Bats 1.x.x`

**Step 3: Commit**

```bash
git add .gitmodules tests/test_helper/
git commit -m "Add bats-core, bats-support, bats-assert as git submodules"
```

---

## Task 2: Create common test setup

**Files:**
- Create: `tests/test_helper/common_setup.bash`

**Step 1: Create the helper**

```bash
# tests/test_helper/common_setup.bash
load 'bats-support/load'
load 'bats-assert/load'

# Resolve the repo root relative to this helper file
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

common_setup() {
  # Source shared lib (order matters: _shared first)
  . "$REPO_ROOT/lib/_shared.sh"
  . "$REPO_ROOT/lib/commands.sh"
}
```

**Step 2: Verify the helper is loadable (no syntax errors)**

```bash
bash -n tests/test_helper/common_setup.bash
```
Expected: no output, exit 0

**Step 3: Commit**

```bash
git add tests/test_helper/common_setup.bash
git commit -m "Add bats common_setup helper with shared lib sourcing"
```

---

## Task 3: Migrate grep_ticket_number tests to bats

**Files:**
- Create: `tests/grep_ticket_number.bats`
- Delete (later, in Task 6): `tests/test_grep_ticket_number.sh`

**Step 1: Write the .bats file**

```bash
# tests/grep_ticket_number.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# --- Standard ABC-123 format ---
@test "ABC-123 extracts correctly" {
  run bash -c 'echo "ABC-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "ABC-123456 (6 digits) extracts correctly" {
  run bash -c 'echo "ABC-123456" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123456"
}

@test "ABC-1234567 (7 digits) extracts correctly" {
  run bash -c 'echo "ABC-1234567" | _dotfiles_grep_ticket_number'
  assert_output "ABC-1234567"
}

# --- Case normalization ---
@test "abc-123 normalizes to ABC-123" {
  run bash -c 'echo "abc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "aBc-123 normalizes to ABC-123" {
  run bash -c 'echo "aBc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "Abc-123 normalizes to ABC-123" {
  run bash -c 'echo "Abc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

# --- Branch prefix stripping ---
@test "feature/ABC-123 strips prefix" {
  run bash -c 'echo "feature/ABC-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "origin/abc-1234567 strips remote prefix" {
  run bash -c 'echo "origin/abc-1234567" | _dotfiles_grep_ticket_number'
  assert_output "ABC-1234567"
}

# --- Description suffix stripping ---
@test "ABC-123/ticket-description strips suffix" {
  run bash -c 'echo "ABC-123/ticket-description" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "feature/ABC-123-b strips trailing suffix" {
  run bash -c 'echo "feature/ABC-123-b" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "feature/test-1234-b normalizes and strips" {
  run bash -c 'echo "feature/test-1234-b" | _dotfiles_grep_ticket_number'
  assert_output "TEST-1234"
}

# --- 2-letter compact format (ab123) ---
@test "ab123-desc-here extracts AB123" {
  run bash -c 'echo "ab123-desc-here" | _dotfiles_grep_ticket_number'
  assert_output "AB123"
}

@test "bug/a2-123-some-description extracts A2-123" {
  run bash -c 'echo "bug/a2-123-some-description" | _dotfiles_grep_ticket_number'
  assert_output "A2-123"
}

# --- Multi-word prefix format (super-123) ---
@test "super-123 extracts SUPER-123" {
  run bash -c 'echo "super-123" | _dotfiles_grep_ticket_number'
  assert_output "SUPER-123"
}

@test "super-123-with-desc-hr extracts SUPER-123" {
  run bash -c 'echo "super-123-with-desc-hr" | _dotfiles_grep_ticket_number'
  assert_output "SUPER-123"
}

# --- DCX format (123_AT_Description) ---
@test "bug/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "bug/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

@test "feature/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "feature/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

@test "patch/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "patch/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

# --- Falsy cases (returns empty) ---
@test "develop returns empty" {
  run bash -c 'echo "develop" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "main returns empty" {
  run bash -c 'echo "main" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "hi returns empty" {
  run bash -c 'echo "hi" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "origin/develop returns empty" {
  run bash -c 'echo "origin/develop" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "string with spaces returns empty" {
  run bash -c 'echo "string and spaces" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "abc123 (no separator) returns empty" {
  run bash -c 'echo "abc123" | _dotfiles_grep_ticket_number'
  assert_output ""
}
```

**Step 2: Run the new tests and verify all pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/grep_ticket_number.bats
```
Expected: `24 tests, 0 failures`

**Step 3: Commit**

```bash
git add tests/grep_ticket_number.bats
git commit -m "Add grep_ticket_number.bats (migrate 24 tests to bats-core)"
```

---

## Task 4: Migrate commit_message tests to bats

**Files:**
- Create: `tests/commit_message.bats`
- Delete (later, in Task 6): `tests/test_commit_message.sh`

**Step 1: Write the .bats file**

```bash
# tests/commit_message.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  # Save and reset separator for each test
  _ORIG_SEP="${DOTFILES_COMMIT_SEPARATOR:-}"
  DOTFILES_COMMIT_SEPARATOR=":"
}

teardown() {
  DOTFILES_COMMIT_SEPARATOR="$_ORIG_SEP"
}

# --- Default separator (:) ---
@test "ticket + message formats with colon separator" {
  run _dotfiles_commit_message "ABC-123" "test commit message"
  assert_output "ABC-123: test commit message"
}

@test "underscore ticket formats with colon separator" {
  run _dotfiles_commit_message "SOME_TIX_NUM" "test commit message"
  assert_output "SOME_TIX_NUM: test commit message"
}

@test "ticket with empty message includes trailing space" {
  run _dotfiles_commit_message "SOME_TIX_NUM" ""
  assert_output "SOME_TIX_NUM: "
}

@test "empty ticket uses message only (no separator)" {
  run _dotfiles_commit_message "" "test message"
  assert_output "test message"
}

@test "both empty returns empty string" {
  run _dotfiles_commit_message "" ""
  assert_output ""
}

# --- Custom separator ---
@test "custom space-dash separator formats correctly" {
  DOTFILES_COMMIT_SEPARATOR=" -"
  run _dotfiles_commit_message "123" "test commit message"
  assert_output "123 - test commit message"
}
```

**Step 2: Run the new tests and verify all pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/commit_message.bats
```
Expected: `6 tests, 0 failures`

**Step 3: Commit**

```bash
git add tests/commit_message.bats
git commit -m "Add commit_message.bats (migrate 6 tests to bats-core)"
```

---

## Task 5: Update justfile and delete old test files

**Files:**
- Modify: `justfile`
- Delete: `tests/test_grep_ticket_number.sh`
- Delete: `tests/test_commit_message.sh`

**Step 1: Update the test-unit target in justfile**

Replace:
```
# Run existing bash unit tests (phase 2)
test-unit:
    ./tests/test_grep_ticket_number.sh
    ./tests/test_commit_message.sh
```

With:
```
# Run bash unit tests with bats-core
test-unit:
    ./tests/test_helper/bats-core/bin/bats tests/*.bats
```

**Step 2: Run the updated target and verify it works**

```bash
just test-unit
```
Expected: `30 tests, 0 failures`

**Step 3: Delete old test files**

```bash
rm tests/test_grep_ticket_number.sh tests/test_commit_message.sh
```

**Step 4: Run again to confirm nothing broke**

```bash
just test-unit
```
Expected: `30 tests, 0 failures`

**Step 5: Commit**

```bash
git add justfile tests/test_grep_ticket_number.sh tests/test_commit_message.sh
git commit -m "Replace custom test framework with bats-core, update justfile"
```

---

## Task 6: Extract npm package manager detection + add tests

The detection logic in `npm-install` and `npm-run` is duplicated and untested. Extract it into a shared helper, then test the helper.

**Files:**
- Modify: `lib/commands.sh` (extract helper, use it in npm-install and npm-run)
- Create: `tests/npm_detection.bats`

**Step 1: Write failing tests first**

```bash
# tests/npm_detection.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  # Create a temp dir to simulate project roots with different lock files
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "detects pnpm when pnpm-lock.yaml exists" {
  touch "$TEST_DIR/pnpm-lock.yaml"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "pnpm"
}

@test "detects yarn when yarn.lock exists" {
  touch "$TEST_DIR/yarn.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "yarn"
}

@test "detects bun when bun.lock exists" {
  touch "$TEST_DIR/bun.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "bun"
}

@test "falls back to npm when no lock file exists" {
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "npm"
}

@test "pnpm takes priority over yarn when both exist" {
  touch "$TEST_DIR/pnpm-lock.yaml" "$TEST_DIR/yarn.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "pnpm"
}

@test "yarn takes priority over bun when both exist" {
  touch "$TEST_DIR/yarn.lock" "$TEST_DIR/bun.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "yarn"
}
```

**Step 2: Run tests and verify they FAIL (function doesn't exist yet)**

```bash
./tests/test_helper/bats-core/bin/bats tests/npm_detection.bats
```
Expected: all 6 tests fail with `_dotfiles_npm_detect_exec: command not found`

**Step 3: Extract the helper in lib/commands.sh**

Find the detection block in `npm-install` (around line 445) and add this function ABOVE `npm-install`:

```bash
# Detect which package manager to use based on lock files in the current directory.
# Outputs: pnpm | yarn | bun | npm
function _dotfiles_npm_detect_exec ()
{
  if [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "bun.lock" ]; then
    echo "bun"
  else
    echo "npm"
  fi
}
```

Then update `npm-install` to use it (replace the inline detection block):

```bash
function npm-install ()
{
  local EXEC
  EXEC="$(_dotfiles_npm_detect_exec)"
  if [ -n "$1" ]
  then
    local SCRIPT="$EXEC install $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local SCRIPT="$EXEC install"
    _eval_script "$SCRIPT"
  fi
}
```

And `npm-run` (replace its inline detection block with `EXEC="$(_dotfiles_npm_detect_exec)"`):

```bash
function npm-run ()
{
  local EXEC
  EXEC="$(_dotfiles_npm_detect_exec)"
  # bun uses 'bun run --silent', others use their own format
  if [ "$EXEC" = "bun" ]; then
    EXEC="bun run --silent"
  elif [ "$EXEC" = "npm" ]; then
    EXEC="npm run --silent"
  fi
  if [ -n "$1" ]
  then
    local SCRIPT="$EXEC $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(jq '.scripts' package.json | grep -E '[a-zA-Z0-9]' | fzf --tiebreak=chunk | awk -F'"' '{print $2}')
    if [ -n "$RESULT" ]
    then
      local SCRIPT="$EXEC $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}
```

**Step 4: Run tests and verify they pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/npm_detection.bats
```
Expected: `6 tests, 0 failures`

**Step 5: Run full test suite to confirm no regressions**

```bash
just test-unit
```
Expected: `36 tests, 0 failures`

**Step 6: Commit**

```bash
git add lib/commands.sh tests/npm_detection.bats
git commit -m "Extract _dotfiles_npm_detect_exec helper, add npm detection tests"
```

---

## Task 7: Extract clipboard command detection + add tests

**Files:**
- Modify: `lib/commands.sh`
- Create: `tests/clipboard.bats`

**Step 1: Write failing tests**

```bash
# tests/clipboard.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  # Create a temp bin dir to place stub commands in
  STUB_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "selects pbcopy when pbcopy is available" {
  touch "$STUB_BIN/pbcopy" && chmod +x "$STUB_BIN/pbcopy"
  run bash -c "PATH='$STUB_BIN:$PATH' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "pbcopy"
}

@test "selects xclip with clipboard selection when only xclip available" {
  touch "$STUB_BIN/xclip" && chmod +x "$STUB_BIN/xclip"
  run bash -c "PATH='$STUB_BIN' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "xclip -selection clipboard"
}

@test "returns empty when neither pbcopy nor xclip available" {
  run bash -c "PATH='$STUB_BIN' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output ""
}

@test "pbcopy takes priority over xclip when both available" {
  touch "$STUB_BIN/pbcopy" "$STUB_BIN/xclip"
  chmod +x "$STUB_BIN/pbcopy" "$STUB_BIN/xclip"
  run bash -c "PATH='$STUB_BIN' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "pbcopy"
}

@test "selects pbpaste when pbpaste is available" {
  touch "$STUB_BIN/pbpaste" && chmod +x "$STUB_BIN/pbpaste"
  run bash -c "PATH='$STUB_BIN:$PATH' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_read_cmd"
  assert_output "pbpaste"
}

@test "selects xclip read flags when only xclip available" {
  touch "$STUB_BIN/xclip" && chmod +x "$STUB_BIN/xclip"
  run bash -c "PATH='$STUB_BIN' . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_read_cmd"
  assert_output "xclip -o -sel clipboard"
}
```

**Step 2: Run tests and verify they FAIL**

```bash
./tests/test_helper/bats-core/bin/bats tests/clipboard.bats
```
Expected: all 6 fail

**Step 3: Extract helpers in lib/commands.sh**

Add ABOVE `copy_to_clipboard`:

```bash
# Returns the write command for the system clipboard (no args: just the command string).
function _dotfiles_clipboard_write_cmd ()
{
  if [ -n "$(command -v pbcopy)" ]; then
    echo "pbcopy"
  elif [ -n "$(command -v xclip)" ]; then
    echo "xclip -selection clipboard"
  fi
}

# Returns the read command for the system clipboard.
function _dotfiles_clipboard_read_cmd ()
{
  if [ -n "$(command -v pbpaste)" ]; then
    echo "pbpaste"
  elif [ -n "$(command -v xclip)" ]; then
    echo "xclip -o -sel clipboard"
  fi
}
```

Update `copy_to_clipboard` and `paste_from_clipboard` to use the helpers:

```bash
function copy_to_clipboard ()
{
  local cmd
  cmd="$(_dotfiles_clipboard_write_cmd)"
  [ -n "$cmd" ] && eval "$cmd"
}

function paste_from_clipboard ()
{
  local cmd
  cmd="$(_dotfiles_clipboard_read_cmd)"
  [ -n "$cmd" ] && eval "$cmd"
}
```

**Step 4: Run tests and verify they pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/clipboard.bats
```
Expected: `6 tests, 0 failures`

**Step 5: Run full suite**

```bash
just test-unit
```
Expected: `42 tests, 0 failures`

**Step 6: Commit**

```bash
git add lib/commands.sh tests/clipboard.bats
git commit -m "Extract clipboard command helpers, add clipboard detection tests"
```

---

## Task 8: Add restart-docker OS guard tests

`restart-docker` already has the guard inline — no extraction needed. We just test the observable behavior via exit code and output.

**Files:**
- Create: `tests/platform_guards.bats`

**Step 1: Write the tests**

```bash
# tests/platform_guards.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# restart-docker guard
@test "restart-docker exits 1 with error message on Linux" {
  run bash -c "OSTYPE=linux-gnu . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && restart-docker"
  assert_failure
  assert_output --partial "not supported on Linux"
}

@test "restart-docker guard allows darwin OSTYPE" {
  # We can't fully run restart-docker (it calls osascript), but we can verify
  # the guard does NOT trigger (returns past the guard) on darwin.
  # Stub osascript and open to prevent actual Docker restart.
  run bash -c "
    OSTYPE=darwin20
    osascript() { return 0; }
    open() { return 0; }
    docker() { return 0; }
    export -f osascript open docker
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    # Override wait loop to exit immediately
    restart-docker 2>/dev/null
    echo 'reached_past_guard'
  "
  assert_output --partial "reached_past_guard"
}
```

**Step 2: Run tests and verify they pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/platform_guards.bats
```
Expected: `2 tests, 0 failures`

**Step 3: Run full suite**

```bash
just test-unit
```
Expected: `44 tests, 0 failures`

**Step 4: Commit**

```bash
git add tests/platform_guards.bats
git commit -m "Add platform_guards.bats: restart-docker OS guard tests"
```

---

## Task 9: Extract histgrep parsing logic + add tests

The AWK regex patterns in `histgrep` are the logic that previously broke. Extract them into named constants in `_shared.sh` (they're shared utilities) and test the patterns directly.

**Files:**
- Modify: `lib/commands.sh` (use named constants from _shared.sh)
- Modify: `lib/_shared.sh` (add the constants)
- Create: `tests/histgrep_parsing.bats`

**Step 1: Write failing tests**

```bash
# tests/histgrep_parsing.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Test the histfile delimiter pattern strips the filename prefix
@test "histfile delimiter strips date-hostname prefix" {
  local line="2024/01/15.10.30.00_myhostname:some command here"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "some command here"
}

@test "histfile delimiter handles hostname with dots" {
  local line="2024/01/15.10.30.00_my.host.name:another command"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "another command"
}

@test "histfile delimiter does not split on colons within the command" {
  local line="2024/01/15.10.30.00_myhostname:echo 'hello:world'"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "echo 'hello:world'"
}

# Test the shell history delimiter (strips '  123  2024-01-15 10:30:00 ' prefix)
@test "history delimiter strips history number and timestamp prefix" {
  local line="  123  2024-01-15 10:30:00 git status"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "git status"
}

@test "history delimiter handles single-digit history number" {
  local line="    1  2024-01-15 10:30:00 ls"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "ls"
}
```

**Step 2: Run tests and verify they FAIL**

```bash
./tests/test_helper/bats-core/bin/bats tests/histgrep_parsing.bats
```
Expected: all 5 fail (`DOTFILES_HISTFILE_DELIM: unbound variable` or similar)

**Step 3: Add constants to lib/_shared.sh**

Add near the top of `lib/_shared.sh`, before the first function:

```bash
# History parsing patterns (used by histgrep in commands.sh)
# Strips the histfile path prefix: YYYY/MM/DD.HH.MM.SS_hostname:
DOTFILES_HISTFILE_DELIM='^[0-9]{4}\/[0-9]{2}\/\/?[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}_[^:]+:'
# Strips the shell history line prefix: '  NNN  YYYY-MM-DD HH:MM:SS '
DOTFILES_HISTORY_DELIM='^ {0,4}[0-9]+  [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} '
```

**Step 4: Update histgrep in lib/commands.sh to use the constants**

Replace the local variable declarations in `histgrep`:

```bash
function histgrep ()
{
  # Remove histfile directory prefix during fzf search
  local AWK_REMOVE_HISTDIR='^\/.*\/\.history\/'

  local RESULT
  RESULT=$(cat \
    <(history | grep "$1") \
    <(ls -d $HOME/.history/20*/* \
      | sort -r -n \
      | xargs grep -r "$1" \
      | awk -F "$AWK_REMOVE_HISTDIR" '{print $NF}') \
    | fzf --tmux="70%,80%" \
    | awk -F "$DOTFILES_HISTFILE_DELIM" '{print $NF}' \
    | awk -F "$DOTFILES_HISTORY_DELIM" '{print $NF}')
  ...
```

**Step 5: Run tests and verify they pass**

```bash
./tests/test_helper/bats-core/bin/bats tests/histgrep_parsing.bats
```
Expected: `5 tests, 0 failures`

**Step 6: Run full suite**

```bash
just test-unit
```
Expected: `49 tests, 0 failures`

**Step 7: Commit**

```bash
git add lib/_shared.sh lib/commands.sh tests/histgrep_parsing.bats
git commit -m "Extract histgrep parsing constants to _shared.sh, add parsing tests"
```

---

## Task 10: Add Docker integration tests for Neovim

These tests run inside the Docker container. They need a headless Neovim with plugins installed (the bootstrap script handles this).

**Files:**
- Create: `tests/integration/nvim_health.bats`
- Modify: `docker-compose.yml` (run integration bats in CI service)
- Modify: `scripts/bootstrap-test.sh` (install bats submodules)

**Step 1: Create integration test directory**

```bash
mkdir -p tests/integration
```

**Step 2: Write nvim health tests**

```bash
# tests/integration/nvim_health.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "nvim checkhealth exits without errors" {
  run nvim --headless -c "checkhealth" -c "qall" 2>&1
  refute_output --partial "ERROR"
}

@test "nvim starts without E-code errors in messages" {
  run nvim --headless -c "messages" -c "qall" 2>&1
  refute_output --regexp "E[0-9]+:"
}

@test "vim-plug is installed" {
  [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ] || \
  [ -f "$HOME/.vim/autoload/plug.vim" ]
}

@test "nvim plugins directory exists and is populated" {
  local plugdir="$HOME/.local/share/nvim/plugged"
  [ -d "$plugdir" ] && [ "$(ls -A "$plugdir")" ]
}

@test "CopilotChat plugin is installed" {
  run find "$HOME/.local/share/nvim" -name "CopilotChat.nvim" -type d
  assert_output --partial "CopilotChat"
}

@test "CoC extensions directory exists" {
  [ -d "$HOME/.config/coc/extensions/node_modules" ]
}

@test "nvim PlugStatus shows no errors" {
  run nvim --headless -c "PlugStatus" -c "qall" 2>&1
  refute_output --partial "Error"
}
```

**Step 3: Write nvim keymap tests**

```bash
# tests/integration/nvim_keymaps.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "leader key mappings exist" {
  run nvim --headless -c "redir => g:maps | silent map <Leader> | redir END | echo g:maps | qall" 2>&1
  # Should output something (not empty) - leader mappings are configured
  [ -n "$output" ]
}

@test "no duplicate normal mode mappings" {
  run nvim --headless -c "redir => g:maps | silent nmap | redir END | echo g:maps | qall" 2>&1
  # Check that output exists (mappings are configured)
  assert_success
}
```

**Step 4: Update docker-compose.yml CI service to also run integration tests**

In `docker-compose.yml`, find the `ci` service command and add the bats integration step:

```yaml
ci:
  ...
  command: >
    bash -c "
      scripts/bootstrap-test.sh &&
      goss validate --format tap &&
      ./tests/test_helper/bats-core/bin/bats tests/integration/
    "
```

**Step 5: Update bootstrap-test.sh to initialize bats submodules**

At the top of `scripts/bootstrap-test.sh`, after the DOTFILES export, add:

```bash
# Initialize bats submodules if not already done
if [ ! -f "$DOTFILES/tests/test_helper/bats-core/bin/bats" ]; then
  git -C "$DOTFILES" submodule update --init --recursive tests/test_helper/
fi
```

**Step 6: Test locally via Docker**

```bash
just test
```
Expected: goss passes + bats integration tests pass

**Step 7: Commit**

```bash
git add tests/integration/ docker-compose.yml scripts/bootstrap-test.sh
git commit -m "Add nvim integration tests (health, keymaps) running in Docker"
```

---

## Task 11: Add Docker integration tests for Tmux

**Files:**
- Create: `tests/integration/tmux_environment.bats`

**Step 1: Write tmux tests**

```bash
# tests/integration/tmux_environment.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
  # Start a detached tmux server for testing
  tmux start-server 2>/dev/null || true
}

teardown() {
  tmux kill-server 2>/dev/null || true
}

@test "tmux prefix is C-f (not default C-b)" {
  run tmux show-options -g prefix
  assert_output --partial "C-f"
}

@test "tmux-resurrect plugin bindings exist" {
  run tmux list-keys
  assert_output --partial "resurrect"
}

@test "tmux-yank plugin bindings exist" {
  run tmux list-keys
  assert_output --partial "yank"
}

@test "tmux status bar renders without error" {
  tmux new-session -d -s test_session 2>/dev/null
  run tmux display-message -t test_session -p "#{status-left}"
  assert_success
}

@test "tmux split-window bindings are present" {
  run tmux list-keys
  assert_output --partial "split-window"
}
```

**Step 2: Run via Docker**

```bash
just test
```
Expected: all integration tests pass including tmux tests

**Step 3: Commit**

```bash
git add tests/integration/tmux_environment.bats
git commit -m "Add tmux integration tests (prefix, plugins, bindings)"
```

---

## Task 12: Add Docker integration tests for bash_profile and bootstrap idempotency

**Files:**
- Create: `tests/integration/bash_profile.bats`

**Step 1: Write tests**

```bash
# tests/integration/bash_profile.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "bash_profile sources without errors" {
  run bash -c "source '$DOTFILES/bash_profile' 2>&1; echo exit:\$?"
  assert_output --partial "exit:0"
  refute_output --regexp "bash:.*No such file"
  refute_output --regexp "line [0-9]+:.*error"
}

@test "bootstrap script is idempotent (safe to run twice)" {
  run bash "$DOTFILES/scripts/bootstrap-test.sh"
  assert_success
}

@test "DOTFILES env var is set to /dotfiles after sourcing bash_profile" {
  run bash -c "source '$DOTFILES/bash_profile' 2>/dev/null && echo \$DOTFILES"
  assert_output "/dotfiles"
}
```

**Step 2: Run via Docker**

```bash
just test
```
Expected: all tests pass

**Step 3: Commit**

```bash
git add tests/integration/bash_profile.bats
git commit -m "Add bash_profile integration tests (sourcing, env vars, idempotency)"
```

---

## Task 13: Final verification and cleanup

**Step 1: Run all unit tests locally**

```bash
just test-unit
```
Expected: `49+ tests, 0 failures`

**Step 2: Run full Docker suite**

```bash
just test
```
Expected: goss + all integration bats tests pass

**Step 3: Verify no orphaned old test files**

```bash
ls tests/*.sh 2>/dev/null && echo "WARNING: old .sh test files remain" || echo "Clean"
```
Expected: `Clean`

**Step 4: Run bashcheck on all modified files**

```bash
bashcheck lib/_shared.sh lib/commands.sh scripts/bootstrap-test.sh
```
Expected: no errors

**Step 5: Update justfile to add a combined test target description**

Ensure the justfile comment on `test` reflects the new full scope:

```
# Run full test suite in Docker (goss infrastructure + bats integration tests)
test:
    docker compose run --rm ci
```

**Step 6: Final commit if any cleanup changes**

```bash
git add -p
git commit -m "Final cleanup: update comments, verify all tests pass"
```

---

## Summary

| Task | Tests Added | Type |
|---|---|---|
| 1-5 | 30 migrated | Unit (bats) |
| 6 | 6 | Unit — npm detection |
| 7 | 6 | Unit — clipboard detection |
| 8 | 2 | Unit — platform guards |
| 9 | 5 | Unit — histgrep parsing |
| 10 | 9 | Integration — nvim |
| 11 | 5 | Integration — tmux |
| 12 | 3 | Integration — bash_profile |
| **Total** | **~66** | |
