*How do we test and fix bugs? -- testing requirements, test running instructions, and bug fix policies.*

# Testing

## Test Commands

```bash
just test-unit    # Bash unit tests with bats-core in parallel (fast, no Docker)
just test         # Full suite in Docker: goss infrastructure + bats integration tests (parallel)
just dev          # Interactive Docker dev environment
just build        # Rebuild Docker image (after Dockerfile changes)
just build-clean  # Rebuild Docker image from scratch, ignoring layer cache
```

## Parallel Execution

Tests run in parallel by default using bats-core `--jobs` with GNU parallel as the backend.

### Default Behavior

- **Linux:** Auto-detects core count via `nproc`
- **macOS:** Auto-detects core count via `sysctl -n hw.ncpu`
- **Fallback:** Runs with 1 job (serial) if neither command is available

### Overriding Job Count

Set the `BATS_JOBS` environment variable to override auto-detection:

```bash
BATS_JOBS=1 just test-unit    # Force serial execution (useful for debugging)
BATS_JOBS=4 just test-unit    # Force 4 parallel jobs
```

### GNU parallel Dependency

GNU parallel is required for bats `--jobs` to work. Install it in your environment:

```bash
# macOS
brew install parallel

# Ubuntu/Debian
sudo apt-get install -y parallel

# Silence citation notice (one-time)
mkdir -p ~/.parallel && touch ~/.parallel/will-cite
```

In CI, GNU parallel is installed automatically in both macOS and Ubuntu workflows.
Inside Docker, it is pre-installed in the image.

## Test Structure

- **`tests/*.bats`**: Unit tests for shell functions -- run fast with no Docker required
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

## Running a Specific Test

When running a single test file, `--jobs` is still applied but has no observable effect since there is only one file:

```bash
./tests/test_helper/bats-core/bin/bats tests/<file>.bats
./tests/test_helper/bats-core/bin/bats tests/commit_message.bats
```

To run a single file without parallel overhead:

```bash
BATS_JOBS=1 just test-unit tests/commit_message.bats
```

## Docker Layer Caching

### Pre-baked Layers

The `Dockerfile` pre-bakes expensive bootstrap steps into cached image layers:

- Go + gopls (via mise)
- Corepack (yarn, pnpm)
- TPM + all tmux plugins
- vim-plug + Neovim plugins
- CoC extensions
- GNU parallel

This means `scripts/bootstrap-test.sh` is a thin shim that only activates mise, creates symlinks, and initializes bats submodules. It completes in seconds inside the Docker image.

### GHA Cache Behavior

The Ubuntu CI workflow uses Docker Buildx with `actions/cache` to persist Docker layers between runs:

- **First run:** Builds all layers from scratch, saves cache.
- **Subsequent runs:** Restores cached layers. Only layers affected by file changes are rebuilt.
- **Cache key:** Based on `hashFiles('Dockerfile')`. Any Dockerfile change invalidates the cache.

### When to Rebuild

- **After Dockerfile structural changes:** Run `just build-clean` to rebuild without layer cache.
- **After test-file-only changes:** Normal `just build` uses cached layers (instant rebuild).
- **After plugin config changes:** Layers downstream of the changed config file are rebuilt automatically.
