# Testing

## Test Commands

```bash
just test-unit    # Bash unit tests with bats-core (fast, no Docker)
just test         # Full suite in Docker: goss infrastructure + bats integration tests
just dev          # Interactive Docker dev environment
just build        # Rebuild Docker image (after Dockerfile changes)
```

## Bug Fix Policy

When fixing any bug, always consider whether a new test should accompany the fix:

- **Runtime environment bugs** (missing binaries, wrong versions, bad env vars): add a `goss.yaml` assertion so the regression is caught by `just test`
- **Shell function bugs**: add a case to the relevant `tests/test_*.sh` or `tests/*.bats` file

The goal is that re-introducing the bug causes `just test` or `just test-unit` to fail.

## Running a Specific Test

```bash
./tests/test_helper/bats-core/bin/bats tests/<file>.bats
./tests/test_grep_ticket_number.sh
./tests/test_commit_message.sh
```
