setup() {
  load 'test_helper/common_setup'
  common_setup
  SCRIPT="$REPO_ROOT/skills/session-outline/session-outline.sh"
  TMPDIR_TEST="$(mktemp -d)"
  export SESSION_OUTLINE_OPENCODE_DB="$TMPDIR_TEST/opencode.db"
  db_init
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

db() { sqlite3 "$SESSION_OUTLINE_OPENCODE_DB" "$1"; }

# Mirror the column names opencode's own schema uses, so the queries under
# test are the ones that will run against a real opencode.db.
db_init() {
  db "CREATE TABLE project (id TEXT PRIMARY KEY, worktree TEXT NOT NULL, time_created INTEGER);
      CREATE TABLE session (id TEXT PRIMARY KEY, project_id TEXT, parent_id TEXT, directory TEXT,
                            title TEXT, agent TEXT, model TEXT, time_created INTEGER, time_updated INTEGER);
      CREATE TABLE message (id TEXT PRIMARY KEY, session_id TEXT, time_created INTEGER, data TEXT);
      CREATE TABLE part (id TEXT PRIMARY KEY, message_id TEXT, session_id TEXT, time_created INTEGER, data TEXT);"
}

project() { db "INSERT INTO project VALUES ('$1','$2',1);"; }

session() { # id project parent title time
  db "INSERT INTO session (id,project_id,parent_id,directory,title,time_created,time_updated)
      VALUES ('$1','$2',$3,'/w','$4',$5,$5);"
}

msg() { # id session role model time
  db "INSERT INTO message VALUES ('$1','$2',$5,json_object('role','$3','modelID','$4'));"
}

part() { # id message session json time
  db "INSERT INTO part VALUES ('$1','$2','$3',$5,'$4');"
}

@test "opencode: reports the models a session ran on" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a assistant claude-sonnet-5 101
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "Models:  claude-sonnet-5"
}

@test "opencode: lists every model a session used, in first-seen order" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a assistant big-pickle 101
  msg msg_2 ses_a assistant gemini-3-pro 102
  msg msg_3 ses_a assistant big-pickle 103
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "Models:  big-pickle,gemini-3-pro"
}

@test "opencode: shows the session title" {
  session ses_a p NULL 'Reading wip directory' 100
  msg msg_1 ses_a assistant big-pickle 101
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "Title:   Reading wip directory"
}

@test "opencode: prints user prompts" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a user '' 101
  part prt_1 msg_1 ses_a '{"type":"text","text":"refactor the parser"}' 102
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "PROMPT refactor the parser"
}

@test "opencode: filters out synthetic injected text" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a user '' 101
  part prt_1 msg_1 ses_a '{"type":"text","text":"real prompt"}' 102
  part prt_2 msg_1 ses_a '{"type":"text","synthetic":true,"text":"Called the Read tool with"}' 103
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "PROMPT real prompt"
  refute_output --partial "Called the Read tool"
}

@test "opencode: lists skills loaded via the skill tool" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a assistant big-pickle 101
  part prt_1 msg_1 ses_a '{"type":"tool","tool":"skill","state":{"input":{"name":"brainstorming"}}}' 102
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "SKILL  brainstorming"
}

@test "opencode: lists task subagents with type, description and model" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a assistant big-pickle 101
  part prt_1 msg_1 ses_a '{"type":"tool","tool":"task","state":{"input":{"subagent_type":"general","description":"Fix auth"},"metadata":{"sessionId":"ses_kid","model":{"modelID":"gpt-6-astra"}}}}' 102
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "AGENT  [general] Fix auth (gpt-6-astra)"
}

@test "opencode: nests a subagent's own skills under its agent line" {
  session ses_a p NULL 'Some work' 100
  msg msg_1 ses_a assistant big-pickle 101
  part prt_1 msg_1 ses_a '{"type":"tool","tool":"task","state":{"input":{"subagent_type":"general","description":"Fix auth"},"metadata":{"sessionId":"ses_kid","model":{"modelID":"gpt-6-astra"}}}}' 102
  session ses_kid p "'ses_a'" 'Fix auth (@general subagent)' 103
  msg msg_k ses_kid assistant gpt-6-astra 104
  part prt_k msg_k ses_kid '{"type":"tool","tool":"skill","state":{"input":{"name":"test-driven-development"}}}' 105
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "AGENT  [general] Fix auth (gpt-6-astra)"
  assert_line --regexp '^ {6,}SKILL  test-driven-development'
}

@test "opencode: picks the newest non-child session for the working directory" {
  project proj_x "$PWD"
  session ses_old proj_x NULL 'Older work' 100
  msg msg_o ses_old assistant big-pickle 101
  session ses_new proj_x NULL 'Newer work' 200
  msg msg_n ses_new assistant gemini-3-pro 201
  run "$SCRIPT" --runtime opencode
  assert_success
  assert_output --partial "Title:   Newer work"
}

@test "opencode: never selects a subagent child session as the session for a directory" {
  project proj_x "$PWD"
  session ses_main proj_x NULL 'Main work' 100
  msg msg_m ses_main assistant big-pickle 101
  session ses_kid proj_x "'ses_main'" 'Fix auth (@general subagent)' 300
  msg msg_k ses_kid assistant gpt-6-astra 301
  run "$SCRIPT" --runtime opencode
  assert_success
  assert_output --partial "Title:   Main work"
  refute_output --partial "Fix auth (@general subagent)"
}

@test "opencode: auto-detects the runtime from a ses_ session id" {
  session ses_a p NULL 'Autodetected' 100
  msg msg_1 ses_a assistant big-pickle 101
  run "$SCRIPT" ses_a
  assert_success
  assert_output --partial "Runtime: opencode"
}

@test "opencode: reports when the directory has no opencode sessions" {
  project proj_x /somewhere/else
  run "$SCRIPT" --runtime opencode
  assert_failure
  assert_output --partial "No opencode sessions"
}
