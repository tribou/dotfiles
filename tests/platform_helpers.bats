setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "platform: is_macos returns true on Darwin" {
  run env OSTYPE=darwin20 bash -c "
    uname() { echo 'Darwin'; }
    export -f uname
    . '$REPO_ROOT/lib/platform.sh'
    is_macos && echo 'yes' || echo 'no'
  "
  assert_output "yes"
}

@test "platform: is_macos returns false on Linux" {
  run env OSTYPE=linux-gnu bash -c "
    uname() { echo 'Linux'; }
    export -f uname
    . '$REPO_ROOT/lib/platform.sh'
    is_macos && echo 'yes' || echo 'no'
  "
  assert_output "no"
}

@test "platform: is_linux returns true on Linux" {
  run env OSTYPE=linux-gnu bash -c "
    uname() { echo 'Linux'; }
    export -f uname
    . '$REPO_ROOT/lib/platform.sh'
    is_linux && echo 'yes' || echo 'no'
  "
  assert_output "yes"
}

@test "platform: is_linux returns false on Darwin" {
  run env OSTYPE=darwin20 bash -c "
    uname() { echo 'Darwin'; }
    export -f uname
    . '$REPO_ROOT/lib/platform.sh'
    is_linux && echo 'yes' || echo 'no'
  "
  assert_output "no"
}
