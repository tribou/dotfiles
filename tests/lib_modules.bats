setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "lib/index.sh sources all 8 command modules" {
  run bash -c "
    export DOTFILES=\"\$REPO_ROOT\"
    . \"\$REPO_ROOT/lib/index.sh\"

    # Check key functions from each module
    type c >/dev/null 2>&1 || exit 1          # git.sh
    type nu >/dev/null 2>&1 || exit 2         # npm.sh
    type restart-docker >/dev/null 2>&1 || exit 3 # docker.sh
    type tmux-large >/dev/null 2>&1 || exit 4 # tmux.sh
    type aws-profile >/dev/null 2>&1 || exit 5 # cloud.sh
    type mkrepo >/dev/null 2>&1 || exit 6      # repo.sh
    type claude-keepalive >/dev/null 2>&1 || exit 7 # agent.sh
    type bashcheck >/dev/null 2>&1 || exit 8   # commands.sh
  "
  assert_success
}

@test "lib/commands.sh is under 300 physical lines" {
  local count
  count=$(wc -l < "$REPO_ROOT/lib/commands.sh")
  [ "$count" -le 300 ]
}

@test "each extracted module can be sourced cleanly without errors" {
  for mod in agent.sh docker.sh tmux.sh cloud.sh repo.sh npm.sh git.sh commands.sh; do
    run bash -c "
      export DOTFILES=\"\$REPO_ROOT\"
      . \"\$REPO_ROOT/lib/_shared.sh\"
      . \"\$REPO_ROOT/lib/$mod\"
    "
    assert_success
  done
}
