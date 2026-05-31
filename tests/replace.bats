# tests/replace.bats

setup() {
  load 'test_helper/common_setup'
  common_setup

  # Create a temp git repo for replace tests
  TEMP_REPO=$(mktemp -d)
  git -C "$TEMP_REPO" init -q
  git -C "$TEMP_REPO" config user.email "test@test.com"
  git -C "$TEMP_REPO" config user.name "Test"
}

teardown() {
  cd "$BATS_TEST_DIRNAME"
  rm -rf "$TEMP_REPO"
}

@test "replace: replaces pattern in a git-tracked file and does not delete unrelated .bak files" {
  cd "$TEMP_REPO"

  # Create a file and track it
  echo "hello world" > test.txt
  git add test.txt
  git commit -m "add test"

  # Create an unrelated .bak file
  echo "preserve me" > unrelated.bak
  git add unrelated.bak
  git commit -m "add unrelated bak"

  # Source the replace script explicitly
  . "$REPO_ROOT/lib/replace.sh"

  # Perform replacement
  run replace "world" "earth"
  assert_success

  # Verify the replacement succeeded
  run cat test.txt
  assert_output "hello earth"

  # Verify that the unrelated .bak file was NOT deleted
  [ -f unrelated.bak ]
  run cat unrelated.bak
  assert_output "preserve me"
}
