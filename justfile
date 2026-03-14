# Run goss assertions in container (CI mode — exits 0 or 1)
test:
    docker compose run --rm ci

# Spin up interactive dev environment (manual tmux/plugin inspection)
dev:
    docker compose run --rm dev

# Rebuild Docker image from scratch (run when Dockerfile changes)
build:
    docker compose build --no-cache

# Run existing bash unit tests (phase 2)
test-unit:
    ./tests/test_grep_ticket_number.sh
    ./tests/test_commit_message.sh
