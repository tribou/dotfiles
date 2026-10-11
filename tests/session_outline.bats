setup() {
  load 'test_helper/common_setup'
  common_setup
  SCRIPT="$REPO_ROOT/skills/session-outline/session-outline.sh"
  TMPDIR_TEST="$(mktemp -d)"
  SESSION="$TMPDIR_TEST/sess.jsonl"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# Append one JSONL record to the main session transcript.
rec() {
  printf '%s\n' "$1" >> "$SESSION"
}

# Write a subagent transcript plus its meta sidecar under the session dir.
subagent() {
  local name=$1 tool_id=$2 meta_model=$3
  mkdir -p "$TMPDIR_TEST/sess/subagents"
  if [[ -n $meta_model ]]; then
    printf '{"agentType":"general-purpose","toolUseId":"%s","model":"%s"}\n' \
      "$tool_id" "$meta_model" > "$TMPDIR_TEST/sess/subagents/$name.meta.json"
  else
    printf '{"agentType":"general-purpose","toolUseId":"%s"}\n' \
      "$tool_id" > "$TMPDIR_TEST/sess/subagents/$name.meta.json"
  fi
  : > "$TMPDIR_TEST/sess/subagents/$name.jsonl"
}

@test "session-outline: reports the model the session ran on" {
  rec '{"type":"user","message":{"content":"hello there"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"text","text":"hi"}]}}'

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "Models:  claude-opus-5"
}

@test "session-outline: lists every model a session used, in first-seen order" {
  rec '{"type":"user","message":{"content":"first"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"text","text":"a"}]}}'
  rec '{"type":"user","message":{"content":"second"}}'
  rec '{"type":"assistant","message":{"model":"claude-sonnet-5","content":[{"type":"text","text":"b"}]}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"text","text":"c"}]}}'

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "Models:  claude-opus-5,claude-sonnet-5"
}

@test "session-outline: omits the model header when no model is recorded" {
  rec '{"type":"user","message":{"content":"just a prompt"}}'

  run "$SCRIPT" "$SESSION"
  assert_success
  refute_output --partial "Models:"
}

@test "session-outline: annotates an agent with the model its transcript ran on" {
  rec '{"type":"user","message":{"content":"go look"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"tool_use","name":"Agent","id":"toolu_1","input":{"subagent_type":"Explore","description":"look around"}}]}}'
  subagent agent-one toolu_1 sonnet
  printf '%s\n' '{"type":"assistant","message":{"model":"claude-sonnet-5","content":[{"type":"text","text":"done"}]}}' \
    > "$TMPDIR_TEST/sess/subagents/agent-one.jsonl"

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "AGENT  [Explore] look around (claude-sonnet-5)"
}

@test "session-outline: falls back to the requested model when the agent transcript is empty" {
  rec '{"type":"user","message":{"content":"go look"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"tool_use","name":"Agent","id":"toolu_2","input":{"subagent_type":"Explore","description":"look around"}}]}}'
  subagent agent-two toolu_2 haiku

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "AGENT  [Explore] look around (haiku)"
}

@test "session-outline: falls back to the model the Agent call asked for when no transcript exists" {
  rec '{"type":"user","message":{"content":"go look"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"tool_use","name":"Agent","id":"toolu_3","input":{"subagent_type":"Explore","description":"look around","model":"opus"}}]}}'

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "AGENT  [Explore] look around (opus)"
}

@test "session-outline: leaves an agent line unannotated when no model is known" {
  rec '{"type":"user","message":{"content":"go look"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"tool_use","name":"Agent","id":"toolu_4","input":{"subagent_type":"Explore","description":"look around"}}]}}'

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "AGENT  [Explore] look around"
  refute_output --partial "look around ()"
}

@test "session-outline: skips a truncated trailing line in a live transcript" {
  rec '{"type":"user","message":{"content":"first prompt"}}'
  rec '{"type":"assistant","message":{"model":"claude-opus-5","content":[{"type":"text","text":"a"}]}}'
  printf '%s' '{"type":"user","message":{"content":"half a line' >> "$SESSION"

  run "$SCRIPT" "$SESSION"
  assert_success
  assert_output --partial "Models:  claude-opus-5"
  assert_output --partial "PROMPT first prompt"
}

@test "session-outline: rejects a session id that escapes the projects directory" {
  run "$SCRIPT" --runtime claude-code "../../etc/hosts"
  assert_failure
  assert_output --partial "Invalid session id"
}

@test "session-outline: resolves the newest transcript in the projects directory" {
  local work="$TMPDIR_TEST/work" slug
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"
  slug=$(printf '%s' "$work" | sed 's#[^A-Za-z0-9]#-#g')
  mkdir -p "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug"
  printf '%s\n' '{"type":"user","message":{"content":"older work"}}' \
    > "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/old.jsonl"
  printf '%s\n' '{"type":"user","message":{"content":"newer work"}}' \
    > "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/new.jsonl"
  touch -t 202401010000 "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/old.jsonl"
  touch -t 202501010000 "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/new.jsonl"

  cd "$work"
  run "$SCRIPT" --runtime claude-code
  assert_success
  assert_output --partial "Session: new"
  assert_output --partial "PROMPT newer work"
}

@test "session-outline: reports when the projects directory holds no sessions" {
  local work="$TMPDIR_TEST/empty"
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"

  cd "$work"
  run "$SCRIPT" --runtime claude-code
  assert_failure
  assert_output --partial "No Claude Code sessions found"
}

@test "session-outline: --runtime without a value reports the error" {
  run "$SCRIPT" --runtime
  assert_failure
  assert_output --partial "--runtime needs a value"
}

@test "session-outline: --runtime= with an empty value reports the error" {
  run "$SCRIPT" --runtime=
  assert_failure
  assert_output --partial "--runtime needs a value"
}

@test "session-outline: rejects a second positional argument" {
  run "$SCRIPT" "$SESSION" extra
  assert_failure
  assert_output --partial "unexpected extra argument"
}

@test "session-outline: strips any extension from a transcript path's session header" {
  printf '%s\n' '{"type":"user","message":{"content":"hi"}}' > "$TMPDIR_TEST/other.txt"

  run "$SCRIPT" "$TMPDIR_TEST/other.txt"
  assert_success
  assert_output --partial "Session: other"
  refute_output --partial "Session: other.txt"
}

@test "detect: picks claude-code when only a Claude Code transcript exists" {
  local work="$TMPDIR_TEST/work" slug
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"
  export SESSION_OUTLINE_OPENCODE_DB="$TMPDIR_TEST/absent.db"
  slug=$(printf '%s' "$work" | sed 's#[^A-Za-z0-9]#-#g')
  mkdir -p "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug"
  printf '%s\n' '{"type":"user","message":{"content":"work"}}' \
    > "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/sess.jsonl"

  cd "$work"
  run "$REPO_ROOT/skills/session-outline/lib/detect.sh"
  assert_success
  assert_output "claude-code"
}

@test "detect: picks opencode when its session is newer than the transcript" {
  local work="$TMPDIR_TEST/work" slug
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"
  export SESSION_OUTLINE_OPENCODE_DB="$TMPDIR_TEST/oc.db"
  slug=$(printf '%s' "$work" | sed 's#[^A-Za-z0-9]#-#g')
  mkdir -p "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug"
  printf '%s\n' '{"type":"user","message":{"content":"work"}}' \
    > "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/sess.jsonl"
  touch -t 202401010000 "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/sess.jsonl"
  sqlite3 "$SESSION_OUTLINE_OPENCODE_DB" "
    CREATE TABLE project (id TEXT PRIMARY KEY, worktree TEXT NOT NULL, time_created INTEGER);
    CREATE TABLE session (id TEXT PRIMARY KEY, project_id TEXT, parent_id TEXT, directory TEXT,
                          title TEXT, agent TEXT, model TEXT, time_created INTEGER, time_updated INTEGER);
    INSERT INTO project VALUES ('p', '$work', 1);
    INSERT INTO session (id,project_id,parent_id,title,time_created,time_updated)
      VALUES ('ses_new','p',NULL,'Newer work', 2000000000000, 2000000000000);"

  cd "$work"
  run "$REPO_ROOT/skills/session-outline/lib/detect.sh"
  assert_success
  assert_output "opencode"
}

@test "detect: picks claude-code when its transcript is newer than the opencode session" {
  local work="$TMPDIR_TEST/work" slug
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"
  export SESSION_OUTLINE_OPENCODE_DB="$TMPDIR_TEST/oc.db"
  slug=$(printf '%s' "$work" | sed 's#[^A-Za-z0-9]#-#g')
  mkdir -p "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug"
  printf '%s\n' '{"type":"user","message":{"content":"work"}}' \
    > "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/sess.jsonl"
  touch -t 203401010000 "$SESSION_OUTLINE_CLAUDE_PROJECTS_DIR/$slug/sess.jsonl"
  sqlite3 "$SESSION_OUTLINE_OPENCODE_DB" "
    CREATE TABLE project (id TEXT PRIMARY KEY, worktree TEXT NOT NULL, time_created INTEGER);
    CREATE TABLE session (id TEXT PRIMARY KEY, project_id TEXT, parent_id TEXT, directory TEXT,
                          title TEXT, agent TEXT, model TEXT, time_created INTEGER, time_updated INTEGER);
    INSERT INTO project VALUES ('p', '$work', 1);
    INSERT INTO session (id,project_id,parent_id,title,time_created,time_updated)
      VALUES ('ses_old','p',NULL,'Older work', 1704067200000, 1704067200000);"

  cd "$work"
  run "$REPO_ROOT/skills/session-outline/lib/detect.sh"
  assert_success
  assert_output "claude-code"
}

@test "detect: survives an opencode database it cannot read" {
  local work="$TMPDIR_TEST/work"
  mkdir -p "$work"
  export SESSION_OUTLINE_CLAUDE_PROJECTS_DIR="$TMPDIR_TEST/projects"
  export SESSION_OUTLINE_OPENCODE_DB="$TMPDIR_TEST/garbage.db"
  printf 'not a database\n' > "$SESSION_OUTLINE_OPENCODE_DB"

  cd "$work"
  run "$REPO_ROOT/skills/session-outline/lib/detect.sh"
  assert_success
  assert_output "claude-code"
}
