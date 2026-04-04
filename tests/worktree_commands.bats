setup() {
  load 'test_helper/common_setup'
  common_setup

  # Create a temp git repo for worktree tests
  TEMP_REPO=$(mktemp -d)
  git -C "$TEMP_REPO" init -q
  git -C "$TEMP_REPO" commit --allow-empty -m "init"
  cd "$TEMP_REPO"
}

teardown() {
  rm -rf "$TEMP_REPO"
}

@test "wtc: errors with no argument" {
  run wtc
  assert_failure
  assert_output --partial "Usage"
}

@test "wtc: errors outside a git repo" {
  cd /tmp
  run wtc some-branch
  assert_failure
  assert_output --partial "git repository"
}

@test "wtc: creates worktree and branch" {
  run wtc my-feature
  assert_success
  assert [ -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  assert_output --partial "my-feature"
}

@test "wtc: adds .worktrees/ to .gitignore" {
  run wtc my-feature
  assert_success
  run grep -F '.worktrees/' .gitignore
  assert_success
}

@test "wtc: does not duplicate .worktrees/ in .gitignore on second call" {
  wtc my-feature
  git worktree remove .worktrees/my-feature
  git branch -D my-feature
  wtc other-feature
  run grep -cF '.worktrees/' .gitignore
  assert_output "1"
}

@test "wtc: errors if branch already exists" {
  git branch my-feature
  run wtc my-feature
  assert_failure
}

@test "wtd: removes worktree and branch" {
  wtc my-feature
  cd "$TEMP_REPO"
  run wtd my-feature
  assert_success
  assert [ ! -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  refute_output --partial "my-feature"
}

@test "wt, wtc, wtd: all functions are defined" {
  run bash -c 'type wtc'
  assert_success
  run bash -c 'type wt'
  assert_success
  run bash -c 'type wtd'
  assert_success
}
