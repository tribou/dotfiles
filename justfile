# Interactive command picker (requires fzf)
default:
    @just --list --unsorted | tail -n +2 | fzf --height=40% --reverse | awk '{print $1}' | xargs -r just

# Run full test suite in Docker (goss infrastructure + bats integration tests)
test:
    docker compose run --rm -T ci

# Spin up interactive dev environment (manual tmux/plugin inspection)
dev:
    docker compose run --rm dev

# Rebuild Docker image (uses layer cache; run after Dockerfile changes)
build:
    docker compose build

# Rebuild Docker image from scratch, ignoring layer cache
build-clean:
    docker compose build --no-cache

# Run bash unit tests with bats-core
test-unit *args="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${BATS_JOBS:-}" ]; then
      jobs="$BATS_JOBS"
    elif command -v nproc &>/dev/null; then
      jobs="$(nproc)"
    elif command -v sysctl &>/dev/null; then
      jobs="$(sysctl -n hw.ncpu)"
    else
      jobs=1
    fi
    if [ -n "{{args}}" ]; then
      # Explicit args: run exactly what was requested
      ./tests/test_helper/bats-core/bin/bats --jobs "$jobs" {{args}}
    else
      # Default: run perf tests serially first (timing-sensitive under CPU contention)
      ./tests/test_helper/bats-core/bin/bats tests/prompt_performance.bats tests/startup_performance.bats
      # Then run all other tests in parallel
      shopt -s nullglob
      other_tests=()
      for f in tests/*.bats; do
        case "$(basename "$f")" in
          prompt_performance.bats|startup_performance.bats) ;;
          *) other_tests+=("$f") ;;
        esac
      done
      if [ ${#other_tests[@]} -gt 0 ]; then
        ./tests/test_helper/bats-core/bin/bats --jobs "$jobs" "${other_tests[@]}"
      fi
    fi


# Run local health checks (symlinks, tools)
doctor:
    ./scripts/doctor.sh

# Show interactive performance history report
perf:
    @bash ./scripts/perf_report.sh

# Clean up stale worktrees
cleanup-worktrees:
    git worktree prune
    @echo "Pruned stale worktrees. Remaining:"
    git worktree list

