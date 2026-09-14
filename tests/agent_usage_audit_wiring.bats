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

@test "agent-usage-audit: SKILL.md documents all three current workflow stages" {
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

@test "agent-usage-audit: skills lock records the repo skill" {
  run bun -e '
    const lock = await Bun.file(process.argv[1]).json();
    const skill = lock.skills?.["agent-usage-audit"];
    if (skill?.source !== "tribou/dotfiles" ||
        skill?.sourceType !== "github" ||
        skill?.skillPath !== "skills/agent-usage-audit/SKILL.md" ||
        !skill?.computedHash) process.exit(1);
  ' "$REPO_ROOT/skills-lock.json"
  [ "$status" -eq 0 ]
}

@test "brainstorming-to-issue: Finalize → Ready is a six-step sequence" {
  run grep -Fq "## Finalize → Ready (all 6 steps, in order)" \
    "$REPO_ROOT/skills/brainstorming-to-issue/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "brainstorming-to-issue: invokes the audit sub-skill for its own stage and target" {
  skill="$REPO_ROOT/skills/brainstorming-to-issue/SKILL.md"
  run grep -Fxq '2. **Strip the `[DRAFT]` prefix** from the title.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '4. **REQUIRED SUB-SKILL:** `agent-usage-audit` — record this stage with `--stage brainstorming-to-issue --target issue:<N>`, after the prefix is stripped and before the URL is shown. A failed audit is reported, never a reason to stop finalizing.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '5. **Show the user the issue URL** and ask them to review. If they request changes, edit and re-run the self-review. This is the spec review gate — keep it.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '| Finalizing without recording the stage'"'"'s agent usage | Run `agent-usage-audit` with `--stage brainstorming-to-issue --target issue:<N>` after stripping `[DRAFT]`, before showing the URL |' "$skill"
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
  run grep -Fxq '5. Verify the published PR: state OPEN, `isDraft` true, and exactly one comment containing the ordered marker pair with the complete plan between them.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '6. **REQUIRED SUB-SKILL:** `agent-usage-audit` — record this stage with `--stage issue-to-plan --target pr:<M>`. Post it after the verification in step 5 so that check reads exactly one comment containing the ordered plan-marker pair. A failed audit is reported, never a reason to skip the handoff.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '7. Print the PR URL.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '| Printing the handoff without recording agent usage | Run `agent-usage-audit` with `--stage issue-to-plan --target pr:<M>` after PR verification, before printing the URL |' "$skill"
  [ "$status" -eq 0 ]
}

@test "issue-to-plan: copies stay byte-identical" {
  run diff -r "$REPO_ROOT/skills/issue-to-plan" "$REPO_ROOT/.agents/skills/issue-to-plan"
  [ "$status" -eq 0 ]
}

@test "plan-to-implementation: both the blocker and finish paths gained a step" {
  skill="$REPO_ROOT/skills/plan-to-implementation/SKILL.md"
  run grep -Fq "## Mid-execution blocker (implementer BLOCKED, or review finding needs a human — all 7 steps, in order)" "$skill"
  [ "$status" -eq 0 ]
  run grep -Fq "## Successful finish (all 7 steps, in order)" "$skill"
  [ "$status" -eq 0 ]
}

@test "plan-to-implementation: invokes the audit sub-skill for its own stage and target" {
  skill="$REPO_ROOT/skills/plan-to-implementation/SKILL.md"
  run grep -Fxq '6. **REQUIRED SUB-SKILL:** `agent-usage-audit` — record this stage with `--stage plan-to-implementation --target pr:<M>` before stopping. Blocked work still gets a row; an honest partial trail beats a missing one.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '7. Stop. Never open a second PR or reset the issue for a blocker.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '5. **REQUIRED SUB-SKILL:** `agent-usage-audit` — record this stage with `--stage plan-to-implementation --target pr:<M>` before flipping the PR ready. It adds a row to the audit comment `issue-to-plan` already created on this PR — never a second comment. A failed audit is reported, never a reason to leave the PR draft.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '6. Push the branch, then run `gh pr ready <M>` on the existing draft PR — in that order.' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '| Flipping the PR ready without recording agent usage | Run `agent-usage-audit` with `--stage plan-to-implementation --target pr:<M>` before `gh pr ready` |' "$skill"
  [ "$status" -eq 0 ]
  run grep -Fxq '| Skipping the audit because execution ended blocked | Blocked work still gets a row — record it before stopping |' "$skill"
  [ "$status" -eq 0 ]
}

@test "plan-to-implementation: copies stay byte-identical" {
  run diff -r "$REPO_ROOT/skills/plan-to-implementation" \
    "$REPO_ROOT/.agents/skills/plan-to-implementation"
  [ "$status" -eq 0 ]
}
