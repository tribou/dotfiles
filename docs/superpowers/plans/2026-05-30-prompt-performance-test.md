# Prompt Performance Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a performance budget test for the terminal prompt to guard against latency regressions in prompt hooks and layout evaluation.

**Architecture:** A bats-core unit test (`tests/prompt_performance.bats`) that sources `bash_profile` inside a subshell, simulates the interactive prompt cycle (PROMPT_COMMAND + PS1 expansion), measures the render latency in both git and non-git directories using `EPOCHREALTIME` (taking the best of 3 runs to minimize noise), and asserts against a defined budget.

**Tech Stack:** bats-core, GNU Bash 5.x

---

### Task 1: Create prompt performance test with failing budget (TDD)

**Files:**
- Create: `tests/prompt_performance.bats`

- [ ] **Step 1: Write the prompt performance test with an impossibly low budget (TDD)**

Write the following content to `tests/prompt_performance.bats`:

```bash
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "performance: prompt latency is within budget" {
  # Set TERM to avoid terminal warnings and ensure tput functions correctly
  export TERM=xterm-256color

  # Create a temporary non-git directory using BATS_TEST_TMPDIR
  local nongit_dir="$BATS_TEST_TMPDIR/non-git-dir"
  mkdir -p "$nongit_dir"

  # Helper function to run the prompt lifecycle (PROMPT_COMMAND + PS1 expansion)
  # inside a subshell for a given target directory
  run_measure() {
    local target_dir="$1"
    bash -c '
      source "$REPO_ROOT/bash_profile" >/dev/null 2>&1
      
      # Force interactive prompt settings
      export PS1="\[\033[0;34m\]\W \$(get_git_location) > \[$(tput sgr0 2>/dev/null)\]"
      
      cd "$1" || exit 1
      
      # Warm-up run
      eval "$PROMPT_COMMAND" >/dev/null 2>&1
      dummy="${PS1@P}"
      
      start="${EPOCHREALTIME/./}"
      for i in {1..5}; do
        eval "$PROMPT_COMMAND" >/dev/null 2>&1
        dummy="${PS1@P}"
      done
      end="${EPOCHREALTIME/./}"
      
      # Calculate average milliseconds per render
      ms=$(( (end - start) / 5000 ))
      echo "$ms"
    ' -- "$target_dir"
  }

  # Measure non-git directory (best of 3 runs)
  local best_nongit=999999
  for run in 1 2 3; do
    local ms=$(run_measure "$nongit_dir")
    if [ "$ms" -lt "$best_nongit" ]; then
      best_nongit=$ms
    fi
  done

  # Measure git directory (best of 3 runs)
  local best_git=999999
  for run in 1 2 3; do
    local ms=$(run_measure "$REPO_ROOT")
    if [ "$ms" -lt "$best_git" ]; then
      best_git=$ms
    fi
  done

  echo "Best non-git prompt render time: ${best_nongit}ms (Budget: ${PROMPT_NONGIT_BUDGET:-1}ms)"
  echo "Best git prompt render time: ${best_git}ms (Budget: ${PROMPT_GIT_BUDGET:-1}ms)"

  # Use failing budget values for TDD validation
  local nongit_budget=${PROMPT_NONGIT_BUDGET:-1}
  local git_budget=${PROMPT_GIT_BUDGET:-1}

  [ "$best_nongit" -lt "$nongit_budget" ]
  [ "$best_git" -lt "$git_budget" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `just test-unit tests/prompt_performance.bats`
Expected: FAIL due to exceeding the 1ms budget.

- [ ] **Step 3: Update budgets to realistic values**

Edit the budget lines in `tests/prompt_performance.bats`:

```diff
-  # Use failing budget values for TDD validation
-  local nongit_budget=${PROMPT_NONGIT_BUDGET:-1}
-  local git_budget=${PROMPT_GIT_BUDGET:-1}
+  # Performance budgets: 50ms for non-git, 60ms for git
+  local nongit_budget=${PROMPT_NONGIT_BUDGET:-50}
+  local git_budget=${PROMPT_GIT_BUDGET:-60}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `just test-unit tests/prompt_performance.bats`
Expected: PASS (with render times around 15ms-25ms).

- [ ] **Step 5: Run the full unit test suite**

Run: `just test-unit`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add tests/prompt_performance.bats
git commit -m "test: add prompt performance budget test"
```
