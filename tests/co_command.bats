# tests/co_command.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "co: passes clean branch name to git checkout unchanged" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo 'feat/just-doctor'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  assert_output --partial '"feat/just-doctor"'
}

@test "co: preserves slash in feature branch names" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo 'feature/something'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  assert_output --partial '"feature/something"'
  refute_output --partial '"something"'
}

@test "co: preserves slash in renovate branch names" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo 'renovate/something-else'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  assert_output --partial '"renovate/something-else"'
  refute_output --partial '"something-else"'
}

@test "co: does nothing when fzf returns no selection" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { return 1; }
    git() { echo 'git called unexpectedly'; return 0; }
    _dotfiles_git_status() { return 0; }
    co
    echo 'exited_ok'
  "
  assert_success
  assert_output 'exited_ok'
}

@test "co: checkouts branch directly without fzf when argument is provided" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo 'should-not-be-called'; exit 1; }
    git() { echo \"git \$*\"; }
    _dotfiles_git_status() { echo \"git_status\"; }
    co \"my-branch\"
  "
  assert_success
  assert_line --index 0 "git checkout my-branch"
  assert_line --index 1 "git_status"
}

@test "co: propagates git checkout failure exit status and skips git status" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { return 42; }
    _dotfiles_git_status() { echo \"should-not-run\"; return 0; }
    co \"invalid-branch\"
  "
  assert_failure 42
  refute_output --partial "should-not-run"
}

