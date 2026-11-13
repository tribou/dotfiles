# covers: bootstrap.sh mise.toml mise-config.toml mise-config.optional.toml.example scripts/link_mise_config.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  FIXTURE_HOME="$BATS_TEST_TMPDIR/home"
  FIXTURE_BIN="$BATS_TEST_TMPDIR/bin"
  CALLS="$BATS_TEST_TMPDIR/mise-calls"
  mkdir -p "$FIXTURE_HOME/.local/bin" "$FIXTURE_BIN"
  printf '#!/usr/bin/env bash\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n' > "$FIXTURE_BIN/uname"
  chmod +x "$FIXTURE_BIN/uname"
  fake_mise 2026.11.7
}

# fake_mise VERSION: a standalone mise that logs its args and PATH.
fake_mise() {
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >> "$MISE_CALLS"' \
    'case "$1" in' \
    "  version) echo \"$1 macos-arm64 (2026-11-12)\" ;;" \
    '  -C) printf "PATH=%s\n" "$PATH" >> "$MISE_CALLS" ;;' \
    'esac' > "$FIXTURE_HOME/.local/bin/mise"
  chmod +x "$FIXTURE_HOME/.local/bin/mise"
}

run_bootstrap() {
  run env HOME="$FIXTURE_HOME" PATH="$FIXTURE_BIN:/usr/bin:/bin" MISE_CALLS="$CALLS" \
    bash "$REPO_ROOT/bootstrap.sh" "$@"
}

@test "bootstrap: self-clones to ~/dev/dotfiles when run outside the repo" {
  grep -q 'REPO_DIR="\$HOME/dev/dotfiles"' "$REPO_ROOT/bootstrap.sh"
  grep -q 'git clone "\$REPO_URL" "\$REPO_DIR"' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: installs minimal Linux prerequisites (curl git build-essential ca-certificates)" {
  grep -q 'apt-get install -y curl git build-essential ca-certificates' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: links the global config, trusts the repo, and hands off to mise bootstrap" {
  run_bootstrap --skip task
  assert_success
  [ "$(readlink "$FIXTURE_HOME/.config/mise/config.toml")" = "$REPO_ROOT/mise-config.toml" ]
  grep -qxF "trust $REPO_ROOT/mise.toml" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --skip task" "$CALLS"
  ! grep -q 'self-update' "$CALLS"
}

@test "bootstrap: exposes standalone mise after the canonical brew prefix" {
  run_bootstrap
  assert_success
  grep -qF "PATH=/opt/homebrew/bin:$FIXTURE_HOME/.local/bin:$FIXTURE_BIN:/usr/bin:/bin" "$CALLS"
}

@test "bootstrap: self-updates a mise older than the config's min_version" {
  fake_mise 2026.9.11
  run_bootstrap
  assert_success
  grep -qx 'self-update --yes' "$CALLS"
  update_line="$(grep -nx 'self-update --yes' "$CALLS" | cut -d: -f1)"
  bootstrap_line="$(grep -nF -- "-C $REPO_ROOT bootstrap" "$CALLS" | cut -d: -f1)"
  [ "$update_line" -lt "$bootstrap_line" ]
}

@test "bootstrap: is thin (fewer than 70 lines)" {
  [ "$(wc -l < "$REPO_ROOT/bootstrap.sh")" -lt 70 ]
}

@test "repo: ships mise-config.optional.toml.example as a commented drop-in template" {
  local f="$REPO_ROOT/mise-config.optional.toml.example"
  [ -f "$f" ]
  # every assignment is commented out (user uncomments what they want)
  ! grep -qE '^[[:space:]]*"?[a-z0-9_:/@-]+"?[[:space:]]*=' "$f"
  for t in awscli terraform-ls navi tlrc tfenv firefox orbstack bruno font-fira-code-nerd-font; do
    grep -q "$t" "$f" || fail "optional template lacks $t"
  done
}

@test "repo: core mise runtimes live in mise-config.toml" {
  grep -qE '^node[[:space:]]*=' "$REPO_ROOT/mise-config.toml"
}

# Node 25+ (node "lts" is 26) no longer bundles corepack.
@test "repo: corepack comes from mise" {
  grep -qF '"npm:corepack" = "latest"' "$REPO_ROOT/mise-config.toml"
}
