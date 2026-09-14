setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "justfile: upgrade runs the upgrade-tagged play through mise" {
  # Extract the upgrade recipe body: from its header to the next unindented line.
  block="$(sed -n '/^upgrade \*args:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  [ -n "$block" ]
  echo "$block" | grep -qF 'ANSIBLE_CONFIG={{justfile_directory()}}/ansible.cfg ~/.local/bin/mise exec -- ansible-playbook playbook.yml -e dotfiles_state=latest --tags upgrade'
  ! echo "$block" | grep -qF 'brew pin'
  ! echo "$block" | grep -qF 'brew deps ansible'
  ! echo "$block" | grep -qF 'brew upgrade ansible'
}
