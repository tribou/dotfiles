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

# Run clean test suite in Docker from scratch (wipes .ci-cache, runs cold without skip-tags)
test-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    # Fallback to docker compose run handles root-owned .ci-cache permissions
    rm -rf .ci-cache 2>/dev/null || docker compose run --rm -T ci rm -rf /dotfiles/.ci-cache
    git_mount=()
    if git_common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
        git_mount=(-v "${git_common_dir}:${git_common_dir}:ro")
    fi
    DOTFILES_ANSIBLE_EXTRA_ARGS="" docker compose run --rm -T "${git_mount[@]}" ci

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
    if command -v ansible-playbook >/dev/null 2>&1; then ANSIBLE_CONFIG={{justfile_directory()}}/ansible.cfg ansible-playbook --syntax-check playbook.yml; fi
    jobs_args=()
    jobs="${DOTFILES_TEST_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"
    if [[ "$jobs" -gt 1 && "$(parallel --version 2>/dev/null || true)" == *"GNU parallel"* ]]; then
        jobs_args=(--jobs "$jobs")
    fi
    ./tests/test_helper/bats-core/bin/bats ${jobs_args[@]+"${jobs_args[@]}"} {{args}}

# Run only the unit tests (and Docker suite, if needed) affected by your changes
test-changed *args:
    ./scripts/test_changed.sh {{args}}

# Install/repair dotfiles on an already-bootstrapped machine (default: present)
# ANSIBLE_CONFIG is pinned to this repo's ansible.cfg so a stale/unrelated
# ANSIBLE_CONFIG in the user's shell env (it has the highest precedence in
# Ansible's config search order) can't shadow this repo's inventory.
install *args:
    ANSIBLE_CONFIG={{justfile_directory()}}/ansible.cfg ~/.local/bin/mise exec -- ansible-playbook playbook.yml {{args}}

# Upgrade everything (dotfiles_state=latest, upgrade-tagged tasks)
alias update := upgrade

# The play runs on mise's ansible + python, so it defers upgrading them
# (dotfiles_mise_upgrade_deferred); upgrade them here after the play exits,
# where replacing the interpreter is harmless.
upgrade *args:
    ANSIBLE_CONFIG={{justfile_directory()}}/ansible.cfg ~/.local/bin/mise exec -- ansible-playbook playbook.yml -e dotfiles_state=latest --tags upgrade {{args}}
    ~/.local/bin/mise upgrade --yes ansible python

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
