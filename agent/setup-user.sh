#!/bin/bash
set -euo pipefail

# NOTE: This script targets Linux only (uses useradd, groupadd, getent).
# It is not intended to run on macOS.

# Resolve dotfiles location from this script's own path
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_USER="${SUDO_USER:-$USER}"
MAIN_HOME="/home/$MAIN_USER"
AGENT_USER="agent"
AGENT_HOME="/home/$AGENT_USER"
GROUP="devteam"

# --- Helpers ---

log() { echo "==> $*"; }

require_linux() {
  if [[ "${OSTYPE:-}" == darwin* ]] || [[ "$(uname -s)" == "Darwin" ]]; then
    echo "agent/setup-user.sh is Linux only and is not supported on macOS." >&2
    exit 1
  fi
}

idempotent_useradd() {
  if id "$AGENT_USER" &>/dev/null; then
    log "User '$AGENT_USER' already exists, skipping"
  else
    log "Creating user '$AGENT_USER'"
    sudo useradd -m -s /bin/bash "$AGENT_USER"
  fi
}

idempotent_groupadd() {
  if getent group "$GROUP" &>/dev/null; then
    log "Group '$GROUP' already exists, skipping"
  else
    log "Creating group '$GROUP'"
    sudo groupadd "$GROUP"
  fi
}

add_user_to_group() {
  local user="$1"
  if id -nG "$user" | grep -qw "$GROUP"; then
    log "User '$user' already in group '$GROUP', skipping"
  else
    log "Adding '$user' to group '$GROUP'"
    sudo usermod -aG "$GROUP" "$user"
  fi
}

grant_home_traversal() {
  log "Granting group traversal access to $MAIN_HOME"
  sudo chown "$MAIN_USER:$GROUP" "$MAIN_HOME"
  sudo chmod g+x "$MAIN_HOME"
}

grant_access_to_dir() {
  local target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    log "WARNING: $target_dir does not exist — skipping permissions setup"
    return
  fi
  log "Setting group ownership and setgid on $target_dir"
  sudo chown -R "$MAIN_USER:$GROUP" "$target_dir"
  sudo chmod -R g+rwX "$target_dir"
  sudo find "$target_dir" -type d -exec chmod g+s {} \;
}

setup_dev_permissions() {
  grant_access_to_dir "$MAIN_HOME/dev"
}

generate_ssh_key() {
  local key_path="$AGENT_HOME/.ssh/id_ed25519"
  sudo mkdir -p "$AGENT_HOME/.ssh"
  sudo chmod 700 "$AGENT_HOME/.ssh"
  sudo chown "$AGENT_USER:$AGENT_USER" "$AGENT_HOME/.ssh"
  if sudo test -f "$key_path"; then
    log "SSH key already exists at $key_path, skipping"
  else
    log "Generating SSH key for '$AGENT_USER'"
    sudo -u "$AGENT_USER" ssh-keygen -t ed25519 -f "$key_path" -C "agent@$(hostname)" -N ""
  fi
}

write_ssh_config() {
  local ssh_config="$AGENT_HOME/.ssh/config"
  log "Writing $ssh_config"
  sudo tee "$ssh_config" > /dev/null <<'EOF'
Host github.com
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host gitlab.com
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF
  sudo chmod 600 "$ssh_config"
  sudo chown "$AGENT_USER:$AGENT_USER" "$ssh_config"
}

write_bash_profile() {
  local bash_profile="$AGENT_HOME/.bash_profile"
  log "Writing $bash_profile (sourcing dotfiles from $DOTFILES)"
  sudo tee "$bash_profile" > /dev/null <<EOF
source "$DOTFILES/bash_profile"
[ -f ~/.agent_overrides.sh ] && source ~/.agent_overrides.sh
EOF
  sudo chown "$AGENT_USER:$AGENT_USER" "$bash_profile"
}

