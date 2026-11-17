# covers: lib/fzf.sh tmux/tmux-conf
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

@test "_dotfiles_ghv_show is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    declare -f _dotfiles_ghv_show > /dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "ghv alias is defined after sourcing fzf.sh" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    alias ghv 2>/dev/null && echo 'defined'
  "
  assert_success
  assert_output --partial "defined"
}

@test "_dotfiles_ghv_show calls gh issue view with the selected issue ID" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    gh() {
      if [[ \"\$1\" == 'issue' && \"\$2\" == 'list' ]]; then
        echo '[{\"number\":141,\"title\":\"Create a ghv command\",\"labels\":[]}]'
      elif [[ \"\$1\" == 'pr' && \"\$2\" == 'list' ]]; then
        echo '[]'
      elif [[ \"\$1\" == 'issue' && \"\$2\" == 'view' ]]; then
        echo \"showing issue: \$3\"
      fi
    }
    fzf() {
      echo \"issue  #141  Create a ghv command\"
    }
    _dotfiles_ghv_show
  "
  assert_success
  assert_output --partial "showing issue: 141"
}

@test "_dotfiles_ghv_show calls gh pr view with the selected PR ID" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    gh() {
      if [[ \"\$1\" == 'issue' && \"\$2\" == 'list' ]]; then
        echo '[]'
      elif [[ \"\$1\" == 'pr' && \"\$2\" == 'list' ]]; then
        echo '[{\"number\":142,\"title\":\"Implement PR feature\",\"labels\":[]}]'
      elif [[ \"\$1\" == 'pr' && \"\$2\" == 'view' ]]; then
        echo \"showing pr: \$3\"
      fi
    }
    fzf() {
      echo \"pr     #142  Implement PR feature\"
    }
    _dotfiles_ghv_show
  "
  assert_success
  assert_output --partial "showing pr: 142"
}

@test "_dotfiles_ghv_show exits silently when fzf returns no selection" {
  run bash -c "
    unalias z 2>/dev/null || true
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/fzf.sh'
    gh() {
      if [[ \"\$1\" == 'issue' && \"\$2\" == 'list' ]]; then
        echo '[{\"number\":141,\"title\":\"Create a ghv command\",\"labels\":[]}]'
      elif [[ \"\$1\" == 'pr' && \"\$2\" == 'list' ]]; then
        echo '[]'
      else
        echo \"Unexpected gh call: \$*\" >&2
        return 1
      fi
    }
    fzf() { return 1; }
    _dotfiles_ghv_show
    echo 'exited_ok'
  "
  assert_success
  assert_output "exited_ok"
}

@test "fo: does not change IFS or leak variables into the shell" {
  fzf-tmux() { printf 'ctrl-e\nsome file.txt\n'; }
  myeditor() { echo "edit [$1]"; }
  EDITOR=myeditor
  unset out key file
  local before_ifs="$IFS"
  fo > "$BATS_TEST_TMPDIR/out"
  assert_equal "$IFS" "$before_ifs"
  [ -z "${out+set}" ]
  [ -z "${key+set}" ]
  [ -z "${file+set}" ]
  run cat "$BATS_TEST_TMPDIR/out"
  assert_output "edit [some file.txt]"
}

@test "fo: ctrl-o opens with xdg-open on Linux" {
  fzf-tmux() { printf 'ctrl-o\nsome file.txt\n'; }
  is_macos() { return 1; }
  is_linux() { return 0; }
  xdg-open() { echo "xdg-open [$1]"; }
  open() { echo "open [$1]"; }
  run fo
  assert_output "xdg-open [some file.txt]"
}

@test "fo: ctrl-o opens with open on macOS" {
  fzf-tmux() { printf 'ctrl-o\nsome file.txt\n'; }
  is_macos() { return 0; }
  is_linux() { return 1; }
  xdg-open() { echo "xdg-open [$1]"; }
  open() { echo "open [$1]"; }
  run fo
  assert_output "open [some file.txt]"
}
