setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "role: configured inventory contains localhost without parse warnings" {
  if ! command -v ansible-inventory >/dev/null 2>&1; then
    skip "ansible-inventory not installed"
  fi

  run bash -c "cd '$REPO_ROOT' && ansible-inventory --list --yaml 2>&1"

  assert_success
  assert_output --partial 'localhost:'
  refute_output --partial 'Unable to parse'
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
