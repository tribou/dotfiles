setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "prereqs: apt task sets cache_valid_time: 86400" {
  run grep -E 'cache_valid_time:\s*86400' "$REPO_ROOT/roles/dotfiles/tasks/prereqs.yml"
  assert_success
}

@test "nvim: gopls task checks which gopls before installation" {
  run grep -E 'which gopls' "$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
  assert_success
  run grep -E 'dotfiles_gopls_check\.rc != 0' "$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
  assert_success
  # Old flawed creates path must not be present
  run grep -E 'creates:.*dev/go/bin/gopls' "$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
  assert_failure
}
