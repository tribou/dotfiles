# covers: scripts/upgrade.sh justfile mise.toml
setup() {
  load 'test_helper/common_setup'
  common_setup
  export HOME="$BATS_TEST_TMPDIR/home"
  STUBS="$BATS_TEST_TMPDIR/bin"
  LOG="$BATS_TEST_TMPDIR/calls.log"
  mkdir -p "$HOME/.tmux/plugins/tpm/bin" "$STUBS"
  : > "$LOG"
  export CALL_LOG="$LOG"
  printf '#!/usr/bin/env bash\necho "tpm update_plugins $*" >> "$CALL_LOG"\n' > "$HOME/.tmux/plugins/tpm/bin/update_plugins"
  chmod +x "$HOME/.tmux/plugins/tpm/bin/update_plugins"
  for cmd in mise nvim tmux python sudo apt-get claude opencode rustup; do stub "$cmd"; done
  # sudo runs its command so apt-get is logged too
  stub sudo '"$@"'
  rm -f "$STUBS/pacman"
}

stub() {
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "%s" "$*" >> "$CALL_LOG"\n%s\n' "$1" "${2:-}" > "$STUBS/$1"
  chmod +x "$STUBS/$1"
}

run_upgrade() {
  run env PATH="$STUBS:/usr/bin:/bin" MISE_BIN="$STUBS/mise" DOTFILES_REPO="$REPO_ROOT" \
    DOTFILES_UNAME="${DOTFILES_UNAME:-Linux}" "$REPO_ROOT/scripts/upgrade.sh"
}

line_of() { grep -nF -- "$1" "$LOG" | head -1 | cut -d: -f1; }

@test "upgrade: upgrades packages, tools, repos, then plugins, in that order" {
  run_upgrade
  assert_success
  local pkgs tools repos converge plug
  pkgs="$(line_of 'mise -C '"$REPO_ROOT"' bootstrap packages upgrade --yes')"
  tools="$(line_of 'mise upgrade --yes')"
  repos="$(line_of 'mise -C '"$REPO_ROOT"' bootstrap repos update')"
  converge="$(line_of 'mise -C '"$REPO_ROOT"' bootstrap --yes')"
  plug="$(line_of 'nvim --headless +PlugUpdate --sync +qall')"
  [ -n "$pkgs" ] && [ -n "$tools" ] && [ -n "$repos" ] && [ -n "$converge" ] && [ -n "$plug" ]
  [ "$pkgs" -lt "$tools" ] && [ "$tools" -lt "$repos" ] && [ "$repos" -lt "$converge" ] && [ "$converge" -lt "$plug" ]
  grep -qF 'python -m pip install --upgrade pynvim' "$LOG"
  grep -qF 'tpm update_plugins all' "$LOG"
  grep -qF 'rustup self update' "$LOG"
  grep -qF 'rustup update' "$LOG"
}

@test "upgrade: upgrades the whole Debian system with apt" {
  run_upgrade
  assert_success
  grep -qF 'apt-get update' "$LOG"
  grep -qF 'apt-get upgrade -y' "$LOG"
}

@test "upgrade: uses pacman on Arch" {
  rm -f "$STUBS/apt-get"
  stub pacman
  run_upgrade
  assert_success
  grep -qF 'pacman -Syu --noconfirm' "$LOG"
}

@test "upgrade: self-updates claude and opencode only when installed" {
  run_upgrade
  grep -qF 'claude upgrade' "$LOG"
  grep -qF 'opencode upgrade' "$LOG"
  rm -f "$STUBS/claude" "$STUBS/opencode"
  : > "$LOG"
  run_upgrade
  assert_success
  ! grep -qE '^(claude|opencode) ' "$LOG"
}

@test "upgrade: a failing optional self-updater does not abort the run" {
  stub claude 'exit 1'
  run_upgrade
  assert_success
  grep -qF 'opencode upgrade' "$LOG"
}

@test "justfile: install converges with mise bootstrap and upgrade runs the mise upgrade task" {
  run just --justfile "$REPO_ROOT/justfile" --show install
  assert_output --partial 'mise -C {{ justfile_directory() }} bootstrap --yes'
  run just --justfile "$REPO_ROOT/justfile" --show upgrade
  assert_output --partial 'mise -C {{ justfile_directory() }} run upgrade'
}
