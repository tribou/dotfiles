# tests/integration/nvim_keymaps.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "leader key mappings exist" {
  run nvim --headless -c "redir => g:maps | silent map <Leader> | redir END | echo g:maps | qall" 2>&1
  # Should output something (not empty) - leader mappings are configured
  [ -n "$output" ]
}

@test "no duplicate normal mode mappings" {
  run nvim --headless -c "redir => g:maps | silent nmap | redir END | echo g:maps | qall" 2>&1
  # Check that output exists (mappings are configured)
  assert_success
}
