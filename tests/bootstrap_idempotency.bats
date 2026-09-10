setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "role: configured inventory contains localhost without parse warnings" {
  if ! command -v ansible-inventory >/dev/null 2>&1; then
    skip "ansible-inventory not installed"
  fi

  # Pin ANSIBLE_CONFIG to this repo's config, exactly as bootstrap.sh and the
  # justfile do, so a stale/unrelated ANSIBLE_CONFIG leaked into the shell
  # (highest precedence in Ansible) can't shadow this repo's inventory and make
  # the test fail spuriously with "only implicit localhost is available".
  run bash -c "cd '$REPO_ROOT' && ANSIBLE_CONFIG='$REPO_ROOT/ansible.cfg' ansible-inventory --list --yaml 2>&1"

  assert_success
  assert_output --partial 'localhost:'
  refute_output --partial 'Unable to parse'
}

@test "bootstrap and Ansible convergence use mise execution boundary" {
  grep -qF 'MISE_BIN="$MISE_BIN" ./scripts/verify_mise_tools.sh' "$REPO_ROOT/bootstrap.sh"
  grep -qF '"$MISE_BIN" exec -- ansible-galaxy collection install -r requirements.yml' "$REPO_ROOT/bootstrap.sh"
  grep -qF 'ANSIBLE_CONFIG="$PWD/ansible.cfg" "$MISE_BIN" exec -- ansible-playbook playbook.yml "$@"' "$REPO_ROOT/bootstrap.sh"
  grep -qF 'MISE_BIN: "{{ dotfiles_home }}/.local/bin/mise"' "$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
}
