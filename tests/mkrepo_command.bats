# tests/mkrepo_command.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "mkrepo: prints usage and fails with no argument" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    mkrepo
  "
  [ "$status" -eq 1 ]
  assert_output --partial "Usage: mkrepo <project-name>"
}

@test "mkrepo: installs all obra/superpowers and most tribou/dotfiles skills" {
  run bash -c "
    tmp=\$(mktemp -d)
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"git \$*\"; }
    gh() { echo \"gh \$*\"; }
    npx() { echo \"npx \$*\"; }
    mkrepo \"\$tmp/myrepo\" 2>&1
  "
  assert_success
  assert_output --partial "npx --yes skills@latest add obra/superpowers"
  assert_output --partial "--agent opencode --agent claude-code -y"
  assert_output --partial "npx --yes skills@latest add tribou/dotfiles"
  assert_output --partial "--skill brainstorming-to-issue"
  assert_output --partial "--skill issue-to-plan"
  assert_output --partial "--skill organize-ai-context"
  assert_output --partial "--skill plan-to-implementation"
  assert_output --partial "--skill prd"
  refute_output --partial "blending-textured-backgrounds"
}

@test "mkrepo: commits and pushes skills after successful install" {
  run bash -c "
    tmp=\$(mktemp -d)
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"git \$*\"; }
    gh() { echo \"gh \$*\"; }
    npx() { echo \"npx \$*\"; }
    mkrepo \"\$tmp/myrepo\" 2>&1
  "
  assert_success
  assert_line --partial "git add -A"
  assert_line --partial "git commit -m Add AI agent skills"
  assert_line --partial "git push"
}

@test "mkrepo: warns but succeeds when skill installation fails" {
  run bash -c "
    tmp=\$(mktemp -d)
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"git \$*\"; }
    gh() { echo \"gh \$*\"; }
    npx() { echo \"npx \$*\"; return 1; }
    mkrepo \"\$tmp/myrepo\" 2>&1
  "
  assert_success
  assert_output --partial "Skill installation failed"
  refute_output --partial "git commit -m Add AI agent skills"
}

@test "mkrepo: creates .gitignore and stages it in the initial commit" {
  tmp="$(mktemp -d)"
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() { echo \"git \$*\"; }
    gh() { echo \"gh \$*\"; }
    npx() { :; }
    mkrepo '$tmp/myrepo'
  "
  assert_success
  # staged alongside README in the initial commit
  assert_line --partial 'git add README.md .gitignore'
  assert_line --partial 'git commit -m Initial commit'
  # file exists with representative entries from each category
  local ignore="$tmp/myrepo/.gitignore"
  assert [ -f "$ignore" ]
  assert grep -qFx 'node_modules/' "$ignore"
  assert grep -qFx 'coverage/' "$ignore"
  assert grep -qFx 'mise.local.toml' "$ignore"
  assert grep -qFx '.env' "$ignore"
  assert grep -qFx '.env.local' "$ignore"
  assert grep -qFx '*.swp' "$ignore"
  assert grep -qFx '.DS_Store' "$ignore"
  assert grep -qFx '.opencode/local/' "$ignore"
  assert grep -qFx '.worktrees/' "$ignore"
}
