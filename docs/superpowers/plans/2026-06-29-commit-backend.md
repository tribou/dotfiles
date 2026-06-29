# Configurable Commit Backend (claude ↔ opencode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the `commit` command generate its AI message via either Claude (default) or opencode/Kimi, switchable through `commit`'s own subcommands.

**Architecture:** A single env var `DOTFILES_COMMIT_BACKEND` selects the backend (`claude`|`opencode`). Two pure-shell helpers resolve the effective backend and its fixed per-backend model. `_dotfiles_commit_generate_message` dispatches the diff to the right CLI. The `commit` function gains `status` and `backend` subcommands; the durable default lives in the committed `bash_profile`.

**Tech Stack:** Bash (functions in `lib/commands.sh`), bats-core unit tests, `claude` / `opencode` CLIs.

## Global Constraints

- Git commits: single-line only via `git commit -m "..."`, no `Co-Authored-By`.
- Bash syntax checking: use `bashcheck <file>` (a function in `lib/commands.sh`), never `bash -n`.
- TDD: every change starts with a failing bats test, then implementation.
- After changes run `just test-unit`, then `just test`.
- Per-backend models are FIXED in code (no `DOTFILES_COMMIT_MODEL`): claude → `haiku`, opencode → `opencode-go/kimi-k2.7-code`.
- Run a single bats file with: `just test-unit tests/<file>.bats`.
- Test files source libs via `common_setup` (sources `lib/_shared.sh` then `lib/commands.sh`, exports `_dotfiles_*`). `commit`/`c` are NOT exported, so tests that drive them source the libs inside `bash -c`.

---

## File Structure

- **Modify** `lib/commands.sh`:
  - Add `_dotfiles_commit_backend` and `_dotfiles_commit_model` helpers (near `_dotfiles_commit_prompt`, ~line 87).
  - Refactor `_dotfiles_commit_generate_message` (~lines 134–147) to dispatch on backend.
  - Add subcommand dispatch to the top of `commit` (~line 179) and make its fallback message backend-aware (~line 212).
- **Modify** `bash_profile`: add the durable default export (after line 82).
- **Create** `tests/commit_backend.bats`: helpers + `commit status` + `commit backend` subcommands.
- **Modify** `tests/commit_generate_message.bats`: opencode dispatch cases.
- **Modify** `tests/commit_command.bats`: backend-aware fallback message case.

---

## Task 1: Backend + model resolver helpers

**Files:**
- Modify: `lib/commands.sh` (insert after `_dotfiles_commit_prompt`, before `_dotfiles_spinner_wait`, ~line 87)
- Test: `tests/commit_backend.bats` (create)

**Interfaces:**
- Produces:
  - `_dotfiles_commit_backend` — reads `$DOTFILES_COMMIT_BACKEND`, echoes `claude` or `opencode` (unknown → warns to stderr, echoes `claude`). No trailing newline.
  - `_dotfiles_commit_model <backend>` — echoes the fixed model for that backend (`opencode` → `opencode-go/kimi-k2.7-code`, anything else → `haiku`). No trailing newline.

- [ ] **Step 1: Write the failing tests**

Create `tests/commit_backend.bats`:

```bash
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# --- _dotfiles_commit_backend ---

@test "commit_backend: defaults to claude when unset" {
  unset DOTFILES_COMMIT_BACKEND
  run _dotfiles_commit_backend
  assert_success
  assert_output "claude"
}

@test "commit_backend: honors opencode" {
  export DOTFILES_COMMIT_BACKEND=opencode
  run _dotfiles_commit_backend
  assert_success
  assert_output "opencode"
}

@test "commit_backend: unknown value warns to stderr and falls back to claude" {
  export DOTFILES_COMMIT_BACKEND=bogus
  run --separate-stderr _dotfiles_commit_backend
  assert_success
  assert_output "claude"
  echo "$stderr" | grep -qF 'unknown DOTFILES_COMMIT_BACKEND=bogus'
}

# --- _dotfiles_commit_model ---

@test "commit_model: claude backend uses haiku" {
  run _dotfiles_commit_model claude
  assert_success
  assert_output "haiku"
}

@test "commit_model: opencode backend uses kimi 2.7" {
  run _dotfiles_commit_model opencode
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `just test-unit tests/commit_backend.bats`
Expected: FAIL — `_dotfiles_commit_backend`/`_dotfiles_commit_model: command not found`.

- [ ] **Step 3: Implement the helpers**

In `lib/commands.sh`, immediately after the closing `}` of `_dotfiles_commit_prompt` (~line 87), add:

```bash
function _dotfiles_commit_backend ()
{
  local backend="${DOTFILES_COMMIT_BACKEND:-claude}"
  case "$backend" in
    claude|opencode) printf '%s' "$backend" ;;
    *)
      printf 'unknown DOTFILES_COMMIT_BACKEND=%s, using claude\n' "$backend" >&2
      printf '%s' 'claude'
      ;;
  esac
}

