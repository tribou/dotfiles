# covers: tmux/tmux-conf
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# tmux, fzf, bat, etc. are mise-managed now; run-shell/#() jobs (TPM included)
# inherit this pinned PATH, so it must reach the mise shims.
@test "tmux-conf: global PATH includes mise shims" {
  grep -E '^set-environment -g PATH ' "$REPO_ROOT/tmux/tmux-conf" | grep -qF '.local/share/mise/shims'
}

# The checkout can live anywhere, so the status bar finds its scripts through
# DOTFILES (set by bash_profile) rather than ~/dev/dotfiles.
@test "tmux-conf: status bar scripts resolve through DOTFILES" {
  run grep -F '~/dev/dotfiles' "$REPO_ROOT/tmux/tmux-conf"
  assert_failure
  grep -qF '#(#{DOTFILES}/scripts/internet.sh)' "$REPO_ROOT/tmux/tmux-conf"
  grep -qF '#(#{DOTFILES}/scripts/battery.sh)' "$REPO_ROOT/tmux/tmux-conf"
}

# A tmux server started without bash_profile (from zsh, a non-login shell or a
# launcher) has no DOTFILES; without a fallback the status bar scripts and the
# right-click menu silently resolve to /scripts/... and show nothing.
@test "tmux-conf: derives DOTFILES from the ~/.tmux.conf link when the server starts without it" {
  command -v tmux >/dev/null || skip "tmux not installed"
  local home="$BATS_TEST_TMPDIR/home" sock="dotfiles-test-$$-$BATS_TEST_NUMBER"
  mkdir -p "$home"
  ln -s "$REPO_ROOT/tmux/tmux-conf" "$home/.tmux.conf"
  env -u DOTFILES -u TMUX HOME="$home" tmux -L "$sock" -f "$home/.tmux.conf" new-session -d
  run tmux -L "$sock" show-environment -g DOTFILES
  tmux -L "$sock" kill-server
  assert_output "DOTFILES=$REPO_ROOT"
}

@test "tmux-conf: keeps a DOTFILES the server already has" {
  command -v tmux >/dev/null || skip "tmux not installed"
  local home="$BATS_TEST_TMPDIR/home" sock="dotfiles-test-$$-$BATS_TEST_NUMBER"
  mkdir -p "$home"
  ln -s "$REPO_ROOT/tmux/tmux-conf" "$home/.tmux.conf"
  env -u TMUX DOTFILES=/somewhere/else HOME="$home" tmux -L "$sock" -f "$home/.tmux.conf" new-session -d
  run tmux -L "$sock" show-environment -g DOTFILES
  tmux -L "$sock" kill-server
  assert_output "DOTFILES=/somewhere/else"
}
