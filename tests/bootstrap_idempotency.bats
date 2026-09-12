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

@test "role: mise tool install reports first convergence changed and second clean" {
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    skip "ansible-playbook not installed"
  fi

  local fixture_home="$BATS_TEST_TMPDIR/home"
  local fixture_bin="$BATS_TEST_TMPDIR/bin"
  local fixture_playbook="$BATS_TEST_TMPDIR/mise-idempotency.yml"
  mkdir -p "$fixture_home/.local/bin" "$fixture_home/.local/share/mise" \
    "$fixture_home/.cache/mise" "$fixture_bin"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'case "$*" in' \
    '  "bootstrap packages --help"|"bootstrap packages status --missing") ;;' \
    '  "bootstrap packages apply --yes")' \
    '    if [ ! -e "'$BATS_TEST_TMPDIR'/mise-installed" ]; then printf "Installing package\\n"; fi' \
    '    ;;' \
    '  "install --yes")' \
    '    case ":$PATH:" in *":'$fixture_home'/.local/bin:"*) ;; *) printf "mise missing from PATH\\n" >&2; exit 1 ;; esac' \
    '    if [ ! -e "'$BATS_TEST_TMPDIR'/mise-installed" ]; then' \
    '      printf "mise ansible@14.4.0 [1/1] install\\n" >&2' \
    '      touch "'$BATS_TEST_TMPDIR'/mise-installed"' \
    '    fi' \
    '    ;;' \
    '  "exec --"*) ;;' \
    '  *) printf "unexpected mise args: %s\\n" "$*" >&2; exit 1 ;;' \
    'esac' > "$fixture_home/.local/bin/mise"
  chmod +x "$fixture_home/.local/bin/mise"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture_bin/corepack"
  chmod +x "$fixture_bin/corepack"

  printf '%s\n' \
    '- hosts: localhost' \
    '  connection: local' \
    '  gather_facts: false' \
    '  vars:' \
    '    dotfiles_home: "'$fixture_home'"' \
    '    dotfiles_repo_root: "'$REPO_ROOT'"' \
    '    ansible_facts:' \
    '      system: Linux' \
    '      env:' \
    '        PATH: "'$fixture_bin':/usr/bin:/bin"' \
    '  tasks:' \
    '    - ansible.builtin.include_tasks: "'$REPO_ROOT'/roles/dotfiles/tasks/mise.yml"' \
    > "$fixture_playbook"

  run env PATH="$fixture_bin:$PATH" ANSIBLE_CONFIG="$REPO_ROOT/ansible.cfg" \
    ansible-playbook -i localhost, "$fixture_playbook"
  assert_success
  [[ "$output" =~ changed=[1-9][0-9]* ]]

  run env PATH="$fixture_bin:$PATH" ANSIBLE_CONFIG="$REPO_ROOT/ansible.cfg" \
    ansible-playbook -i localhost, "$fixture_playbook"
  assert_success
  assert_output --partial 'changed=0'
}

@test "Docker exercises mise-first bootstrap twice" {
  local compose="$REPO_ROOT/docker-compose.yml"
  [ "$(grep -cF './bootstrap.sh' "$compose")" -eq 2 ]
  grep -qF '/tmp/second-converge.log' "$compose"
  grep -qE "changed=\[1-9\]" "$compose" || grep -qF 'changed=[1-9]' "$compose"

  ! grep -qF 'https://mise.run' "$REPO_ROOT/Dockerfile"
  ! grep -qF 'ansible-core' "$REPO_ROOT/Dockerfile"
  ! grep -qF 'setup_24.x' "$REPO_ROOT/Dockerfile"
  ! grep -qF 'nvim-linux' "$REPO_ROOT/Dockerfile"
}
