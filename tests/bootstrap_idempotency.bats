setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "role: second ansible run reports no changes (idempotence via --check)" {
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    skip "ansible-playbook not installed (idempotence is covered by molecule in CI)"
  fi
  cd "$REPO_ROOT"
  run ansible-playbook playbook.yml --check --diff
  refute_output --partial "changed:"
}
