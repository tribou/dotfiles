# covers: lib/git.sh
# tests/gbd_command.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "gbd: picker offers only local branches, not remote-only ones" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/git.sh'
    git() {
      case \"\$*\" in
        *refs/heads*) printf '%s\n' local-branch ;;
        *refs/remotes*) printf '%s\n' remote-only ;;
      esac
    }
    fzf() { cat >&2; }
    gbd 2>&1
  "
  assert_success
  assert_output "local-branch"
}
