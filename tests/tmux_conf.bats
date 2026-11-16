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

# The README clones wherever the user likes, so the status bar finds its
# scripts through DOTFILES (set by bash_profile) rather than ~/dev/dotfiles.
@test "tmux-conf: status bar scripts resolve through DOTFILES" {
  run grep -F '~/dev/dotfiles' "$REPO_ROOT/tmux/tmux-conf"
  assert_failure
  grep -qF '#(#{DOTFILES}/scripts/internet.sh)' "$REPO_ROOT/tmux/tmux-conf"
  grep -qF '#(#{DOTFILES}/scripts/battery.sh)' "$REPO_ROOT/tmux/tmux-conf"
}
