#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "agent-usage-audit: SKILL.md exists with a matching frontmatter name" {
  [ -f "$REPO_ROOT/skills/agent-usage-audit/SKILL.md" ]
  run grep -Fxq "name: agent-usage-audit" "$REPO_ROOT/skills/agent-usage-audit/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "agent-usage-audit: SKILL.md sits beside the support script it documents" {
  [ -x "$REPO_ROOT/skills/agent-usage-audit/scripts/agent-usage-audit" ]
  run grep -Fq "scripts/agent-usage-audit" "$REPO_ROOT/skills/agent-usage-audit/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "agent-usage-audit: SKILL.md documents both audit comment markers" {
  run grep -Fq "<!-- BEGIN AGENT USAGE -->" "$REPO_ROOT/skills/agent-usage-audit/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -Fq "<!-- END AGENT USAGE -->" "$REPO_ROOT/skills/agent-usage-audit/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "agent-usage-audit: SKILL.md documents all three stage strings" {
  for stage in brainstorming-to-issue issue-to-plan plan-to-implementation; do
    run grep -Fq -- "--stage $stage" "$REPO_ROOT/skills/agent-usage-audit/SKILL.md"
    [ "$status" -eq 0 ]
  done
}

@test "agent-usage-audit: .agents/skills entry is a relative symlink to the repo skill" {
  [ -L "$REPO_ROOT/.agents/skills/agent-usage-audit" ]
  [ "$(readlink "$REPO_ROOT/.agents/skills/agent-usage-audit")" = "../../skills/agent-usage-audit" ]
  [ -f "$REPO_ROOT/.agents/skills/agent-usage-audit/SKILL.md" ]
}

@test "agent-usage-audit: .claude/skills entry chains through .agents/skills" {
  [ -L "$REPO_ROOT/.claude/skills/agent-usage-audit" ]
  [ "$(readlink "$REPO_ROOT/.claude/skills/agent-usage-audit")" = "../../.agents/skills/agent-usage-audit" ]
  [ -f "$REPO_ROOT/.claude/skills/agent-usage-audit/SKILL.md" ]
}
