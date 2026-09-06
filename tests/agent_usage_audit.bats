#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup

  if ! command -v bun &>/dev/null && [ -d "$HOME/.local/share/mise/shims" ]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
  fi

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
  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-cc-0001 \
    bun "$SCRIPT" probe --stage brainstorming-to-issue
  [ "$status" -eq 0 ]
  [ "$(json_field schema)" = "1" ]
  [ "$(json_field stage)" = "brainstorming-to-issue" ]
  [ "$(json_field session_id)" = "sess-cc-0001" ]
  [[ "$(json_field updated_at)" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "probe: --session overrides environment detection" {
  run env AGENT_USAGE_AUDIT_SESSION_ID=from-env \
    bun "$SCRIPT" probe --stage issue-to-plan --session from-flag
  [ "$status" -eq 0 ]
  [ "$(json_field session_id)" = "from-flag" ]
}

@test "probe: rejects an unknown stage" {
  run bun "$SCRIPT" probe --stage not-a-stage
  [ "$status" -ne 0 ]
}

@test "detect_harness: CLAUDECODE marker selects the claude-code harness" {
  run env CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=sess-cc-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "claude-code" ]
}

@test "detect_harness: OPENCODE marker selects the opencode harness" {
  run env OPENCODE=1 OPENCODE_SESSION_ID=ses_fixture_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "opencode" ]
}

install_claude_fixture() {
  local dir="$AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR/-fixture-project"
  mkdir -p "$dir"
  cp "$REPO_ROOT/tests/fixtures/agent-usage-audit/claude-code-session.jsonl" \
    "$dir/sess-cc-0001.jsonl"
}

install_opencode_fixture() {
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    opencode "$AGENT_USAGE_AUDIT_OPENCODE_DB"
}

install_agy_fixture() {
  mkdir -p "$AGENT_USAGE_AUDIT_AGY_DIR"
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    agy "$AGENT_USAGE_AUDIT_AGY_DIR/conv-0001.db"
}

@test "claude-code adapter: dedups repeated streaming rows by (message id, request id)" {
  install_claude_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-cc-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
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

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-cc-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field children.0.tokens.output)" = "7" ]
  [ "$(json_field children.0.tokens.cache_read)" = "300" ]
  [ "$(json_field children.0.models.0)" = "claude-sonnet-5" ]
  [ "$(json_field models.0)" = "claude-opus-5" ]
  [ "$(json_field models.1)" = "claude-sonnet-5" ]
}

@test "claude-code adapter: a missing transcript is unavailable, not zero-filled truth" {
  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-does-not-exist \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"transcript"* ]]
}

@test "opencode adapter: reads the session row and rolls up its child sessions" {
  install_opencode_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_fixture_parent \
    bun "$SCRIPT" probe --stage plan-to-implementation
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-opencode" ]
  # parent 120 + child 20
  [ "$(json_field tokens.input)" = "140" ]
  # (340 + 60) + (30 + 5): opencode stores reasoning separately from output
  [ "$(json_field tokens.output)" = "435" ]
  [ "$(json_field tokens.reasoning)" = "65" ]
  [ "$(json_field tokens.cache_read)" = "5900" ]
  [ "$(json_field tokens.cache_write)" = "800" ]
  [ "$(json_field tokens.total)" = "7275" ]
  [ "$(json_field children.0.session_id)" = "ses_fixture_child" ]
  [ "$(json_field children.0.tokens.input)" = "20" ]
  [ "$(json_field cost_usd)" = "0.5" ]
}

@test "opencode adapter: preserves a zero parent-plus-child cost" {
  install_opencode_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_fixture_zero_cost_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-opencode" ]
  [ "$(json_field children.0.session_id)" = "ses_fixture_zero_cost_child" ]
  [ "$(json_field cost_usd)" = "0" ]
}

@test "opencode adapter: a session id absent from the database is unavailable" {
  install_opencode_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_not_here \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
}

@test "opencode adapter: a missing database file is unavailable" {
  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_fixture_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"opencode.db"* ]]
}

@test "opencode adapter: an unreadable database is unavailable" {
  printf 'definitely not a sqlite database' > "$AGENT_USAGE_AUDIT_OPENCODE_DB"

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_fixture_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"unreadable"* ]]
}

@test "agy adapter: sums only rows whose stored total verifies" {
  install_agy_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-agy" ]
  [ "$(json_field tokens.input)" = "3000" ]
  [ "$(json_field tokens.cache_read)" = "50000" ]
  # output folds thinking in: (300 + 50) + (400 + 60)
  [ "$(json_field tokens.output)" = "810" ]
  [ "$(json_field tokens.reasoning)" = "110" ]
  [ "$(json_field models.0)" = "gemini-3.8-flash" ]
}

@test "agy adapter: a row failing the #3 == #9 + #10 self-check is dropped, not guessed" {
  install_agy_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field verified_rows)" = "2" ]
  [ "$(json_field dropped_rows)" = "1" ]
  # The drifted row's 9999 input never reaches the totals.
  [ "$(json_field tokens.input)" = "3000" ]
}

@test "agy adapter: a missing conversation database is unavailable" {
  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-missing \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
}

@test "agy adapter: a conversation where every row fails verification is unavailable" {
  mkdir -p "$AGENT_USAGE_AUDIT_AGY_DIR"
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    agy-drift "$AGENT_USAGE_AUDIT_AGY_DIR/conv-drift.db"

  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-drift \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"self-check"* ]]
}
