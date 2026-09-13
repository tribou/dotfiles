setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "mise verifier checks packages and every portable tool" {
  local script="$REPO_ROOT/scripts/verify_mise_tools.sh"
  [ -x "$script" ]
  grep -qF 'bootstrap packages status --missing' "$script"
  grep -qF '/opt/homebrew/bin' "$script"
  grep -qF '/home/linuxbrew/.linuxbrew/bin' "$script"
  for command in ansible-playbook nvim python jq fd rg bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux prettier solargraph; do
    grep -qE "(^|[[:space:]\"'])${command}([[:space:]\"']|$)" "$script"
  done
  grep -qF "python -c 'import pynvim'" "$script"
}

@test "mise verifier returns the first mise failure" {
  local fake_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fake_bin"
  printf '#!/usr/bin/env bash\nexit 42\n' > "$fake_bin/mise"
  chmod +x "$fake_bin/mise"

  run env MISE_BIN="$fake_bin/mise" "$REPO_ROOT/scripts/verify_mise_tools.sh"
  [ "$status" -eq 42 ]
}

@test "mise verifier reports a missing executable clearly" {
  local output status
  set +e
  output="$(env MISE_BIN="$BATS_TEST_TMPDIR/missing-mise" "$REPO_ROOT/scripts/verify_mise_tools.sh" 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 127 ]
  [[ "$output" == *"mise executable not found"* ]]
}

@test "package qualification workflows authenticate mise GitHub requests" {
  local workflow block

  for workflow in macos-tests.yml ubuntu-tests.yml; do
    block="$(awk '/- name: Install and verify mise packages and tools/{found=1} found && /- name: Install just/{exit} found' "$REPO_ROOT/.github/workflows/$workflow")"
    echo "$block" | grep -qF 'GITHUB_TOKEN: ${{ github.token }}'
  done
}

@test "macOS workflow smoke-tests the Darwin cask role through mise" {
  local workflow="$REPO_ROOT/.github/workflows/macos-tests.yml"
  grep -qF 'ansible-galaxy collection install -r requirements.yml' "$workflow"
  grep -qF 'Smoke-test Darwin Homebrew cask role' "$workflow"
  grep -qF 'exec -- ansible-playbook' "$workflow"
  grep -qF 'playbook.yml' "$workflow"
  grep -qF 'dotfiles_brew_macos_casks=[]' "$workflow"
}
