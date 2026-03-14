setup() {
  load 'test_helper/common_setup'
  common_setup
  # Save and reset separator for each test
  _ORIG_SEP="${DOTFILES_COMMIT_SEPARATOR:-}"
  DOTFILES_COMMIT_SEPARATOR=":"
}

teardown() {
  DOTFILES_COMMIT_SEPARATOR="$_ORIG_SEP"
}

# --- Default separator (:) ---
@test "ticket + message formats with colon separator" {
  run _dotfiles_commit_message "ABC-123" "test commit message"
  assert_output "ABC-123: test commit message"
}

@test "underscore ticket formats with colon separator" {
  run _dotfiles_commit_message "SOME_TIX_NUM" "test commit message"
  assert_output "SOME_TIX_NUM: test commit message"
}

@test "ticket with empty message includes trailing space" {
  run _dotfiles_commit_message "SOME_TIX_NUM" ""
  assert_output "SOME_TIX_NUM: "
}

@test "empty ticket uses message only (no separator)" {
  run _dotfiles_commit_message "" "test message"
  assert_output "test message"
}

@test "both empty returns empty string" {
  run _dotfiles_commit_message "" ""
  assert_output ""
}

# --- Custom separator ---
@test "custom space-dash separator formats correctly" {
  DOTFILES_COMMIT_SEPARATOR=" -"
  run _dotfiles_commit_message "123" "test commit message"
  assert_output "123 - test commit message"
}
