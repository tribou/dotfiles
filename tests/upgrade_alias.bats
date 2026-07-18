setup() {
  load 'test_helper/common_setup'
  common_setup
}

# `just update` should be a plain alias for `just upgrade`, so muscle-memory
# from other tools (npm update, apt update, etc.) still works here.
@test "justfile: update is an alias for upgrade" {
  run just --justfile "$REPO_ROOT/justfile" --show update
  assert_success
  # `--show` on an alias prefixes an "alias x := y" line before the aliased
  # recipe body, so drop that line before comparing bodies.
  assert_equal "$(echo "$output" | tail -n +2)" "$(just --justfile "$REPO_ROOT/justfile" --show upgrade)"
}
