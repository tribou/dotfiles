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
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo 'mock diff'; }
    claude() { echo 'fix(bootstrap): silence brew prompt'; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "fix(bootstrap): silence brew prompt"
  echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
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
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo 'mock diff'; }
    claude() { return 1; }
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
  echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
}

@test "generate_message: fails when claude returns empty output" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo ''; }
    claude() { echo ''; }
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
  echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
}

@test "generate_message: caps the diff sent to claude at 100000 bytes" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { yes a | head -c 200000; }
    claude() { wc -c | tr -d ' '; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "100000"
  echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
}

@test "generate_message: returns 130 and emits no stdout when interrupted" {
  run -130 --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo 'mock diff'; }
    claude() { sleep 1; echo 'should not be seen'; }
    ( sleep 0.2; kill -INT \$\$ ) &
    _dotfiles_commit_generate_message ''
  "
  assert_output ""
}

@test "generate_message: opencode backend invokes opencode run with the kimi model" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    export DOTFILES_COMMIT_BACKEND=opencode
    git() { echo 'mock diff'; }
    opencode() { printf '%s' \"\$3\"; }
    _dotfiles_commit_generate_message ''
  "
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
}

@test "generate_message: opencode backend fails when opencode is not on PATH" {
  local empty_path
  empty_path="$(mktemp -d)"
  run bash -c "
    export PATH='$empty_path'
    export DOTFILES_COMMIT_BACKEND=opencode
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    _dotfiles_commit_generate_message ''
  "
  assert_failure
  assert_output ""
  rm -rf "$empty_path"
}
