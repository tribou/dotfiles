setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "bootstrap: homebrew install uses NONINTERACTIVE=1 to avoid interactive sudo prompt" {
  grep -q 'NONINTERACTIVE=1' "$REPO_ROOT/bootstrap.sh"
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
