# doctor.sh skills-dir check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `scripts/doctor.sh` so `just doctor` validates the per-skill symlink layout that `bootstrap.sh` now creates across three target dirs, instead of the stale whole-dir-symlink check.

**Architecture:** Add a dedicated `check_skills_dirs()` function mirroring the existing `check_symlinks` / `check_tools` convention. It validates each of the three skills target dirs (`~/.claude/skills`, `~/.config/opencode/skills`, `~/.gemini/config/skills`) is a real directory whose contained symlinks all resolve into `$DOTFILES/skills/`. Remove the obsolete `"~/.claude/skills~skills"` entry from `check_symlinks`, and wire the new check into `main()` with an updated total of 23.

**Tech Stack:** Bash, bats-core (test runner via `./tests/test_helper/bats-core/bin/bats`).

**Reference spec:** `docs/superpowers/specs/2026-05-28-doctor-skills-dir-check-design.md`

---

## File Structure

- `scripts/doctor.sh` — Modify: add `check_skills_dirs()`, remove stale entry from `check_symlinks`, wire into `main()` and bump `total_checks`.
- `tests/doctor.bats` — Modify: add three new tests for `check_skills_dirs`; update the two summary-count tests and the "all checks pass" setup.

---

## Conventions to follow (read before starting)

- Validate any bash edit with `bashcheck scripts/doctor.sh` (never `bash -n`).
- Run the full unit suite with: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats`
- Run a single test by name: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats -f "test name substring"`
- Commit style: single-line `git commit -m "..."`, no Co-Authored-By.
- Do NOT prefix shell commands with `cd` into the repo — use the persisted working dir / absolute paths.

---

### Task 1: Add `check_skills_dirs()` (TDD)

**Files:**
- Modify: `scripts/doctor.sh` (add function after `check_symlinks`, before `check_tools` at line 68)
- Test: `tests/doctor.bats`

- [ ] **Step 1: Write the failing tests**

Add these three tests to `tests/doctor.bats` (after the existing `check_symlinks fails for broken symlink` test, before `check_tools passes for available tool`):

```bash
@test "check_skills_dirs passes for dir of valid skill symlinks" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a" "$DOTFILES/skills/skill-b"
    mkdir -p "$HOME/.claude/skills"
    ln -sf "$DOTFILES/skills/skill-a" "$HOME/.claude/skills/skill-a"
    ln -sf "$DOTFILES/skills/skill-b" "$HOME/.claude/skills/skill-b"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓"* ]]
}

@test "check_skills_dirs fails when target is a whole-dir symlink (old layout)" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a"
    mkdir -p "$HOME/.claude"
    ln -sf "$DOTFILES/skills" "$HOME/.claude/skills"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗"* ]]
    [[ "$output" == *"run: ./bootstrap.sh"* ]]
}

@test "check_skills_dirs fails on a broken skill symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a"
    mkdir -p "$HOME/.claude/skills"
    ln -sf "$DOTFILES/skills/skill-a" "$HOME/.claude/skills/skill-a"
    ln -sf "$DOTFILES/skills/removed-skill" "$HOME/.claude/skills/removed-skill"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗"* ]]
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats -f "check_skills_dirs"`
Expected: FAIL — `check_skills_dirs: command not found` (function not defined yet).

- [ ] **Step 3: Implement `check_skills_dirs()`**

Insert into `scripts/doctor.sh` immediately after the closing `}` of `check_symlinks` (line 66) and before the `# --- Tool check ---` comment:

```bash
# --- Skills directory check ---
check_skills_dirs() {
    local failed=0
    # Target dirs of per-skill symlinks (accepts args to override default list)
    local -a dirs=("$@")
    if [[ ${#dirs[@]} -eq 0 ]]; then
        dirs=(
            "$HOME/.claude/skills"
            "$HOME/.config/opencode/skills"
            "$HOME/.gemini/config/skills"
        )
    fi

    echo "Skills:"
    for dir in "${dirs[@]}"; do
        local display="${dir/#$HOME\//~\/}"

        # Must be a real directory, not the old whole-dir symlink or missing.
        if [[ -L "$dir" || ! -d "$dir" ]]; then
            fail "$display" "run: ./bootstrap.sh"
            failed=1
            continue
        fi

        # Every symlink inside must resolve to an existing dir under $DOTFILES/skills/.
        local dir_ok=1
        local link_path
        for link_path in "$dir"/*; do
            [[ -L "$link_path" ]] || continue
            local resolved
            resolved="$(readlink "$link_path")"
            if [[ "$resolved" != "$DOTFILES/skills/"* || ! -d "$resolved" ]]; then
                dir_ok=0
                break
            fi
        done

        if [[ $dir_ok -eq 1 ]]; then
            pass "$display"
        else
            fail "$display" "run: ./bootstrap.sh"
            failed=1
        fi
    done
    return $failed
}
```

