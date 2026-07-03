setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "spinner_wait: returns 0 when the watched process exits 0, label printed to stderr" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    sleep 0.2 &
    pid=\$!
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
  "
  assert_success
  assert_output ""
  echo "$stderr" | grep -qF 'Asking Claude for a commit message...'
}

@test "spinner_wait: returns the watched process's nonzero exit status" {
  run -7 --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    (sleep 0.1; exit 7) &
    pid=\$!
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
  "
  assert_output ""
}

@test "spinner_wait: times out, kills the watched pid, and returns 124" {
  run -124 --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    command sleep 5 &
    pid=\$!
    sleep() { :; }
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...' 1
    status=\$?
    command sleep 0.2
    if kill -0 \"\$pid\" 2>/dev/null; then
      echo 'pid_still_alive' >&2
    else
      echo 'pid_killed' >&2
    fi
    exit \"\$status\"
  "
  assert_output ""
  echo "$stderr" | grep -qF 'pid_killed'
}

@test "spinner_wait: process finishing before the timeout returns its exit status" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    command sleep 0.2 &
    pid=\$!
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...' 30
  "
  assert_success
}

@test "spinner_wait: a non-numeric timeout is treated as no timeout" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    command sleep 0.2 &
    pid=\$!
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...' 'bogus'
  "
  assert_success
}

@test "spinner_wait: SIGINT kills the watched pid and returns 130 with no stdout output" {
  run -130 --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    sleep 5 &
    pid=\$!
    sleep() {
      unset -f sleep
      kill -INT \$\$
    }
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
    status=\$?
    command sleep 0.2
    if kill -0 \"\$pid\" 2>/dev/null; then
      echo 'pid_still_alive' >&2
    else
      echo 'pid_killed' >&2
    fi
    exit \"\$status\"
  "
  assert_output ""
  echo "$stderr" | grep -qF 'pid_killed'
}
