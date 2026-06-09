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

# --- npm-install tests ---

@test "npm-install: formats correctly for pnpm with no args" {
  touch "$TEST_DIR/pnpm-lock.yaml"
  run bash -c "
    cd '$TEST_DIR'
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    _eval_script() { echo \"eval_script \$*\"; }
    npm-install
  "
  assert_success
  assert_output "eval_script pnpm install"
}

@test "npm-install: runs pnpm install with arguments" {
  touch "$TEST_DIR/pnpm-lock.yaml"
  run bash -c "
    cd '$TEST_DIR'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    eval() { echo \"eval \$*\"; }
    npm-install \"lodash\" \"-D\"
  "
  assert_success
  assert_line --index 0 "pnpm install lodash -D"
}

# --- y tests ---

@test "y: runs yarn when arguments are passed" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    eval() { echo \"eval \$*\"; }
    y \"add\" \"react\"
  "
  assert_success
  assert_line --index 0 "yarn add react"
}

@test "y: delegates to npm-install when no arguments are passed" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    npm-install() { echo \"npm-install called\"; }
    y
  "
  assert_success
  assert_output "npm-install called"
}

# --- npm-run tests ---

@test "npm-run: formats correctly for npm run" {
  run bash -c "
    cd '$TEST_DIR'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    eval() { echo \"eval \$*\"; }
    npm-run \"test\"
  "
  assert_success
  assert_line --index 0 "npm run --silent test"
}

# --- mise-run tests ---

@test "mise-run: uses mise run <task>" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    eval() { echo \"eval \$*\"; }
    mise-run \"build\"
  "
  assert_success
  assert_line --index 0 "mise run build"
}

# --- nu error path ---

@test "nu: returns 1 and outputs error when package.json does not exist" {
  run bash -c "
    cd '$TEST_DIR'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    nu
  "
  assert_failure
  assert_output "No package.json to upgrade"
}
