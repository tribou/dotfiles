setup() {
  load 'test_helper/common_setup'
  common_setup
}

# --- Standard ABC-123 format ---
@test "ABC-123 extracts correctly" {
  run bash -c 'echo "ABC-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "ABC-123456 (6 digits) extracts correctly" {
  run bash -c 'echo "ABC-123456" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123456"
}

@test "ABC-1234567 (7 digits) extracts correctly" {
  run bash -c 'echo "ABC-1234567" | _dotfiles_grep_ticket_number'
  assert_output "ABC-1234567"
}

# --- Case normalization ---
@test "abc-123 normalizes to ABC-123" {
  run bash -c 'echo "abc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "aBc-123 normalizes to ABC-123" {
  run bash -c 'echo "aBc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "Abc-123 normalizes to ABC-123" {
  run bash -c 'echo "Abc-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

# --- Branch prefix stripping ---
@test "feature/ABC-123 strips prefix" {
  run bash -c 'echo "feature/ABC-123" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "origin/abc-1234567 strips remote prefix" {
  run bash -c 'echo "origin/abc-1234567" | _dotfiles_grep_ticket_number'
  assert_output "ABC-1234567"
}

# --- Description suffix stripping ---
@test "ABC-123/ticket-description strips suffix" {
  run bash -c 'echo "ABC-123/ticket-description" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "feature/ABC-123-b strips trailing suffix" {
  run bash -c 'echo "feature/ABC-123-b" | _dotfiles_grep_ticket_number'
  assert_output "ABC-123"
}

@test "feature/test-1234-b normalizes and strips" {
  run bash -c 'echo "feature/test-1234-b" | _dotfiles_grep_ticket_number'
  assert_output "TEST-1234"
}

# --- 2-letter compact format (ab123) ---
@test "ab123-desc-here extracts AB123" {
  run bash -c 'echo "ab123-desc-here" | _dotfiles_grep_ticket_number'
  assert_output "AB123"
}

@test "bug/a2-123-some-description extracts A2-123" {
  run bash -c 'echo "bug/a2-123-some-description" | _dotfiles_grep_ticket_number'
  assert_output "A2-123"
}

# --- Multi-word prefix format (super-123) ---
@test "super-123 extracts SUPER-123" {
  run bash -c 'echo "super-123" | _dotfiles_grep_ticket_number'
  assert_output "SUPER-123"
}

@test "super-123-with-desc-hr extracts SUPER-123" {
  run bash -c 'echo "super-123-with-desc-hr" | _dotfiles_grep_ticket_number'
  assert_output "SUPER-123"
}

# --- DCX format (123_AT_Description) ---
@test "bug/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "bug/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

@test "feature/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "feature/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

@test "patch/123_AT_TestDesc extracts DCX123" {
  run bash -c 'echo "patch/123_AT_TestDesc" | _dotfiles_grep_ticket_number'
  assert_output "DCX123"
}

# --- Falsy cases (returns empty) ---
@test "develop returns empty" {
  run bash -c 'echo "develop" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "main returns empty" {
  run bash -c 'echo "main" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "hi returns empty" {
  run bash -c 'echo "hi" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "origin/develop returns empty" {
  run bash -c 'echo "origin/develop" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "string with spaces returns empty" {
  run bash -c 'echo "string and spaces" | _dotfiles_grep_ticket_number'
  assert_output ""
}

@test "abc123 (no separator) returns empty" {
  run bash -c 'echo "abc123" | _dotfiles_grep_ticket_number'
  assert_output ""
}
