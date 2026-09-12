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

@test "package qualification workflows authenticate mise GitHub requests" {
  local workflow block

  for workflow in macos-tests.yml ubuntu-tests.yml; do
    block="$(awk '/- name: Install and verify mise packages and tools/{found=1} found && /- name: Install just/{exit} found' "$REPO_ROOT/.github/workflows/$workflow")"
    echo "$block" | grep -qF 'GITHUB_TOKEN: ${{ github.token }}'
  done
}
