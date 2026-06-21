# `commit` — AI-Generated Commit via Claude Haiku Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `alias commit='git commit -ev'` in `lib/commands.sh` with a `commit` shell function that stages everything, asks Claude Haiku to draft a one-line commit message from the staged diff, and commits — falling back to the existing `c` function whenever Haiku is unavailable, errors, or returns nothing usable.

**Architecture:** Three small `_dotfiles_commit_*` helpers (sanitize output, build the model prompt, run Haiku and produce a clean message) compose into the public `commit` function. Each helper is independently unit-tested with mocked `git`/`claude`; `commit` itself is tested with all of its collaborators mocked.

**Tech Stack:** Bash, bats-core, the `claude` CLI in print mode (`-p --model haiku`)

## Global Constraints

- Commits in this repo are single-line only via `git commit -m "..."`, no `Co-Authored-By` line (applies to the commits this plan's steps make, not just the feature under test).
- Bash syntax/lint checks use `bashcheck`, never `bash -n` directly.
- New behavior requires bats tests under `tests/` (TDD: failing test → implementation → passing test).
- The staged diff sent to Haiku is capped at 100000 bytes (`head -c 100000`) before piping into `claude -p --model haiku`.
- `claude` is invoked in print mode (`-p`) so it only emits text — no tools, no permission prompts, no git calls from the model itself.
- When a ticket is present, the model must NOT add a Conventional Commits prefix (the ticket prefix is added separately by `_dotfiles_commit_message`, and stacking both would read like `AB-123: fix(scope): ...`). When no ticket is present, Conventional Commits style is allowed.
- Any fallback path (`claude` missing, non-zero exit, or empty output after sanitizing) prints a short note to stderr and calls the existing `c` function — never aborts uncommitted.
- Out of scope: confirmation prompt before committing, pushing after commit, making the model configurable (hard-coded to `haiku`).

---

### Task 1: Commit message sanitizer helper

**Files:**
- Modify: `lib/commands.sh` (insert after the `cn` function, before `clean()` — currently lines 69-71)
- Test: Create `tests/commit_sanitize_message.bats`

**Interfaces:**
- Produces: `_dotfiles_commit_sanitize_message "$raw_text"` — echoes the first line of `$raw_text` with surrounding quotes/backticks/whitespace stripped. Empty input produces empty output. Consumed by Task 2's `_dotfiles_commit_generate_message`.

- [ ] **Step 1: Write the failing tests**

  Create `tests/commit_sanitize_message.bats`:

  ```bash
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  @test "passes through a clean single-line message unchanged" {
    run _dotfiles_commit_sanitize_message "fix the thing"
    assert_output "fix the thing"
  }

  @test "strips surrounding double quotes" {
    run _dotfiles_commit_sanitize_message '"fix the thing"'
    assert_output "fix the thing"
  }

  @test "strips surrounding single quotes" {
    run _dotfiles_commit_sanitize_message "'fix the thing'"
    assert_output "fix the thing"
  }

  @test "strips surrounding backticks" {
    run _dotfiles_commit_sanitize_message '`fix the thing`'
    assert_output "fix the thing"
  }

  @test "strips leading and trailing whitespace" {
    run _dotfiles_commit_sanitize_message "   fix the thing   "
    assert_output "fix the thing"
  }

  @test "takes only the first line of multi-line output" {
    run _dotfiles_commit_sanitize_message "$(printf 'fix the thing\nsome extra explanation\nmore text')"
    assert_output "fix the thing"
  }

  @test "reduces multi-line quoted output to a clean single line" {
    run _dotfiles_commit_sanitize_message "$(printf '"fix(bootstrap): silence brew prompt"\nThis change updates the bootstrap script.')"
    assert_output "fix(bootstrap): silence brew prompt"
  }

  @test "empty input produces empty output" {
    run _dotfiles_commit_sanitize_message ""
    assert_output ""
  }
  ```

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_sanitize_message.bats`
  Expected: every test FAILs with `_dotfiles_commit_sanitize_message: command not found`

- [ ] **Step 3: Implement the helper**

  In `lib/commands.sh`, find this exact block (the end of the `cn` function, lines 67-71):

  ```bash
    fi
  }

  function clean ()
  ```

  Replace it with:

  ```bash
    fi
  }

  function _dotfiles_commit_sanitize_message ()
  {
    printf '%s' "$1" | head -n1 | sed -E "s/^[\"'\`[:space:]]+//; s/[\"'\`[:space:]]+$//"
  }

  function clean ()
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_sanitize_message.bats`
  Expected: all 8 tests PASS

- [ ] **Step 5: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/commit_sanitize_message.bats`
  Expected: `All files passed`

- [ ] **Step 6: Commit**

  ```bash
  git add lib/commands.sh tests/commit_sanitize_message.bats
  git commit -m "feat(commit): add commit message sanitizer helper"
  ```

---

### Task 2: AI message generation helper

**Files:**
- Modify: `lib/commands.sh` (insert after `_dotfiles_commit_sanitize_message`, before `clean()`)
- Test: Create `tests/commit_generate_message.bats`

