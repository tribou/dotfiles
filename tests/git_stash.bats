# covers: lib/git.sh
# tests/git_stash.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  git() { printf '[%s]' "$@"; echo; }
}

@test "gss: stashes with git stash push" {
  run gss
  assert_output "[stash][push]"
}

@test "gss: passes a message with -m" {
  run gss wip on login
  assert_output "[stash][push][-m][wip on login]"
}

@test "gssk: keeps the index and passes a message with -m" {
  run gssk wip
  assert_output "[stash][push][--keep-index][-m][wip]"
}
