# Interactive command picker (requires fzf; matches recipe names only, not descriptions)
default:
    @just --list --unsorted | tail -n +2 | fzf --height=40% --reverse --nth=1 | awk '{print $1}' | xargs -r just

# Run full test suite in Docker (goss infrastructure + bats integration tests)
test:
    #!/usr/bin/env bash
    set -euo pipefail
    git_mount=()
    if git_common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
        git_mount=(-v "${git_common_dir}:${git_common_dir}:ro")
    fi
    docker compose run --rm -T "${git_mount[@]}" ci

# Run clean test suite in Docker from scratch (wipes .ci-cache, runs cold with every tool, rust included)
test-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    # Fallback to docker compose run handles root-owned .ci-cache permissions
    rm -rf .ci-cache 2>/dev/null || docker compose run --rm -T ci rm -rf /dotfiles/.ci-cache
    git_mount=()
    if git_common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
        git_mount=(-v "${git_common_dir}:${git_common_dir}:ro")
    fi
    MISE_DISABLE_TOOLS="" docker compose run --rm -T "${git_mount[@]}" ci

# Spin up interactive dev environment (manual tmux/plugin inspection)
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    git_mount=()
    if git_common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
        git_mount=(-v "${git_common_dir}:${git_common_dir}:ro")
    fi
    docker compose run --rm "${git_mount[@]}" dev

# Rebuild Docker image (uses layer cache; run after Dockerfile changes)
build:
    docker compose build

# Rebuild Docker image from scratch, ignoring layer cache
build-clean:
    docker compose build --no-cache

# Run bash unit tests with bats-core (parallel when GNU parallel is installed;
# DOTFILES_TEST_JOBS overrides the job count, 1 forces serial)
test-unit *args="tests/*.bats":
    #!/usr/bin/env bash
    set -euo pipefail
    jobs_args=()
    jobs="${DOTFILES_TEST_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"
    if [[ "$jobs" -gt 1 && "$(parallel --version 2>/dev/null || true)" == *"GNU parallel"* ]]; then
        jobs_args=(--jobs "$jobs")
    fi
    ./tests/test_helper/bats-core/bin/bats ${jobs_args[@]+"${jobs_args[@]}"} {{args}}

# Run only the unit tests (and Docker suite, if needed) affected by your changes
test-changed *args:
    ./scripts/test_changed.sh {{args}}

# Install/repair dotfiles on an already-bootstrapped machine: `mise bootstrap`
# applies mise.toml (dotfiles, repos, bootstrap task) and the global
# mise-config.toml (packages, tools). Extra args pass through (e.g. --dry-run).
install *args:
    ~/.local/bin/mise -C {{justfile_directory()}} bootstrap --yes {{args}}

# Upgrade everything: OS packages, mise packages and tools, repos, and plugins
# (the `upgrade` task in mise.toml, scripts/upgrade.sh)
alias update := upgrade

upgrade:
    ~/.local/bin/mise -C {{justfile_directory()}} run upgrade

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
