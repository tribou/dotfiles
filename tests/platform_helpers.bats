setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "platform: is_macos returns true on Darwin" {
  run bash -c "
    OSTYPE=darwin20
    . '$REPO_ROOT/lib/platform.sh'
    is_macos && echo 'yes' || echo 'no'
  "
  assert_output "yes"
}

@test "platform: is_macos returns false on Linux" {
  run bash -c "
    OSTYPE=linux-gnu
    . '$REPO_ROOT/lib/platform.sh'
    is_macos && echo 'yes' || echo 'no'
  "
  assert_output "no"
}

@test "platform: is_linux returns true on Linux" {
  run bash -c "
    OSTYPE=linux-gnu
    . '$REPO_ROOT/lib/platform.sh'
    is_linux && echo 'yes' || echo 'no'
  "
  assert_output "yes"
}

@test "platform: is_linux returns false on Darwin" {
  run bash -c "
    OSTYPE=darwin20
    . '$REPO_ROOT/lib/platform.sh'
    is_linux && echo 'yes' || echo 'no'
  "
  assert_output "no"
}
