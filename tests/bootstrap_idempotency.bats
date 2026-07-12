setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "role: ansible check mode completes on an installed machine" {
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    skip "ansible-playbook not installed"
  fi
  if ! command -v brew >/dev/null 2>&1; then
    skip "Homebrew not installed"
  fi
  cd "$REPO_ROOT"
  run ansible-playbook playbook.yml --check --diff
  assert_success
}