**Interfaces:**
- Consumes: `_dotfiles_commit_sanitize_message` (Task 1)
- Produces:
  - `_dotfiles_commit_prompt "$ticket"` — echoes the prompt text to send to Haiku; wording depends on whether `$ticket` is non-empty.
  - `_dotfiles_commit_generate_message "$ticket"` — on success, echoes the sanitized model message and returns 0; on any failure (claude missing, non-zero exit, empty output after sanitizing), prints nothing and returns 1. Consumed by Task 3's `commit`.

- [ ] **Step 1: Write the failing tests for `_dotfiles_commit_prompt`**

  Create `tests/commit_generate_message.bats`:

  ```bash
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  # --- _dotfiles_commit_prompt ---

  @test "prompt: ticket present requests a plain summary with no Conventional Commits prefix" {
    run _dotfiles_commit_prompt "AB-123"
    assert_success
    refute_output --partial "Conventional Commits"
  }

  @test "prompt: no ticket allows Conventional Commits style" {
    run _dotfiles_commit_prompt ""
    assert_success
    assert_output --partial "Conventional Commits"
  }
  ```

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: both tests FAIL with `_dotfiles_commit_prompt: command not found`

- [ ] **Step 3: Implement `_dotfiles_commit_prompt`**

  In `lib/commands.sh`, find this exact block (the `_dotfiles_commit_sanitize_message` function added in Task 1):

  ```bash
  function _dotfiles_commit_sanitize_message ()
  {
    printf '%s' "$1" | head -n1 | sed -E "s/^[\"'\`[:space:]]+//; s/[\"'\`[:space:]]+$//"
  }

  function clean ()
  ```

  Replace it with:

  ```bash
  function _dotfiles_commit_sanitize_message ()
  {
    printf '%s' "$1" | head -n1 | sed -E "s/^[\"'\`[:space:]]+//; s/[\"'\`[:space:]]+$//"
  }

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

  function clean ()
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: both tests PASS

- [ ] **Step 5: Append the failing tests for `_dotfiles_commit_generate_message`**

  Append to `tests/commit_generate_message.bats` (after the two prompt tests, inside the same file):

  ```bash

  # --- _dotfiles_commit_generate_message ---

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

  @test "generate_message: fails when claude is not found on PATH" {
    local empty_path
    empty_path="$(mktemp -d)"
    run bash -c "
      export PATH='$empty_path'
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      _dotfiles_commit_generate_message ''
    "
    assert_failure
    assert_output ""
    rm -rf "$empty_path"
  }

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

- [ ] **Step 6: Run the tests to verify the new ones fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: the 2 prompt tests PASS, the 5 new `generate_message` tests FAIL with `_dotfiles_commit_generate_message: command not found`

- [ ] **Step 7: Implement `_dotfiles_commit_generate_message`**

  In `lib/commands.sh`, find this exact block (the `_dotfiles_commit_prompt` function added in Step 3 above):

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

  function clean ()
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

  function clean ()
  ```

- [ ] **Step 8: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_generate_message.bats`
  Expected: all 7 tests PASS

- [ ] **Step 9: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/commit_generate_message.bats`
  Expected: `All files passed`

- [ ] **Step 10: Commit**

  ```bash
  git add lib/commands.sh tests/commit_generate_message.bats
  git commit -m "feat(commit): add AI commit message generation helper"
  ```

---

### Task 3: `commit` function, alias removal, and doc update

**Files:**
- Modify: `lib/commands.sh` (insert `commit` function after `_dotfiles_commit_generate_message`, before `clean()`; remove the `alias commit='git commit -ev' # non-signed commit` line currently near the aliases section)
- Modify: `docs/DEVELOPMENT.md` (document the new `commit` function next to the existing `c` documentation)
- Test: Create `tests/commit_command.bats`

**Interfaces:**
- Consumes: `_dotfiles_grep_ticket_number`, `_dotfiles_commit_message`, `_dotfiles_git_log_commit`, `_dotfiles_git_status` (existing, `lib/_shared.sh`); `_dotfiles_commit_generate_message` (Task 2); `c` (existing, `lib/commands.sh`)
- Produces: `commit` — the public-facing function with no required arguments.

