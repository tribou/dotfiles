# covers: lib/commands.sh
# tests/histgrep_parsing.bats
bats_require_minimum_version 1.5.0

setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Test the histfile delimiter pattern strips the filename prefix
@test "histfile delimiter strips date-hostname prefix" {
  local line="2024/01/15.10.30.00_myhostname:some command here"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "some command here"
}

@test "histfile delimiter handles hostname with dots" {
  local line="2024/01/15.10.30.00_my.host.name:another command"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "another command"
}

@test "histfile delimiter does not split on colons within the command" {
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && printf '%s\n' \"2024/01/15.10.30.00_myhostname:echo 'hello:world'\" | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "echo 'hello:world'"
}

# Test the shell history delimiter (strips '  123  2024-01-15 10:30:00 ' prefix)
@test "history delimiter strips history number and timestamp prefix" {
  local line="  123  2024-01-15 10:30:00 git status"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "git status"
}

@test "history delimiter handles single-digit history number" {
  local line="    1  2024-01-15 10:30:00 ls"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "ls"
}

@test "histgrep parses history files without awk warnings" {
  mkdir -p "$BATS_TEST_TMPDIR/home/.history/2024/01"
  printf '%s\n' "ssh remote" > "$BATS_TEST_TMPDIR/home/.history/2024/01/15.10.30.00_server"

  run --separate-stderr bash -c "
    unset TMUX HERDR_PANE_ID
    export HOME='$BATS_TEST_TMPDIR/home'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { cat; }
    copy_to_clipboard() { :; }
    histgrep remote
  "

  assert_success
  assert_output "ssh remote"
  assert_equal "$stderr" ""
}

@test "histgrep warns instead of erroring when ~/.history target is unavailable" {
  mkdir -p "$BATS_TEST_TMPDIR/home"
  ln -s "$BATS_TEST_TMPDIR/unmounted-drive/.history" "$BATS_TEST_TMPDIR/home/.history"

  run --separate-stderr bash -c "
    unset TMUX HERDR_PANE_ID
    export HOME='$BATS_TEST_TMPDIR/home'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    fzf() { cat; }
    copy_to_clipboard() { :; }
    histgrep remote
  "

  assert_success
  assert_output ""
  assert_equal "$stderr" "histgrep: no saved history in ~/.history (is Google Drive mounted?); searching current shell history only"
}

# Runs histgrep in a fake pane whose prompt leaves canonical mode on the 3rd
# stty check; the multiplexer stub records how many checks preceded the send.
_run_histgrep_in_pane() {
  mkdir -p "$BATS_TEST_TMPDIR/home/.history/2024/01"
  printf '%s\n' "ssh remote" > "$BATS_TEST_TMPDIR/home/.history/2024/01/15.10.30.00_server"
  cat > "$BATS_TEST_TMPDIR/pane.sh" <<'EOF'
. "$REPO_ROOT/lib/_shared.sh"
. "$REPO_ROOT/lib/commands.sh"
CHECKS="$BATS_TEST_TMPDIR/checks"
SENT="$BATS_TEST_TMPDIR/sent"
fzf() { cat; }
copy_to_clipboard() { echo 'clipboard called' >&2; }
tty() { echo /dev/null; }
stty() {
  echo x >> "$CHECKS"
  if [ "$(wc -l < "$CHECKS")" -ge 3 ]; then echo 'speed 38400 baud; -icanon -echo'; else echo 'speed 38400 baud; icanon echo'; fi
}
_record_send() { { printf 'checks=%s %s' $(wc -l < "$CHECKS") "$1"; shift; printf ' [%s]' "$@"; echo; } > "$SENT"; }
herdr() { _record_send herdr "$@"; }
tmux() { _record_send tmux "$@"; }
histgrep remote
for _ in $(seq 100); do [ -s "$SENT" ] && break; sleep 0.05; done
cat "$SENT"
EOF
  run --separate-stderr env "$@" HOME="$BATS_TEST_TMPDIR/home" REPO_ROOT="$REPO_ROOT" \
    BATS_TEST_TMPDIR="$BATS_TEST_TMPDIR" bash "$BATS_TEST_TMPDIR/pane.sh"
}

@test "histgrep types the selection into a herdr pane only after the prompt leaves canonical mode" {
  _run_histgrep_in_pane -u TMUX HERDR_PANE_ID='w1:p2'

  assert_success
  assert_output "checks=3 herdr [pane] [send-text] [w1:p2] [ssh remote]"
  assert_equal "$stderr" ""
}

@test "histgrep types the selection into a tmux pane only after the prompt leaves canonical mode" {
  _run_histgrep_in_pane -u HERDR_PANE_ID TMUX='/tmp/tmux-1/default,1,0' TMUX_PANE='%7'

  assert_success
  assert_output "checks=3 tmux [send-keys] [-t] [%7] [ssh remote]"
  assert_equal "$stderr" ""
}
