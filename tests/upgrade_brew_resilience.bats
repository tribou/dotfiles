setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "upgrade.yml: retained cask upgrades are Darwin-only and non-aborting" {
  block="$(awk '/name: Upgrade retained macOS Homebrew casks/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml")"
  [ -n "$block" ]
  echo "$block" | grep -qF 'community.general.homebrew_cask:'
  echo "$block" | grep -qE 'state: *latest'
  echo "$block" | grep -qE 'register: *dotfiles_brew_cask_upgrade'
  echo "$block" | grep -qE 'failed_when: *false'
  echo "$block" | grep -qF "ansible_facts.system == 'Darwin'"
}

@test "upgrade.yml: Homebrew problems are surfaced for manual remediation" {
  grep -q 'brew_manual_problems' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  grep -q 'stderr' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  grep -qF 'bundle --global --upgrade' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  grep -qF 'brewfile_stat.stat.exists' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}

@test "upgrade.yml: cask and Brewfile failures collect nonzero rc safely" {
  local file="$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  grep -qF "selectattr('rc', 'defined')" "$file"
  grep -qF "selectattr('rc', 'ne', 0)" "$file"
  grep -qF "selectattr('failed', 'equalto', true)" "$file"
  grep -qF 'dotfiles_brewfile_upgrade.rc | default(0)' "$file"
  grep -qF 'problem.item' "$file"
  grep -qF 'problem.stderr' "$file"
  grep -qF 'problem.msg' "$file"
}

@test "upgrade.yml: formula and tool upgrades use mise" {
  grep -qF 'bootstrap packages upgrade' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  grep -qF 'mise upgrade --yes' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  ! grep -qF 'upgrade_all: true' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}
