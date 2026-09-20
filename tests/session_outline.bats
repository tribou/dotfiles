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
