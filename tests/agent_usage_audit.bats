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
        node = Array.isArray(node) && /^\d+$/.test(part) ? node[Number(part)] : node[part];
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

@test "ledger merge: appends record to empty ledger" {
  local rec="$FIXTURES/rec1.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "brainstorming-to-issue",
  "harness": "claude-code",
  "session_id": "sess-1",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [
    {
      "model": "claude-3-7-sonnet",
      "tokens": { "input": 10, "output": 20, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 30 }
    }
  ],
  "tokens": { "input": 10, "output": 20, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 30 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run bun "$SCRIPT" merge --record "$rec"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "1" ]
  [ "$(json_field records.0.session_id)" = "sess-1" ]
}

@test "ledger merge: refreshes existing record in place for same (session_id, stage) without duplicating" {
  local existing="$FIXTURES/ledger-existing.json"
  local rec="$FIXTURES/rec-updated.json"
  cat > "$existing" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "issue-to-plan",
      "harness": "claude-code",
      "session_id": "sess-1",
      "source": "builtin-claude-code",
      "models": ["claude-3-7-sonnet"],
      "model_breakdowns": [],
      "tokens": { "input": 10, "output": 20, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 30 },
      "cost_usd": null,
      "children": [],
      "updated_at": "2026-09-07T00:00:00Z"
    }
  ]
}
EOF
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-1",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [],
  "tokens": { "input": 50, "output": 50, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 100 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T01:00:00Z"
}
EOF

  run bun "$SCRIPT" merge --existing "$existing" --record "$rec"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "1" ]
  [ "$(json_field records.0.tokens.total)" = "100" ]
  [ "$(json_field records.0.updated_at)" = "2026-09-07T01:00:00Z" ]
}

@test "ledger merge: appends new record for different stage or sitting and sorts stably" {
  local existing="$FIXTURES/ledger-sort.json"
  local rec="$FIXTURES/rec-sort.json"
  cat > "$existing" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "plan-to-implementation",
      "harness": "claude-code",
      "session_id": "sess-2",
      "source": "builtin-claude-code",
      "models": ["claude-3-7-sonnet"],
      "model_breakdowns": [],
      "tokens": { "input": 10, "output": 10, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 20 },
      "cost_usd": null,
      "children": [],
      "updated_at": "2026-09-07T03:00:00Z"
    }
  ]
}
EOF
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "brainstorming-to-issue",
  "harness": "claude-code",
  "session_id": "sess-1",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [],
  "tokens": { "input": 5, "output": 5, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 10 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T01:00:00Z"
}
EOF

  run bun "$SCRIPT" merge --existing "$existing" --record "$rec"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "2" ]
  [ "$(json_field records.0.stage)" = "brainstorming-to-issue" ]
  [ "$(json_field records.1.stage)" = "plan-to-implementation" ]
}

@test "render: single-model session renders one table row and correct totals" {
  local ledger="$FIXTURES/ledger-single.json"
  cat > "$ledger" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "issue-to-plan",
      "harness": "claude-code",
      "session_id": "sess-single",
      "source": "builtin-claude-code",
      "models": ["claude-3-7-sonnet"],
      "model_breakdowns": [
        {
          "model": "claude-3-7-sonnet",
          "tokens": { "input": 1200, "output": 800, "cache_read": 100, "cache_write": 50, "reasoning": 0, "total": 2150 }
        }
      ],
      "tokens": { "input": 1200, "output": 800, "cache_read": 100, "cache_write": 50, "reasoning": 0, "total": 2150 },
      "cost_usd": null,
      "children": [],
      "updated_at": "2026-09-07T00:00:00Z"
    }
  ]
}
EOF

  run bun "$SCRIPT" render --file "$ledger"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<!-- BEGIN AGENT USAGE -->"* ]]
  [[ "$output" == *"<!-- END AGENT USAGE -->"* ]]
  [[ "$output" == *"| Stage | Session | Harness | Model | Input | Output | Cache Read | Cache Write | Total | Source |"* ]]
  [[ "$output" == *"| issue-to-plan | sess-single | claude-code | claude-3-7-sonnet | 1,200 | 800 | 100 | 50 | 2,150 | builtin-claude-code |"* ]]
  [[ "$output" == *"| **Total** | | | | 1,200 | 800 | 100 | 50 | 2,150 | |"* ]]
  [[ "$output" == *"<summary>Ledger data</summary>"* ]]
}

