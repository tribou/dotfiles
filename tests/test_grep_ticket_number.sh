#!/bin/bash

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
. "$THIS_DIR/../lib/_shared.sh"
. "$THIS_DIR/../lib/commands.sh"

##
# $1: EXPECTED
# $2: ACTUAL
# $3: LINENO
# $4: ERROR_MESSAGE
##
function assert_equals() {
  local EXPECTED=${1}
  local ACTUAL=${2}
  local LINE_NO="${3}:"
	local DEFAULT_ERROR_MESSAGE="ACTUAL '${ACTUAL}' not equal to EXPECTED '${EXPECTED}'"
  local ERROR_MESSAGE="❌ ${LINE_NO} ${4:-$DEFAULT_ERROR_MESSAGE}"
	set -e
	# Assert both equal
	[ "$EXPECTED" == "$ACTUAL" ] \
		|| (echo "$ERROR_MESSAGE" && echo && \
			git diff "$(echo "$EXPECTED" | git hash-object -w --stdin)" "$(echo "$ACTUAL" | git hash-object -w --stdin)" \
			--color-words="[^[:space:]]|([[:alnum:]]|UTF_8_GUARD)+" \
			| tail -n +6 && echo && exit 1)
	set +e
}

function test_all() {
	local ACTUAL
	local EXPECTED

	ACTUAL=$(echo "ABC-123" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "ABC-123456" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123456"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "ABC-1234567" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-1234567"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "abc-123" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "aBc-123" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "Abc-123" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "feature/ABC-123" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "ABC-123/ticket-description" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "feature/ABC-123-b" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "feature/test-1234-b" | _dotfiles_grep_ticket_number)
	EXPECTED="TEST-1234"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "origin/abc-1234567" | _dotfiles_grep_ticket_number)
	EXPECTED="ABC-1234567"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "ab123-desc-here" | _dotfiles_grep_ticket_number)
	EXPECTED="AB123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "bug/123_AT_TestDesc" | _dotfiles_grep_ticket_number)
	EXPECTED="DCX123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "feature/123_AT_TestDesc" | _dotfiles_grep_ticket_number)
	EXPECTED="DCX123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "patch/123_AT_TestDesc" | _dotfiles_grep_ticket_number)
	EXPECTED="DCX123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	## Falsy cases
	ACTUAL=$(echo "develop" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "main" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "hi" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "origin/develop" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "string and spaces" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "abc123" | _dotfiles_grep_ticket_number)
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "bug/a2-123-some-description" | _dotfiles_grep_ticket_number)
	EXPECTED="A2-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "super-123" | _dotfiles_grep_ticket_number)
	EXPECTED="SUPER-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(echo "super-123-with-desc-hr" | _dotfiles_grep_ticket_number)
	EXPECTED="SUPER-123"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO
}

test_all

echo
echo "✅ All tests passed!"
echo

unset THIS_DIR
unset -f assert_equals
unset -f test_all
