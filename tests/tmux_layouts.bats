# covers: lib/tmux.sh
# tests/tmux_layouts.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  mkdir -p "$BATS_TEST_TMPDIR/primary" "$BATS_TEST_TMPDIR/secondary"
  TMUX_LOG="$BATS_TEST_TMPDIR/tmux.log"
  tmux() { printf '%s\n' "$*" >> "$TMUX_LOG"; }
  unset PRIMARY_REPO SECONDARY_REPO
}

@test "tmux-large: opens the secondary pane in the second argument" {
  TMUX=yes tmux-large "$BATS_TEST_TMPDIR/primary" "$BATS_TEST_TMPDIR/secondary"
  grep -qF -- "-c $BATS_TEST_TMPDIR/secondary" "$TMUX_LOG"
}

@test "tmux-small-3: opens the secondary pane in the second argument" {
  TMUX=yes tmux-small-3 "$BATS_TEST_TMPDIR/primary" "$BATS_TEST_TMPDIR/secondary"
  grep -qF -- "-c $BATS_TEST_TMPDIR/secondary" "$TMUX_LOG"
}

@test "tmux-small-2: opens the secondary pane in the second argument" {
  TMUX=yes tmux-small-2 "$BATS_TEST_TMPDIR/primary" "$BATS_TEST_TMPDIR/secondary"
  grep -qF -- "-c $BATS_TEST_TMPDIR/secondary" "$TMUX_LOG"
}

@test "tmux-xl: stops outside a tmux session" {
  unset TMUX
  run tmux-xl
  assert_failure
  assert_output "Not in a tmux session"
  [ ! -e "$TMUX_LOG" ]
}

@test "tmux-small-2: stops outside a tmux session" {
  unset TMUX
  run tmux-small-2
  assert_failure
  assert_output "Not in a tmux session"
  [ ! -e "$TMUX_LOG" ]
}

@test "tmux layouts never call send-keys without keys" {
  local layout
  for layout in tmux-large tmux-xl tmux-small tmux-small-2 tmux-small-3 tmux-small-half; do
    TMUX=yes "$layout" "$BATS_TEST_TMPDIR/primary" "$BATS_TEST_TMPDIR/secondary"
  done
  run grep -E '^send-keys -t [0-9]+$' "$TMUX_LOG"
  assert_failure
}

@test "tmux-xl: still adds its extra pane when primary and secondary are the same" {
  TMUX=yes tmux-xl "$BATS_TEST_TMPDIR/primary"
  grep -qF "split-window -v -l 20%" "$TMUX_LOG"
}
