# covers: scripts/brew_cleanup.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  STUBS="$BATS_TEST_TMPDIR/bin"
  LOG="$BATS_TEST_TMPDIR/calls.log"
  mkdir -p "$STUBS"
  : > "$LOG"
  export CALL_LOG="$LOG"
  VERIFY="$BATS_TEST_TMPDIR/verify.sh"
  printf '#!/bin/sh\necho verify >> "$CALL_LOG"\nexit 0\n' > "$VERIFY"
  chmod +x "$VERIFY"
  export DOTFILES_VERIFY_MISE="$VERIFY"
}

# fake_brew INSTALLED...: a brew that lists the given formulae and logs uninstalls.
fake_brew() {
  {
    printf '#!/usr/bin/env bash\n'
    printf 'if [ "$1 $2 $3" = "list --formula -1" ]; then echo list >> "$CALL_LOG"; printf "%%s\\n" %s; exit 0; fi\n' "$*"
    printf 'if [ "$1" = uninstall ]; then echo "uninstall $3" >> "$CALL_LOG"; [ "$3" = neovim ] && { echo "cannot remove $3" >&2; exit 1; }; fi\n'
    printf 'echo "brew $*" >> "$CALL_LOG"\n'
  } > "$STUBS/brew"
  chmod +x "$STUBS/brew"
}

@test "brew_cleanup: no Homebrew means nothing to do" {
  run env DOTFILES_BREW_BIN=/nonexistent/brew "$REPO_ROOT/scripts/brew_cleanup.sh"
  assert_success
  [ ! -s "$LOG" ]
}

@test "brew_cleanup: lists once, verifies mise, then removes only replaced formulae" {
  fake_brew bash fzf python@3.13 git-delta zlib
  run env DOTFILES_BREW_BIN="$STUBS/brew" "$REPO_ROOT/scripts/brew_cleanup.sh"
  assert_success
  [ "$(grep -cx list "$LOG")" -eq 1 ]
  sed -n 2p "$LOG" | grep -qx verify
  grep -qx 'uninstall fzf' "$LOG"
  grep -qx 'uninstall git-delta' "$LOG"
  grep -qx 'uninstall python@3.13' "$LOG"
  ! grep -qx 'uninstall bash' "$LOG"
  ! grep -qx 'uninstall zlib' "$LOG"
  assert_output --partial 'changed: removed legacy Homebrew fzf'
}

@test "brew_cleanup: skips verification when nothing legacy is installed" {
  fake_brew bash zlib
  run env DOTFILES_BREW_BIN="$STUBS/brew" "$REPO_ROOT/scripts/brew_cleanup.sh"
  assert_success
  ! grep -qx verify "$LOG"
  refute_output --partial 'changed:'
}

@test "brew_cleanup: a failed mise verification stops before any uninstall" {
  fake_brew fzf
  printf '#!/bin/sh\nexit 1\n' > "$VERIFY"
  run env DOTFILES_BREW_BIN="$STUBS/brew" "$REPO_ROOT/scripts/brew_cleanup.sh"
  assert_failure
  ! grep -q '^uninstall' "$LOG"
}

@test "brew_cleanup: an uninstall failure warns but does not fail" {
  fake_brew neovim fzf
  run env DOTFILES_BREW_BIN="$STUBS/brew" "$REPO_ROOT/scripts/brew_cleanup.sh"
  assert_success
  assert_output --partial 'WARNING: Homebrew cleanup could not remove these legacy formulae'
  assert_output --partial 'neovim: cannot remove neovim'
  grep -qx 'uninstall fzf' "$LOG"
}

@test "brew_cleanup: never prunes or ignores dependencies" {
  ! grep -qE 'prune|--ignore-dependencies' "$REPO_ROOT/scripts/brew_cleanup.sh"
}
