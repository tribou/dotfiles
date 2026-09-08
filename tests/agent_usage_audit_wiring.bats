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

@test "brainstorming-to-issue: Finalize → Ready is a six-step sequence" {
  run grep -Fq "## Finalize → Ready (all 6 steps, in order)" \
    "$REPO_ROOT/skills/brainstorming-to-issue/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "brainstorming-to-issue: invokes the audit sub-skill for its own stage and target" {
  skill="$REPO_ROOT/skills/brainstorming-to-issue/SKILL.md"
  run grep -Fq "agent-usage-audit" "$skill"
  [ "$status" -eq 0 ]
  run grep -Fq -- "--stage brainstorming-to-issue" "$skill"
  [ "$status" -eq 0 ]
  run grep -Fq -- "--target issue:<N>" "$skill"
  [ "$status" -eq 0 ]
}

@test "brainstorming-to-issue: copies stay byte-identical" {
  run diff -r "$REPO_ROOT/skills/brainstorming-to-issue" \
    "$REPO_ROOT/.agents/skills/brainstorming-to-issue"
  [ "$status" -eq 0 ]
}

@test "issue-to-plan: Publish the Durable Handoff is a nine-step sequence" {
  run grep -Fq "## Publish the Durable Handoff (all 9 steps, in order)" \
    "$REPO_ROOT/skills/issue-to-plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "issue-to-plan: invokes the audit sub-skill for its own stage and target" {
  skill="$REPO_ROOT/skills/issue-to-plan/SKILL.md"
  run grep -Fq "agent-usage-audit" "$skill"
  [ "$status" -eq 0 ]
  run grep -Fq -- "--stage issue-to-plan" "$skill"
  [ "$status" -eq 0 ]
  run grep -Fq -- "--target pr:<M>" "$skill"
  [ "$status" -eq 0 ]
}

@test "issue-to-plan: copies stay byte-identical" {
  run diff -r "$REPO_ROOT/skills/issue-to-plan" "$REPO_ROOT/.agents/skills/issue-to-plan"
  [ "$status" -eq 0 ]
}