function _dotfiles_commit_model ()
{
  local backend="$1"
  case "$backend" in
    opencode) printf '%s' 'opencode-go/kimi-k2.7-code' ;;
    *)        printf '%s' 'haiku' ;;
  esac
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `just test-unit tests/commit_backend.bats`
Expected: PASS (5 tests).

- [ ] **Step 5: Syntax check and commit**

```bash
bashcheck lib/commands.sh
git add lib/commands.sh tests/commit_backend.bats
git commit -m "feat(commit): add backend and model resolver helpers"
```

---

## Task 2: Dispatch message generation to the active backend

**Files:**
- Modify: `lib/commands.sh` — `_dotfiles_commit_generate_message` (~lines 134–147)
- Test: `tests/commit_generate_message.bats`

**Interfaces:**
- Consumes: `_dotfiles_commit_backend`, `_dotfiles_commit_model` (Task 1).
- Produces: `_dotfiles_commit_generate_message <ticket>` unchanged signature — now uses the resolved backend's CLI; availability check targets the backend binary.

- [ ] **Step 1: Write the failing tests**

Append to `tests/commit_generate_message.bats`:

```bash
@test "generate_message: opencode backend invokes opencode run with the kimi model" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    git() { echo 'mock diff'; }
    opencode() { printf '%s' \"\$3\"; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
}

@test "generate_message: opencode backend fails when opencode is not on PATH" {
  local empty_path
  empty_path="$(mktemp -d)"
  run bash -c "
    export PATH='$empty_path'
    export DOTFILES_COMMIT_BACKEND=opencode
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
  rm -rf "$empty_path"
}
```

(The first stub echoes `$3`, which is the `--model` value, so the captured "message" equals the model — proving opencode was invoked with the right model.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `just test-unit tests/commit_generate_message.bats`
Expected: FAIL — opencode test outputs nothing/uses claude (the new opencode test fails); the existing claude tests still pass.

- [ ] **Step 3: Refactor the generator**

In `lib/commands.sh`, replace this block inside `_dotfiles_commit_generate_message`:

```bash
  if ! command -v claude > /dev/null 2>&1
  then
    return 1
  fi

  local outfile
  outfile=$(mktemp)

  git diff --cached | head -c 100000 | claude -p --model haiku "$(_dotfiles_commit_prompt "$ticket")" > "$outfile" &
  local pid=$!
```

with:

```bash
  local backend model
  backend=$(_dotfiles_commit_backend)
  model=$(_dotfiles_commit_model "$backend")

  if ! command -v "$backend" > /dev/null 2>&1
  then
    return 1
  fi

  local outfile
  outfile=$(mktemp)

  case "$backend" in
    opencode)
      git diff --cached | head -c 100000 \
        | opencode run --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
          > "$outfile" 2> /dev/null &
      ;;
    *)
      git diff --cached | head -c 100000 \
        | claude -p --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
          > "$outfile" &
      ;;
  esac
  local pid=$!
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `just test-unit tests/commit_generate_message.bats`
Expected: PASS — all existing claude tests plus the two new opencode tests.

- [ ] **Step 5: Syntax check and commit**

```bash
bashcheck lib/commands.sh
git add lib/commands.sh tests/commit_generate_message.bats
git commit -m "feat(commit): dispatch message generation to the active backend"
```

---

## Task 3: Backend-aware fallback message

**Files:**
- Modify: `lib/commands.sh` — `commit` fallback branch (~line 212)
- Test: `tests/commit_command.bats`

**Interfaces:**
- Consumes: `_dotfiles_commit_backend` (Task 1).

- [ ] **Step 1: Write the failing test**

Append to `tests/commit_command.bats`:

```bash
@test "commit: fallback message names the active backend (opencode)" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
      if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
      return 0
    }
    _dotfiles_commit_generate_message() { return 1; }
    c() { echo 'c_invoked'; }
    commit
  "
  assert_success
  assert_output --partial "opencode unavailable, falling back to manual commit"
  assert_output --partial "c_invoked"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `just test-unit tests/commit_command.bats`
Expected: FAIL — output says "claude unavailable…" not "opencode unavailable…".

- [ ] **Step 3: Make the message dynamic**

In `lib/commands.sh`, inside `commit`, replace:

