# covers: justfile
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

# Regression: the play runs on mise's own ansible + python. Upgrading those
# mid-play (via an un-scoped `mise upgrade`) can delete the running install and
# crash with "Unknown profile name 'module_legacy_m2c'". The play must defer
# them, and the recipe upgrades them afterward in a separate process.
@test "upgrade.yml: in-play mise upgrade defers ansible and python" {
  local file="$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  local block
  block="$(awk '/name: Upgrade mise-managed tools/,/^$/' "$file")"
  [ -n "$block" ]
  ! echo "$block" | grep -qE 'cmd: .*mise upgrade --yes"?$'
  grep -qE '^dotfiles_mise_upgrade_deferred:' "$REPO_ROOT/roles/dotfiles/defaults/main.yml"
  awk '/^dotfiles_mise_upgrade_deferred:/,/^$/' "$REPO_ROOT/roles/dotfiles/defaults/main.yml" | grep -qE '^ *- *ansible$'
  awk '/^dotfiles_mise_upgrade_deferred:/,/^$/' "$REPO_ROOT/roles/dotfiles/defaults/main.yml" | grep -qE '^ *- *python$'
  echo "$block" | grep -qF 'dotfiles_mise_upgrade_deferred'
}

@test "justfile: upgrade upgrades ansible and python after the play" {
  block="$(sed -n '/^upgrade \*args:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  play_line="$(echo "$block" | grep -n 'ansible-playbook' | head -1 | cut -d: -f1)"
  upg_line="$(echo "$block" | grep -nE 'mise upgrade --yes ansible python' | head -1 | cut -d: -f1)"
  [ -n "$play_line" ] && [ -n "$upg_line" ]
  [ "$play_line" -lt "$upg_line" ]
}
