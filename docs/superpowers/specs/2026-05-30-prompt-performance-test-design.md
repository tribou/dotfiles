# Prompt Performance Test Design

## Goal

Add a performance budget test for the terminal prompt to guard against latency regressions in the prompt lifecycle (`PROMPT_COMMAND` execution + `PS1` expansion) that run before/after every command in the terminal.

## Design

- **Test File:** `tests/prompt_performance.bats`
- **Methodology:** 
  - Measures latency using `EPOCHREALTIME` in a subshell after sourcing `bash_profile`.
  - Simulates the interactive prompt cycle by executing `eval "$PROMPT_COMMAND"` and performing prompt expansion `${PS1@P}` inside a loop ($N=5$).
  - Repeats the test 3 times and takes the **best** average execution time to minimize noise from system load.
- **Scenarios:**
  - **Git Directory:** Measures latency within the repository root where `get_git_location` calls `git rev-parse` (Budget: **60ms** per render).
  - **Non-Git Directory:** Measures latency within a temporary non-git directory (Budget: **50ms** per render).
- **Runners:** Runs as a standard fast unit test using `just test-unit`.

## Why

Prompt latency degrades the responsiveness of every command typed in the terminal. By adding a performance test with a tight budget, we ensure that new shell libraries, hooks (like `mise`), and custom helper functions do not silently degrade prompt performance.
