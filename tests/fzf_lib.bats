# tests/fzf_lib.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "lib/fzf.sh sources without error when z alias is not set" {
  run bash -c "
    set -euo pipefail
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    echo 'sourced_ok'
  "
  assert_success
  assert_output --partial "sourced_ok"
}

@test "tmux-conf uses run without -b flag for tpm init" {
  run grep -E "^run\s+-b\s+'[^']*tpm/tpm'" "$REPO_ROOT/tmux/tmux-conf"
  assert_failure
}
