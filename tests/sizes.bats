# covers: lib/sizes.sh
# tests/sizes.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  cd "$BATS_TEST_TMPDIR"
  mkdir -p "my dir"
  touch "my dir/a b.txt" "my dir/c.txt" plain.txt
  du() { printf '[%s]' "$@"; }
}

@test "sizes: lists the entries of a directory, keeping spaces intact" {
  run sizes "my dir"
  assert_success
  assert_output "[-sh][--][my dir/a b.txt][my dir/c.txt]"
}

@test "sizes: accepts a trailing slash" {
  run sizes "my dir/"
  assert_success
  assert_output "[-sh][--][my dir/a b.txt][my dir/c.txt]"
}

@test "sizes: measures a plain file argument itself" {
  run sizes plain.txt
  assert_success
  assert_output "[-sh][--][plain.txt]"
}

@test "sizes: expands a quoted glob instead of appending another one" {
  run sizes 'my dir/*'
  assert_success
  assert_output "[-sh][--][my dir/a b.txt][my dir/c.txt]"
}

@test "sizes: passes multiple arguments through unchanged" {
  run sizes "my dir" plain.txt
  assert_success
  assert_output "[-sh][--][my dir][plain.txt]"
}

@test "sizes: defaults to the entries of the current directory" {
  run sizes
  assert_success
  assert_output "[-sh][--][my dir][plain.txt]"
}
