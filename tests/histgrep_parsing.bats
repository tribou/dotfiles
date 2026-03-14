# tests/histgrep_parsing.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Test the histfile delimiter pattern strips the filename prefix
@test "histfile delimiter strips date-hostname prefix" {
  local line="2024/01/15.10.30.00_myhostname:some command here"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "some command here"
}

@test "histfile delimiter handles hostname with dots" {
  local line="2024/01/15.10.30.00_my.host.name:another command"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "another command"
}

@test "histfile delimiter does not split on colons within the command" {
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && printf '%s\n' \"2024/01/15.10.30.00_myhostname:echo 'hello:world'\" | awk -F \"\$DOTFILES_HISTFILE_DELIM\" '{print \$NF}'"
  assert_output "echo 'hello:world'"
}

# Test the shell history delimiter (strips '  123  2024-01-15 10:30:00 ' prefix)
@test "history delimiter strips history number and timestamp prefix" {
  local line="  123  2024-01-15 10:30:00 git status"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "git status"
}

@test "history delimiter handles single-digit history number" {
  local line="    1  2024-01-15 10:30:00 ls"
  run bash -c ". '$REPO_ROOT/lib/_shared.sh' && echo '$line' | awk -F \"\$DOTFILES_HISTORY_DELIM\" '{print \$NF}'"
  assert_output "ls"
}
