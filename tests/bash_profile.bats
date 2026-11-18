# covers: bash_profile
# tests/bash_profile.bats
bats_require_minimum_version 1.5.0
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

@test "bash_profile: a PATH prepend in ~/.ssh/api_keys comes first, once" {
  # ~/.yarn/bin stands in for any dir the profile prepends late (mise, brew, installers).
  mkdir -p "$TEST_HOME/.yarn/bin"
  printf 'export PATH="$HOME/.yarn/bin:$PATH"\n' > "$TEST_HOME/.ssh/api_keys"
  _source_profile 'echo "${PATH%%:*}"; echo ":$PATH:" | grep -o ":$HOME/.yarn/bin:" | wc -l | tr -d " "'
  assert_success
  assert_output "$TEST_HOME/.yarn/bin"$'\n'"1"
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

# Load only _dotfiles_debug_timing from bash_profile, then run "$1".
_debug_timing() {
  run --separate-stderr bash -c "
    eval \"\$(sed -n '/^function _dotfiles_debug_timing/,/^}/p' '$REPO_ROOT/bash_profile')\"
    DEBUG_BASH_PROFILE=1
    $1
  "
}

@test "bash_profile: debug timing reports elapsed milliseconds" {
  # Unsetting EPOCHREALTIME drops its special meaning, so it can be faked.
  _debug_timing '
    unset EPOCHREALTIME
    EPOCHREALTIME=1704067200.000000; _dotfiles_debug_timing here
    EPOCHREALTIME=1704067200.250123; _dotfiles_debug_timing there
  '
  assert_success
  assert_output $'2024-01-01T00:00:00.000Z here +0\n2024-01-01T00:00:00.250Z there +250'
  assert_equal "$stderr" ""
}

@test "bash_profile: debug timing works with BSD date and no EPOCHREALTIME (macOS /bin/bash)" {
  # BSD date has no -d or %N; the fallback must not need either.
  _debug_timing '
    unset EPOCHREALTIME
    date() {
      case " $* " in
        *" -d "*|*%N*) echo "date: illegal option -- d" >&2; return 1 ;;
      esac
      [ -e "$BATS_TEST_TMPDIR/later" ] && echo "1704067202 2024-01-01T00:00:02Z" && return
      touch "$BATS_TEST_TMPDIR/later"
      echo "1704067200 2024-01-01T00:00:00Z"
    }
    _dotfiles_debug_timing here
    _dotfiles_debug_timing there
  '
  assert_success
  assert_output $'2024-01-01T00:00:00Z here +0\n2024-01-01T00:00:02Z there +2000'
  assert_equal "$stderr" ""
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
