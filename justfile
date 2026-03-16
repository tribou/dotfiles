# Interactive command picker (requires fzf)
default:
    @just --list --unsorted | tail -n +2 | fzf --height=40% --reverse | awk '{print $1}' | xargs -r just

# Run full test suite in Docker (goss infrastructure + bats integration tests)
test:
    docker compose run --rm -T ci

# Spin up interactive dev environment (manual tmux/plugin inspection)
dev:
    docker compose run --rm dev

# Rebuild Docker image from scratch (run when Dockerfile changes)
build:
    docker compose build --no-cache

# Run bash unit tests with bats-core
test-unit:
    ./tests/test_helper/bats-core/bin/bats tests/*.bats
