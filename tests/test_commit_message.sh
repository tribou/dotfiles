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
	local PREV_DOTFILES_COMMIT_SEPARATOR
	if [ -n "$DOTFILES_COMMIT_SEPARATOR" ]
	then
		local PREV_DOTFILES_COMMIT_SEPARATOR=${DOTFILES_COMMIT_SEPARATOR}
	fi

	# default
	DOTFILES_COMMIT_SEPARATOR=":"

	ACTUAL=$(_dotfiles_commit_message "ABC-123" "test commit message")
	EXPECTED="ABC-123: test commit message"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(_dotfiles_commit_message "SOME_TIX_NUM" "test commit message")
	EXPECTED="SOME_TIX_NUM: test commit message"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(_dotfiles_commit_message "SOME_TIX_NUM" "")
	EXPECTED="SOME_TIX_NUM: "
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	ACTUAL=$(_dotfiles_commit_message "" "test message")
	EXPECTED="test message"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	DOTFILES_COMMIT_SEPARATOR=" -"

	ACTUAL=$(_dotfiles_commit_message "123" "test commit message")
	EXPECTED="123 - test commit message"
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	## Falsy cases
	ACTUAL=$(_dotfiles_commit_message "" "")
	EXPECTED=""
	assert_equals "$EXPECTED" "$ACTUAL" $LINENO

	if [ -n "$PREV_DOTFILES_COMMIT_SEPARATOR" ]
	then
		DOTFILES_COMMIT_SEPARATOR=${PREV_DOTFILES_COMMIT_SEPARATOR}
	fi
}

test_all

echo
echo "✅ All tests passed!"
echo

unset THIS_DIR
unset -f assert_equals
unset -f test_all
