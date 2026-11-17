# covers: lib/command_reference.sh
# tests/command_reference.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  fzf() { cat; }
  tput() { :; }
}

@test "command_reference: does not leak REFERENCE_MESSAGE into the shell" {
  unset REFERENCE_MESSAGE
  command_reference > /dev/null
  vim_reference > /dev/null
  [ -z "${REFERENCE_MESSAGE+set}" ]
}

@test "command_reference: no longer lists docker-machine" {
  run command_reference
  refute_output --partial "docker-machine"
}

@test "vim_reference: lists the location list previous command as lprev" {
  run vim_reference prev
  assert_output --partial "lprev"
}
