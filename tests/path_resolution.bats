setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "path_resolution: resolves existing directory directly" {
  local target_dir="$BATS_TEST_TMPDIR/target-dir"
  mkdir -p "$target_dir"
  
  DOTFILES="$REPO_ROOT"
  . "$REPO_ROOT/lib/_shared.sh"
  
  local result
  result=$(_dotfiles_full_path "$target_dir")
  assert_equal "$result" "$target_dir"
}

@test "path_resolution: falls back to zoxide query when available" {
  zoxide() {
    if [[ "$1" == "query" && "$2" == "matching_dir" ]]; then
      echo "/resolved/path/matching_dir"
      return 0
    fi
    return 1
  }
  
  DOTFILES="$REPO_ROOT"
  . "$REPO_ROOT/lib/_shared.sh"
  
  local result
  result=$(_dotfiles_full_path "matching_dir")
  assert_equal "$result" "/resolved/path/matching_dir"
}

@test "path_resolution: falls back to input string when zoxide query fails" {
  zoxide() {
    return 1
  }
  
  DOTFILES="$REPO_ROOT"
  . "$REPO_ROOT/lib/_shared.sh"
  
  local result
  result=$(_dotfiles_full_path "untracked_dir")
  assert_equal "$result" "untracked_dir"
}
