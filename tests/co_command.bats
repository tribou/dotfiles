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
