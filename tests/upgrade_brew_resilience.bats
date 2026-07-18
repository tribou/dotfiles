setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: a single `brew upgrade` (community.general.homebrew upgrade_all)
# upgrades BOTH formulae and casks. When one cask fails -- e.g. it needs sudo
# (no TTY under `just upgrade`), or an app already exists in /Applications --
# `brew upgrade` exits non-zero and the module reports the task as failed. With
# Ansible's default abort-on-failure, the entire play stops there, so the
# mise/rustup/nvim/tmux/beads upgrades below never run. The Homebrew upgrade
# must be non-aborting so the rest of the upgrade completes.
@test "upgrade.yml: Homebrew upgrade is non-aborting on partial failure" {
  block="$(awk '/name: Upgrade Homebrew/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml")"
  [ -n "$block" ]
  echo "$block" | grep -qE 'register: *brew_upgrade'
  echo "$block" | grep -qE 'failed_when: *false'
}

# The partial failures (sudo-required casks, already-present apps, docker-desktop
# needing a forced reinstall) are genuinely manual, so they must be surfaced in a
# clear summary for the user instead of silently swallowed by `failed_when: false`.
@test "upgrade.yml: Homebrew problems are surfaced for manual remediation" {
  grep -q 'brew_manual_problems' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}
