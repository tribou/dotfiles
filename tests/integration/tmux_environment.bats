# tests/integration/tmux_environment.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
  # Start a detached tmux server for testing
  tmux start-server 2>/dev/null || true
}

teardown() {
  tmux kill-server 2>/dev/null || true
}

@test "tmux prefix is C-f (not default C-b)" {
  run tmux show-options -g prefix
  assert_output --partial "C-f"
}

@test "tmux-resurrect plugin bindings exist" {
  run tmux list-keys
  assert_output --partial "resurrect"
}

@test "tmux-yank plugin bindings exist" {
  run tmux list-keys
  assert_output --partial "yank"
}

@test "tmux status bar renders without error" {
  tmux new-session -d -s test_session 2>/dev/null
  run tmux display-message -t test_session -p "#{status-left}"
  assert_success
}

@test "tmux split-window bindings are present" {
  run tmux list-keys
  assert_output --partial "split-window"
}
