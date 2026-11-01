# covers: roles/dotfiles/tasks/prereqs.yml roles/dotfiles/tasks/nvim.yml
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

@test "nvim: --break-system-packages is only passed when the target pip supports it" {
  # Ansible's interpreter discovery can fall back to Apple's /usr/bin/python3
  # (Python 3.9, pip 21.2.4), whose pip predates --break-system-packages
  # (pip 23.0.1) and rejects it with "no such option".
  local nvim="$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
  run grep -E 'pip install --help' "$nvim"
  assert_success
  # No task may hardcode the flag; it must come from the support check.
  run grep -nE '^[^#]*(pip install|extra_args:).*--break-system-packages' "$nvim"
  assert_failure
  run grep -E 'extra_args:.*dotfiles_pip_user_args' "$nvim"
  assert_success
  run grep -E 'pip install \{\{ dotfiles_pip_user_args \}\} packaging' "$nvim"
  assert_success
}
