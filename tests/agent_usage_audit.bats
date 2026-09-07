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
  unset CLAUDECODE CLAUDE_CODE_SESSION_ID CLAUDE_SESSION_ID
  unset OPENCODE OPENCODE_SESSION_ID
  unset AGY_CONVERSATION_ID ANTIGRAVITY_CONVERSATION_ID ANTIGRAVITY_AGENT
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
  [ "$(json_field model_breakdowns)" = "[]" ]
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

@test "probe: invalid harness override falls back to the unknown harness" {
  run env AGENT_USAGE_AUDIT_HARNESS=not-a-harness \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-invalid-harness \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "unknown" ]
  [ "$(json_field session_id)" = "sess-invalid-harness" ]
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

@test "detect_harness: AGY marker selects the agy harness" {
  run env AGY_CONVERSATION_ID=conv-0001 \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field harness)" = "agy" ]
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
  [ "$(json_field model_breakdowns.0.model)" = "claude-opus-5" ]
  [ "$(json_field model_breakdowns.0.tokens.total)" = "3390" ]
  [ "$(json_field model_breakdowns.1.model)" = "claude-sonnet-5" ]
  [ "$(json_field model_breakdowns.1.tokens.total)" = "311" ]
}

@test "claude-code adapter: a missing transcript is unavailable, not zero-filled truth" {
  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-does-not-exist \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"transcript"* ]]
}

@test "claude-code adapter: unreadable transcript is unavailable" {
  local dir="$AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR/-fixture-project"
  mkdir -p "$dir"
  local transcript="$dir/sess-unreadable.jsonl"
  touch "$transcript"
  chmod 000 "$transcript"

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-unreadable \
    bun "$SCRIPT" probe --stage issue-to-plan

  chmod 644 "$transcript"
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"unreadable"* ]]
}

@test "claude-code adapter: transcript with no assistant turns is unavailable" {
  local dir="$AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR/-fixture-project"
  mkdir -p "$dir"
  echo '{"type":"user","message":{"content":"hello"}}' > "$dir/sess-no-assistant.jsonl"

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-no-assistant \
    bun "$SCRIPT" probe --stage issue-to-plan

  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [[ "$(json_field reason)" == *"no assistant turns"* ]]
}

@test "claude-code adapter: malformed usage rows are dropped without corrupting totals" {
  local dir="$AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR/-fixture-project"
  mkdir -p "$dir"
  printf '%s\n' \
    '{"type":"assistant","requestId":"valid","message":{"id":"valid","model":"claude-opus-5","usage":{"input_tokens":10,"output_tokens":20,"cache_read_input_tokens":30,"cache_creation_input_tokens":40,"output_tokens_details":{"thinking_tokens":5}}}}' \
    '{"type":"assistant","requestId":"bad","message":{"id":"bad","model":"claude-opus-5","usage":{"input_tokens":"10","output_tokens":2,"cache_read_input_tokens":3,"cache_creation_input_tokens":4,"output_tokens_details":{"thinking_tokens":1}}}}' \
    > "$dir/sess-malformed.jsonl"

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-malformed \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.input)" = "10" ]
  [ "$(json_field tokens.output)" = "20" ]
  [ "$(json_field tokens.total)" = "100" ]
}

@test "probe: unexpected errors preserve detected harness and session context" {
  local projects="$FIXTURES/not-a-directory"
  printf '%s' 'not a directory' > "$projects"

  run env AGENT_USAGE_AUDIT_HARNESS=claude-code \
    AGENT_USAGE_AUDIT_SESSION_ID=sess-context \
    AGENT_USAGE_AUDIT_CLAUDE_PROJECTS_DIR="$projects" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "unavailable" ]
  [ "$(json_field harness)" = "claude-code" ]
  [ "$(json_field session_id)" = "sess-context" ]
  [[ "$(json_field reason)" == *"unexpected probe error"* ]]
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
  # Tokens divided per model: orchestrator vs subagent
  [ "$(json_field model_breakdowns.0.model)" = "anthropic/claude-opus-5" ]
  [ "$(json_field model_breakdowns.0.tokens.input)" = "120" ]
  [ "$(json_field model_breakdowns.0.tokens.output)" = "400" ]
  [ "$(json_field model_breakdowns.0.tokens.total)" = "6220" ]
  [ "$(json_field model_breakdowns.0.cost_usd)" = "0.42" ]
  [ "$(json_field model_breakdowns.1.model)" = "anthropic/claude-sonnet-5" ]
  [ "$(json_field model_breakdowns.1.tokens.input)" = "20" ]
  [ "$(json_field model_breakdowns.1.tokens.output)" = "35" ]
  [ "$(json_field model_breakdowns.1.tokens.total)" = "1055" ]
  [ "$(json_field model_breakdowns.1.cost_usd)" = "0.08" ]
}

