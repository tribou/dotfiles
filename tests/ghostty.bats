# covers: lib/ghostty.sh bash_profile ghostty/* tmux/tmux-conf mise.toml mise-config.toml mise-config.optional.toml.example scripts/bootstrap/converge.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  CONFIG="$REPO_ROOT/ghostty/config.ghostty"
  THEME="$REPO_ROOT/ghostty/themes/dotfiles-night"
  # Fake Ghostty resources dir whose integration script records that it ran.
  RES="$BATS_TEST_TMPDIR/ghostty-resources"
  mkdir -p "$RES/shell-integration/bash"
  # shellcheck disable=SC2016
  printf '__ghostty_precmd() { :; }\necho sourced >> "%s"\n' "$BATS_TEST_TMPDIR/calls" \
    > "$RES/shell-integration/bash/ghostty.bash"
}

# Run the bash_profile loading pattern twice (as a re-sourced profile would)
# in a clean shell with the given env.
run_loader() {
  # shellcheck disable=SC2016
  run env -u TMUX -u GHOSTTY_RESOURCES_DIR "$@" bash -c '
    . "$REPO_ROOT/lib/ghostty.sh"
    for _ in 1 2; do
      if _dotfiles_ghostty_bash_integration; then
        builtin source "$_DOTFILES_GHOSTTY_SCRIPT"
      fi
    done'
}

@test "ghostty: loader sources Ghostty's bash integration outside tmux, once" {
  run_loader GHOSTTY_RESOURCES_DIR="$RES"
  assert_success
  [ "$(cat "$BATS_TEST_TMPDIR/calls")" = sourced ]
}

@test "ghostty: loader skips inside tmux" {
  run_loader GHOSTTY_RESOURCES_DIR="$RES" TMUX=/tmp/tmux-1/default,1,0
  assert_success
  [ ! -e "$BATS_TEST_TMPDIR/calls" ]
}

@test "ghostty: loader skips outside Ghostty or without the script" {
  run_loader
  assert_success
  run_loader GHOSTTY_RESOURCES_DIR="$BATS_TEST_TMPDIR/missing"
  assert_success
  [ ! -e "$BATS_TEST_TMPDIR/calls" ]
}

@test "ghostty: bash_profile loads the integration after lib/index.sh" {
  local lib_line hook_line
  # shellcheck disable=SC2016  # literal $DOTFILES in the pattern
  lib_line="$(grep -n '^\. "\$DOTFILES/lib/index.sh"' "$REPO_ROOT/bash_profile" | cut -d: -f1)"
  hook_line="$(grep -n '^if _dotfiles_ghostty_bash_integration; then$' "$REPO_ROOT/bash_profile" | cut -d: -f1)"
  [ -n "$lib_line" ] && [ -n "$hook_line" ]
  [ "$hook_line" -gt "$lib_line" ]
}

@test "ghostty: config uses manual shell integration with the ssh and sudo features" {
  grep -qxF 'shell-integration = none' "$CONFIG"
  grep -qxF 'shell-integration-features = no-cursor,sudo,ssh-env,ssh-terminfo' "$CONFIG"
  grep -qxF 'command = /bin/bash --login' "$CONFIG"
}

@test "ghostty: config keeps the font, opacity, padding and theme" {
  grep -qxF 'font-family = Hack Nerd Font' "$CONFIG"
  grep -qxF 'font-thicken = true' "$CONFIG"
  grep -qxF 'font-size = 13' "$CONFIG"
  grep -qxF 'background-opacity = 0.98' "$CONFIG"
  grep -qxF 'window-padding-x = 0' "$CONFIG"
  grep -qxF 'window-padding-y = 0' "$CONFIG"
  grep -qxF 'theme = dotfiles-night' "$CONFIG"
  grep -qxF 'bold-color = bright' "$CONFIG"
}

@test "ghostty: theme defines background, foreground and all 16 palette colors" {
  grep -qxF 'background = #011627' "$THEME"
  grep -qxF 'foreground = #91ddff' "$THEME"
  local i
  for i in $(seq 0 15); do
    grep -qE "^palette = ${i}=#[0-9a-f]{6}$" "$THEME" || fail "palette $i"
  done
}

@test "ghostty: config leaves tmux's C-S-Left/Right window swaps to tmux" {
  grep -qF 'bind-key -n C-S-Left swap-window' "$REPO_ROOT/tmux/tmux-conf"
  grep -qxF 'keybind = ctrl+shift+arrow_left=unbind' "$CONFIG"
  grep -qxF 'keybind = ctrl+shift+arrow_right=unbind' "$CONFIG"
}

@test "ghostty: config validates with ghostty when it is installed" {
  command -v ghostty >/dev/null || skip "ghostty not installed"
  local cfg="$BATS_TEST_TMPDIR/xdg/ghostty"
  mkdir -p "$cfg/themes"
  cp "$CONFIG" "$cfg/config.ghostty"
  cp "$THEME" "$cfg/themes/"
  XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg" run ghostty +validate-config --config-file="$cfg/config.ghostty"
  assert_success
}

@test "ghostty: mise links the config and theme, and doctor checks them" {
  grep -qxF '"~/.config/ghostty/config.ghostty" = "ghostty/config.ghostty"' "$REPO_ROOT/mise.toml"
  grep -qxF '"~/.config/ghostty/themes/dotfiles-night" = "ghostty/themes/dotfiles-night"' "$REPO_ROOT/mise.toml"
  grep -qF '"~/.config/ghostty/config.ghostty~ghostty/config.ghostty"' "$REPO_ROOT/scripts/doctor.sh"
  grep -qF '"~/.config/ghostty/themes/dotfiles-night~ghostty/themes/dotfiles-night"' "$REPO_ROOT/scripts/doctor.sh"
}

@test "ghostty: installed as a macOS cask by default and opt-in on Arch" {
  grep -qxF '"brew-cask:ghostty" = { version = "latest", os = "macos", adopt = true }' "$REPO_ROOT/mise-config.toml"
  grep -qxF '# "pacman:ghostty" = "latest"' "$REPO_ROOT/mise-config.optional.toml.example"
}

@test "ghostty: the configured font is installed with Ghostty on macOS" {
  # Without it Ghostty silently falls back to its built-in JetBrains Mono,
  # which looks different and has taller rows.
  grep -qxF 'font-family = Hack Nerd Font' "$CONFIG"
  grep -qxF '"brew-cask:font-hack-nerd-font" = { version = "latest", os = "macos" }' "$REPO_ROOT/mise-config.toml"
  run grep -F 'brew-cask:font-hack-nerd-font' "$REPO_ROOT/mise-config.optional.toml.example"
  assert_failure
}

@test "ghostty: tmux advertises Ghostty's features to tmux" {
  grep -qE "^set -as terminal-features ',xterm-ghostty:" "$REPO_ROOT/tmux/tmux-conf"
}

@test "ghostty: no Alacritty references remain outside historical docs" {
  run bash -c "cd '$REPO_ROOT' && git ls-files -z -- . ':!docs/plans/' ':!docs/superpowers/' ':!docs/research/' ':!tests/ghostty.bats' | xargs -0 grep -d skip -Ili 'alacritty' --"
  assert_output ''
  [ ! -e "$REPO_ROOT/alacritty.toml" ]
  [ ! -e "$REPO_ROOT/tmux/xterm-256color-italic.terminfo" ]
}
