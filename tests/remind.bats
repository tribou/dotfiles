# covers: lib/remind.sh
# tests/remind.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  tput() { case "$1" in lines) echo 5 ;; cols) echo 20 ;; esac; }
}

@test "remind: centers the message on the screen" {
  run remind 'hi'
  assert_success
  assert_output $'\n         hi'
}

@test "remind: does not leak loop variables into the shell" {
  unset i X N
  remind 'hi' > /dev/null
  [ -z "${i+set}" ]
  [ -z "${X+set}" ]
}