- [ ] **Step 4: Validate syntax**

Run: `bashcheck scripts/doctor.sh`
Expected: no errors.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats -f "check_skills_dirs"`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): add check_skills_dirs for per-skill symlink layout"
```

---

### Task 2: Remove stale skills entry from `check_symlinks` and wire `check_skills_dirs` into `main()`

**Files:**
- Modify: `scripts/doctor.sh` (`check_symlinks` default list line 32; `main()` lines 97–135)
- Test: `tests/doctor.bats` (update the two summary-count tests)

- [ ] **Step 1: Update the failing summary tests first**

In `tests/doctor.bats`, in the test `main exits 0 when all checks pass`:

Remove this line from the `symlinks` array (around line 86):
```bash
        "~/.claude/skills~skills"
```

Then, just before `run main` (after the symlink setup `for` loop ends, around line 100), add setup for the three skills dirs:
```bash
    # Set up valid per-skill symlinks for the three skills target dirs
    mkdir -p "$DOTFILES/skills/skill-a"
    for skills_dir in "$HOME/.claude/skills" "$HOME/.config/opencode/skills" "$HOME/.gemini/config/skills"; do
        mkdir -p "$skills_dir"
        ln -sf "$DOTFILES/skills/skill-a" "$skills_dir/skill-a"
    done
```

Update the assertion in the same test from:
```bash
    [[ "$output" == *"doctor: 21/21 checks passed (0 failures)"* ]]
```
to:
```bash
    [[ "$output" == *"doctor: 23/23 checks passed (0 failures)"* ]]
```

In the test `main exits 1 when checks fail`, update:
```bash
    [[ "$output" == *"doctor: 0/23 checks passed (23 failures)"* ]]
```
(was `0/21 ... (21 failures)`).

- [ ] **Step 2: Run the summary tests to verify they fail**

Run: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats -f "main exits"`
Expected: FAIL — counts still 21 (skills dir check not wired in; stale entry still present).

- [ ] **Step 3: Remove the stale entry from `check_symlinks`**

In `scripts/doctor.sh`, delete this line from the default `symlinks` array (line 32):
```bash
            "~/.claude/skills~skills"
```

- [ ] **Step 4: Wire `check_skills_dirs` into `main()`**

In `scripts/doctor.sh`, update the `total_checks` declaration (line 98) from:
```bash
    local total_checks=21  # 14 symlinks + 7 tools
```
to:
```bash
    local total_checks=23  # 13 symlinks + 3 skills dirs + 7 tools
```

Then, immediately after the symlink-counting `while` loop block (the one ending `done <<< "$symlink_output"`, around line 114) and before the `# Run tool checks` comment, insert:
```bash
    # Run skills directory checks
    local skills_output
    skills_output=$(check_skills_dirs) || true
    output+="$skills_output"$'\n'
    local skills_passed=0 skills_failed=0
    while IFS= read -r line; do
        if [[ "$line" == *"✓"* ]]; then
            (( skills_passed += 1 ))
        elif [[ "$line" == *"✗"* ]]; then
            (( skills_failed += 1 ))
        fi
    done <<< "$skills_output"
```

Update the totals aggregation (lines 129–130) from:
```bash
    passed=$((symlink_passed + tool_passed))
    failed=$((symlink_failed + tool_failed))
```
to:
```bash
    passed=$((symlink_passed + skills_passed + tool_passed))
    failed=$((symlink_failed + skills_failed + tool_failed))
```

- [ ] **Step 5: Validate syntax**

Run: `bashcheck scripts/doctor.sh`
Expected: no errors.

- [ ] **Step 6: Run the full doctor test file to verify all pass**

Run: `./tests/test_helper/bats-core/bin/bats tests/doctor.bats`
Expected: PASS (all tests, including the new `check_skills_dirs` ones and updated summary tests).

- [ ] **Step 7: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): validate three skills dirs and drop stale whole-dir check"
```

---

### Task 3: Full suite verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full unit suite**

Run: `just test-unit`
Expected: all bats tests pass, including `tests/doctor.bats`.

- [ ] **Step 2: Smoke-test the real script**

Run: `just doctor`
Expected: a `Skills:` section listing the three target dirs with `✓` (assuming `./bootstrap.sh` has been run on this machine), and a summary line `doctor: N/23 checks passed`.

- [ ] **Step 3: If anything fails, debug before claiming done**

Use superpowers:systematic-debugging if a test or the live run misbehaves. Do not adjust the expected counts to paper over a real failure.
