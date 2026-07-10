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

@test "bootstrap: installs Homebrew non-interactively when missing" {
  grep -q 'NONINTERACTIVE=1' "$REPO_ROOT/bootstrap.sh"
  grep -q 'Homebrew/install/HEAD/install.sh' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: installs ansible via brew if absent" {
  grep -q 'brew install ansible' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: hands off to ansible-playbook playbook.yml" {
  grep -q 'ansible-playbook playbook.yml' "$REPO_ROOT/bootstrap.sh"
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
  for f in dirs links terminfo gpg ssh prereqs rust mise brew brew_casks tools_cli npm nvim tpm zoxide beads upgrade; do
    grep -q "$f.yml" "$REPO_ROOT/roles/dotfiles/tasks/main.yml"
  done
}

@test "role: upgrade tasks are gated on dotfiles_state == latest" {
  grep -q "dotfiles_state == 'latest'" "$REPO_ROOT/roles/dotfiles/tasks/main.yml"
}

@test "role: core brew list includes tmux (installed via homebrew)" {
  awk '/^dotfiles_brew_core:/,/^dotfiles_brew_taps:/' "$REPO_ROOT/roles/dotfiles/defaults/main.yml" | grep -qE '^\s*-\s*tmux\s*$'
}