```bash
    echo "claude unavailable, falling back to manual commit" >&2
```

with:

```bash
    echo "$(_dotfiles_commit_backend) unavailable, falling back to manual commit" >&2
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `just test-unit tests/commit_command.bats`
Expected: PASS — the new opencode test plus the existing "claude unavailable" test (unset backend → `claude`).

- [ ] **Step 5: Syntax check and commit**

```bash
bashcheck lib/commands.sh
git add lib/commands.sh tests/commit_command.bats
git commit -m "feat(commit): name the active backend in the fallback message"
```

---

## Task 4: `commit status` subcommand

**Files:**
- Modify: `lib/commands.sh` — add dispatch at the top of `commit` (~line 179, right after the opening `{`)
- Test: `tests/commit_backend.bats`

**Interfaces:**
- Consumes: `_dotfiles_commit_backend`, `_dotfiles_commit_model` (Task 1).
- Produces: `commit status` prints three aligned lines: `backend:`, `model:`, `available:` (yes/no from `command -v <backend>`), returns 0. Reserves `status` as a first-arg keyword; all other args fall through to the existing commit behavior.

- [ ] **Step 1: Write the failing tests**

Append to `tests/commit_backend.bats`:

```bash
# --- commit status ---

@test "commit status: reports opencode backend, model, availability" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:   opencode"
  assert_output --partial "model:     opencode-go/kimi-k2.7-code"
  assert_output --partial "available: yes"
}

@test "commit status: defaults to claude/haiku" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    unset DOTFILES_COMMIT_BACKEND
    claude() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:   claude"
  assert_output --partial "model:     haiku"
}
```

(`command -v` succeeds for shell functions, so defining `opencode()`/`claude()` makes `available: yes` deterministic regardless of what's installed.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `just test-unit tests/commit_backend.bats`
Expected: FAIL — `commit status` runs the normal commit path (no `backend:` output).

- [ ] **Step 3: Add the `status` branch**

In `lib/commands.sh`, immediately after `function commit ()` and its opening `{`, before the `if [ -f "./.git/MERGE_HEAD" ]` line, insert:

```bash
  case "$1" in
    status)
      local b m avail=no
      b=$(_dotfiles_commit_backend)
      m=$(_dotfiles_commit_model "$b")
      command -v "$b" > /dev/null 2>&1 && avail=yes
      printf 'backend:   %s\nmodel:     %s\navailable: %s\n' "$b" "$m" "$avail"
      return 0
      ;;
  esac
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `just test-unit tests/commit_backend.bats`
Expected: PASS (all Task 1 + Task 4 tests).

- [ ] **Step 5: Syntax check and commit**

```bash
bashcheck lib/commands.sh
git add lib/commands.sh tests/commit_backend.bats
git commit -m "feat(commit): add commit status subcommand"
```

---

## Task 5: `commit backend <name>` setter / getter

**Files:**
- Modify: `lib/commands.sh` — extend the `case "$1"` dispatch in `commit`
- Test: `tests/commit_backend.bats`

**Interfaces:**
- Consumes: `_dotfiles_commit_backend`, `_dotfiles_commit_model` (Task 1).
- Produces: within `commit`'s top-level `case`, a `backend)` branch:
  - `commit backend` (no value) → prints current effective backend, returns 0.
  - `commit backend claude|opencode` → `export DOTFILES_COMMIT_BACKEND=<value>`, prints `commit backend set to <value> (model: <model>) for this shell`, returns 0.
  - `commit backend <other>` → prints `unknown backend: <other> (expected claude or opencode)` to stderr, returns 1, leaves the env var unchanged.

- [ ] **Step 1: Write the failing tests**

Append to `tests/commit_backend.bats`:

