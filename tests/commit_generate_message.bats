setup() {
  load 'test_helper/common_setup'
  common_setup
}

# --- _dotfiles_commit_prompt ---

@test "prompt: ticket present requests a plain summary with no Conventional Commits prefix" {
  run _dotfiles_commit_prompt "AB-123"
  assert_success
  refute_output --partial "Conventional Commits"
}

@test "prompt: no ticket allows Conventional Commits style" {
  run _dotfiles_commit_prompt ""
  assert_success
  assert_output --partial "Conventional Commits"
}

# --- _dotfiles_commit_generate_message ---

@test "generate_message: returns claude's sanitized output on success" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo 'mock diff'; }
    claude() { echo 'fix(bootstrap): silence brew prompt'; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "fix(bootstrap): silence brew prompt"
}

@test "generate_message: fails when claude is not found on PATH" {
  local empty_path
  empty_path="$(mktemp -d)"
  run bash -c "
    export PATH='$empty_path'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
  rm -rf "$empty_path"
}

@test "generate_message: fails when claude exits non-zero" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo 'mock diff'; }
    claude() { return 1; }
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
}

@test "generate_message: fails when claude returns empty output" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo ''; }
    claude() { echo ''; }
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
}

@test "generate_message: caps the diff sent to claude at 100000 bytes" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { yes a | head -c 200000; }
    claude() { wc -c | tr -d ' '; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "100000"
}
