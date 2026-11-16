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
