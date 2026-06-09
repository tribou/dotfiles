# tests/merge_command.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "merge: runs git merge with the provided arguments" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"merge\" ]; then
        echo \"git_merge \${*:2}\" >&2
      fi
    }
    _dotfiles_git_status() { echo \"git_status\"; }
    merge \"my-feature\"
  "
  assert_success
  assert_line --index 0 "git_merge my-feature"
}

@test "merge: prints commit log and status if merge changes code" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"Updating 123456..789abc\"; }
    _dotfiles_git_log_commit() { echo \"git_log_commit\"; }
    _dotfiles_git_status() { echo \"git_status\"; }
    merge \"my-feature\"
  "
  assert_success
  assert_line --index 0 "git_log_commit"
  assert_line --index 1 "git_status"
}

@test "merge: prints only status if merge is already up to date" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"Already up to date.\"; }
    _dotfiles_git_log_commit() { echo \"git_log_commit_unexpected\"; }
    _dotfiles_git_status() { echo \"git_status\"; }
    merge \"my-feature\"
  "
  assert_success
  refute_output --partial "git_log_commit_unexpected"
  assert_output --partial "git_status"
}

@test "merge: handles multiple arguments correctly" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"merge\" ]; then
        echo \"git_merge \${*:2}\" >&2
      fi
    }
    _dotfiles_git_status() { echo \"git_status\"; }
    merge \"main\" \"--no-ff\"
  "
  assert_success
  assert_line --index 0 "git_merge main --no-ff"
}

@test "merge: returns status of logging/status when merge succeeds or fails" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"Conflict!\"; return 12; }
    _dotfiles_git_log_commit() { return 0; }
    _dotfiles_git_status() { return 5; }
    merge \"my-feature\"
  "
  [ "$status" -eq 5 ]
}

@test "merge: works with no arguments" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"merge\" ]; then
        echo \"git_merge_empty\" >&2
      fi
    }
    _dotfiles_git_status() { echo \"git_status\"; }
    merge
  "
  assert_success
}

