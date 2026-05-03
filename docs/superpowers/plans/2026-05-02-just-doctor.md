# Just Doctor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `just doctor` command that runs a bash script to verify symlink integrity and tool presence, with human-readable output and bats-core tests.

**Architecture:** Pure bash script `scripts/doctor.sh` with per-category check functions, output helpers, and a main guard to allow sourcing for tests. The `main` function aggregates check results, prints a summary, and exits non-zero if any check fails. A Justfile recipe invokes the script. Bats-core tests in `tests/doctor.bats` source the script and test individual functions.

**Tech Stack:** Bash, bats-core, Just

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `scripts/doctor.sh` | Create | Main health check script with check functions, output helpers, main guard |
| `Justfile` | Modify | Add `doctor` recipe to invoke `./scripts/doctor.sh` |
| `tests/doctor.bats` | Create | Bats-core tests for all doctor.sh functionality |

---

### Task 1: Create doctor.sh skeleton with output helpers and main guard

**Files:**
- Create: `scripts/doctor.sh`
- Test: `tests/doctor.bats` (initial test)

- [ ] **Step 1: Write failing test for main guard**

Create `tests/doctor.bats` with:
```bats
#!/usr/bin/env bats

setup() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
}

@test "main guard prevents automatic execution when sourced" {
    run bash -c 'source scripts/doctor.sh && echo $?'
    [ "$status" -eq 0 ]
    # When sourced, main should not run, so no output
    [ "${lines[0]}" = "" ]
}
```

