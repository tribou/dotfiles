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

## Bug Fix Policy

When fixing any bug, always consider whether a new test should accompany the fix:

- **Runtime environment bugs** (missing binaries, wrong versions, bad env vars): add a `goss.yaml` assertion so the regression is caught by `just test`
- **Shell function bugs**: add a case to the relevant `tests/test_*.sh` or `tests/*.bats` file

The goal is that re-introducing the bug causes `just test` or `just test-unit` to fail.

## Running a Specific Test

```bash
./tests/test_helper/bats-core/bin/bats tests/<file>.bats
./tests/test_helper/bats-core/bin/bats tests/commit_message.bats
```
