# tests/co_command.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "co: strips worktree indicator (+) from branch name before checkout" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo '+ feat/just-doctor'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  refute_output --partial '+ feat/just-doctor'
  assert_output --partial 'feat/just-doctor'
}

@test "co: strips current branch indicator (*) from branch name before checkout" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo '* main'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  refute_output --partial '* main'
  assert_output --partial 'main'
}

@test "co: strips remote prefix from branch name before checkout" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { echo '  remotes/origin/feat/some-branch'; }
    git() { return 0; }
    _dotfiles_git_status() { return 0; }
    co
  "
  assert_success
  refute_output --partial 'remotes/origin/'
  assert_output --partial 'feat/some-branch'
}
