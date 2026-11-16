# covers: scripts/link_mise_config.sh bootstrap.sh
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
