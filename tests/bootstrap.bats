# covers: bootstrap.sh mise.toml mise-config.toml mise-config.optional.toml.example scripts/link_mise_config.sh justfile scripts/bootstrap/run.sh scripts/bootstrap/pre_dotfiles.sh scripts/bootstrap/is_dry_run.sh
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

# mise bootstrap --dry-run neither clones repos nor runs the pre-dotfiles hook,
# so its dotfiles check fails on a machine that was never bootstrapped (#226).
@test "bootstrap --dry-run: previews everything but dotfiles with mise, then dotfiles without changing them" {
  printf 'mine\n' > "$FIXTURE_HOME/.gitconfig"
  run_bootstrap --dry-run
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --dry-run --skip dotfiles" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
  assert_output --partial 'would back up ~/.gitconfig to ~/.gitconfig.backup'
  assert_output --partial 'a real run applies these before tools and the task'
  refute_output --partial 'is not linked'
  [ "$(cat "$FIXTURE_HOME/.gitconfig")" = mine ]
  [ ! -e "$FIXTURE_HOME/.gitconfig.backup" ]
}

# fake_linux: a Linux uname plus sudo and apt-get that log to $CALLS.
fake_linux() {
  printf '#!/usr/bin/env bash\ncase "$1" in -s) echo Linux ;; -m) echo x86_64 ;; esac\n' > "$FIXTURE_BIN/uname"
  printf '#!/usr/bin/env bash\nprintf "sudo %%s\\n" "$*" >> "$MISE_CALLS"\n' > "$FIXTURE_BIN/sudo"
  printf '#!/usr/bin/env bash\n' > "$FIXTURE_BIN/apt-get"
  chmod +x "$FIXTURE_BIN/sudo" "$FIXTURE_BIN/apt-get"
}

@test "bootstrap: installs the Linux prerequisites with sudo on a real run" {
  fake_linux
  run_bootstrap
  assert_success
  grep -qxF 'sudo apt-get install -y curl git build-essential ca-certificates' "$CALLS"
}

@test "bootstrap --dry-run: installs no Linux packages" {
  fake_linux
  run_bootstrap --dry-run
  assert_success
  ! grep -q '^sudo' "$CALLS"
}

@test "bootstrap --dry-run: stops instead of updating a mise older than min_version" {
  fake_mise 2026.9.11
  run_bootstrap --dry-run
  assert_failure
  assert_output --partial 'mise 2026.9.11 is older than the required'
  ! grep -q 'self-update' "$CALLS"
  ! grep -qF -- "-C $REPO_ROOT" "$CALLS"
}

@test "bootstrap --dry-run: reports a finished dry run, not a finished bootstrap" {
  run_bootstrap --dry-run
  assert_success
  assert_output --partial 'Dry run complete'
  refute_output --partial 'Open a new login shell'
}

@test "bootstrap -ny: combined short flags are a dry run too" {
  run_bootstrap -ny
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes -ny --skip dotfiles" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
}

@test "bootstrap --dry-run --only/--skip: a missing or empty value is an error" {
  for flags in '--only' '--skip' '--only=' '--skip='; do
    run_bootstrap --dry-run $flags
    assert_failure
    assert_output --partial "${flags%=} needs a value"
  done
  ! grep -qF -- "-C $REPO_ROOT" "$CALLS"
}

@test "bootstrap --dry-run --only with --skip: rejected, as mise does" {
  run_bootstrap --dry-run --only dotfiles --skip task
  assert_failure
  assert_output --partial '--only and --skip cannot be combined'
  ! grep -qF -- "-C $REPO_ROOT" "$CALLS"
}

@test "bootstrap -n: is the same as --dry-run" {
  run_bootstrap -n --skip task
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes -n --skip task --skip dotfiles" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
}

@test "bootstrap --dry-run --only dotfiles: previews only dotfiles" {
  run_bootstrap --dry-run --only dotfiles
  assert_success
  ! grep -qF -- "-C $REPO_ROOT bootstrap" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
}

@test "bootstrap --dry-run --only: keeps the other parts for mise" {
  run_bootstrap --dry-run --only repos,dotfiles --only=tools
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --dry-run --only repos --only=tools" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
}

@test "bootstrap --dry-run --skip dotfiles: skips the dotfiles preview" {
  run_bootstrap --dry-run --skip task,dotfiles
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --dry-run --skip task,dotfiles" "$CALLS"
  ! grep -qF 'dot diff' "$CALLS"
  refute_output --partial 'would '
}

@test "just install --dry-run: previews like bootstrap.sh --dry-run" {
  printf 'mine\n' > "$FIXTURE_HOME/.gitconfig"
  run env HOME="$FIXTURE_HOME" PATH="$PATH" MISE_CALLS="$CALLS" \
    just --justfile "$REPO_ROOT/justfile" install --dry-run
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --dry-run --skip dotfiles" "$CALLS"
  grep -qxF -- "-C $REPO_ROOT dot diff" "$CALLS"
  [ ! -e "$FIXTURE_HOME/.gitconfig.backup" ]
}

# Without the global config, mise previews no packages and no global tools.
@test "just install --dry-run: warns when the global mise config is not linked" {
  run env HOME="$FIXTURE_HOME" PATH="$PATH" MISE_CALLS="$CALLS" \
    just --justfile "$REPO_ROOT/justfile" install --dry-run
  assert_success
  assert_output --partial '~/.config/mise/config.toml is not linked to this repo'
}

@test "just install: quotes the script path, so a checkout path with spaces works" {
  grep -qF '"{{justfile_directory()}}/scripts/bootstrap/run.sh"' "$REPO_ROOT/justfile"
}

@test "just install: applies with mise bootstrap" {
  run env HOME="$FIXTURE_HOME" PATH="$PATH" MISE_CALLS="$CALLS" \
    just --justfile "$REPO_ROOT/justfile" install --skip task
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes --skip task" "$CALLS"
}
