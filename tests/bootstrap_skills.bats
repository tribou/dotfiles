setup() {
  load 'test_helper/common_setup'
  common_setup

  TEMP_HOME=$(mktemp -d)
  TEMP_REPO=$(mktemp -d)

  # Create a minimal fake repo with skills/
  mkdir -p "$TEMP_REPO/skills/skill-a"
  mkdir -p "$TEMP_REPO/skills/skill-b"
  touch "$TEMP_REPO/skills/skill-a/SKILL.md"
  touch "$TEMP_REPO/skills/skill-b/SKILL.md"

  # Extract linkSkillsDir from bootstrap.sh and define it
  eval "$(sed -n '/^function linkSkillsDir/,/^}/p' "$BATS_TEST_DIRNAME/../bootstrap.sh")"
}

teardown() {
  rm -rf "$TEMP_HOME" "$TEMP_REPO"
}

@test "linkSkillsDir: creates individual symlinks in target directory" {
  run linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"

  [ -d "$TEMP_HOME/.test/skills" ]
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  [ -L "$TEMP_HOME/.test/skills/skill-b" ]
  local target_a
  target_a=$(readlink "$TEMP_HOME/.test/skills/skill-a")
  [ "$target_a" = "$TEMP_REPO/skills/skill-a" ]
  [[ "$output" == *"Creating a symlink for"*"skill-a"* ]]
  [[ "$output" == *"Creating a symlink for"*"skill-b"* ]]
}

@test "linkSkillsDir: preserves existing non-symlink contents in target" {
  # Setup: target has a real directory (built-in skill) and a file
  mkdir -p "$TEMP_HOME/.test/skills"
  mkdir -p "$TEMP_HOME/.test/skills/built-in"
  touch "$TEMP_HOME/.test/skills/built-in/SKILL.md"
  touch "$TEMP_HOME/.test/skills/other-file"

  linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"

  # Built-in directory should still exist
  [ -d "$TEMP_HOME/.test/skills/built-in" ]
  [ -f "$TEMP_HOME/.test/skills/built-in/SKILL.md" ]
  # Other file should still exist
  [ -f "$TEMP_HOME/.test/skills/other-file" ]
  # Dotfiles skills should be symlinks
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  [ -L "$TEMP_HOME/.test/skills/skill-b" ]
}

@test "linkSkillsDir: overwrites existing built-in skills with dotfiles version" {
  # Setup: target has an old version of skill-a as a real directory
  mkdir -p "$TEMP_HOME/.test/skills"
  mkdir -p "$TEMP_HOME/.test/skills/skill-a"
  touch "$TEMP_HOME/.test/skills/skill-a/OLD.md"

  linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"

  # Should now be a symlink to dotfiles version
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  local target
  target=$(readlink "$TEMP_HOME/.test/skills/skill-a")
  [ "$target" = "$TEMP_REPO/skills/skill-a" ]
  # Old file should be gone
  [ ! -f "$TEMP_HOME/.test/skills/skill-a/OLD.md" ]
  [ -f "$TEMP_HOME/.test/skills/skill-a/SKILL.md" ]
}

@test "linkSkillsDir: removes stale symlinks for deleted skills" {
  # First run: create all symlinks
  linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  [ -L "$TEMP_HOME/.test/skills/skill-b" ]

  # Remove skill-b from source
  rm -rf "$TEMP_REPO/skills/skill-b"

  # Second run: should remove stale symlink
  linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  [ ! -e "$TEMP_HOME/.test/skills/skill-b" ]
}

@test "linkSkillsDir: migrates old whole-directory symlink to per-skill symlinks" {
  # Setup: old whole-directory symlink
  mkdir -p "$TEMP_HOME/.test"
  ln -sf "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"

  [ -L "$TEMP_HOME/.test/skills" ]

  linkSkillsDir "$TEMP_REPO/skills" "$TEMP_HOME/.test/skills"

  # Should now be a directory with individual symlinks
  [ -d "$TEMP_HOME/.test/skills" ]
  [ ! -L "$TEMP_HOME/.test/skills" ]
  [ -L "$TEMP_HOME/.test/skills/skill-a" ]
  [ -L "$TEMP_HOME/.test/skills/skill-b" ]
}
