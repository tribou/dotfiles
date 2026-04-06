# tests/agent_setup_user.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  MOCK_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

write_mock() {
  local name="$1" body="$2"
  printf '#!/bin/bash\n%s\n' "$body" > "$MOCK_BIN/$name"
  chmod +x "$MOCK_BIN/$name"
}

# Prepend MOCK_BIN and set OSTYPE=linux-gnu to get past require_linux on macOS
linux_env() {
  write_mock uname "echo Linux"
  write_mock sudo 'echo "sudo: $*"'
  write_mock getent "exit 0"    # group already exists
  write_mock id "echo devteam"  # user already in group
}

# --- macOS guard ---

@test "setup-user.sh exits with clear error on macOS" {
  run env OSTYPE=darwin20 bash "$REPO_ROOT/agent/setup-user.sh"

  assert_failure
  assert_output --partial "Linux only"
  assert_output --partial "not supported on macOS"
}

@test "--grant on macOS exits with Linux-only error" {
  run env OSTYPE=darwin20 bash "$REPO_ROOT/agent/setup-user.sh" --grant /tmp

  assert_failure
  assert_output --partial "Linux only"
}

# --- --grant flag ---

@test "--grant with missing directory outputs warning" {
  linux_env

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash "$REPO_ROOT/agent/setup-user.sh" --grant /nonexistent-path-xyz

  assert_output --partial "WARNING"
  assert_output --partial "/nonexistent-path-xyz"
}

@test "--grant with existing directory succeeds and reports path" {
  linux_env
  local target
  target="$(mktemp -d)"

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash "$REPO_ROOT/agent/setup-user.sh" --grant "$target"

  assert_success
  assert_output --partial "$target"
  rm -rf "$target"
}

@test "--grant defaults to PWD when no directory argument given" {
  linux_env
  local target
  target="$(mktemp -d)"

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash -c "cd '$target' && bash '$REPO_ROOT/agent/setup-user.sh' --grant"

  assert_output --partial "$target"
  rm -rf "$target"
}

@test "--grant is idempotent: re-running on same directory succeeds" {
  linux_env
  local target
  target="$(mktemp -d)"

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash "$REPO_ROOT/agent/setup-user.sh" --grant "$target"
  assert_success

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash "$REPO_ROOT/agent/setup-user.sh" --grant "$target"
  assert_success
  rm -rf "$target"
}

# --- agent-grant shell function ---

@test "agent-grant with 'n' aborts without calling setup script" {
  write_mock sudo 'echo SUDO_WAS_CALLED'

  run bash -c "
    PATH='$MOCK_BIN:\$PATH'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    echo n | agent-grant /tmp
  "

  assert_failure
  assert_output --partial "Aborted"
  refute_output --partial "SUDO_WAS_CALLED"
}

@test "agent-grant with 'y' invokes setup-user.sh --grant with target path" {
  write_mock sudo 'echo "sudo: $*"'

  run bash -c "
    PATH='$MOCK_BIN:\$PATH'
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    echo y | agent-grant /tmp/test-target
  "

  assert_output --partial "--grant"
  assert_output --partial "/tmp/test-target"
}

# --- write_gitconfig includes dotfiles aliases ---

@test "write_gitconfig includes dotfiles gitconfig so git aliases are available" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  # sudo passthrough: the mock IS sudo, so just run all args directly
  write_mock sudo '"$@"'

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    AGENT_HOME='$tmp_home'
    AGENT_USER=agent
    DOTFILES='$REPO_ROOT'
    log() { :; }
    # Extract and source only the write_gitconfig function
    eval \"\$(awk '/^write_gitconfig\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    write_gitconfig
    cat '$tmp_home/.gitconfig'
  "

  assert_success
  assert_output --partial '[include]'
  assert_output --partial "path = $REPO_ROOT/gitconfig"
  rm -rf "$tmp_home"
}

# --- write_gitconfig uses HTTPS URL rewrites, not sshCommand ---

@test "write_gitconfig does not contain sshCommand" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  write_mock sudo '"$@"'

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    AGENT_HOME='$tmp_home'
    AGENT_USER=agent
    DOTFILES='$REPO_ROOT'
    log() { :; }
    eval \"\$(awk '/^write_gitconfig\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    write_gitconfig
    cat '$tmp_home/.gitconfig'
  "

  assert_success
  refute_output --partial 'sshCommand'
  rm -rf "$tmp_home"
}

