#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup

  SCRIPT="$REPO_ROOT/skills/agent-usage-audit/scripts/agent-usage-audit"
  FIXTURES="$BATS_TEST_TMPDIR/fixtures"
  mkdir -p "$FIXTURES"

  # Never let the developer's real harness environment leak into a test.
  unset CLAUDECODE CLAUDE_CODE_SESSION_ID
  unset OPENCODE OPENCODE_SESSION_ID
  unset AGY_CONVERSATION_ID ANTIGRAVITY_CONVERSATION_ID
  unset AGENT_USAGE_AUDIT_HARNESS AGENT_USAGE_AUDIT_SESSION_ID

  export AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR="$FIXTURES/claude-projects"
  export AGENT_USAGE_AUDIT_OPENCODE_DB="$FIXTURES/opencode.db"
  export AGENT_USAGE_AUDIT_AGY_DIR="$FIXTURES/agy"

  # Adapter tests must be deterministic even on machines that have ccusage.
  export AGENT_USAGE_AUDIT_DISABLE_CCUSAGE=1
}

# Read one dotted key out of the JSON on stdout of the last `run`.
json_field() {
  printf '%s' "$output" | AUDIT_JSON_FIELD="$1" bun -e '
    Bun.stdin.text().then((text) => {
      let node = JSON.parse(text);
      for (const part of (process.env.AUDIT_JSON_FIELD ?? "").split(".").filter(Boolean)) {
        node = Array.isArray(node) ? node[Number(part)] : node[part];
      }
      console.log(node === undefined || node === null ? "" : node);
    });
  '
}

@test "agent-usage-audit: script is executable" {
  [ -x "$SCRIPT" ]
}

@test "probe: unknown harness yields an unavailable record, never fabricated numbers" {
  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [ "$(json_field harness)" = "unknown" ]
  [ "$(json_field tokens.total)" = "0" ]
  [ -n "$(json_field reason)" ]
}

@test "probe: record carries schema, stage and an ISO-8601 UTC timestamp" {
  export AGENT_USAGE_AUDIT_HARNESS="claude-code"
  export AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001"
  run bun "$SCRIPT" probe --stage brainstorming-to-issue
  [ "$status" -eq 0 ]
  [ "$(json_field schema)" = "1" ]
  [ "$(json_field stage)" = "brainstorming-to-issue" ]
  [ "$(json_field session_id)" = "sess-cc-0001" ]
  [[ "$(json_field updated_at)" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "probe: --session overrides environment detection" {
  export AGENT_USAGE_AUDIT_SESSION_ID="from-env"
  run bun "$SCRIPT" probe --stage issue-to-plan --session from-flag
  [ "$status" -eq 0 ]
  [ "$(json_field session_id)" = "from-flag" ]
}

@test "probe: rejects an unknown stage" {
  run bun "$SCRIPT" probe --stage not-a-stage
  [ "$status" -ne 0 ]
}

@test "detect_harness: CLAUDECODE marker selects the claude-code harness" {
  export CLAUDECODE=1
  export CLAUDE_CODE_SESSION_ID="sess-cc-0001"
  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "claude-code" ]
}

@test "detect_harness: OPENCODE marker selects the opencode harness" {
  export OPENCODE=1
  export OPENCODE_SESSION_ID="ses_fixture_parent"
  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "opencode" ]
}

install_claude_fixture() {
  local dir="$AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR/-fixture-project"
  mkdir -p "$dir"
  cp "$REPO_ROOT/tests/fixtures/agent-usage-audit/claude-code-session.jsonl" \
    "$dir/sess-cc-0001.jsonl"
}

@test "claude-code adapter: dedups repeated streaming rows by (message id, request id)" {
  install_claude_fixture
  export AGENT_USAGE_AUDIT_HARNESS="claude-code"
  export AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001"

  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.input)" = "16" ]
  [ "$(json_field tokens.output)" = "307" ]
  [ "$(json_field tokens.cache_read)" = "3300" ]
  [ "$(json_field tokens.cache_write)" = "78" ]
  [ "$(json_field tokens.reasoning)" = "52" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "claude-code adapter: subagent usage rolls up and is itemized in children" {
  install_claude_fixture
  export AGENT_USAGE_AUDIT_HARNESS="claude-code"
  export AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001"

  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field children.0.tokens.output)" = "7" ]
  [ "$(json_field children.0.tokens.cache_read)" = "300" ]
  [ "$(json_field children.0.models.0)" = "claude-sonnet-5" ]
  [ "$(json_field models.0)" = "claude-opus-5" ]
  [ "$(json_field models.1)" = "claude-sonnet-5" ]
}

@test "claude-code adapter: a missing transcript is unavailable, not zero-filled truth" {
  export AGENT_USAGE_AUDIT_HARNESS="claude-code"
  export AGENT_USAGE_AUDIT_SESSION_ID="sess-does-not-exist"

  run bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"transcript"* ]]
}