- [ ] **Step 1: Write the failing tests for `commit`'s behavior**

  Create `tests/commit_command.bats`:

  ```bash
  setup() {
    load 'test_helper/common_setup'
    common_setup
  }

  @test "commit: ticket present builds TICKET: <summary> and commits" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() {
        if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
        if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
        if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'feature/ABC-123-b'; return 0; fi
        if [ \"\$1\" = \"commit\" ] && [ \"\$2\" = \"-m\" ]; then echo \"git_commit_message:\$3\"; return 0; fi
      }
      _dotfiles_commit_generate_message() { echo 'silence brew prompt'; }
      _dotfiles_git_log_commit() { echo 'git_log_commit'; }
      _dotfiles_git_status() { echo 'git_status'; }
      commit
    "
    assert_success
    assert_output --partial "git_commit_message:ABC-123: silence brew prompt"
    assert_output --partial "git_log_commit"
    assert_output --partial "git_status"
  }

  @test "commit: no ticket uses the generated message verbatim" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() {
        if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
        if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
        if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
        if [ \"\$1\" = \"commit\" ] && [ \"\$2\" = \"-m\" ]; then echo \"git_commit_message:\$3\"; return 0; fi
      }
      _dotfiles_commit_generate_message() { echo 'fix(bootstrap): silence brew prompt'; }
      _dotfiles_git_log_commit() { echo 'git_log_commit'; }
      _dotfiles_git_status() { echo 'git_status'; }
      commit
    "
    assert_success
    assert_output --partial "git_commit_message:fix(bootstrap): silence brew prompt"
    refute_output --partial "git_commit_message:ABC"
  }

  @test "commit: nothing staged prints message and skips commit" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() {
        if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
        if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 0; fi
        echo \"git_unexpected_call:\$*\"
        return 0
      }
      _dotfiles_commit_generate_message() { echo 'should-not-be-called'; }
      commit
    "
    assert_success
    assert_output "nothing to commit"
    refute_output --partial "should-not-be-called"
    refute_output --partial "git_unexpected_call"
  }

  @test "commit: falls back to c when message generation fails" {
    run bash -c "
      . '$REPO_ROOT/lib/_shared.sh'
      . '$REPO_ROOT/lib/commands.sh'
      git() {
        if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
        if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
        if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
        echo \"git_commit_message:unexpected\"
        return 0
      }
      _dotfiles_commit_generate_message() { return 1; }
      c() { echo 'c_invoked'; }
      commit
    "
    assert_success
    assert_output --partial "claude unavailable, falling back to manual commit"
    assert_output --partial "c_invoked"
    refute_output --partial "git_commit_message"
  }
  ```

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: all 4 tests FAIL with `commit: command not found`

- [ ] **Step 3: Implement `commit`**

  In `lib/commands.sh`, find this exact block (the `_dotfiles_commit_generate_message` function added in Task 2):

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

  function clean ()
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

  function commit ()
  {
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
      c
      return
    fi

    local message
    message=$(_dotfiles_commit_message "$ticket" "$generated")

    git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
  }

  function clean ()
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: all 4 tests PASS

- [ ] **Step 5: Write the failing regression test for alias removal**

  Append to `tests/commit_command.bats`:

  ```bash

  @test "commit: removes the old non-AI alias" {
    run grep -F "alias commit=" "$REPO_ROOT/lib/commands.sh"
    assert_failure
  }
  ```

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: the new test FAILS (grep finds `alias commit='git commit -ev' # non-signed commit`)

- [ ] **Step 6: Remove the old alias**

  In `lib/commands.sh`, find this exact block (in the aliases section):

  ```bash
  alias cos='co staging'
  alias commit='git commit -ev' # non-signed commit
  alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
  ```

  Replace it with:

  ```bash
  alias cos='co staging'
  alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
  ```

- [ ] **Step 7: Run the tests to verify they all pass**

  Run: `./tests/test_helper/bats-core/bin/bats tests/commit_command.bats`
  Expected: all 5 tests PASS

- [ ] **Step 8: Document the new function**

  In `docs/DEVELOPMENT.md`, find this exact line (in the "Git Workflow with Ticket Numbers" section):

  ```markdown
  - Commit separator configurable via `DOTFILES_COMMIT_SEPARATOR` (default: `:`)
  ```

  Replace it with:

  ```markdown
  - Commit separator configurable via `DOTFILES_COMMIT_SEPARATOR` (default: `:`)

  `commit` (no args) stages everything, asks Claude Haiku to draft the message, and commits — falling back to `c` (manual editor) if Haiku is unavailable or errors.
  ```

- [ ] **Step 9: Run bashcheck**

  Run: `bashcheck lib/commands.sh tests/commit_command.bats`
  Expected: `All files passed`

- [ ] **Step 10: Commit**

  ```bash
  git add lib/commands.sh tests/commit_command.bats docs/DEVELOPMENT.md
  git commit -m "feat(commit): add AI-generated commit function, replace git commit -ev alias"
  ```

---

### Task 4: Full suite verification

**Files:** none (verification only)

- [ ] **Step 1: Run bashcheck across all changed files**

  Run: `bashcheck lib/commands.sh tests/commit_sanitize_message.bats tests/commit_generate_message.bats tests/commit_command.bats`
  Expected: `All files passed`

- [ ] **Step 2: Run the fast unit suite**

  Run: `just test-unit`
  Expected: all tests pass, including the 8 + 7 + 5 new tests added in Tasks 1-3

- [ ] **Step 3: Run the full Docker suite**

  Run: `just test`
  Expected: all bats integration tests and goss infrastructure checks pass

- [ ] **Step 4: Fix forward if anything fails**

  If any step above fails, fix the regression in the relevant task's files, re-run the failing command until it passes, then commit the fix with a message describing what broke (e.g. `git commit -m "fix(commit): correct sed escaping in sanitizer"`). Do not skip ahead — Task 4 is the final gate before the feature is considered done.
