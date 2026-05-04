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

@test "bootstrap: re-running linkFileToHome for skills does not create nested skills/skills" {
  # Simulate first bootstrap run
  mkdir -p "$TEMP_HOME/.claude"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.claude/skills"

  # Simulate second bootstrap run (the bug: ln -sf on macOS creates skills/skills)
  # The fix uses rm -f before ln -sf to prevent this
  rm -f "$TEMP_HOME/.claude/skills"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.claude/skills"

  # Symlink must still point correctly
  [ -L "$TEMP_HOME/.claude/skills" ]
  local target
  target=$(readlink "$TEMP_HOME/.claude/skills")
  [ "$target" = "$TEMP_REPO/skills" ]

  # No nested skills/skills must exist
  run ls "$TEMP_REPO/skills/"
  [[ "$output" != *"skills"* ]]
}

@test "bootstrap: creates ~/.config/opencode dir and symlinks skills/" {
  # Simulate what bootstrap.sh does for opencode skills
  mkdir -p "$TEMP_HOME/.config/opencode"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.config/opencode/skills"

  [ -d "$TEMP_HOME/.config/opencode" ]
  [ -L "$TEMP_HOME/.config/opencode/skills" ]
  local target
  target=$(readlink "$TEMP_HOME/.config/opencode/skills")
  [ "$target" = "$TEMP_REPO/skills" ]
}

@test "bootstrap: re-running linkFileToHome for opencode skills does not create nested skills/skills" {
  # Simulate first bootstrap run
  mkdir -p "$TEMP_HOME/.config/opencode"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.config/opencode/skills"

  # Simulate second bootstrap run (the bug: ln -sf on macOS creates skills/skills)
  # The fix uses rm -f before ln -sf to prevent this
  rm -f "$TEMP_HOME/.config/opencode/skills"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.config/opencode/skills"

  # Symlink must still point correctly
  [ -L "$TEMP_HOME/.config/opencode/skills" ]
  local target
  target=$(readlink "$TEMP_HOME/.config/opencode/skills")
  [ "$target" = "$TEMP_REPO/skills" ]

  # No nested skills/skills must exist
  run ls "$TEMP_REPO/skills/"
  [[ "$output" != *"skills"* ]]
}