```bash
# --- commit backend (setter/getter) ---

@test "commit backend opencode: exports the backend for the current shell" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    commit backend opencode > /dev/null
    echo \"BACKEND=\$DOTFILES_COMMIT_BACKEND\"
  "
  assert_success
  assert_output --partial "BACKEND=opencode"
}

@test "commit backend opencode: prints a confirmation including the model" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    commit backend opencode
  "
  assert_success
  assert_output --partial "commit backend set to opencode (model: opencode-go/kimi-k2.7-code) for this shell"
}

@test "commit backend: with no value prints the current backend" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    commit backend
  "
  assert_success
  assert_output "opencode"
}

@test "commit backend bogus: errors, returns 1, leaves the backend unchanged" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=claude
    commit backend bogus
    echo \"RC=\$? BACKEND=\$DOTFILES_COMMIT_BACKEND\"
  "
  assert_success
  assert_output --partial "RC=1 BACKEND=claude"
  echo "$stderr" | grep -qF 'unknown backend: bogus'
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `just test-unit tests/commit_backend.bats`
Expected: FAIL — `commit backend …` falls through to the normal commit path.

- [ ] **Step 3: Add the `backend` branch**

In `lib/commands.sh`, extend the `case "$1"` block in `commit` (added in Task 4) so it reads:

```bash
  case "$1" in
    status)
      local b m avail=no
      b=$(_dotfiles_commit_backend)
      m=$(_dotfiles_commit_model "$b")
      command -v "$b" > /dev/null 2>&1 && avail=yes
      printf 'backend:   %s\nmodel:     %s\navailable: %s\n' "$b" "$m" "$avail"
      return 0
      ;;
    backend)
      shift
      if [ -z "$1" ]
      then
        printf '%s\n' "$(_dotfiles_commit_backend)"
        return 0
      fi
      case "$1" in
        claude|opencode)
          export DOTFILES_COMMIT_BACKEND="$1"
          printf 'commit backend set to %s (model: %s) for this shell\n' \
            "$1" "$(_dotfiles_commit_model "$1")"
          return 0
          ;;
        *)
          printf 'unknown backend: %s (expected claude or opencode)\n' "$1" >&2
          return 1
          ;;
      esac
      ;;
  esac
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `just test-unit tests/commit_backend.bats`
Expected: PASS (all backend tests).

- [ ] **Step 5: Syntax check and commit**

```bash
bashcheck lib/commands.sh
git add lib/commands.sh tests/commit_backend.bats
git commit -m "feat(commit): add commit backend switch subcommand"
```

---

## Task 6: Durable default in `bash_profile` + full verification

**Files:**
- Modify: `bash_profile` (after line 82, the `REACT_EDITOR` export)
- Test: `tests/commit_backend.bats`

**Interfaces:**
- Produces: a tracked `export DOTFILES_COMMIT_BACKEND=claude` that ships the cross-machine default.

- [ ] **Step 1: Write the failing test**

Append to `tests/commit_backend.bats`:

```bash
# --- durable default ---

@test "bash_profile: exports a DOTFILES_COMMIT_BACKEND default" {
  run grep -E "^export DOTFILES_COMMIT_BACKEND=" "$REPO_ROOT/bash_profile"
  assert_success
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `just test-unit tests/commit_backend.bats`
Expected: FAIL — grep finds no match (exit 1).

- [ ] **Step 3: Add the export**

In `bash_profile`, after line 82 (`export REACT_EDITOR='vscode'`), add:

```bash

# Commit AI backend: claude or opencode (opencode uses Kimi 2.7)
export DOTFILES_COMMIT_BACKEND=claude
```

- [ ] **Step 4: Run test to verify it passes**

Run: `just test-unit tests/commit_backend.bats`
Expected: PASS.

- [ ] **Step 5: Run the full unit suite, then the Docker suite**

```bash
just test-unit
just test
```
Expected: all bats tests pass; the full Docker suite passes. If any pre-existing commit test regressed, fix before committing.

- [ ] **Step 6: Syntax check and commit**

```bash
bashcheck bash_profile lib/commands.sh
git add bash_profile tests/commit_backend.bats
git commit -m "feat(commit): ship claude as the default commit backend"
```

---

## Self-Review

**Spec coverage:**
- `DOTFILES_COMMIT_BACKEND` env + default → Task 1 (helper), Task 6 (`bash_profile`). ✓
- Per-backend fixed models (haiku / kimi-k2.7-code) → Task 1 (`_dotfiles_commit_model`). ✓
- Backend dispatch in generate (claude unchanged, opencode + stderr suppression, stdin diff) → Task 2. ✓
- `command -v` keyed off active backend → Task 2. ✓
- `commit` default behavior unchanged / args fall through → Tasks 4 & 5 (reserved keywords only). ✓
- `commit status` (backend, model, availability) → Task 4. ✓
- `commit backend <name>` setter exporting in-shell + getter + invalid → Task 5. ✓
- Backend-aware fallback message → Task 3. ✓
- Durable default in committed `bash_profile` → Task 6. ✓
- No `DOTFILES_COMMIT_MODEL` / no model setter (out of scope) → not implemented. ✓

**Placeholder scan:** No TBD/TODO; every code and test step has complete content. ✓

**Type/name consistency:** `_dotfiles_commit_backend` and `_dotfiles_commit_model` names match across Tasks 1–5. `DOTFILES_COMMIT_BACKEND` spelled consistently. Confirmation/error strings in Task 5 implementation match the Task 5 test assertions verbatim. ✓
