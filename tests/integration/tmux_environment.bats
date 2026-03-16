# tests/integration/tmux_environment.bats
#
# Tests tmux configuration by parsing the config file directly.
# Avoids starting a live tmux server (which requires a TTY and hangs in CI).
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
  TMUX_CONF="$DOTFILES/tmux/tmux-conf"
}

@test "tmux config file exists" {
  [ -f "$TMUX_CONF" ]
}

@test "tmux prefix is set to C-f (not default C-b)" {
  run grep -E "^set -g prefix C-f" "$TMUX_CONF"
  assert_success
}

@test "default C-b prefix is unbound" {
  run grep -E "^unbind C-b" "$TMUX_CONF"
  assert_success
}

@test "vertical split binding exists (C-v)" {
  run grep -E "split-window" "$TMUX_CONF"
  assert_success
  assert_output --partial "C-v"
}

@test "horizontal split binding exists (C-h)" {
  run grep -E "split-window" "$TMUX_CONF"
  assert_success
  assert_output --partial "C-h"
}

@test "tmux-resurrect plugin is listed in config" {
  run grep -r "resurrect" "$DOTFILES/tmux/"
  assert_success
}

@test "tmux-yank plugin is listed in config" {
  run grep -r "yank" "$DOTFILES/tmux/"
  assert_success
}

@test "tmux-resurrect plugin directory exists" {
  [ -d "$HOME/.tmux/plugins/tmux-resurrect" ]
}

@test "tmux-yank plugin directory exists" {
  [ -d "$HOME/.tmux/plugins/tmux-yank" ]
}

@test "mouse mode is enabled in config" {
  run grep "mouse on" "$TMUX_CONF"
  assert_success
}

@test "256color terminal is configured" {
  run grep "256color" "$TMUX_CONF"
  assert_success
}
