setup() {
  load 'test_helper/common_setup'
  common_setup
  # Create a temp dir to simulate project roots with different lock files
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "detects pnpm when pnpm-lock.yaml exists" {
  touch "$TEST_DIR/pnpm-lock.yaml"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "pnpm"
}

@test "detects yarn when yarn.lock exists" {
  touch "$TEST_DIR/yarn.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "yarn"
}

@test "detects bun when bun.lock exists" {
  touch "$TEST_DIR/bun.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "bun"
}

@test "falls back to npm when no lock file exists" {
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "npm"
}

@test "pnpm takes priority over yarn when both exist" {
  touch "$TEST_DIR/pnpm-lock.yaml" "$TEST_DIR/yarn.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "pnpm"
}

@test "yarn takes priority over bun when both exist" {
  touch "$TEST_DIR/yarn.lock" "$TEST_DIR/bun.lock"
  run bash -c "cd '$TEST_DIR' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_npm_detect_exec"
  assert_output "yarn"
}
