# tests/platform_guards.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# restart-docker guard
@test "restart-docker exits 1 with error message on Linux" {
  run bash -c "
    OSTYPE=linux-gnu
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    restart-docker
  "
  assert_failure
  assert_output --partial "not supported on Linux"
}

@test "restart-docker guard allows darwin OSTYPE" {
  # We can't fully run restart-docker (it calls osascript), but we can verify
  # the guard does NOT trigger (returns past the guard) on darwin.
  # Stub osascript and open to prevent actual Docker restart.
  run bash -c "
    OSTYPE=darwin20
    osascript() { return 0; }
    open() { return 0; }
    docker() { return 0; }
    export -f osascript open docker
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    # Override wait loop to exit immediately
    restart-docker 2>/dev/null
    echo 'reached_past_guard'
  "
  assert_output --partial "reached_past_guard"
}