@test "render: multi-model session renders separate rows for each model with divided tokens" {
  local ledger="$FIXTURES/ledger-multi.json"
  cat > "$ledger" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "plan-to-implementation",
      "harness": "opencode",
      "session_id": "sess-multi",
      "source": "builtin-opencode",
      "models": ["model-orchestrator", "model-worker"],
      "model_breakdowns": [
        {
          "model": "model-orchestrator",
          "tokens": { "input": 1000, "output": 200, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 1200 }
        },
        {
          "model": "model-worker",
          "tokens": { "input": 3000, "output": 800, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 3800 }
        }
      ],
      "tokens": { "input": 4000, "output": 1000, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 5000 },
      "cost_usd": null,
      "children": [],
      "updated_at": "2026-09-07T00:00:00Z"
    }
  ]
}
EOF

  run bun "$SCRIPT" render --file "$ledger"
  [ "$status" -eq 0 ]
  [[ "$output" == *"| plan-to-implementation | sess-multi | opencode | model-orchestrator | 1,000 | 200 | 0 | 0 | 1,200 | builtin-opencode |"* ]]
  [[ "$output" == *"| plan-to-implementation | sess-multi | opencode | model-worker | 3,000 | 800 | 0 | 0 | 3,800 | builtin-opencode |"* ]]
  [[ "$output" == *"| **Total** | | | | 4,000 | 1,000 | 0 | 0 | 5,000 | |"* ]]
}

@test "render: unavailable record renders em-dashes and is excluded from totals row" {
  local ledger="$FIXTURES/ledger-unavail.json"
  cat > "$ledger" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "issue-to-plan",
      "harness": "unknown",
      "session_id": "sess-unavail",
      "source": "unavailable",
      "models": [],
      "model_breakdowns": [],
      "tokens": { "input": 0, "output": 0, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 0 },
      "cost_usd": null,
      "children": [],
      "reason": "no session id",
      "updated_at": "2026-09-07T00:00:00Z"
    }
  ]
}
EOF

  run bun "$SCRIPT" render --file "$ledger"
  [ "$status" -eq 0 ]
  [[ "$output" == *"| issue-to-plan | sess-unavail | unknown | — | — | — | — | — | — | unavailable |"* ]]
  [[ "$output" == *"| **Total** | | | | 0 | 0 | 0 | 0 | 0 | |"* ]]
}

@test "parse: round-trip test extracts identical ledger records from rendered comment" {
  local ledger="$FIXTURES/ledger-rt.json"
  cat > "$ledger" <<'EOF'
{
  "schema": 1,
  "records": [
    {
      "schema": 1,
      "stage": "issue-to-plan",
      "harness": "claude-code",
      "session_id": "sess-rt",
      "source": "builtin-claude-code",
      "models": ["claude-3-7-sonnet"],
      "model_breakdowns": [
        {
          "model": "claude-3-7-sonnet",
          "tokens": { "input": 100, "output": 50, "cache_read": 10, "cache_write": 5, "reasoning": 0, "total": 165 }
        }
      ],
      "tokens": { "input": 100, "output": 50, "cache_read": 10, "cache_write": 5, "reasoning": 0, "total": 165 },
      "cost_usd": null,
      "children": [],
      "updated_at": "2026-09-07T00:00:00Z"
    }
  ]
}
EOF

  local rendered="$FIXTURES/rendered.md"
  bun "$SCRIPT" render --file "$ledger" > "$rendered"

  run bun "$SCRIPT" parse --file "$rendered"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "1" ]
  [ "$(json_field records.0.session_id)" = "sess-rt" ]
  [ "$(json_field records.0.tokens.total)" = "165" ]
}

