*How do we test and fix bugs? — testing requirements, test running instructions, and bug fix policies.*

# Testing

## Test Commands

```bash
just test-unit    # Bash unit tests with bats-core (fast, no Docker)
just test         # Full suite in Docker: goss infrastructure + bats integration tests
just dev          # Interactive Docker dev environment
just build        # Rebuild Docker image (after Dockerfile changes)
```

## Test Structure

- **`tests/*.bats`**: Unit tests for shell functions — run fast with no Docker required
  - `commit_message.bats`, `grep_ticket_number.bats`: Core git workflow helpers
  - `fzf_lib.bats`, `npm_detection.bats`, `path.bats`: Utility function coverage
  - `bootstrap_skills.bats`, `agent_setup_user.bats`: Bootstrap and agent setup
  - `clipboard.bats`, `platform_guards.bats`, `histgrep_parsing.bats`, `worktree_commands.bats`: Additional functionality

- **`tests/integration/`**: Integration tests run inside Docker (included in `just test`)
  - `nvim_health.bats`: Neovim plugin health validation
  - `nvim_keymaps.bats`: Key mapping configuration verification
  - `tmux_environment.bats`: Tmux session and environment setup validation

- **`goss.yaml`**: Infrastructure assertions (binary presence, environment variables) validated inside Docker by goss

## Bug Fix Policy (TDD)

Bug fixes MUST follow test-driven development:

1. **Write a failing test first** that reproduces the bug (red)
2. **Fix the bug** until the test passes (green)
3. **Refactor** if needed, keeping the test green

Where the test goes:

- **Runtime environment bugs** (missing binaries, wrong versions, bad env vars): add a `goss.yaml` assertion so the regression is caught by `just test`
- **Shell function bugs**: add a case to the relevant `tests/*.bats` file

The test must fail before the fix and pass after. Re-introducing the bug must cause `just test` or `just test-unit` to fail.

## Running a Specific Test

```bash
./tests/test_helper/bats-core/bin/bats tests/<file>.bats
./tests/test_helper/bats-core/bin/bats tests/commit_message.bats
```
