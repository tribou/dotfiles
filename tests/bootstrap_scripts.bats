# covers: scripts/link_mise_config.sh scripts/ensure_brew_prefix.sh bootstrap.sh roles/dotfiles/tasks/mise.yml
setup() {
  load 'test_helper/common_setup'
  common_setup
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

# --- link_mise_config.sh -----------------------------------------------------

@test "link_mise_config: backs up a pre-existing regular file before linking" {
  mkdir -p "$TMP/home/.config/mise"
  printf 'my = "config"\n' > "$TMP/home/.config/mise/config.toml"
  run "$REPO_ROOT/scripts/link_mise_config.sh" "$REPO_ROOT/mise-config.toml" "$TMP/home/.config/mise/config.toml"
  assert_success
  [ -L "$TMP/home/.config/mise/config.toml" ]
  [ "$(readlink "$TMP/home/.config/mise/config.toml")" = "$REPO_ROOT/mise-config.toml" ]
  [ "$(cat "$TMP/home/.config/mise/config.toml.backup")" = 'my = "config"' ]
}

@test "link_mise_config: replaces an existing symlink without a backup" {
  mkdir -p "$TMP/home/.config/mise"
  ln -s /nonexistent "$TMP/home/.config/mise/config.toml"
  run "$REPO_ROOT/scripts/link_mise_config.sh" "$REPO_ROOT/mise-config.toml" "$TMP/home/.config/mise/config.toml"
  assert_success
  [ "$(readlink "$TMP/home/.config/mise/config.toml")" = "$REPO_ROOT/mise-config.toml" ]
  [ ! -e "$TMP/home/.config/mise/config.toml.backup" ]
}

@test "link_mise_config: creates the parent directory on a fresh machine" {
  run "$REPO_ROOT/scripts/link_mise_config.sh" "$REPO_ROOT/mise-config.toml" "$TMP/home/.config/mise/config.toml"
  assert_success
  [ -L "$TMP/home/.config/mise/config.toml" ]
}

@test "bootstrap: links the mise config through the backup-aware helper" {
  grep -qF 'scripts/link_mise_config.sh' "$REPO_ROOT/bootstrap.sh"
  ! grep -qE '^[^#]*ln -sfn[^#]*mise-config\.toml' "$REPO_ROOT/bootstrap.sh"
}

# --- ensure_brew_prefix.sh ---------------------------------------------------

# Fake sudo that records its args and runs the command unprivileged.
make_fake_sudo() {
  cat > "$TMP/sudo" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SUDO_LOG"
"$@"
SH
  chmod +x "$TMP/sudo"
}

@test "ensure_brew_prefix: creates a missing prefix via sudo and hands it to the user" {
  make_fake_sudo
  run env SUDO_LOG="$TMP/sudo.log" DOTFILES_SUDO="$TMP/sudo" DOTFILES_EUID=1000 \
    DOTFILES_BREW_PREFIX="$TMP/linuxbrew/.linuxbrew" "$REPO_ROOT/scripts/ensure_brew_prefix.sh"
  assert_success
  [ -d "$TMP/linuxbrew/.linuxbrew" ]
  grep -qF "mkdir -p $TMP/linuxbrew/.linuxbrew" "$TMP/sudo.log"
  grep -qE "^chown $(id -un):[^ ]+ $TMP/linuxbrew/.linuxbrew$" "$TMP/sudo.log"
}

@test "ensure_brew_prefix: is a no-op when the prefix already exists" {
  make_fake_sudo
  mkdir -p "$TMP/linuxbrew/.linuxbrew"
  run env SUDO_LOG="$TMP/sudo.log" DOTFILES_SUDO="$TMP/sudo" DOTFILES_EUID=1000 \
    DOTFILES_BREW_PREFIX="$TMP/linuxbrew/.linuxbrew" "$REPO_ROOT/scripts/ensure_brew_prefix.sh"
  assert_success
  [ ! -e "$TMP/sudo.log" ]
}

@test "ensure_brew_prefix: root creates the prefix without sudo" {
  make_fake_sudo
  run env SUDO_LOG="$TMP/sudo.log" DOTFILES_SUDO="$TMP/sudo" DOTFILES_EUID=0 \
    DOTFILES_BREW_PREFIX="$TMP/linuxbrew/.linuxbrew" "$REPO_ROOT/scripts/ensure_brew_prefix.sh"
  assert_success
  [ -d "$TMP/linuxbrew/.linuxbrew" ]
  [ ! -e "$TMP/sudo.log" ]
}

@test "bootstrap and mise.yml ensure the Homebrew prefix before applying brew packages" {
  local bs="$REPO_ROOT/bootstrap.sh" role="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  prefix_line="$(grep -n 'ensure_brew_prefix.sh' "$bs" | head -1 | cut -d: -f1)"
  apply_line="$(grep -n 'bootstrap packages apply' "$bs" | head -1 | cut -d: -f1)"
  [ -n "$prefix_line" ] && [ "$prefix_line" -lt "$apply_line" ]
  prefix_line="$(grep -n 'ensure_brew_prefix.sh' "$role" | head -1 | cut -d: -f1)"
  apply_line="$(grep -n 'bootstrap packages apply' "$role" | head -1 | cut -d: -f1)"
  [ -n "$prefix_line" ] && [ "$prefix_line" -lt "$apply_line" ]
}

# --- pynvim convergence --------------------------------------------------------

# python's postinstall only runs when mise installs that python, so an
# already-present python never gets pynvim. Converge it explicitly before
# verify_mise_tools.sh checks `import pynvim`.
@test "bootstrap and mise.yml converge pynvim before verifying tools" {
  local bs="$REPO_ROOT/bootstrap.sh" role="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  pynvim_line="$(grep -n 'pip install.*pynvim' "$bs" | head -1 | cut -d: -f1)"
  verify_line="$(grep -n 'verify_mise_tools.sh' "$bs" | head -1 | cut -d: -f1)"
  [ -n "$pynvim_line" ] && [ "$pynvim_line" -lt "$verify_line" ]
  pynvim_line="$(grep -n 'pip install.*pynvim' "$role" | head -1 | cut -d: -f1)"
  verify_line="$(grep -n 'verify_mise_tools.sh' "$role" | head -1 | cut -d: -f1)"
  [ -n "$pynvim_line" ] && [ "$pynvim_line" -lt "$verify_line" ]
}

@test "upgrade.yml upgrades pynvim on every upgrade" {
  grep -qE 'pip install .*--upgrade pynvim' "$REPO_ROOT/roles/dotfiles/tasks/upgrade.yml"
}
