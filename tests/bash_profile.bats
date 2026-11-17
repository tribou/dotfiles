# covers: bash_profile
# tests/bash_profile.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME/.ssh"
}

# Source bash_profile non-interactively with an isolated HOME, then run "$1".
_source_profile() {
  run --separate-stderr env -u DOTFILES_COMMIT_BACKEND -u DOTFILES_COMMIT_TIMEOUT \
    HOME="$TEST_HOME" STARTPATH="$BATS_TEST_TMPDIR" TERM=dumb \
    bash -c "cd '$BATS_TEST_TMPDIR' && source '$REPO_ROOT/bash_profile' >/dev/null && $1"
}

@test "bash_profile: commit backend and timeout set in ~/.ssh/api_keys are kept" {
  printf 'export DOTFILES_COMMIT_BACKEND=claude\nexport DOTFILES_COMMIT_TIMEOUT=60\n' > "$TEST_HOME/.ssh/api_keys"
  _source_profile 'echo "$DOTFILES_COMMIT_BACKEND $DOTFILES_COMMIT_TIMEOUT"'
  assert_success
  assert_output "claude 60"
}

@test "bash_profile: commit backend and timeout default to opencode and 30" {
  _source_profile 'echo "$DOTFILES_COMMIT_BACKEND $DOTFILES_COMMIT_TIMEOUT"'
  assert_success
  assert_output "opencode 30"
}

@test "bash_profile: does not add a missing ~/.composer/vendor/bin to PATH" {
  _source_profile 'echo "$PATH"'
  assert_success
  refute_output --partial "$TEST_HOME/.composer/vendor/bin"
}

@test "bash_profile: adds ~/.composer/vendor/bin to PATH when it exists" {
  mkdir -p "$TEST_HOME/.composer/vendor/bin"
  _source_profile 'echo "$PATH"'
  assert_success
  assert_output --partial "$TEST_HOME/.composer/vendor/bin"
}

@test "bash_profile: debug timing reports elapsed milliseconds" {
  run bash -c "
    eval \"\$(sed -n '/^function _dotfiles_debug_timing/,/^}/p' '$REPO_ROOT/bash_profile')\"
    date() {
      case \"\$*\" in
        *'+%Y-%m-%dT%H:%M:%S.%NZ'*) echo 2024-01-01T00:00:00.250000000Z ;;
        *) command date \"\$@\" ;;
      esac
    }
    OS=Linux DEBUG_BASH_PROFILE=1 DOTFILES_DEBUG_LAST_TIME=2024-01-01T00:00:00.000000000Z
    _dotfiles_debug_timing here
  "
  assert_success
  assert_output "2024-01-01T00:00:00.250000000Z here +250"
}

@test "bash_profile: tmux version lookup is quiet when tmux is not installed" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  ln -s "$(command -v sed)" "$BATS_TEST_TMPDIR/bin/sed"
  local snippet
  snippet=$(sed -n '/^# tmux$/,/^# yarn$/p' "$REPO_ROOT/bash_profile")
  run --separate-stderr env -u TMUX_VERSION PATH="$BATS_TEST_TMPDIR/bin" /bin/bash -c "$snippet"$'\necho "[$TMUX_VERSION]"'
  assert_success
  assert_output "[]"
  assert_equal "$stderr" ""
}
