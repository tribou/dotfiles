setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "brew_casks.yml: externally installed apps are accepted" {
  block="$(awk '/name: Install macOS-only Homebrew casks/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/brew_casks.yml")"
  [ -n "$block" ]
  echo "$block" | grep -qE 'accept_external_apps: *true'
}
