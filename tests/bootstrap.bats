setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "bootstrap: self-clones to ~/dev/dotfiles when run outside the repo" {
  grep -q 'REPO_DIR="\$HOME/dev/dotfiles"' "$REPO_ROOT/bootstrap.sh"
  grep -q 'git clone "\$REPO_URL" "\$REPO_DIR"' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: installs minimal Linux brew prerequisites (curl git build-essential ca-certificates)" {
  grep -q 'apt-get install -y curl git build-essential ca-certificates' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap refreshes mise and runs package then tool phases before Ansible" {
  local file="$REPO_ROOT/bootstrap.sh"
  grep -qF 'bootstrap packages --help' "$file"
  grep -qF 'bootstrap packages apply --yes' "$file"
  grep -qF 'install --yes' "$file"
  grep -qF 'exec -- ansible-galaxy collection install -r requirements.yml' "$file"
  grep -qF 'exec -- ansible-playbook playbook.yml "$@"' "$file"
  ! grep -qF 'brew install ansible' "$file"

  local apply_line install_line playbook_line
  apply_line="$(grep -nF 'bootstrap packages apply --yes' "$file" | tail -1 | cut -d: -f1)"
  install_line="$(grep -nF 'install --yes' "$file" | tail -1 | cut -d: -f1)"
  playbook_line="$(grep -nF 'exec -- ansible-playbook' "$file" | tail -1 | cut -d: -f1)"
  [ "$apply_line" -lt "$install_line" ]
  [ "$install_line" -lt "$playbook_line" ]
}

@test "Ansible convergence repeats explicit package and tool phases" {
  local file="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  grep -qF 'bootstrap packages --help' "$file"
  grep -qF 'bootstrap packages apply --yes' "$file"
  grep -qF 'install --yes' "$file"
  grep -qF 'verify_mise_tools.sh' "$file"
}

# Regression: a leaked ANSIBLE_CONFIG in the invoking shell (highest precedence
# in Ansible's config search order) would shadow this repo's own ansible.cfg,
# same root cause as the justfile install/upgrade fix (see
# tests/ansible_config_isolation.bats).
@test "bootstrap: pins ANSIBLE_CONFIG to this repo's ansible.cfg before handing off" {
  grep -qE 'ANSIBLE_CONFIG=.*ansible\.cfg.*ansible-playbook playbook\.yml' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: is thin (fewer than 60 lines)" {
  run bash -c "grep -vcE '^\\s*(#|$)' '$REPO_ROOT/bootstrap.sh'"
  [ "$output" -lt 60 ]
}

@test "role: playbook.yml targets localhost with connection local" {
  grep -q 'hosts: localhost' "$REPO_ROOT/playbook.yml"
  grep -q 'connection: local' "$REPO_ROOT/playbook.yml"
}

@test "role: tasks/main.yml includes all concern files" {
  for f in dirs links terminfo gpg ssh prereqs rust mise brew brew_casks tools_cli nvim tpm zoxide beads upgrade; do
    grep -q "$f.yml" "$REPO_ROOT/roles/dotfiles/tasks/main.yml"
  done
}

@test "role: package ownership assertions live in package_management.bats" {
  [ -f "$REPO_ROOT/tests/package_management.bats" ]
}

@test "role: upgrade tasks are gated on dotfiles_state == latest" {
  grep -q "dotfiles_state == 'latest'" "$REPO_ROOT/roles/dotfiles/tasks/main.yml"
}

@test "role: core brew list excludes optional tools (moved to mise/Brewfile opt-in)" {
  local block
  block="$(awk '/^dotfiles_brew_core:/,/^dotfiles_brew_taps:/' "$REPO_ROOT/roles/dotfiles/defaults/main.yml")"
  for opt in nmap ansible tree awscli dos2unix tidy-html5 navi tlrc; do
    if echo "$block" | grep -qE "^[[:space:]]*-[[:space:]]*${opt}[[:space:]]*$"; then
      fail "optional tool '$opt' must not be in dotfiles_brew_core"
    fi
  done
}

@test "role: macOS formula inventory is removed" {
  ! grep -qE '^dotfiles_brew_macos_formulae:' "$REPO_ROOT/roles/dotfiles/defaults/main.yml"
}

@test "role: macOS casks list is empty (casks are opt-in via ~/.Brewfile)" {
  local block
  block="$(awk '/^dotfiles_brew_macos_casks:/,/^dotfiles_tmux_plugins:/' "$REPO_ROOT/roles/dotfiles/defaults/main.yml")"
  if echo "$block" | grep -qE '^[[:space:]]*-[[:space:]]*\S+'; then
    fail "dotfiles_brew_macos_casks must be empty; found entries"
  fi
  echo "$block" | grep -qE '^[[:space:]]*dotfiles_brew_macos_casks:[[:space:]]*\[\][[:space:]]*$'
}

@test "role: dirs.yml creates ~/.config/mise/conf.d for opt-in drop-ins" {
  grep -q '\.config/mise/conf\.d' "$REPO_ROOT/roles/dotfiles/tasks/dirs.yml"
}

@test "role: mise.yml installs all tools un-scoped (picks up conf.d drop-ins)" {
  local f="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  grep -qF '/.local/bin/mise install --yes' "$f"
  ! grep -q 'mise install {{ item }}' "$f"
  grep -q 'all tools are installed' "$f"
}

@test "role: upgrade.yml upgrades mise tools un-scoped" {
  grep -qE 'mise upgrade( --yes)?($|[^[:alnum:]_-])' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}

@test "role: brew_casks.yml applies ~/.Brewfile on Darwin only" {
  local f="$REPO_ROOT/roles/dotfiles/tasks/brew_casks.yml"
  local block
  block="$(awk '/name: Stat global Brewfile/,0' "$f")"
  echo "$block" | grep -q "ansible_facts.system == 'Darwin'"
  grep -q '{{ dotfiles_brew_bin }} bundle --global --no-upgrade' "$f"
}

@test "repo: ships mise-config.optional.toml.example as a commented drop-in template" {
  local f="$REPO_ROOT/mise-config.optional.toml.example"
  [ -f "$f" ]
  # every tool assignment is commented out (user uncomments what they want)
  ! grep -qE '^[[:space:]]*[a-z0-9_-]+[[:space:]]*=' "$f"
  # lists the verified-backend optional mise tools
  for t in awscli terraform-ls navi tlrc tfenv; do
    grep -q "$t" "$f"
  done
}

@test "repo: ships Brewfile.optional.example as a commented opt-in template" {
  local f="$REPO_ROOT/Brewfile.optional.example"
  [ -f "$f" ]
  # every cask/brew directive is commented
  ! grep -qE '^[[:space:]]*(cask|brew)[[:space:]]' "$f"
  # includes only optional casks
  for t in firefox orbstack bruno font-fira-code-nerd-font cmake; do
    grep -q "$t" "$f"
  done
}

@test "role: core mise runtimes come from mise-config.toml, not a role variable" {
  # mise.yml installs un-scoped, so dotfiles_mise_tools no longer drives
  # anything -- mise-config.toml is the single source of truth for the core
  # runtime set. A stale list here reads as authoritative and isn't.
  if grep -q '^dotfiles_mise_tools:' "$REPO_ROOT/roles/dotfiles/defaults/main.yml"; then
    fail "dotfiles_mise_tools is dead config; core runtimes live in mise-config.toml"
  fi
  grep -qE '^node[[:space:]]*=' "$REPO_ROOT/mise-config.toml"
}
