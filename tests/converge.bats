# covers: scripts/bootstrap/converge.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  export HOME="$BATS_TEST_TMPDIR/home"
  STUBS="$BATS_TEST_TMPDIR/bin"
  LOG="$BATS_TEST_TMPDIR/calls.log"
  mkdir -p "$HOME" "$STUBS"
  : > "$LOG"
  export CALL_LOG="$LOG"
  export PATH="$STUBS:$PATH"
  # shellcheck source=/dev/null
  source "$REPO_ROOT/scripts/bootstrap/converge.sh"
}

# stub NAME [BODY]: an executable that logs "NAME args" and runs BODY.
stub() {
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "%s" "$*" >> "$CALL_LOG"\n%s\n' "$1" "${2:-}" > "$STUBS/$1"
  chmod +x "$STUBS/$1"
}

@test "converge: sourcing does not run any step" {
  run bash -c "source '$REPO_ROOT/scripts/bootstrap/converge.sh'"
  assert_success
  assert_output ''
}

@test "converge: generates rsa and ed25519 keys once, private" {
  mkdir -p "$HOME/.ssh"
  stub ssh-keygen 'f=""; while [ $# -gt 0 ]; do [ "$1" = -f ] && f="$2"; shift; done; : > "$f"; : > "$f.pub"'
  run step_ssh_keys
  assert_success
  assert_output --partial 'changed: generated ~/.ssh/id_rsa'
  assert_output --partial 'changed: generated ~/.ssh/id_ed25519'
  grep -qE '^ssh-keygen .*-t rsa -b 4096 .*-N  .*-f '"$HOME"'/.ssh/id_rsa' "$LOG"
  grep -qE '^ssh-keygen .*-t ed25519 .*-C tribou@users.noreply.github.com' "$LOG"
  [ "$(stat -c %a "$HOME/.ssh/id_rsa" 2>/dev/null || stat -f %Lp "$HOME/.ssh/id_rsa")" = 600 ]
  : > "$LOG"
  run step_ssh_keys
  assert_success
  refute_output --partial 'changed:'
  [ ! -s "$LOG" ]
}

@test "converge: macOS keychain block is added once and keys are loaded" {
  mkdir -p "$HOME/.ssh"
  stub ssh-add
  DOTFILES_UNAME=Darwin run step_macos_ssh
  assert_success
  assert_output --partial 'changed: added keychain block to ~/.ssh/config'
  grep -qF '# BEGIN dotfiles' "$HOME/.ssh/config"
  grep -qF '  UseKeychain yes' "$HOME/.ssh/config"
  grep -qF '# END dotfiles' "$HOME/.ssh/config"
  grep -qF 'ssh-add --apple-use-keychain' "$LOG"
  DOTFILES_UNAME=Darwin run step_macos_ssh
  refute_output --partial 'changed:'
  [ "$(grep -c '# BEGIN dotfiles' "$HOME/.ssh/config")" -eq 1 ]
}

@test "converge: macOS keychain step does nothing on Linux" {
  stub ssh-add
  DOTFILES_UNAME=Linux run step_macos_ssh
  assert_success
  [ ! -e "$HOME/.ssh/config" ]
  [ ! -s "$LOG" ]
}

@test "converge: compiles both custom terminfo entries" {
  stub tic
  run step_terminfo
  assert_success
  grep -qF "tic -x $REPO_ROOT/tmux/xterm-256color-italic.terminfo" "$LOG"
  grep -qF "tic -x $REPO_ROOT/tmux/tmux-256color.terminfo" "$LOG"
}

@test "converge: makes regular ~/.gnupg files 0600 and skips symlinks" {
  mkdir -p "$HOME/.gnupg"
  printf x > "$HOME/.gnupg/pubring.kbx" && chmod 644 "$HOME/.gnupg/pubring.kbx"
  ln -s /etc/hostname "$HOME/.gnupg/gpg-agent.conf"
  run step_gnupg_perms
  assert_success
  [ "$(stat -c %a "$HOME/.gnupg/pubring.kbx" 2>/dev/null || stat -f %Lp "$HOME/.gnupg/pubring.kbx")" = 600 ]
  [ -L "$HOME/.gnupg/gpg-agent.conf" ]
}

@test "converge: installs nvim and CoC plugins only when missing" {
  stub nvim
  run step_nvim_plugins
  assert_success
  grep -qF 'nvim --headless +PlugInstall --sync +qall' "$LOG"
  grep -qF 'CocInstall -sync' "$LOG"
  mkdir -p "$HOME/.local/share/nvim/plugged" "$HOME/.config/coc/extensions/node_modules"
  : > "$LOG"
  run step_nvim_plugins
  refute_output --partial 'changed:'
  [ ! -s "$LOG" ]
}