@test "parse: returns empty ledger for unparseable or malformed comment markdown" {
  local malformed="$FIXTURES/malformed.md"
  cat > "$malformed" <<'EOF'
<!-- BEGIN AGENT USAGE -->
```json
{ invalid json here
```
<!-- END AGENT USAGE -->
EOF

  run bun "$SCRIPT" parse --file "$malformed"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "0" ]
}

@test "parse: returns empty ledger when no ledger block or markers exist" {
  local plain="$FIXTURES/plain.md"
  cat > "$plain" <<'EOF'
Just a regular PR comment without any usage markers.
EOF

  run bun "$SCRIPT" parse --file "$plain"
  [ "$status" -eq 0 ]
  [ "$(json_field records.length)" = "0" ]
}

@test "record: creates new comment (POST) when no audit comment exists" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  local logfile="$FIXTURES/gh.log"
  rm -f "$logfile"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$FIXTURES/gh.log"
if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  echo "[]"
elif [[ "$1" == "api" && "$2" == "-X" && "$3" == "POST" ]]; then
  echo "{"id": 999}"
fi
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/mock-record.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-post-test",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [
    {
      "model": "claude-3-7-sonnet",
      "tokens": { "input": 100, "output": 100, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 200 }
    }
  ],
  "tokens": { "input": 100, "output": 100, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 200 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run env PATH="$stubdir:$PATH" FIXTURES="$FIXTURES" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec"
  [ "$status" -eq 0 ]
  run grep "POST repos/:owner/:repo/issues/181/comments" "$logfile"
  [ "$status" -eq 0 ]
}

@test "record: PATCHes existing comment when audit comment exists" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  local logfile="$FIXTURES/gh.log"
  rm -f "$logfile"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$FIXTURES/gh.log"
if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  echo '[{"id": 456, "body": "### 🤖 Agent usage\n\n<!-- BEGIN AGENT USAGE -->\n```json\n{\"schema\": 1, \"records\": []}\n```\n<!-- END AGENT USAGE -->"}]'
elif [[ "$1" == "api" && "$2" == "-X" && "$3" == "PATCH" ]]; then
  echo "{"id": 456}"
fi
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/mock-record-patch.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-patch-test",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [],
  "tokens": { "input": 50, "output": 50, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 100 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run env PATH="$stubdir:$PATH" FIXTURES="$FIXTURES" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec"
  [ "$status" -eq 0 ]
  run grep "PATCH repos/:owner/:repo/issues/comments/456" "$logfile"
  [ "$status" -eq 0 ]
}

@test "record: never selects a plan comment as the audit comment" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  local logfile="$FIXTURES/gh.log"
  rm -f "$logfile"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$FIXTURES/gh.log"
if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  echo '[{"id": 111, "body": "<details><summary>Plan</summary>\n<!-- BEGIN PLAN -->\nTask 1\n<!-- END PLAN -->\n</details>"}]'
elif [[ "$1" == "api" && "$2" == "-X" && "$3" == "POST" ]]; then
  echo "{\"id\": 999}"
fi
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/mock-record-plan.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-plan-test",
  "source": "builtin-claude-code",
  "models": [],
  "model_breakdowns": [],
  "tokens": { "input": 1, "output": 1, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 2 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run env PATH="$stubdir:$PATH" FIXTURES="$FIXTURES" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec"
  [ "$status" -eq 0 ]
  run grep "PATCH.*111" "$logfile"
  [ "$status" -ne 0 ]
  run grep "POST repos/:owner/:repo/issues/181/comments" "$logfile"
  [ "$status" -eq 0 ]
}

@test "record: never selects a plan comment that embeds an audit usage block" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  local logfile="$FIXTURES/gh.log"
  rm -f "$logfile"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$FIXTURES/gh.log"
