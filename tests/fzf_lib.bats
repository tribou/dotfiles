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

@test "_dotfiles_beads_show is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    declare -f _dotfiles_beads_show > /dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "bdr alias is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    alias bdr 2>/dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "bds alias is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    alias bds 2>/dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "_dotfiles_beads_show calls bd show with the selected issue ID" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    bd() {
      if [[ \"\$1\" == 'list' ]]; then
        echo '○ dotfiles-ynp ● P2 Add fzf command'
      elif [[ \"\$1\" == 'show' ]]; then
        echo \"showing: \$2\"
      fi
    }
    fzf() { cat; }
    _dotfiles_beads_show
  "
  assert_success
  assert_output --partial "showing: dotfiles-ynp"
}

@test "_dotfiles_beads_show exits silently when fzf returns no selection" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    bd() { echo 'bd called unexpectedly'; }
    fzf() { return 1; }
    _dotfiles_beads_show
    echo 'exited_ok'
  "
  assert_success
  assert_output "exited_ok"
}
