setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "bootstrap: homebrew install uses NONINTERACTIVE=1 to avoid interactive sudo prompt" {
  grep -q 'NONINTERACTIVE=1' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: exports NONINTERACTIVE=1 near the top for all Homebrew commands" {
  awk 'NR <= 25 && /export NONINTERACTIVE=1/{found=1} END{exit !found}' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: does not export the nonexistent HOMEBREW_NONINTERACTIVE var (brew never reads it; only HOMEBREW_NO_ASK disables the install confirmation prompt)" {
  ! grep -q 'export HOMEBREW_NONINTERACTIVE' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: exports HOMEBREW_NO_ASK=1 near the top to skip brew's default ask-mode confirmation prompt" {
  awk 'NR <= 25 && /export HOMEBREW_NO_ASK=1/{found=1} END{exit !found}' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: claude upgrade is gated behind command -v claude" {
  awk '/command -v claude/,/claude upgrade/' "$REPO_ROOT/bootstrap.sh" | grep -q 'claude upgrade'
}

@test "bootstrap: opencode upgrade is gated behind type -P opencode, not command -v" {
  awk '/OPENCODE_BIN=.*type -P opencode/,/opencode.*upgrade/' "$REPO_ROOT/bootstrap.sh" | grep -q '"$OPENCODE_BIN" upgrade'
  ! awk '/OPENCODE_BIN/,/opencode.*upgrade/' "$REPO_ROOT/bootstrap.sh" | grep -q 'command -v opencode'
}

@test "bootstrap: apt-get block upgrades packages non-interactively after update" {
  awk '/command -v apt-get/,/apt-get install/' "$REPO_ROOT/bootstrap.sh" | awk '/apt-get update/{updated=1} updated && /apt-get upgrade -y/{upgraded=1} END{exit !upgraded}'
}

@test "bootstrap: calls hash -r after mise install node to pick up newly created shims" {
  awk '/mise install node go/{found=1} found && /hash -r/{found=2} END{exit (found!=2)}' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: bash-completion is not in the shared brew install block (conflicts with util-linux on Linux)" {
  # grep -c returns the match count; must be 0 for the test to pass
  run bash -c "awk '/^  brew install \\\\/,/^  # Linux-only/' \"$REPO_ROOT/bootstrap.sh\" | grep -c 'bash-completion'"
  [ "$output" = "0" ]
}

@test "bootstrap: bash-completion is installed in the macOS-only brew block" {
  awk '/# macOS-only packages/,/^  fi/' "$REPO_ROOT/bootstrap.sh" | grep -q 'bash-completion'
}

@test "bootstrap: rename is not in the shared brew install block (conflicts with util-linux on Linux)" {
  run bash -c "awk '/^  brew install \\\\/,/^  # Linux-only/' \"$REPO_ROOT/bootstrap.sh\" | grep -cw 'rename'"
  [ "$output" = "0" ]
}

@test "bootstrap: rename is installed in the macOS-only brew block" {
  awk '/# macOS-only packages/,/^  fi/' "$REPO_ROOT/bootstrap.sh" | grep -qw 'rename'
}

@test "bootstrap: shared brew install block has no blank lines within continuations (blank lines break line continuation)" {
  # Only check lines that are inside the continuation (i.e., preceded by a \-terminated line)
  run bash -c "awk '/^  brew install \\\\/,/^  # Linux-only/' \"$REPO_ROOT/bootstrap.sh\" | awk 'prev ~ /\\\\$/ && /^$/{found=1} {prev=\$0} END{exit !found}'"
  [ "$status" -eq 1 ]
}

@test "bootstrap: installs gcc via brew on Linux only" {
  grep -q 'brew install gcc' "$REPO_ROOT/bootstrap.sh"
  awk '/\!\= .*darwin/{inblock=1} inblock && /brew install gcc/{found=1} inblock && /^  fi/{inblock=0} END{exit !found}' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: linkFileToHome uses rm -f before ln -sf to prevent nested symlinks on re-run" {
  awk '/function linkFileToHome/,/^\}/' "$REPO_ROOT/bootstrap.sh" | grep -q 'rm -f'
}

@test "bootstrap: installs bun via mise" {
  grep -q 'mise install.*bun' "$REPO_ROOT/bootstrap.sh"
}

@test "bootstrap: tpm install is anchored in an ephemeral detached session so it works in non-tmux shells" {
  # 'tmux start-server' alone does not keep the server alive between commands;
  # the next 'tmux set-environment -g' then fails with "no server running" outside
  # tmux and aborts the script under set -euo pipefail. A detached new-session
  # keeps the server up for the duration of the install.
  awk '/# Install tmux plugins/,/^fi$/' "$REPO_ROOT/bootstrap.sh" | grep -q 'tmux new-session -d'
}

@test "bootstrap: tpm install branches on \$TMUX so it reuses an existing server when already inside tmux" {
  awk '/# Install tmux plugins/,/^fi$/' "$REPO_ROOT/bootstrap.sh" | grep -q 'TMUX:-'
}

@test "bootstrap: hydrates the beads issue DB via 'bd bootstrap' on a fresh clone" {
  awk '/# beads issue database/,/^  fi/' "$REPO_ROOT/bootstrap.sh" | grep -q 'bd -C "$THIS_DIR" bootstrap --yes'
}

@test "bootstrap: beads hydration is guarded on a missing embedded Dolt dir so it never clobbers existing local issues" {
  awk '/# beads issue database/,/^  fi$/' "$REPO_ROOT/bootstrap.sh" | grep -q 'embeddeddolt'
}

@test "bootstrap: registers/repairs the beads Dolt remote from config.yaml sync.remote on existing machines" {
  awk '/# beads issue database/,/^  fi$/' "$REPO_ROOT/bootstrap.sh" | grep -q 'dolt remote add origin "$_beads_remote"'
}

@test "bootstrap: chmod 700 the Homebrew trust store directory before brew install (new brew refuses group-writable dirs)" {
  # New Homebrew versions refuse to write trust.json if the trust store
  # directory is group/world-writable. With umask 0002 (common on Linux),
  # mkdir creates dirs with 775, and brew only chmods to 0700 if it created
  # the dir itself — pre-existing dirs keep insecure perms and trigger:
  #   "Refusing to write insecure trust store: trust store directory ... is
  #    group or world writable."
  awk '/Brew is required/,/^  brew install \\/' "$REPO_ROOT/bootstrap.sh" | grep -q 'chmod 700'
}

@test "bootstrap: installs mise using curl with -fsSL flags" {
  grep -q 'curl -fsSL https://mise.run' "$REPO_ROOT/bootstrap.sh"
}

@test "Dockerfile: installs mise using curl with -fsSL flags" {
  grep -q 'curl -fsSL https://mise.run' "$REPO_ROOT/Dockerfile"
}

@test "bootstrap-test: installs mise using curl with -fsSL flags" {
  grep -q 'curl -fsSL https://mise.run' "$REPO_ROOT/scripts/bootstrap-test.sh"
}


