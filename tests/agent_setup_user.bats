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