symlink_agent_overrides() {
  local target="$DOTFILES/agent/overrides.sh"
  local link="$AGENT_HOME/.agent_overrides.sh"
  log "Symlinking $link -> $target"
  sudo ln -sf "$target" "$link"
  sudo chown -h "$AGENT_USER:$AGENT_USER" "$link"
}

write_gitconfig() {
  local gitconfig="$AGENT_HOME/.gitconfig"
  log "Writing $gitconfig"
  sudo tee "$gitconfig" > /dev/null <<'EOF'
[user]
  name = Agent
  email = tribou@users.noreply.github.com
[core]
  sshCommand = ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes
EOF
  sudo chown "$AGENT_USER:$AGENT_USER" "$gitconfig"
}

install_z() {
  local z_dir="$AGENT_HOME/dev/z"
  sudo mkdir -p "$AGENT_HOME/dev/bin"
  sudo chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_HOME/dev"
  if sudo test -d "$z_dir"; then
    log "z already installed at $z_dir, skipping"
  else
    log "Installing rupa/z for '$AGENT_USER'"
    sudo -u "$AGENT_USER" git clone --depth 1 https://github.com/rupa/z.git "$z_dir"
  fi
}

install_mise() {
  local mise_bin="$AGENT_HOME/.local/bin/mise"
  if sudo test -x "$mise_bin"; then
    log "mise already installed, skipping"
  else
    log "Installing mise for '$AGENT_USER'"
    sudo -u "$AGENT_USER" bash -c 'curl https://mise.run | sh'
  fi
}

symlink_mise_config() {
  local target="$DOTFILES/mise-config.toml"
  local config_dir="$AGENT_HOME/.config/mise"
  local link="$config_dir/config.toml"
  log "Symlinking $link -> $target"
  sudo mkdir -p "$config_dir"
  sudo chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_HOME/.config"
  sudo ln -sf "$target" "$link"
  sudo chown -h "$AGENT_USER:$AGENT_USER" "$link"
}

setup_sudoers() {
  local sudoers_file="/etc/sudoers.d/agent-access"
  if sudo test -f "$sudoers_file"; then
    log "Sudoers entry already exists, skipping"
  else
    log "Adding sudoers entry for $MAIN_USER -> $AGENT_USER"
    echo "$MAIN_USER ALL=($AGENT_USER) NOPASSWD: /bin/bash" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 440 "$sudoers_file"
  fi
}

print_public_key() {
  local pub_key="$AGENT_HOME/.ssh/id_ed25519.pub"
  echo
  echo "================================================================"
  echo "NEXT STEP: Register this deploy key on GitHub/GitLab per-repo:"
  echo "  Repo -> Settings -> Deploy keys -> Add deploy key"
  echo "================================================================"
  sudo cat "$pub_key"
  echo "================================================================"
}

# --- Main ---

# --grant [DIR]: grant agent group access to a specific directory (or pwd)
if [[ "${1:-}" == "--grant" ]]; then
  require_linux
  TARGET="${2:-$PWD}"
  log "Granting agent group access to $TARGET"
  idempotent_groupadd
  add_user_to_group "$MAIN_USER"
  add_user_to_group "$AGENT_USER"
  grant_access_to_dir "$TARGET"
  log "Done! Agent user can now read/write $TARGET"
  exit 0
fi

log "Setting up agent user on $(hostname)"
log "Dotfiles: $DOTFILES"
log "Main user: $MAIN_USER"

require_linux
idempotent_useradd
idempotent_groupadd
add_user_to_group "$MAIN_USER"
add_user_to_group "$AGENT_USER"
grant_home_traversal
setup_dev_permissions
grant_access_to_dir "$DOTFILES"
generate_ssh_key
write_ssh_config
write_bash_profile
symlink_agent_overrides
write_gitconfig
install_z
install_mise
symlink_mise_config
setup_sudoers
print_public_key

log "Done! Run 'llm' to switch to the agent user."
