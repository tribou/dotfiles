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

@test "spinner_wait: SIGINT kills the watched pid and returns 130 with no stdout output" {
  run -130 --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    sleep 5 &
    pid=\$!
    ( sleep 0.2; kill -INT \$\$ ) &
    _dotfiles_spinner_wait \"\$pid\" 'Asking Claude for a commit message...'
    status=\$?
    sleep 0.2
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
