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
