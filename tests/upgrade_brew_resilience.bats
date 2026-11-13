# covers: roles/dotfiles/tasks/upgrade.yml
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
  # failed_when: false rewrites failed=False, hiding homebrew_cask failures
  # (which carry msg but no rc) from brew_manual_problems.
  ! echo "$block" | grep -qE 'failed_when: *false'
  echo "$block" | grep -qE 'ignore_errors: *true'
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
  grep -qF "'upgrade', '--yes'" "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
  ! grep -qF 'upgrade_all: true' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}

@test "upgrade.yml: bootstrap packages upgrade is non-interactive and uses the apply environment" {
  local block
  block="$(awk '/name: Upgrade mise-managed host packages/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml")"
  [ -n "$block" ]
  echo "$block" | grep -qF 'bootstrap packages upgrade --yes'
  echo "$block" | grep -qF 'MISE_DATA_DIR'
  echo "$block" | grep -qF '/opt/homebrew/bin'
  echo "$block" | grep -qF '/home/linuxbrew/.linuxbrew/bin'
  echo "$block" | grep -qF 'dotfiles_mise_package_upgrade.stderr'
}
