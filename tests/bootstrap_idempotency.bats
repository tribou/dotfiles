setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "bootstrap: running twice does not duplicate lines in generated rc files" {
  # Create a temp home directory to avoid polluting the real one
  local tmp_home
  tmp_home=$(mktemp -d)
  
  # Run bootstrap twice in a row with a temp HOME
  HOME="$tmp_home" bash "$REPO_ROOT/bootstrap.sh" || true
  HOME="$tmp_home" bash "$REPO_ROOT/bootstrap.sh" || true

  # Check that no file has duplicate lines
  local dupes=0
  for f in "$tmp_home/.bash_profile" "$tmp_home/.zshrc" "$tmp_home/.gitconfig"; do
    if [ -f "$f" ]; then
      local d
      d=$(sort "$f" | uniq -d | wc -l)
      dupes=$((dupes + d))
    fi
  done

  rm -rf "$tmp_home"
  [ "$dupes" -eq 0 ]
}
