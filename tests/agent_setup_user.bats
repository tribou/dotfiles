# tests/agent_setup_user.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "agent/setup-user.sh exits with clear error on macOS" {
  run env OSTYPE=darwin20 bash "$REPO_ROOT/agent/setup-user.sh"

  assert_failure
  assert_output --partial "Linux only"
  assert_output --partial "not supported on macOS"
}
