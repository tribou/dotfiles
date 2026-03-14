# tests/integration/bash_profile.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "bash_profile sources without errors" {
  run bash -c "source '$DOTFILES/bash_profile' 2>&1; echo exit:\$?"
  assert_output --partial "exit:0"
  refute_output --regexp "bash:.*No such file"
  refute_output --regexp "line [0-9]+:.*error"
}

@test "bootstrap script is idempotent (safe to run twice)" {
  run bash "$DOTFILES/scripts/bootstrap-test.sh"
  assert_success
}

@test "DOTFILES env var is set to /dotfiles after sourcing bash_profile" {
  run bash -c "source '$DOTFILES/bash_profile' 2>/dev/null && echo \$DOTFILES"
  assert_output "/dotfiles"
}
