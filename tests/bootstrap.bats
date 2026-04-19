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

@test "bootstrap: installs gcc via brew on Linux only" {
  grep -q 'brew install gcc' "$REPO_ROOT/bootstrap.sh"
  awk '/\!\= .*darwin/{inblock=1} inblock && /brew install gcc/{found=1} inblock && /^  fi/{inblock=0} END{exit !found}' "$REPO_ROOT/bootstrap.sh"
}
