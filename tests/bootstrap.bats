# covers: bootstrap.sh mise.toml mise-config.toml mise-config.optional.toml.example scripts/link_mise_config.sh justfile scripts/bootstrap/run.sh scripts/bootstrap/pre_dotfiles.sh scripts/bootstrap/preflight.sh scripts/bootstrap/next_steps.sh bash_profile
setup() {
  load 'test_helper/common_setup'
  common_setup
  FIXTURE_HOME="$BATS_TEST_TMPDIR/home"
  FIXTURE_BIN="$BATS_TEST_TMPDIR/bin"
  CALLS="$BATS_TEST_TMPDIR/mise-calls"
  mkdir -p "$FIXTURE_HOME/.local/bin" "$FIXTURE_BIN"
  printf '#!/usr/bin/env bash\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n' > "$FIXTURE_BIN/uname"
  printf '#!/usr/bin/env bash\necho /Library/Developer/CommandLineTools\n' > "$FIXTURE_BIN/xcode-select"
  chmod +x "$FIXTURE_BIN/uname" "$FIXTURE_BIN/xcode-select"
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
    SHELL="${LOGIN_SHELL:-/opt/homebrew/bin/bash}" bash "$REPO_ROOT/bootstrap.sh" "$@"
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
  printf '#!/usr/bin/env bash\nexit 2\n' > "$FIXTURE_BIN/xcode-select" # never consulted on Linux
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
  assert_output --partial 'then re-run'
  run grep -q 'self-update' "$CALLS"
  assert_failure
  ! grep -qF -- "-C $REPO_ROOT" "$CALLS"
}

