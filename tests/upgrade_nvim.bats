setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: `--sync` is a vim-plug argument to the PlugUpdate ex-command, not an
# nvim CLI option. It must stay quoted/glued to the `+PlugUpdate` command, otherwise
# Ansible's shlex splits it out and nvim errors with `Unknown option argument: "--sync"`.
@test "upgrade.yml: PlugUpdate --sync is quoted so nvim does not receive --sync as an option" {
  run bash -c "grep -n 'PlugUpdate' \"$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml\""
  [ "$status" -eq 0 ]
  # The +PlugUpdate command and its --sync argument must be a single quoted token.
  run bash -c "grep -q '\"+PlugUpdate --sync\"' \"$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml\""
  [ "$status" -eq 0 ]
}