if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  echo '[{"id": 222, "body": "<details><summary>Plan</summary>\n<!-- BEGIN PLAN -->\nTask 1\n<!-- END PLAN -->\n\n<!-- BEGIN AGENT USAGE -->\n```json\n{\"schema\": 1, \"records\": []}\n```\n<!-- END AGENT USAGE -->\n</details>"}]'
elif [[ "$1" == "api" && "$2" == "-X" && "$3" == "POST" ]]; then
  echo "{\"id\": 999}"
fi
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/mock-record-plan-embed.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-plan-embed-test",
  "source": "builtin-claude-code",
  "models": [],
  "model_breakdowns": [],
  "tokens": { "input": 1, "output": 1, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 2 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run env PATH="$stubdir:$PATH" FIXTURES="$FIXTURES" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec"
  [ "$status" -eq 0 ]
  run grep "PATCH.*222" "$logfile"
  [ "$status" -ne 0 ]
  run grep "POST repos/:owner/:repo/issues/181/comments" "$logfile"
  [ "$status" -eq 0 ]
}

@test "record: --dry-run prints comment body without calling POST or PATCH" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  local logfile="$FIXTURES/gh.log"
  rm -f "$logfile"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$FIXTURES/gh.log"
if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  echo "[]"
fi
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/mock-record-dry.json"
  cat > "$rec" <<'EOF'
{
  "schema": 1,
  "stage": "issue-to-plan",
  "harness": "claude-code",
  "session_id": "sess-dry-test",
  "source": "builtin-claude-code",
  "models": ["claude-3-7-sonnet"],
  "model_breakdowns": [],
  "tokens": { "input": 10, "output": 10, "cache_read": 0, "cache_write": 0, "reasoning": 0, "total": 20 },
  "cost_usd": null,
  "children": [],
  "updated_at": "2026-09-07T00:00:00Z"
}
EOF

  run env PATH="$stubdir:$PATH" FIXTURES="$FIXTURES" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"<!-- BEGIN AGENT USAGE -->"* ]]
  [[ "$output" == *"sess-dry-test"* ]]
  run grep -E "(POST|PATCH)" "$logfile"
  [ "$status" -ne 0 ]
}

