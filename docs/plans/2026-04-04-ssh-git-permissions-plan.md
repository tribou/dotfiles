# SSH Git Permissions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create an `agent` Linux user setup that gives LLM tools isolated git credentials while sharing all dotfiles config, with a `llm` alias to switch into it.

**Architecture:** A separate `agent` Linux user belongs to a shared `devteam` group for filesystem access, uses a deploy SSH key for git (registered per-repo on GitHub), and sources the main user's dotfiles with overrides for git identity and PS1. A one-time setup script wires everything up idempotently.

**Tech Stack:** bash, ssh-keygen, sudoers, Linux user management

---

### Task 1: Add `agent/overrides.sh`

This file holds all agent-specific overrides — git identity env vars and PS1. It will be symlinked into the agent's home by the setup script.

**Files:**
- Create: `agent/overrides.sh`

**Step 1: Create the file**

```bash
#!/bin/bash

# Git identity overrides — ensure agent identity regardless of repo-level config
export GIT_AUTHOR_NAME="Agent"
export GIT_COMMITTER_NAME="Agent"
export GIT_AUTHOR_EMAIL="tribou@users.noreply.github.com"
export GIT_COMMITTER_EMAIL="tribou@users.noreply.github.com"

# Prompt — [llm] prefix on existing PS1 style
PS1='\[\033[0;34m\][llm] \W $(get_git_location) > \[\]'
```

**Step 2: Verify bash syntax**

Run: `bashcheck agent/overrides.sh`
Expected: no errors

**Step 3: Commit**

```bash
git add agent/overrides.sh
git commit -m "Add agent/overrides.sh for agent user environment"
```

---

### Task 2: Add `llm` alias to `lib/commands.sh`

The `llm` alias lets you switch to the agent user in one keystroke. Add it near the other short git/utility aliases (around line 1048).

**Files:**
- Modify: `lib/commands.sh` (alias section, around line 1048)

**Step 1: Find the right spot**

The alias block is around line 1048. Add `llm` alphabetically — it goes after `ll` and before `mm` (or wherever `l` aliases are). Search for `alias ll=` to find the exact line.

**Step 2: Add the alias**

```bash
alias llm='sudo -u agent -i'
```

**Step 3: Verify bash syntax**

Run: `bashcheck lib/commands.sh`
Expected: no errors

**Step 4: Commit**

```bash
git add lib/commands.sh
git commit -m "Add llm alias to switch to agent user"
```

---

### Task 3: Create `agent/setup-user.sh`

The main setup script. Run once on any server where you want agent support. Idempotent — safe to re-run.

**Files:**
- Create: `agent/setup-user.sh`

**Step 1: Write the script**

```bash
#!/bin/bash
set -euo pipefail

# Resolve dotfiles location from this script's own path
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_USER="${SUDO_USER:-$USER}"
MAIN_HOME="/home/$MAIN_USER"
AGENT_USER="agent"
AGENT_HOME="/home/$AGENT_USER"
GROUP="devteam"

# --- Helpers ---

log() { echo "==> $*"; }

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

setup_dev_permissions() {
  local dev_dir="$MAIN_HOME/dev"
  if [ ! -d "$dev_dir" ]; then
    log "WARNING: $dev_dir does not exist — skipping permissions setup"
    return
  fi
  log "Setting group ownership and setgid on $dev_dir"
  sudo chown -R "$MAIN_USER:$GROUP" "$dev_dir"
  sudo chmod -R g+rw "$dev_dir"
  sudo find "$dev_dir" -type d -exec chmod g+s {} \;
}

generate_ssh_key() {
  local key_path="$AGENT_HOME/.ssh/id_ed25519"
  sudo mkdir -p "$AGENT_HOME/.ssh"
  sudo chmod 700 "$AGENT_HOME/.ssh"
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
source $DOTFILES/bash_profile
source ~/.agent_overrides.sh
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

log "Setting up agent user on $(hostname)"
log "Dotfiles: $DOTFILES"
log "Main user: $MAIN_USER"

idempotent_useradd
idempotent_groupadd
add_user_to_group "$MAIN_USER"
add_user_to_group "$AGENT_USER"
setup_dev_permissions
generate_ssh_key
write_ssh_config
write_bash_profile
symlink_agent_overrides
write_gitconfig
setup_sudoers
print_public_key

log "Done! Run 'llm' to switch to the agent user."
```

**Step 2: Make it executable**

```bash
chmod +x agent/setup-user.sh
```

**Step 3: Verify bash syntax**

Run: `bashcheck agent/setup-user.sh`
Expected: no errors

**Step 4: Commit**

```bash
git add agent/setup-user.sh
git commit -m "Add agent/setup-user.sh for agent user setup"
```

---

### Task 4: Verify everything looks correct end-to-end

Do a final review of all three files together to check for consistency.

**Step 1: Confirm all files exist**

```bash
ls agent/overrides.sh agent/setup-user.sh
grep -n "alias llm=" lib/commands.sh
```

Expected: files exist, alias found

**Step 2: Run full bash syntax check**

```bash
bashcheck agent/overrides.sh
bashcheck agent/setup-user.sh
bashcheck lib/commands.sh
```

Expected: no errors on any file

**Step 3: Run test suite**

```bash
just test-unit
```

Expected: all tests pass (no regressions from the alias addition)

**Step 4: Final commit if any fixups needed**

```bash
git add -p
git commit -m "Fix any issues found in review"
```
