setup() {
  load 'test_helper/common_setup'
  common_setup

  # Create a temp git repo for worktree tests
  TEMP_REPO=$(mktemp -d)
  git -C "$TEMP_REPO" init -q
  git -C "$TEMP_REPO" config user.email "test@test.com"
  git -C "$TEMP_REPO" config user.name "Test"
  git -C "$TEMP_REPO" commit --allow-empty -m "init"
}

teardown() {
  cd "$BATS_TEST_DIRNAME"
  rm -rf "$TEMP_REPO"
}

@test "wtc: errors with no argument" {
  cd "$TEMP_REPO"
  run wtc
  assert_failure
  assert_output --partial "Usage"
}

@test "wtc: errors outside a git repo" {
  local NON_GIT_DIR
  NON_GIT_DIR=$(mktemp -d)
  cd "$NON_GIT_DIR"
  run wtc some-branch
  assert_failure
  assert_output --partial "git repository"
  rm -rf "$NON_GIT_DIR"
}

@test "wtc: creates worktree and branch" {
  cd "$TEMP_REPO"
  run wtc my-feature
  assert_success
  [ -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  assert_output --partial "my-feature"
}

@test "wtc: adds .worktrees/ to .gitignore" {
  cd "$TEMP_REPO"
  run wtc my-feature
  assert_success
  run grep -F '.worktrees/' .gitignore
  assert_success
}

@test "wtc: does not duplicate .worktrees/ in .gitignore on second call" {
  cd "$TEMP_REPO"
  run wtc my-feature
  assert_success
  git worktree remove .worktrees/my-feature
  git branch -D my-feature
  run wtc other-feature
  assert_success
  run grep -cF '.worktrees/' .gitignore
  assert_output "1"
}

@test "wtc: errors if branch already exists" {
  cd "$TEMP_REPO"
  git branch my-feature
  run wtc my-feature
  assert_failure
}

@test "wtd: removes worktree and branch" {
  cd "$TEMP_REPO"
  wtc my-feature
  cd "$TEMP_REPO"
  run wtd my-feature
  assert_success
  [ ! -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  refute_output --partial "my-feature"
}

@test "wtd: removes worktree containing submodules" {
  cd "$TEMP_REPO"
  wtc my-feature
  # Create a bare repo to use as submodule origin
  local SUBMODULE_ORIGIN
  SUBMODULE_ORIGIN=$(mktemp -d)
  git -C "$SUBMODULE_ORIGIN" init -q
  git -C "$SUBMODULE_ORIGIN" config user.email "test@test.com"
  git -C "$SUBMODULE_ORIGIN" config user.name "Test"
  git -C "$SUBMODULE_ORIGIN" commit --allow-empty -m "init"
  # Initialize a submodule inside the worktree (triggers the git restriction
  # even when not committed); allow file transport for test isolation
  cd "$TEMP_REPO/.worktrees/my-feature"
  git -c protocol.file.allow=always submodule add "$SUBMODULE_ORIGIN" submod
  cd "$TEMP_REPO"
  run wtd my-feature
  assert_success
  [ ! -d ".worktrees/my-feature" ]
  run git branch --list my-feature
  refute_output --partial "my-feature"
  rm -rf "$SUBMODULE_ORIGIN"
}

@test "wtc: copies .claude/ directory into worktree when it exists" {
  cd "$TEMP_REPO"
  mkdir -p .claude/commands
  echo "# project instructions" > .claude/CLAUDE.md
  echo "some command" > .claude/commands/foo.md
  run wtc my-feature
  assert_success
  [ -f ".worktrees/my-feature/.claude/CLAUDE.md" ]
  [ -f ".worktrees/my-feature/.claude/commands/foo.md" ]
}

@test "wtc: succeeds without error when .claude/ does not exist" {
  cd "$TEMP_REPO"
  run wtc my-feature
  assert_success
  [ ! -d ".worktrees/my-feature/.claude" ]
}

@test "wt, wtc, wtd: all functions are defined" {
  run type wtc
  assert_success
  run type wt
  assert_success
  run type wtd
  assert_success
}
