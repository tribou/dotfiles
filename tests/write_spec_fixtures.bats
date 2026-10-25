setup() {
  load 'test_helper/common_setup'
  common_setup
  FIXTURE_ROOT="$BATS_TEST_TMPDIR/repos"
  mkdir -p "$FIXTURE_ROOT/unrelated"
  bash "$REPO_ROOT/docs/research/write-spec-bench/build-fixtures.sh" "$FIXTURE_ROOT"
}

@test "write-spec generated ordering assertion passes for the fixed loader" {
  run bash -c 'cd "$1" && "$2" tests/index_order.bats' -- \
    "$FIXTURE_ROOT/S5-stale" "$REPO_ROOT/tests/test_helper/bats-core/bin/bats"
  assert_success
}

@test "write-spec generated ordering assertion rejects a module loaded before shared helpers" {
  local loader="$FIXTURE_ROOT/S5-stale/lib/index.sh"
  local original
  original="$(<"$loader")"
  printf 'source lib/ai.sh\n%s\n' "$original" > "$loader"

  run bash -c 'cd "$1" && "$2" tests/index_order.bats' -- \
    "$FIXTURE_ROOT/S5-stale" "$REPO_ROOT/tests/test_helper/bats-core/bin/bats"
  assert_failure
  assert_output --partial "not ok 1"
}

@test "write-spec fixture builder initializes only its own repositories" {
  [ -d "$FIXTURE_ROOT/S5-true/.git" ]
  [ -d "$FIXTURE_ROOT/S5-stale/.git" ]
  [ -d "$FIXTURE_ROOT/S1-repo/.git" ]
  [ ! -e "$FIXTURE_ROOT/unrelated/.git" ]
}
