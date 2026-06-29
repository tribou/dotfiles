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

# --- commit status ---

@test "commit status: reports opencode backend, model, availability" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:   opencode"
  assert_output --partial "model:     opencode-go/kimi-k2.7-code"
  assert_output --partial "available: yes"
}

@test "commit status: defaults to claude/haiku" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    unset DOTFILES_COMMIT_BACKEND
    claude() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:   claude"
  assert_output --partial "model:     haiku"
}

# --- commit backend (setter/getter) ---

@test "commit backend opencode: exports the backend for the current shell" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    commit backend opencode > /dev/null
    echo \"BACKEND=\$DOTFILES_COMMIT_BACKEND\"
  "
  assert_success
  assert_output --partial "BACKEND=opencode"
}

@test "commit backend opencode: prints a confirmation including the model" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    commit backend opencode
  "
  assert_success
  assert_output --partial "commit backend set to opencode (model: opencode-go/kimi-k2.7-code) for this shell"
}

@test "commit backend: with no value prints the current backend" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    commit backend
  "
  assert_success
  assert_output "opencode"
}

@test "commit backend bogus: errors, returns 1, leaves the backend unchanged" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=claude
    commit backend bogus
    echo \"RC=\$? BACKEND=\$DOTFILES_COMMIT_BACKEND\"
  "
  assert_success
  assert_output --partial "RC=1 BACKEND=claude"
  echo "$stderr" | grep -qF 'unknown backend: bogus'
}

# --- durable default ---

@test "bash_profile: exports a DOTFILES_COMMIT_BACKEND default" {
  run grep -E "^export DOTFILES_COMMIT_BACKEND=" "$REPO_ROOT/bash_profile"
  assert_success
}
