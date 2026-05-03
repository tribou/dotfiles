# PATH Deduplication and Homebrew Precedence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure homebrew-installed tools (e.g. `bash`) take precedence over system equivalents by cleaning up PATH duplication and re-adding homebrew paths last.

**Architecture:** Add `_path_strip` and `_path_dedup` helpers to a new `lib/path.sh` (auto-sourced by `lib/index.sh`). After `lib/index.sh` is sourced in `bash_profile`, strip stale homebrew entries, deduplicate all remaining PATH entries, then re-run `brew shellenv` so homebrew paths are cleanly first.

**Tech Stack:** bash, bats-core (unit tests)

---

### Task 1: Create `lib/path.sh` with helper functions

**Files:**
- Create: `lib/path.sh`

**Step 1: Write the failing test**

Create `tests/path.bats`:

```bash
setup() {
  load 'test_helper/common_setup'
  common_setup
  . "$REPO_ROOT/lib/path.sh"
}

@test "_path_strip removes entries matching a single glob pattern" {
  export PATH="/usr/bin:/opt/homebrew/bin:/bin"
  _path_strip "*homebrew*"
  assert_equal "$PATH" "/usr/bin:/bin"
}

@test "_path_strip removes entries matching multiple glob patterns" {
  export PATH="/usr/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/bin"
  _path_strip "*homebrew*" "*linuxbrew*"
  assert_equal "$PATH" "/usr/bin:/bin"
}

@test "_path_strip preserves PATH when no entries match" {
  export PATH="/usr/bin:/usr/local/bin:/bin"
  _path_strip "*homebrew*"
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_strip handles empty PATH" {
  export PATH=""
  _path_strip "*homebrew*"
  assert_equal "$PATH" ""
}

@test "_path_dedup removes duplicate entries preserving first occurrence" {
  export PATH="/usr/bin:/usr/local/bin:/usr/bin:/bin"
  _path_dedup
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_dedup preserves order of first occurrences" {
  export PATH="/a:/b:/c:/b:/a"
  _path_dedup
  assert_equal "$PATH" "/a:/b:/c"
}

@test "_path_dedup is a no-op on a PATH with no duplicates" {
  export PATH="/usr/bin:/usr/local/bin:/bin"
  _path_dedup
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_dedup handles empty PATH" {
  export PATH=""
  _path_dedup
  assert_equal "$PATH" ""
}
```

**Step 2: Run tests to confirm they fail**

```bash
just test-unit -- --filter path
```

Expected: FAIL — `lib/path.sh` does not exist yet.

**Step 3: Create `lib/path.sh`**

```bash
#!/bin/bash

# Removes PATH entries matching any of the given glob patterns.
# Usage: _path_strip "*homebrew*" "*linuxbrew*"
_path_strip() {
  local new_path="" dir match pattern
  while IFS= read -r -d: dir; do
    match=0
    for pattern in "$@"; do
      case "$dir" in $pattern) match=1; break ;; esac
    done
    [ "$match" -eq 0 ] && new_path="${new_path:+$new_path:}$dir"
  done <<< "${PATH}:"
  export PATH="$new_path"
}

# Deduplicates PATH entries, preserving first-occurrence order.
# Usage: _path_dedup
_path_dedup() {
  local new_path="" dir
  while IFS= read -r -d: dir; do
    case ":$new_path:" in
      *":$dir:"*) ;;
      *) new_path="${new_path:+$new_path:}$dir" ;;
    esac
  done <<< "${PATH}:"
  export PATH="$new_path"
}
```

**Step 4: Run tests to confirm they pass**

```bash
just test-unit -- --filter path
```

Expected: all 8 tests PASS.

**Step 5: Syntax check**

```bash
bashcheck lib/path.sh
```

Expected: no errors or warnings.

**Step 6: Commit**

```bash
git add lib/path.sh tests/path.bats
git commit -m "Add _path_strip and _path_dedup helpers to lib/path.sh"
```

---

### Task 2: Update `bash_profile` to use the helpers

**Files:**
- Modify: `bash_profile`

**Step 1: Locate the insertion point**

The new block goes after `. "$DOTFILES/lib/index.sh"` (currently line 311).

**Step 2: Add the PATH cleanup block**

After the line `. "$DOTFILES/lib/index.sh"`, add:

```bash
# Deduplicate PATH and ensure homebrew takes precedence
_path_strip "*homebrew*" "*linuxbrew*"
_path_dedup
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

**Step 3: Syntax check**

```bash
bashcheck bash_profile
```

Expected: no errors or warnings.

**Step 4: Run full test suite**

```bash
just test-unit
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add bash_profile
git commit -m "Deduplicate PATH and ensure homebrew takes precedence at shell startup"
```

---

### Task 3: Verify end-to-end (manual)

On the target macOS machine, open a new terminal session and run:

```bash
echo $PATH | tr ':' '\n' | head -5
```

Expected: `/opt/homebrew/bin` and `/opt/homebrew/sbin` appear in the first two lines.

```bash
echo $PATH | tr ':' '\n' | sort | uniq -d
```

Expected: no output (no duplicate entries).

```bash
which bash
```

Expected: `/opt/homebrew/bin/bash` (not `/bin/bash`).
