setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "passes through a clean single-line message unchanged" {
  run _dotfiles_commit_sanitize_message "fix the thing"
  assert_output "fix the thing"
}

@test "strips surrounding double quotes" {
  run _dotfiles_commit_sanitize_message '"fix the thing"'
  assert_output "fix the thing"
}

@test "strips surrounding single quotes" {
  run _dotfiles_commit_sanitize_message "'fix the thing'"
  assert_output "fix the thing"
}

@test "strips surrounding backticks" {
  # shellcheck disable=SC2016
  run _dotfiles_commit_sanitize_message '`fix the thing`'
  assert_output "fix the thing"
}

@test "strips leading and trailing whitespace" {
  run _dotfiles_commit_sanitize_message "   fix the thing   "
  assert_output "fix the thing"
}

@test "takes only the first line of multi-line output" {
  run _dotfiles_commit_sanitize_message "$(printf 'fix the thing\nsome extra explanation\nmore text')"
  assert_output "fix the thing"
}

@test "reduces multi-line quoted output to a clean single line" {
  run _dotfiles_commit_sanitize_message "$(printf '"fix(bootstrap): silence brew prompt"\nThis change updates the bootstrap script.')"
  assert_output "fix(bootstrap): silence brew prompt"
}

@test "empty input produces empty output" {
  run _dotfiles_commit_sanitize_message ""
  assert_output ""
}