@test "opencode adapter: extracts model id from JSON model column" {
  install_opencode_fixture

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_fixture_json_model_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-opencode" ]
  [ "$(json_field models.0)" = "glm-4-flash" ]
  [ "$(json_field models.1)" = "glm-5.3" ]
  [ "$(json_field children.0.session_id)" = "ses_fixture_json_model_child" ]
  [ "$(json_field children.0.models.0)" = "glm-4-flash" ]
  [ "$(json_field model_breakdowns.0.model)" = "glm-4-flash" ]
  [ "$(json_field model_breakdowns.0.tokens.input)" = "10" ]
  [ "$(json_field model_breakdowns.0.tokens.output)" = "20" ]
  [ "$(json_field model_breakdowns.0.cost_usd)" = "0.05" ]
  [ "$(json_field model_breakdowns.1.model)" = "glm-5.3" ]
  [ "$(json_field model_breakdowns.1.tokens.input)" = "100" ]
  [ "$(json_field model_breakdowns.1.tokens.output)" = "220" ]
  [ "$(json_field model_breakdowns.1.cost_usd)" = "0.15" ]
}

@test "opencode adapter: rolls up nested descendants and stops on parent cycles" {
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    opencode-nested "$AGENT_USAGE_AUDIT_OPENCODE_DB"

  run env AGENT_USAGE_AUDIT_HARNESS=opencode \
    AGENT_USAGE_AUDIT_SESSION_ID=ses_nested_parent \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-opencode" ]
  [ "$(json_field tokens.input)" = "115" ]
  [ "$(json_field tokens.output)" = "250" ]
  [ "$(json_field tokens.reasoning)" = "24" ]
  [ "$(json_field tokens.cache_read)" = "1250" ]
  [ "$(json_field tokens.cache_write)" = "137" ]
  [ "$(json_field tokens.total)" = "1752" ]
  [ "$(json_field children.0.session_id)" = "ses_nested_child" ]
  [ "$(json_field children.1.session_id)" = "ses_nested_grandchild" ]
  [ "$(json_field cost_usd)" = "0.6" ]
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

@test "agy adapter: malformed and truncated protobuf rows are dropped" {
  mkdir -p "$AGENT_USAGE_AUDIT_AGY_DIR"
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    agy-malformed "$AGENT_USAGE_AUDIT_AGY_DIR/conv-malformed.db"

  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-malformed \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-agy" ]
  [ "$(json_field verified_rows)" = "1" ]
  [ "$(json_field dropped_rows)" = "3" ]
  [ "$(json_field tokens.input)" = "1000" ]
  [ "$(json_field tokens.total)" = "21350" ]
}

stub_ccusage() {
  # $1 is the JSON the stub prints; $2 (optional) its exit status.
  local payload="$1" rc="${2:-0}"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/ccusage" <<EOF
#!/usr/bin/env bash
cat <<'JSON'
$payload
JSON
exit $rc
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/ccusage"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

stub_ccusage_timeout() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/ccusage" <<'EOF'
#!/usr/bin/env bash
sleep 31
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/ccusage"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "probe order: ccusage wins over the built-in adapter when it is installed" {
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"totalCost":1.25,"modelsUsed":["claude-opus-5"]}]}'

  run env -u AGENT_USAGE_AUDIT_DISABLE_CCUSAGE \
    AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "ccusage" ]
  [ "$(json_field tokens.input)" = "1" ]
  [ "$(json_field tokens.output)" = "2" ]
  [ "$(json_field tokens.cache_read)" = "3" ]
  [ "$(json_field tokens.cache_write)" = "4" ]
  [ "$(json_field cost_usd)" = "1.25" ]
}

@test "probe order: a failing ccusage falls back to the built-in adapter" {
  install_claude_fixture
  stub_ccusage 'not json at all' 1

  run env -u AGENT_USAGE_AUDIT_DISABLE_CCUSAGE \
    AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: AGENT_USAGE_AUDIT_DISABLE_CCUSAGE skips ccusage entirely" {
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2}]}'

  run env AGENT_USAGE_AUDIT_DISABLE_CCUSAGE=1 \
    AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
}

@test "probe order: malformed ccusage token fields fall back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":"not-a-number"}]}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: ccusage entries missing usage fall back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001"}]}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: ccusage children missing identity or usage fall back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"children":[{}]}]}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: malformed ccusage children fall back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","children":{}}]}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: a non-array ccusage sessions field falls back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":"not-an-array","sessionId":"sess-cc-0001","inputTokens":1}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}

@test "probe order: a timed-out ccusage falls back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage_timeout

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
}