# run_piped_bootstrap ARGS: bootstrap.sh from stdin outside the repo, as
# `curl ... | bash -s -- ARGS` runs it; ~/dev/dotfiles already holds the repo.
run_piped_bootstrap() {
  mkdir -p "$FIXTURE_HOME/dev"
  ln -s "$REPO_ROOT" "$FIXTURE_HOME/dev/dotfiles"
  printf '#!/usr/bin/env bash\n' > "$FIXTURE_BIN/git"
  chmod +x "$FIXTURE_BIN/git"
  cd "${PIPED_CWD:-$BATS_TEST_TMPDIR}"
  run env HOME="$FIXTURE_HOME" PATH="$FIXTURE_BIN:/usr/bin:/bin" MISE_CALLS="$CALLS" \
    SHELL=/opt/homebrew/bin/bash bash -s -- "$@" < "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap piped: installs git with sudo before cloning on a real run" {
  fake_linux
  run_piped_bootstrap
  assert_success
  grep -qxF 'sudo apt-get install -y curl git ca-certificates' "$CALLS"
}

@test "bootstrap piped --dry-run: installs no Linux packages" {
  fake_linux
  run_piped_bootstrap --dry-run
  assert_success
  assert_output --partial 'Dry run complete'
  ! grep -q '^sudo' "$CALLS"
}

@test "bootstrap -nC: -n ahead of a short flag that takes a value is a dry run too" {
  fake_linux
  run_bootstrap -nj4
  assert_success
  grep -qxF -- "-C $REPO_ROOT bootstrap --yes -nj4 --skip dotfiles" "$CALLS"
  ! grep -q '^sudo' "$CALLS"
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
  assert_output --partial "~/.config/mise/config.toml is not linked to this checkout's mise-config.toml"
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

# Stock macOS: git, clang and make are stubs until the Command Line Tools are
# installed, and the login shell is zsh, which these dotfiles do not configure (#229).
@test "bootstrap: on macOS stops before doing anything when the Command Line Tools are missing" {
  printf '#!/usr/bin/env bash\nexit 2\n' > "$FIXTURE_BIN/xcode-select"
  run_bootstrap
  assert_failure
  assert_output --partial 'xcode-select --install'
  [ ! -e "$CALLS" ]
}

@test "bootstrap: rejects Intel macOS" {
  printf '#!/usr/bin/env bash\ncase "$1" in -s) echo Darwin ;; -m) echo x86_64 ;; esac\n' > "$FIXTURE_BIN/uname"
  run_bootstrap
  assert_failure
  assert_output --partial 'Intel macOS is not supported'
  run grep -qF -- "-C $REPO_ROOT bootstrap" "$CALLS"
  assert_failure
}

@test "bootstrap: on macOS with a zsh login shell says how to switch to Homebrew bash" {
  LOGIN_SHELL=/bin/zsh run_bootstrap
  assert_success
  assert_output --partial 'Your login shell is /bin/zsh'
  assert_output --partial 'chsh -s /opt/homebrew/bin/bash'
  assert_output --partial 'open a new terminal window'
  refute_output --partial 'exec $SHELL -l'
}

@test "bootstrap: says nothing about the login shell when it is already Homebrew bash" {
  run_bootstrap
  assert_success
  assert_output --partial 'Open a new login shell'
  refute_output --partial 'chsh'
}

@test "bootstrap: on Linux says nothing about the login shell" {
  fake_linux
  LOGIN_SHELL=/bin/zsh run_bootstrap
  assert_success
  refute_output --partial 'chsh'
}

@test "bootstrap --dry-run: says nothing about the login shell" {
  LOGIN_SHELL=/bin/zsh run_bootstrap --dry-run
  assert_success
  refute_output --partial 'chsh'
}

# Manual follow-ups: things bootstrap cannot or should not do itself, such as
# Spotlight's Search Privacy list, which only Full Disk Access could script.
@test "bootstrap: on macOS lists Spotlight folders to exclude as a manual follow-up" {
  run_bootstrap
  assert_success
  assert_output --partial 'Manual follow-ups:'
  assert_output --partial 'Search Privacy'
  assert_output --partial '~/dev'
  assert_output --partial '~/Library/Developer/Xcode/DerivedData'
  assert_output --partial '~/Library/Caches'
}

@test "bootstrap: on macOS with a zsh login shell numbers the shell switch and Spotlight follow-ups" {
  LOGIN_SHELL=/bin/zsh run_bootstrap
  assert_success
  assert_line --regexp '^1\. .*login shell'
  assert_line --regexp '^2\. .*Spotlight'
}

@test "bootstrap: on Linux lists no manual follow-ups" {
  fake_linux
  run_bootstrap
  assert_success
  refute_output --partial 'Manual follow-ups'
  refute_output --partial 'Spotlight'
  assert_output --partial 'Open a new login shell'
}

@test "bootstrap --dry-run: lists no manual follow-ups" {
  run_bootstrap --dry-run
  assert_success
  refute_output --partial 'Manual follow-ups'
  refute_output --partial 'Spotlight'
}

run_preflight() {
  run env PATH="$FIXTURE_BIN:/usr/bin:/bin" bash "$REPO_ROOT/scripts/bootstrap/preflight.sh" "$@"
}

@test "preflight: warns about the sudo prompt when the Homebrew prefix is missing" {
  run_preflight "$BATS_TEST_TMPDIR/no-brew" 0
  assert_success
  assert_output --partial "password once (sudo) to create $BATS_TEST_TMPDIR/no-brew"
}

@test "preflight: is silent when the Homebrew prefix exists, and in a dry run" {
  run_preflight "$BATS_TEST_TMPDIR" 0
  assert_success
  refute_output --partial 'sudo'
  run_preflight "$BATS_TEST_TMPDIR/no-brew" 1
  assert_success
  refute_output --partial 'sudo'
}

# Piped from curl there is no script path, so the repo is never the current directory.
@test "bootstrap piped: ignores a mise.toml in the current directory" {
  mkdir "$BATS_TEST_TMPDIR/project"
  touch "$BATS_TEST_TMPDIR/project/mise.toml"
  PIPED_CWD="$BATS_TEST_TMPDIR/project" run_piped_bootstrap --skip task
  assert_success
  grep -qxF -- "-C $FIXTURE_HOME/dev/dotfiles bootstrap --yes --skip task" "$CALLS"
}

@test "bash_profile: sources bash-completion from the Apple Silicon Homebrew prefix" {
  grep -qF '. "/opt/homebrew/etc/profile.d/bash_completion.sh"' "$REPO_ROOT/bash_profile"
}
