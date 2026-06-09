setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "_eval_script: when TMUX is not set, prints and evaluates the script" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"echo 'hello'\"
  "
  assert_success
  assert_line --index 0 "echo 'hello'"
  assert_line --index 1 "hello"
}

@test "_eval_script: when TMUX is set, uses tmux send-keys to execute in target pane" {
  run bash -c "
    export TMUX=\"yes\"
    export TMUX_PANE=\"%1\"
    tmux() { echo \"tmux \$*\"; }
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"echo 'hello'\"
  "
  assert_success
  assert_output "tmux send-keys -t %1 echo 'hello' Enter"
}

@test "_eval_script: when TMUX is set, formats command with target pane and sends Enter" {
  run bash -c "
    export TMUX=\"yes\"
    export TMUX_PANE=\"%2\"
    tmux() { echo \"tmux \$*\"; }
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"git status\"
  "
  assert_success
  assert_output "tmux send-keys -t %2 git status Enter"
}

@test "_eval_script: executes multi-statement commands correctly under eval" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"VAL=abc && echo \\\$VAL\"
  "
  assert_success
  assert_line --index 0 "VAL=abc && echo \$VAL"
  assert_line --index 1 "abc"
}

@test "_eval_script: propagates exit code of evaluated script in non-TMUX mode" {
  run bash -c "
    unset TMUX
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"false\"
  "
  assert_failure
}

@test "_eval_script: propagates failure of tmux command in TMUX mode" {
  run bash -c "
    export TMUX=\"yes\"
    export TMUX_PANE=\"%1\"
    tmux() { return 99; }
    . '$REPO_ROOT/lib/_shared.sh'
    _eval_script \"echo 'hello'\"
  "
  assert_failure
  [ "$status" -eq 99 ]
}