@test "record: errors when comment body exceeds 65536 characters" {
  local stubdir="$FIXTURES/bin"
  mkdir -p "$stubdir"
  cat > "$stubdir/gh" <<'EOF'
#!/usr/bin/env bash
echo "[]"
EOF
  chmod +x "$stubdir/gh"

  local rec="$FIXTURES/huge-record.json"
  bun -e '
    const huge = {
      schema: 1,
      stage: "issue-to-plan",
      harness: "claude-code",
      session_id: "sess-huge",
      source: "builtin-claude-code",
      models: ["model-x"],
      model_breakdowns: [],
      tokens: { input: 1, output: 1, cache_read: 0, cache_write: 0, reasoning: 0, total: 2 },
      cost_usd: null,
      children: [],
      reason: "x".repeat(70000),
      updated_at: "2026-09-07T00:00:00Z"
    };
    await Bun.write(process.argv[1], JSON.stringify(huge));
  ' "$rec"

  run env PATH="$stubdir:$PATH" bun "$SCRIPT" record --stage issue-to-plan --target pr:181 --record "$rec"
  [ "$status" -ne 0 ]
  [[ "$output" == *"exceeds GitHub limit of 65536"* ]]
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
  [ "$(json_field model_breakdowns.0.model)" = "gemini-3.8-flash" ]
  [ "$(json_field model_breakdowns.0.tokens.total)" = "53810" ]
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

@test "agy adapter: groups tokens across multiple models" {
  mkdir -p "$AGENT_USAGE_AUDIT_AGY_DIR"
  bun "$REPO_ROOT/tests/fixtures/agent-usage-audit/make_fixtures.ts" \
    agy-multi-model "$AGENT_USAGE_AUDIT_AGY_DIR/conv-multi.db"

  run env AGENT_USAGE_AUDIT_HARNESS=agy \
    AGENT_USAGE_AUDIT_SESSION_ID=conv-multi \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-agy" ]
  [ "$(json_field models.0)" = "gemini-3.8-flash" ]
  [ "$(json_field models.1)" = "gemini-3.8-pro" ]
  [ "$(json_field model_breakdowns.0.model)" = "gemini-3.8-flash" ]
  [ "$(json_field model_breakdowns.0.tokens.input)" = "100" ]
  [ "$(json_field model_breakdowns.0.tokens.total)" = "335" ]
  [ "$(json_field model_breakdowns.1.model)" = "gemini-3.8-pro" ]
  [ "$(json_field model_breakdowns.1.tokens.input)" = "500" ]
  [ "$(json_field model_breakdowns.1.tokens.total)" = "1600" ]
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
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"totalCost":1.25,"modelsUsed":["claude-opus-5"],"modelBreakdowns":[{"modelName":"claude-opus-5","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"cost":1.25}]}]}'

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
  [ "$(json_field model_breakdowns.0.model)" = "claude-opus-5" ]
}

@test "probe order: ccusage extracts multiple model breakdowns" {
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":10,"outputTokens":20,"cacheReadTokens":30,"cacheCreationTokens":40,"totalCost":2.50,"modelsUsed":["claude-opus-5","claude-sonnet-5"],"modelBreakdowns":[{"modelName":"claude-opus-5","inputTokens":8,"outputTokens":15,"cacheReadTokens":20,"cacheCreationTokens":30,"cost":2.00},{"modelName":"claude-sonnet-5","inputTokens":2,"outputTokens":5,"cacheReadTokens":10,"cacheCreationTokens":10,"cost":0.50}]}]}'

  run env -u AGENT_USAGE_AUDIT_DISABLE_CCUSAGE \
    AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "ccusage" ]
  [ "$(json_field model_breakdowns.0.model)" = "claude-opus-5" ]
  [ "$(json_field model_breakdowns.0.tokens.input)" = "8" ]
  [ "$(json_field model_breakdowns.0.cost_usd)" = "2" ]
  [ "$(json_field model_breakdowns.1.model)" = "claude-sonnet-5" ]
  [ "$(json_field model_breakdowns.1.tokens.input)" = "2" ]
  [ "$(json_field model_breakdowns.1.cost_usd)" = "0.5" ]
}

@test "probe order: ccusage falls back to modelsUsed when modelBreakdowns is omitted" {
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"totalCost":1.25,"modelsUsed":["claude-opus-5"]}]}'

  run env -u AGENT_USAGE_AUDIT_DISABLE_CCUSAGE \
    AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "ccusage" ]
  [ "$(json_field model_breakdowns.0.model)" = "claude-opus-5" ]
  [ "$(json_field model_breakdowns.0.tokens.total)" = "10" ]
  [ "$(json_field model_breakdowns.0.cost_usd)" = "1.25" ]
}

@test "probe order: malformed ccusage modelBreakdowns falls back to the built-in adapter" {
  unset AGENT_USAGE_AUDIT_DISABLE_CCUSAGE
  install_claude_fixture
  stub_ccusage '{"sessions":[{"sessionId":"sess-cc-0001","inputTokens":1,"outputTokens":2,"cacheReadTokens":3,"cacheCreationTokens":4,"modelBreakdowns":"not-an-array"}]}'

  run env AGENT_USAGE_AUDIT_HARNESS="claude-code" \
    AGENT_USAGE_AUDIT_SESSION_ID="sess-cc-0001" \
    bun "$SCRIPT" probe --stage issue-to-plan
  [ "$status" -eq 0 ]
  [ "$(json_field source)" = "builtin-claude-code" ]
  [ "$(json_field tokens.total)" = "3701" ]
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
