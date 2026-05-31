# Design Spec: Migrating from `rupa/z` to `zoxide`

**Author:** Antigravity  
**Date:** 2026-05-31  
**Bead Issue:** `dotfiles-4t8`

---

## 1. Goal & Context

This design document outlines the migration of our directory switching utility in our dotfiles repository from the legacy shell-based `rupa/z` tool to the modern, Rust-based **`zoxide`**. 

`zoxide` tracks frequently and recently used directories (frecency) and is compiled into a single optimized machine binary. This eliminates the shell process forks (`awk`, `sed`, `sort`) executed by legacy `z` on every prompt render/directory jump, reducing terminal latency to sub-milliseconds.

Additionally, this spec introduces a lightweight performance capture and visualization framework (`just perf`) to record and compare terminal startup and prompt latency before and after the migration.

---

## 2. Requirements

* **Zero-Loss Data Migration:** Seamlessly import the user's existing legacy `~/.z` history database into the `zoxide` database on the first run.
* **Unified Command Set:** Utilize `zoxide`'s default `z` for directory jumping, and `zi` for interactive fuzzy-finding via `fzf`.
* **Simplify Config Code:** Remove custom `z` and `zz` wrapper functions in `lib/fzf.sh`.
* **Robust Path Resolution:** Enhance `_dotfiles_full_path` inside `lib/_shared.sh` with fallbacks for untracked paths.
* **Performance Capture:** Record benchmarks before and after the migration, and visualize them using a high-quality ANSI bar chart terminal command.
* **Thorough Testing:** Ensure existing tests are updated and add new bats-core tests specifically validating path resolution.

---

## 3. Detailed Changes

### Component 1: `bootstrap.sh`
* **Remove cloning:** Eliminate git-cloning of `https://github.com/rupa/z.git` to `~/dev/z`.
* **Add package:** Add `zoxide` to the macOS/Linux Homebrew installation section.
* **Automate History Import:** Add a hook after brew/mise installs that checks if:
  1. A legacy `~/.z` file exists.
  2. `zoxide` is installed.
  3. No `zoxide` database exists yet.
  
  If all match, it runs `zoxide import --from z "$HOME/.z"`.

### Component 2: Shell Initialization
* **`bash_profile`:** Replace legacy sourcing of `$DEVPATH/z/z.sh` with `eval "$(zoxide init bash)"`.
* **`zshrc`:** Add `eval "$(zoxide init zsh)"` at the end of the file.

### Component 3: Path Resolution (`lib/_shared.sh`)
* Redefine `_dotfiles_full_path` to be highly resilient:
  ```bash
  function _dotfiles_full_path () {
    if [ -d "$1" ]; then
      # Resolve to absolute path directly if it is a directory on disk
      (cd "$1" && pwd)
    elif command -v zoxide &>/dev/null; then
      # Fall back to zoxide query
      zoxide query "$1" 2>/dev/null || echo "$1"
    else
      # If zoxide is not available, return original argument
      echo "$1"
    fi
  }
  ```

### Component 4: FZF Library (`lib/fzf.sh`)
* Remove the custom `z()` and `zz()` shell functions from `lib/fzf.sh`.
* Rely on native `z` and `zi` provided by `zoxide init`.

---

## 4. Performance Capture & Visualization Plan

### 4.1 JSONL Logging (`tests/.perf_log.jsonl`)
We will append local performance runtimes to a local, gitignored JSONL file.
* **Format:**
  ```json
  {"timestamp": "2026-05-31T12:35:46-05:00", "commit": "2aa9972", "metric": "startup_ms", "value": 125}
  ```
* **Updates to Performance Tests:** Update `tests/startup_performance.bats` and `tests/prompt_performance.bats` to automatically log their best-run results to `tests/.perf_log.jsonl` upon success.

### 4.2 Terminal Reporter (`scripts/perf_report.sh` & `just perf`)
* We will build `scripts/perf_report.sh` which aggregates metrics and prints a beautiful, colored ANSI bar chart directly inside the terminal.
* We will expose this as `just perf` in `justfile`.

---

## 5. Verification Plan

### Automated Unit Tests
* **Mock Update:** In `tests/bootstrap_idempotency.bats`, update the git mock to remove references to `z.sh` and ensure a mock of `zoxide` is created.
* **New Tests:** Create `tests/path_resolution.bats` to test `_dotfiles_full_path` with:
  1. Resolution of existing relative and absolute directory paths.
  2. Integration with mocked `zoxide query` returning a successful match.
  3. Graceful fallback when `zoxide query` fails (untracked directories).

### Manual Verification
* **Baseline Perf Capture:** Run the bats tests before starting code changes to capture the "Before" benchmark in `tests/.perf_log.jsonl`.
* **Post-Migration Perf Capture:** Run the tests after implementation to log the "After" benchmark.
* **Verification:** Run `just perf` to visually verify prompt and startup latency improvements!