@test "converge: installs tmux plugins via TPM in a detached session when outside tmux" {
  stub tmux
  mkdir -p "$HOME/.tmux/plugins/tpm/bin"
  printf '#!/usr/bin/env bash\necho install_plugins >> "$CALL_LOG"\n' > "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  chmod +x "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  TMUX='' run step_tmux_plugins
  assert_success
  grep -qF 'tmux new-session -d -s _bootstrap_tpm' "$LOG"
  grep -qx 'install_plugins' "$LOG"
  grep -qF 'tmux kill-session -t _bootstrap_tpm' "$LOG"
  mkdir -p "$HOME/.tmux/plugins/tmux-sensible"
  : > "$LOG"
  run step_tmux_plugins
  [ ! -s "$LOG" ]
}

@test "converge: migrates legacy z history into zoxide once" {
  printf '/tmp|1|1\n' > "$HOME/.z"
  stub zoxide
  run step_zoxide
  assert_success
  grep -qF "zoxide import --from z $HOME/.z --merge" "$LOG"
  [ ! -e "$HOME/.z" ] && [ -f "$HOME/.z.migrated" ]
  : > "$LOG"
  run step_zoxide
  [ ! -s "$LOG" ]
}

@test "converge: keeps ~/.z when the zoxide import fails" {
  printf '/tmp|1|1\n' > "$HOME/.z"
  stub zoxide 'exit 1'
  run step_zoxide
  assert_success
  [ -f "$HOME/.z" ]
}

@test "converge: installs pynvim into the mise python and reports only real installs" {
  stub python 'echo "Requirement already satisfied: pynvim"'
  run step_pynvim
  assert_success
  grep -qF 'python -m pip install pynvim' "$LOG"
  refute_output --partial 'changed:'
  stub python 'echo "Successfully installed pynvim-0.6.0"'
  run step_pynvim
  assert_output --partial 'changed: installed pynvim'
}

@test "converge: enables corepack shims only when yarn or pnpm is missing" {
  stub mise 'case "$*" in "which yarn"|"which pnpm") [ -e "$CALL_LOG.enabled" ] ;; esac'
  stub corepack 'touch "$CALL_LOG.enabled"'
  MISE_BIN="$STUBS/mise" run step_corepack
  assert_success
  grep -qx 'corepack enable' "$LOG"
  grep -qx 'mise reshim' "$LOG"
  assert_output --partial 'changed: enabled corepack'
  : > "$LOG"
  MISE_BIN="$STUBS/mise" run step_corepack
  refute_output --partial 'changed:'
  ! grep -q '^corepack' "$LOG"
}

@test "converge: hydrates beads on a fresh clone with a sync remote" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo/.beads"
  printf 'sync.remote: "https://example.test/beads"\n' > "$repo/.beads/config.yaml"
  stub bd
  DOTFILES_REPO="$repo" run step_beads
  assert_success
  grep -qF "bd -C $repo bootstrap --yes" "$LOG"
}

@test "converge: beads step is skipped when bd is not installed" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo/.beads"
  printf 'sync.remote: "https://example.test/beads"\n' > "$repo/.beads/config.yaml"
  PATH="$STUBS:/usr/bin:/bin" DOTFILES_REPO="$repo" run step_beads
  assert_success
}

@test "converge: writes the bootstrap-done marker once" {
  run step_marker
  assert_output --partial 'changed: marked bootstrap complete'
  [ -f "$HOME/.dotfiles-bootstrap-done" ]
  run step_marker
  refute_output --partial 'changed:'
}

@test "converge: main runs every step, verification before the marker" {
  run grep -nE '^ *step_[a-z_]+$' "$REPO_ROOT/scripts/bootstrap/converge.sh"
  for step in ssh_keys macos_ssh terminfo gnupg_perms nvim_plugins tmux_plugins zoxide beads pynvim corepack brew_cleanup verify marker; do
    echo "$output" | grep -qE ":? *step_${step}$" || fail "main does not run step_$step"
  done
  verify_line="$(echo "$output" | grep -E 'step_verify$' | cut -d: -f1)"
  marker_line="$(echo "$output" | grep -E 'step_marker$' | cut -d: -f1)"
  [ "$verify_line" -lt "$marker_line" ]
}

# The Docker suite bind-mounts the developer's checkout; `bd bootstrap` there
# rewrites tracked .beads files as root.
@test "converge: DOTFILES_SKIP_BEADS=1 leaves beads alone" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo/.beads"
  printf 'sync.remote: "https://example.test/beads"\n' > "$repo/.beads/config.yaml"
  stub bd
  DOTFILES_SKIP_BEADS=1 DOTFILES_REPO="$repo" run step_beads
  assert_success
  [ ! -s "$LOG" ]
}
