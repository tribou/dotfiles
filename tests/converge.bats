# covers: scripts/bootstrap/converge.sh
bats_require_minimum_version 1.5.0

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

@test "converge: macOS keychain block starts on its own line when ~/.ssh/config lacks a final newline" {
  mkdir -p "$HOME/.ssh"
  printf 'Host example\n  User me' > "$HOME/.ssh/config"
  stub ssh-add
  DOTFILES_UNAME=Darwin run step_macos_ssh
  assert_success
  grep -qx '  User me' "$HOME/.ssh/config"
  grep -qx '# BEGIN dotfiles' "$HOME/.ssh/config"
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

@test "converge: compiles the custom tmux terminfo entry" {
  stub tic
  run step_terminfo
  assert_success
  run grep -F "xterm-256color-italic" "$LOG"
  assert_failure
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
  # Tree-sitter parsers install synchronously before the CoC run, whose quick
  # quit would otherwise kill init.vim's async install mid-download.
  grep -qF "install(vim.g.dotfiles_treesitter_parsers):wait(" "$LOG"
  [ "$(grep -n 'treesitter' "$LOG" | cut -d: -f1)" -lt "$(grep -n 'CocInstall' "$LOG" | cut -d: -f1)" ]
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

@test "converge: a failed pynvim install fails the step and shows pip's output" {
  stub python 'echo "ERROR: no matching distribution for pynvim"; exit 1'
  run step_pynvim
  assert_failure
  assert_output --partial 'ERROR: no matching distribution for pynvim'
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

# docker_stubs [GROUPS]: sudo logs (and swallows piped input), id reports GROUPS.
docker_stubs() {
  stub sudo 'if [ "$1" = tee ]; then sed "s/^/tee< /" >> "$CALL_LOG"; fi'
  stub dpkg 'echo amd64'
  stub id "if [ \"\$1\" = -un ]; then echo tester; else echo '${1:-tester sudo}'; fi"
  export DOTFILES_DOCKER="$BATS_TEST_TMPDIR/no-docker"
  export DOTFILES_SYSTEMD_DIR="$BATS_TEST_TMPDIR/systemd"
  mkdir -p "$DOTFILES_SYSTEMD_DIR"
  export DOTFILES_OS_RELEASE="$BATS_TEST_TMPDIR/os-release"
}

@test "converge: installs Docker CE from Docker's apt repo on Ubuntu and adds the user to the docker group" {
  docker_stubs
  printf 'ID=ubuntu\nID_LIKE=debian\nVERSION_CODENAME=noble\nUBUNTU_CODENAME=noble\n' > "$DOTFILES_OS_RELEASE"
  DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=apt run step_docker
  assert_success
  grep -qF 'sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc' "$LOG"
  grep -qF 'tee< deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable' "$LOG"
  grep -qF 'sudo tee /etc/apt/sources.list.d/docker.list' "$LOG"
  grep -qF 'sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin' "$LOG"
  grep -qF 'sudo systemctl enable --now docker' "$LOG"
  grep -qF 'sudo usermod -aG docker tester' "$LOG"
  assert_output --partial 'changed: installed Docker'
  assert_output --partial 'changed: added tester to the docker group'
}

@test "converge: an Ubuntu derivative uses Docker's Ubuntu repo and its Ubuntu codename" {
  docker_stubs
  printf 'ID=linuxmint\nID_LIKE="ubuntu debian"\nVERSION_CODENAME=xia\nUBUNTU_CODENAME=noble\n' > "$DOTFILES_OS_RELEASE"
  DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=apt run step_docker
  assert_success
  grep -qF 'https://download.docker.com/linux/ubuntu noble stable' "$LOG"
}

@test "converge: Debian uses Docker's Debian repo" {
  docker_stubs
  printf 'ID=debian\nVERSION_CODENAME=trixie\n' > "$DOTFILES_OS_RELEASE"
  DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=apt run step_docker
  assert_success
  grep -qF 'https://download.docker.com/linux/debian trixie stable' "$LOG"
}

@test "converge: an apt distro Docker has no repo for is left alone with a warning" {
  docker_stubs
  printf 'ID=someos\nVERSION_CODENAME=x\n' > "$DOTFILES_OS_RELEASE"
  DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=apt run --separate-stderr step_docker
  assert_success
  [[ "$stderr" == *"install Docker yourself"* ]] || fail "no warning: $stderr"
  ! grep -q '^sudo ' "$LOG" || fail "unexpected: $(cat "$LOG")"
}

@test "converge: installs Docker with pacman on Arch and skips systemd and the group when not needed" {
  docker_stubs 'tester wheel docker'
  rmdir "$DOTFILES_SYSTEMD_DIR"
  DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=pacman run step_docker
  assert_success
  grep -qF 'sudo pacman -S --needed --noconfirm docker docker-buildx docker-compose' "$LOG"
  ! grep -qF 'systemctl' "$LOG" || fail "unexpected: $(cat "$LOG")"
  ! grep -qF 'usermod' "$LOG" || fail "unexpected: $(cat "$LOG")"
  assert_output 'changed: installed Docker'
}

@test "converge: Docker step does nothing when docker is installed or on macOS" {
  docker_stubs
  stub docker
  DOTFILES_DOCKER=docker DOTFILES_UNAME=Linux DOTFILES_PKG_MANAGER=apt run step_docker
  assert_success
  assert_output ''
  DOTFILES_UNAME=Darwin DOTFILES_PKG_MANAGER=apt run step_docker
  assert_success
  assert_output ''
  [ ! -s "$LOG" ]
}

@test "converge: main asks for sudo before the spinner only when Docker will be installed" {
  run grep -B2 -E '^  run_step "Installing Docker" step_docker$' "$REPO_ROOT/scripts/bootstrap/converge.sh"
  assert_output --partial 'if _docker_wanted; then sudo -v; fi'
}

@test "converge: writes the bootstrap-done marker once" {
  run step_marker
  assert_output --partial 'changed: marked bootstrap complete'
  [ -f "$HOME/.dotfiles-bootstrap-done" ]
  run step_marker
  refute_output --partial 'changed:'
}

@test "converge: main runs every step, verification before the marker" {
  run grep -nE '^ *(run_step "[^"]+" )?step_[a-z_]+$' "$REPO_ROOT/scripts/bootstrap/converge.sh"
  for step in ssh_keys macos_ssh terminfo gnupg_perms nvim_plugins tmux_plugins zoxide pynvim corepack docker brew_cleanup verify marker; do
    echo "$output" | grep -qE " step_${step}$|:step_${step}$" || fail "main does not run step_$step"
  done
  verify_line="$(echo "$output" | grep -E 'step_verify$' | cut -d: -f1)"
  marker_line="$(echo "$output" | grep -E 'step_marker$' | cut -d: -f1)"
  [ "$verify_line" -lt "$marker_line" ]
}

@test "converge: main labels every step but macos_ssh with a spinner" {
  run grep -cE '^  step_[a-z_]+$' "$REPO_ROOT/scripts/bootstrap/converge.sh"
  assert_output 1
  run grep -cE '^  run_step "[^"]+" step_[a-z_]+$' "$REPO_ROOT/scripts/bootstrap/converge.sh"
  assert_output 12
}

@test "converge: run_step shows the label, then replays the step's stdout and stderr" {
  noisy() { echo "changed: did a thing"; echo "a warning" >&2; }
  run --separate-stderr run_step "Doing a thing" noisy
  assert_success
  assert_output "changed: did a thing"
  [[ "$stderr" == *"Doing a thing"* ]] || fail "label missing from stderr: $stderr"
  [[ "$stderr" == *"a warning"* ]] || fail "step stderr missing: $stderr"
}

@test "converge: run_step returns the step's failure status and still shows its output" {
  broken() { echo "partial"; echo "boom" >&2; return 3; }
  run -3 --separate-stderr run_step "Breaking" broken
  assert_output "partial"
  [[ "$stderr" == *"boom"* ]] || fail "step stderr missing: $stderr"
}

@test "converge: run_step keeps errexit inside the step" {
  halfway() { false; echo "should not run"; }
  run -1 --separate-stderr run_step "Halfway" halfway
  refute_output --partial "should not run"
}

@test "converge: run_step leaves SIGINT at its default so Ctrl-C stops what the step runs" {
  run with_default_sigint bash -c "
    source '$REPO_ROOT/scripts/bootstrap/converge.sh'
    probe() { bash -c 'trap -p INT; echo probed'; }
    run_step 'Probing' probe 2>/dev/null
  "
  assert_success
  assert_output "probed"
}
