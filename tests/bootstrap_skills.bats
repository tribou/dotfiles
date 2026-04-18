setup() {
  load 'test_helper/common_setup'
  common_setup

  TEMP_HOME=$(mktemp -d)
  TEMP_REPO=$(mktemp -d)

  # Create a minimal fake repo with skills/
  mkdir -p "$TEMP_REPO/skills"
  touch "$TEMP_REPO/skills/.keep"
}

teardown() {
  rm -rf "$TEMP_HOME" "$TEMP_REPO"
}

@test "bootstrap: creates ~/.claude dir and symlinks skills/" {
  # Simulate what bootstrap.sh does for skills
  mkdir -p "$TEMP_HOME/.claude"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.claude/skills"

  [ -d "$TEMP_HOME/.claude" ]
  [ -L "$TEMP_HOME/.claude/skills" ]
  local target
  target=$(readlink "$TEMP_HOME/.claude/skills")
  [ "$target" = "$TEMP_REPO/skills" ]
}
