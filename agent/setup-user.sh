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
  sudo find "$target_dir" \( -type d -exec chmod g+s,g+rwx {} + \) -o \( -type f -exec chmod g+rw {} + \)
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
# SSH key used for server-to-server auth (not GitHub git auth — gh CLI handles that)
Host *
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
  sudo tee "$gitconfig" > /dev/null <<EOF
[include]
  path = $DOTFILES/gitconfig
[user]
  name = Agent
  email = tribou@users.noreply.github.com
[url "https://github.com/"]
  insteadOf = git@github.com:
[url "https://gitlab.com/"]
  insteadOf = git@gitlab.com:
[safe]
  directory = *
EOF
  sudo chown "$AGENT_USER:$AGENT_USER" "$gitconfig"
}

symlink_dev_dir() {
  local target="$MAIN_HOME/dev"
  local link="$AGENT_HOME/dev"
  if sudo test -L "$link"; then
    log "$AGENT_HOME/dev symlink already exists, skipping"
    return
  fi
  if sudo test -d "$link"; then
    log "Removing agent-owned ~/dev to replace with shared symlink"
    sudo rm -rf "$link"
  fi
  sudo ln -sf "$target" "$link"
  sudo chown -h "$AGENT_USER:$AGENT_USER" "$link"
  log "Symlinked $link -> $target"
}

share_home_dir() {
  local dir_name="$1"
  local source="$MAIN_HOME/$dir_name"
  local link="$AGENT_HOME/$dir_name"
  if ! sudo test -e "$source"; then
    log "WARNING: $source does not exist — skipping share"
    return
  fi
  grant_access_to_dir "$source"
  if sudo test -L "$link"; then
    log "$link symlink already exists, skipping"
    return
  fi
  if sudo test -e "$link"; then
    log "WARNING: $link already exists and is not a symlink — skipping"
    return
  fi
  sudo mkdir -p "$(dirname "$link")"
  sudo ln -sf "$source" "$link"
  sudo chown -h "$AGENT_USER:$AGENT_USER" "$link"
  log "Symlinked $link -> $source"
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

symlink_main_user_bin() {
  local bin_name="$1"
  local source="$MAIN_HOME/.local/bin/$bin_name"
  local link="$AGENT_HOME/.local/bin/$bin_name"
  if ! sudo test -x "$source"; then
    log "WARNING: $bin_name not found at $source — skipping symlink"
    return
  fi
  sudo mkdir -p "$(dirname "$link")"
  sudo ln -sf "$source" "$link"
  sudo chown -h "$AGENT_USER:$AGENT_USER" "$link"
  log "Symlinked $bin_name: $link -> $source"
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

setup_gh_credential_helper() {
  log "Configuring gh credential helper for agent user"
  sudo -u "$AGENT_USER" bash -lc "gh auth setup-git" || log "WARNING: gh auth setup-git failed (expected if not yet authenticated — see instructions below)"
}

print_gh_auth_instructions() {
  echo
  echo "================================================================"
  echo "NEXT STEP: Authenticate agent with GitHub using a fine-grained PAT:"
  echo "  sudo -u agent bash -lc \"gh auth login --with-token <<< 'YOUR_FINE_GRAINED_PAT'\""
  echo "Token rotation: re-run the above command with a new token at any time."
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
symlink_dev_dir
symlink_main_user_bin mise
symlink_mise_config
share_home_dir .local/share/mise
share_home_dir .claude
share_home_dir .opencode
symlink_main_user_bin claude
symlink_main_user_bin opencode
symlink_main_user_bin gh
setup_gh_credential_helper
setup_sudoers
print_gh_auth_instructions

log "Done! Run 'llm' to switch to the agent user."