Run: `bats tests/doctor.bats -v`
Expected: FAIL (doctor.sh doesn't exist yet)

- [ ] **Step 2: Run test to verify failure**

Run: `bats tests/doctor.bats -v`
Expected: FAIL with "scripts/doctor.sh: No such file or directory"

- [ ] **Step 3: Write minimal doctor.sh skeleton**

Create `scripts/doctor.sh` with:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Script directory and DOTFILES root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Output helpers ---
pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s → %s\n' "$1" "$2"; }

# --- Main ---
main() {
    echo "doctor: starting checks"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

- [ ] **Step 4: Run test to verify pass**

Run: `bats tests/doctor.bats -v`
Expected: PASS (main guard works, no automatic execution when sourced)

- [ ] **Step 5: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): add doctor.sh skeleton with main guard and output helpers"
```

---

### Task 2: Implement check_symlinks function

**Files:**
- Modify: `scripts/doctor.sh` (add check_symlinks)
- Test: `tests/doctor.bats` (add symlink check tests)

- [ ] **Step 1: Write failing test for valid symlink**

Add to `tests/doctor.bats`:
```bats
@test "check_symlinks passes for valid symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    echo "test" > "$DOTFILES/test-file"
    ln -sf "$DOTFILES/test-file" "$HOME/.test-link"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run check_symlinks
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ ~/.test-link"* ]]
}
```

Run: `bats tests/doctor.bats::check_symlinks-valid -v`
Expected: FAIL (check_symlinks not defined)

- [ ] **Step 2: Run test to verify failure**

Run: `bats tests/doctor.bats -v`
Expected: FAIL with "check_symlinks: command not found"

- [ ] **Step 3: Implement check_symlinks in doctor.sh**

Add after output helpers:
```bash
# --- Check functions ---
check_symlinks() {
    local failed=0
    # Symlink definitions: "target~source"
    local symlinks=(
        "~/.bash_profile~bash_profile"
        "~/.vimrc~init.vim"
        "~/.gitconfig~gitconfig"
        "~/.zshrc~zshrc"
        "~/.tmux.conf~tmux/tmux-conf"
        "~/.default-node-packages~default-node-packages"
        "~/.default-gems~default-gems"
        "~/.default-python-packages~default-python-packages"
        "~/.gnupg/gpg-agent.conf~gpg-agent-conf"
        "~/.config/nvim/init.vim~init.vim"
        "~/.config/alacritty/alacritty.toml~alacritty.toml"
        "~/.config/mise/config.toml~mise-config.toml"
        "~/.config/nvim/coc-settings.json~coc-settings.json"
        "~/.claude/skills~skills"
    )

    echo "Symlinks:"
    for link in "${symlinks[@]}"; do
        local target="${link%~*}"
        local source="${link#*~}"
        local target_path="${target/#\~/$HOME}"
        local expected_source="$DOTFILES/$source"

        if [[ ! -e "$target_path" ]]; then
            fail "$target" "run: ./bootstrap.sh"
            failed=1
        elif [[ ! -L "$target_path" ]]; then
            fail "$target" "run: ./bootstrap.sh"
            failed=1
        else
            local link_target
            if [[ "$(uname)" == "Darwin" ]]; then
                link_target="$(readlink "$target_path")"
            else
                link_target="$(readlink -f "$target_path")"
            fi
            if [[ "$link_target" != "$expected_source" ]]; then
                fail "$target" "run: ./bootstrap.sh"
                failed=1
            else
                pass "$target"
            fi
        fi
    done
    return $failed
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `bats tests/doctor.bats::check_symlinks-valid -v`
Expected: PASS

- [ ] **Step 5: Add test for broken symlink**

Add to `tests/doctor.bats`:
```bats
@test "check_symlinks fails for broken symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    echo "test" > "$DOTFILES/test-file"
    ln -sf "$DOTFILES/non-existent" "$HOME/.test-link"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run check_symlinks
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗ ~/.test-link → run: ./bootstrap.sh"* ]]
}
```

Run: `bats tests/doctor.bats::check_symlinks-broken -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): implement check_symlinks with 14 symlink checks"
```

---

### Task 3: Implement check_tools function

**Files:**
- Modify: `scripts/doctor.sh` (add check_tools)
- Test: `tests/doctor.bats` (add tool check tests)

- [ ] **Step 1: Write failing test for available tool**

Add to `tests/doctor.bats`:
```bats
@test "check_tools passes for available tool" {
    export PATH="$(mktemp -d):$PATH"
    local tool_dir="$(echo "$PATH" | cut -d: -f1)"
    touch "$tool_dir/git"
    chmod +x "$tool_dir/git"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run check_tools
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ git"* ]]
}
```

Run: `bats tests/doctor.bats::check_tools-present -v`
Expected: FAIL (check_tools not defined)

- [ ] **Step 2: Run test to verify failure**

Run: `bats tests/doctor.bats -v`
Expected: FAIL with "check_tools: command not found"

- [ ] **Step 3: Implement check_tools in doctor.sh**

Add after check_symlinks:
```bash
check_tools() {
    local failed=0
    # Tool definitions: "tool~remediation"
    local tools=(
        "git~run: brew install git"
        "nvim~run: brew install neovim"
        "tmux~run: brew install tmux"
        "mise~run: brew install mise"
        "node~run: mise install node"
        "go~run: mise install go"
        "bun~run: mise install bun"
    )

    echo "Tools:"
    for tool in "${tools[@]}"; do
        local cmd="${tool%~*}"
        local remediation="${tool#*~}"
        if command -v "$cmd" &>/dev/null; then
            pass "$cmd"
        else
            fail "$cmd" "$remediation"
            failed=1
        fi
    done
    return $failed
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `bats tests/doctor.bats::check_tools-present -v`
Expected: PASS

- [ ] **Step 5: Add test for missing tool**

Add to `tests/doctor.bats`:
```bats
@test "check_tools fails for missing tool" {
    export PATH="$(mktemp -d)"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run check_tools
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗ go → run: mise install go"* ]]
}
```

Run: `bats tests/doctor.bats::check_tools-missing -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): implement check_tools with 7 tool checks"
```

---

### Task 4: Implement main function with summary and exit codes

**Files:**
- Modify: `scripts/doctor.sh` (update main function)
- Test: `tests/doctor.bats` (add main function tests)

- [ ] **Step 1: Write failing test for main exit 0 when all pass**

Add to `tests/doctor.bats`:
```bats
@test "main exits 0 when all checks pass" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    
    # Set up valid symlinks for all 14 entries
    local symlinks=(
        "~/.bash_profile~bash_profile"
        "~/.vimrc~init.vim"
        "~/.gitconfig~gitconfig"
        "~/.zshrc~zshrc"
        "~/.tmux.conf~tmux/tmux-conf"
        "~/.default-node-packages~default-node-packages"
        "~/.default-gems~default-gems"
        "~/.default-python-packages~default-python-packages"
        "~/.gnupg/gpg-agent.conf~gpg-agent-conf"
        "~/.config/nvim/init.vim~init.vim"
        "~/.config/alacritty/alacritty.toml~alacritty.toml"
        "~/.config/mise/config.toml~mise-config.toml"
        "~/.config/nvim/coc-settings.json~coc-settings.json"
        "~/.claude/skills~skills"
    )
    
    for link in "${symlinks[@]}"; do
        local target="${link%~*}"
        local source="${link#*~}"
        local target_path="${target/#\~/$HOME}"
        local source_path="$DOTFILES/$source"
        mkdir -p "$(dirname "$target_path")"
        echo "test" > "$source_path"
        ln -sf "$source_path" "$target_path"
    done
    
    # Add all tools to PATH
    export PATH="$(mktemp -d):$PATH"
    local tool_dir="$(echo "$PATH" | cut -d: -f1)"
    for cmd in git nvim tmux mise node go bun; do
        touch "$tool_dir/$cmd"
        chmod +x "$tool_dir/$cmd"
    done
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"doctor: 21/21 checks passed (0 failures)"* ]]
}
```

Run: `bats tests/doctor.bats::main-exit-0 -v`
Expected: FAIL (main function is stubbed)

- [ ] **Step 2: Run test to verify failure**

Run: `bats tests/doctor.bats -v`
Expected: FAIL (main doesn't run checks)

- [ ] **Step 3: Implement main function in doctor.sh**

Replace the stub main() with:
```bash
main() {
    local total_checks=21  # 14 symlinks + 7 tools
    local output=""
    local passed=0
    local failed=0

    # Run symlink checks
    local symlink_output
    symlink_output=$(check_symlinks)
    output+="$symlink_output"$'\n'
    local symlink_passed=$(echo "$symlink_output" | grep -c '✓' || true)
    local symlink_failed=$(echo "$symlink_output" | grep -c '✗' || true)

    # Run tool checks
    local tool_output
    tool_output=$(check_tools)
    output+="$tool_output"$'\n'
    local tool_passed=$(echo "$tool_output" | grep -c '✓' || true)
    local tool_failed=$(echo "$tool_output" | grep -c '✗' || true)

    passed=$((symlink_passed + tool_passed))
    failed=$((symlink_failed + tool_failed))

    # Print all output
    echo "$output"
    # Print summary
    echo "doctor: $passed/$total_checks checks passed ($failed failures)"
    
    # Exit with appropriate code
    if [[ $failed -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `bats tests/doctor.bats::main-exit-0 -v`
Expected: PASS

- [ ] **Step 5: Add test for main exit 1 when checks fail**

Add to `tests/doctor.bats`:
```bats
@test "main exits 1 when checks fail" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    # No symlinks set up (all fail)
    export PATH="$(mktemp -d)"  # No tools (all fail)
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
    source "$SCRIPT_DIR/doctor.sh"
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"doctor: 0/21 checks passed (21 failures)"* ]]
}
```

Run: `bats tests/doctor.bats::main-exit-1 -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(doctor): implement main function with summary and exit codes"
```

---

### Task 5: Add doctor recipe to Justfile

**Files:**
- Modify: `Justfile`

- [ ] **Step 1: Write failing test for Justfile doctor recipe**

Add to `tests/doctor.bats`:
```bats
@test "Justfile has doctor recipe" {
    run grep -A 2 '^doctor:' Justfile
    [ "$status" -eq 0 ]
    [[ "$output" == *"./scripts/doctor.sh"* ]]
}
```

Run: `bats tests/doctor.bats::justfile-doctor-recipe -v`
Expected: FAIL (recipe not present)

- [ ] **Step 2: Run test to verify failure**

Run: `bats tests/doctor.bats -v`
Expected: FAIL

- [ ] **Step 3: Add doctor recipe to Justfile**

Add to `Justfile`:
```just
# Run local health checks (symlinks, tools)
doctor:
    ./scripts/doctor.sh
```

- [ ] **Step 4: Run test to verify pass**

Run: `bats tests/doctor.bats::justfile-doctor-recipe -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Justfile
git commit -m "feat(doctor): add doctor recipe to Justfile"
```

---

## Self-Review

1. **Spec coverage:**
   - ✅ `scripts/doctor.sh` with main guard: Task 1
   - ✅ 14 symlink checks: Task 2
   - ✅ 7 tool checks: Task 3
   - ✅ Main function with summary/exit codes: Task 4
   - ✅ Justfile recipe: Task 5
   - ✅ Bats tests for all components: Tasks 1-5
   - ✅ Output format (✓/✗, remediation): Tasks 2-3
   - ✅ Exit 0 (all pass) / 1 (any fail): Task 4

2. **Placeholder scan:** No TBD/TODO/placeholder content found. All code blocks are complete.

3. **Consistency:** All function names (`check_symlinks`, `check_tools`, `main`, `pass`, `fail`) are consistent across tasks. Symlink/tool definitions match the spec exactly.

---

Plan complete and saved to `docs/superpowers/plans/2026-05-02-just-doctor.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?