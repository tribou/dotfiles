*How do we test and fix bugs? — testing requirements, test running instructions, and bug fix policies.*

# Testing

## Test Commands

```bash
just test-changed # Only the tests affected by your changes (default agent check)
just test-unit    # Bash unit tests with bats-core (fast, no Docker)
just test         # Full suite in Docker: goss infrastructure + bats integration tests
just dev          # Interactive Docker dev environment
just build        # Rebuild Docker image (after Dockerfile changes)
```

## Quality Gate Selection

Choose validation from the complete changed-file set:

| Change scope | Required validation |
|---|---|
| Only non-executable skill documentation or reference files under `.agents/skills/**` or `skills/**` | Follow `writing-skills` RED/GREEN scenarios and run `git diff --check`; skip `just test-unit` and `just test` |
| Executable or runtime-consumed skill supporting files | Run targeted validation, then `just test-changed` |
| Mixed skill and non-skill changes | Run targeted validation as applicable, then `just test-changed` |
| Uncertain classification | Run targeted validation as applicable, then `just test-changed` |

`just test-changed` is the default check after a change. It may miss a break
that the full suites would catch; CI runs `just test-unit` and `just test` on
every push and pull request as the backstop. Run the full suites locally when
asked or when a change is broad enough that you doubt the selection.

“Documentation or reference” means prose or reference assets that agents read
but no script, test, application, or configuration parser executes. File
location or extension alone does not make a file non-executable.

## Test Structure

- **`tests/*.bats`**: Unit tests for shell functions — run fast with no Docker required
  - `commit_message.bats`, `grep_ticket_number.bats`: Core git workflow helpers
  - `fzf_lib.bats`, `npm_detection.bats`, `path.bats`: Utility function coverage
  - `agent_setup_user.bats`: Bootstrap and agent setup
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

## Change-Based Test Selection

`just test-changed` (`scripts/test_changed.sh`) collects changed files (since
the merge-base with `origin/HEAD`, else `origin/main`, plus uncommitted and
untracked files; override the base with `DOTFILES_TEST_BASE`) and maps them to
tests. It exits non-zero when the base can't be resolved (a bad
`DOTFILES_TEST_BASE`, or no merge-base with origin), and warns when there is no
origin to diff against, since only uncommitted changes are checked then.

- Each `tests/*.bats` declares what it exercises on a `# covers:` line of
  space-separated globs, where `*` also matches `/`
  (e.g. `# covers: lib/git.sh bash_profile`). A changed test file always runs
  itself.
- Shared files (`lib/_shared.sh`, `lib/index.sh`, `lib/platform.sh`,
  `tests/test_helper/*`) and any file no header claims run the full unit suite.
  Unclaimed docs, `.github/*`, `goss.yaml`, and integration tests need no unit
  tests.
- The Docker suite runs unless every changed file is in a known
  Docker-irrelevant area (`lib/`, `skills/`, `agent/`, unit tests and their
  fixtures, docs, `.github/`, and the dev-only `scripts/doctor.sh`,
  `scripts/perf_report.sh`, `scripts/test_changed.sh`). The exceptions in
  `lib/` are `index.sh`, `path.sh`, and `platform.sh`: `bash_profile` runs them
  in the container to set up the environment goss checks, so they always run
  it. Other `lib/` files rely on CI to catch Linux-only breaks.

`just test-changed --list` prints the plan without running it. When adding a
test file, add its `# covers:` header; `tests/test_changed.bats` fails if a
header is missing or a pattern matches no file.

## Parallel Runs

`just test-unit` passes `--jobs <cpu count>` to bats when GNU `parallel` is
installed (CI installs it). Set `DOTFILES_TEST_JOBS=1` to force a serial run.
Tests must not share fixed paths; use `$BATS_TEST_TMPDIR`. Parallel jobs
inherit an ignored SIGINT, so tests that send SIGINT wrap the command under
test in `with_default_sigint` from `tests/test_helper/common_setup.bash`.

## Running a Specific Test

```bash
./tests/test_helper/bats-core/bin/bats tests/<file>.bats
./tests/test_helper/bats-core/bin/bats tests/commit_message.bats
```
