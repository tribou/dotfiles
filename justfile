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
test-unit *args="tests/*.bats":
    ./tests/test_helper/bats-core/bin/bats {{args}}

# Install/repair dotfiles on an already-bootstrapped machine (default: present)
install *args:
    ansible-playbook playbook.yml {{args}}

# Upgrade everything (dotfiles_state=latest, upgrade-tagged tasks)
# Ansible and its Python runtime are brew-managed, so the play's `brew upgrade`
# would replace the running interpreter mid-run. Ansible lazily imports its
# module-result deserialization profile after a module completes, so that swap
# crashes with "Unknown profile name 'module_legacy_m2c'". Pin ansible + its
# python (derived from `brew deps ansible`) for the play, then upgrade them
# afterward in a separate process where self-replacement is harmless.
alias update := upgrade

upgrade *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v brew >/dev/null && brew list ansible >/dev/null 2>&1; then
        mapfile -t py_pkgs < <(brew deps ansible | grep '^python@' || true)
        self_pkgs=(ansible "${py_pkgs[@]}")
        brew pin "${self_pkgs[@]}"
        trap 'brew unpin "${self_pkgs[@]}" >/dev/null 2>&1 || true' EXIT
    fi
    ansible-playbook playbook.yml -e dotfiles_state=latest --tags upgrade {{args}}
    if [[ -n "${self_pkgs[*]:-}" ]]; then
        brew unpin "${self_pkgs[@]}"
        trap - EXIT
        brew upgrade "${self_pkgs[@]}"
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