@test "write_gitconfig rewrites git@github.com SSH URLs to HTTPS" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  write_mock sudo '"$@"'

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    AGENT_HOME='$tmp_home'
    AGENT_USER=agent
    DOTFILES='$REPO_ROOT'
    log() { :; }
    eval \"\$(awk '/^write_gitconfig\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    write_gitconfig
    cat '$tmp_home/.gitconfig'
  "

  assert_success
  assert_output --partial 'insteadOf = git@github.com:'
  assert_output --partial 'https://github.com/'
  rm -rf "$tmp_home"
}

@test "write_gitconfig rewrites git@gitlab.com SSH URLs to HTTPS" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  write_mock sudo '"$@"'

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    AGENT_HOME='$tmp_home'
    AGENT_USER=agent
    DOTFILES='$REPO_ROOT'
    log() { :; }
    eval \"\$(awk '/^write_gitconfig\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    write_gitconfig
    cat '$tmp_home/.gitconfig'
  "

  assert_success
  assert_output --partial 'insteadOf = git@gitlab.com:'
  assert_output --partial 'https://gitlab.com/'
  rm -rf "$tmp_home"
}

# --- setup_gh_credential_helper ---

@test "setup_gh_credential_helper calls gh auth setup-git as agent user" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  write_mock sudo 'echo "sudo: $*"'
  write_mock gh 'echo "gh: $*"'

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    AGENT_HOME='$tmp_home'
    AGENT_USER=agent
    DOTFILES='$REPO_ROOT'
    log() { :; }
    eval \"\$(awk '/^setup_gh_credential_helper\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    setup_gh_credential_helper
  "

  assert_success
  assert_output --partial 'auth setup-git'
  rm -rf "$tmp_home"
}

# --- print_gh_auth_instructions ---

@test "main run prints gh auth login instructions instead of deploy key instructions" {
  linux_env
  write_mock ssh-keygen 'echo "ssh-keygen: $*"'
  write_mock gh 'echo "gh: $*"'
  write_mock useradd 'echo "useradd: $*"'

  run env OSTYPE=linux-gnu PATH="$MOCK_BIN:$PATH" \
    bash "$REPO_ROOT/agent/setup-user.sh"

  assert_output --partial 'gh auth login'
  refute_output --partial 'Deploy keys'
  refute_output --partial 'deploy key'
}

# --- agent-grant defaults ---

# --- grant_access_to_dir permissions ---

@test "grant_access_to_dir sets setgid on directories and group rw on files" {
  # sudo passthrough: run commands directly (we own the temp dir)
  write_mock sudo '"$@"'
  # chown no-op: group 'devteam' won't exist locally
  write_mock chown ':'

  local target
  target="$(mktemp -d)"
  mkdir -p "$target/subdir"
  touch "$target/file.txt"
  touch "$target/subdir/nested.txt"

  run env PATH="$MOCK_BIN:$PATH" bash -c "
    MAIN_USER='$(id -un)'
    GROUP='devteam'
    log() { :; }
    eval \"\$(awk '/^grant_access_to_dir\(\)/,/^\}/' '$REPO_ROOT/agent/setup-user.sh')\"
    grant_access_to_dir '$target'
  "

  assert_success

  # Directories must have setgid ('s' at group-execute position in ls output)
  run bash -c "ls -ld '$target' | awk '{print \$1}'"
  assert_output --regexp '^d.....s'

  run bash -c "ls -ld '$target/subdir' | awk '{print \$1}'"
  assert_output --regexp '^d.....s'

  # Files must have group read and write (positions 5-6 in ls permission string)
  run bash -c "ls -l '$target/file.txt' | awk '{print \$1}'"
  assert_output --regexp '^....rw'

  run bash -c "ls -l '$target/subdir/nested.txt' | awk '{print \$1}'"
  assert_output --regexp '^....rw'

  rm -rf "$target"
}

# --- agent-grant defaults ---

@test "agent-grant defaults to PWD when no argument given" {
  write_mock sudo 'echo "sudo: $*"'
  local target
  target="$(mktemp -d)"

  run bash -c "
    PATH='$MOCK_BIN:\$PATH'
    DOTFILES='$REPO_ROOT'
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    cd '$target'
    echo y | agent-grant
  "

  assert_output --partial "$target"
  rm -rf "$target"
}
