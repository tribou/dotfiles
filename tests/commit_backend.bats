setup() {
  load 'test_helper/common_setup'
  common_setup
}

# --- _dotfiles_commit_backend ---

@test "commit_backend: defaults to claude when unset" {
  unset DOTFILES_COMMIT_BACKEND
  run _dotfiles_commit_backend
  assert_success
  assert_output "claude"
}

@test "commit_backend: honors opencode" {
  export DOTFILES_COMMIT_BACKEND=opencode
  run _dotfiles_commit_backend
  assert_success
  assert_output "opencode"
}

@test "commit_backend: unknown value warns to stderr and falls back to claude" {
  export DOTFILES_COMMIT_BACKEND=bogus
  run --separate-stderr _dotfiles_commit_backend
  assert_success
  assert_output "claude"
  echo "$stderr" | grep -qF 'unknown DOTFILES_COMMIT_BACKEND=bogus'
}

# --- _dotfiles_commit_model ---

@test "commit_model: claude backend uses haiku" {
  run _dotfiles_commit_model claude
  assert_success
  assert_output "haiku"
}

@test "commit_model: opencode backend uses kimi 2.7" {
  run _dotfiles_commit_model opencode
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
}
