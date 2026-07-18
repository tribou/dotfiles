setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: bash_profile exports ANSIBLE_CONFIG globally, pointing at an
# unrelated legacy ansible.cfg (~/dev/sys/ansible/ansible.cfg from an old
# personal ops-scripting project). ANSIBLE_CONFIG has the highest precedence
# in Ansible's config search order, so it silently shadows this repo's own
# ansible.cfg/inventory for every ansible-playbook invocation, producing:
#   [WARNING]: No inventory was parsed, only implicit localhost is available
#   [WARNING]: provided hosts list is empty, only localhost is available...
# The install/upgrade recipes must pin ANSIBLE_CONFIG to this repo's own
# ansible.cfg so they're immune to whatever the user's shell environment
# happens to export.
@test "justfile: install pins ANSIBLE_CONFIG to this repo's ansible.cfg" {
  block="$(sed -n '/^install \*args:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'ansible-playbook playbook.yml'
  echo "$block" | grep -qE 'ANSIBLE_CONFIG=.*ansible\.cfg.*ansible-playbook playbook\.yml'
}

@test "justfile: upgrade pins ANSIBLE_CONFIG to this repo's ansible.cfg" {
  block="$(sed -n '/^upgrade \*args:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'ansible-playbook playbook.yml'
  echo "$block" | grep -qE 'ANSIBLE_CONFIG=.*ansible\.cfg.*ansible-playbook playbook\.yml'
}
