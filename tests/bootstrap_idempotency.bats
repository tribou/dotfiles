setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "bootstrap: running twice does not duplicate lines in generated rc files" {
  # Create a temp home directory to avoid polluting the real one
  local tmp_home
  tmp_home=$(mktemp -d)
  
  # Create mock bin directory for external dependencies
  local mock_bin="$tmp_home/mock_bin"
  mkdir -p "$mock_bin"
  
  # Create basic mock commands that exit 0
  for cmd in brew curl gpgconf gpg-agent tic tmux ssh-keygen ssh-add mise corepack npm pip3 gem go bd apt-get pacman sudo nvim; do
    echo '#!/bin/sh' > "$mock_bin/$cmd"
    echo 'exit 0' >> "$mock_bin/$cmd"
    chmod +x "$mock_bin/$cmd"
  done
  
  # Custom mock for ssh-agent
  echo '#!/bin/sh' > "$mock_bin/ssh-agent"
  echo 'echo "SSH_AUTH_SOCK=/tmp/ssh-mock; export SSH_AUTH_SOCK; SSH_AGENT_PID=12345; export SSH_AGENT_PID;"' >> "$mock_bin/ssh-agent"
  chmod +x "$mock_bin/ssh-agent"
  
  # Create mock for zoxide binary so bootstrap sourcing doesn't fail
  echo '#!/bin/sh' > "$mock_bin/zoxide"
  echo 'exit 0' >> "$mock_bin/zoxide"
  chmod +x "$mock_bin/zoxide"

  # Custom mock for git to handle directory setup for tpm
  cat << 'EOF' > "$mock_bin/git"
#!/bin/sh
if [ "$1" = "clone" ]; then
  # Create mock install_plugins for tpm
  mkdir -p "$HOME/.tmux/plugins/tpm/bin"
  echo '#!/bin/sh' > "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  echo 'exit 0' >> "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  chmod +x "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi
exit 0
EOF
  chmod +x "$mock_bin/git"
  
  # Export environment for bootstrap.sh to use the temp home and mock binaries
  export HOME="$tmp_home"
  export PATH="$mock_bin:$PATH"
  
  # Run bootstrap the first time (should succeed)
  bash "$REPO_ROOT/bootstrap.sh"
  
  # Assert symlinks are valid and point to correct targets
  [ -L "$tmp_home/.bash_profile" ]
  [ -L "$tmp_home/.zshrc" ]
  [ -L "$tmp_home/.gitconfig" ]
  [ -L "$tmp_home/.local/bin/dotfiles_remote_browser_open.sh" ]
  
  # Run bootstrap the second time and capture output/exit status
  run bash "$REPO_ROOT/bootstrap.sh"
  
  # Assert second run succeeded
  assert_success
  
  # Assert no errors or failures printed on second run
  refute_output --partial "error"
  refute_output --partial "failed"
  refute_output --partial "No such file"
  refute_output --partial "ln:"
  
  # Assert ~/.ssh/config does not have duplicate blocks
  if [ -f "$tmp_home/.ssh/config" ]; then
    local count
    count=$(grep -c "AddKeysToAgent" "$tmp_home/.ssh/config")
    [ "$count" -le 1 ]
  fi
  
  # Clean up
  rm -rf "$tmp_home"
}
