setup() {
  load 'test_helper/common_setup'
  common_setup
  unset DOTFILES_AI_BACKEND DOTFILES_COMMIT_BACKEND
  unset DOTFILES_AI_MODEL DOTFILES_COMMIT_MODEL
  unset DOTFILES_COMMIT_TIMEOUT DOTFILES_QQ_TIMEOUT
}

# --- shared AI configuration ---

@test "ai_backend: defaults to opencode when both names are unset" {
  unset DOTFILES_AI_BACKEND DOTFILES_COMMIT_BACKEND
  run --separate-stderr _dotfiles_ai_backend
  assert_success
  assert_output "opencode"
  [ -z "$stderr" ]
}

@test "ai_backend: deprecated commit name warns on stderr only" {
  unset DOTFILES_AI_BACKEND
  export DOTFILES_COMMIT_BACKEND=claude
  run --separate-stderr _dotfiles_ai_backend
  assert_success
  assert_output "claude"
  assert_equal "$stderr" "DOTFILES_COMMIT_BACKEND is deprecated; use DOTFILES_AI_BACKEND"
}

@test "ai_backend: canonical name wins without a deprecation warning" {
  export DOTFILES_AI_BACKEND=agy DOTFILES_COMMIT_BACKEND=claude
  run --separate-stderr _dotfiles_ai_backend
  assert_success
  assert_output "agy"
  [ -z "$stderr" ]
}

@test "ai_backend: explicitly empty canonical value uses the default without consulting the old name" {
  export DOTFILES_AI_BACKEND="" DOTFILES_COMMIT_BACKEND=claude
  run --separate-stderr _dotfiles_ai_backend
  assert_success
  assert_output "opencode"
  [ -z "$stderr" ]
}

@test "ai_backend: canonical values are accepted" {
  for backend in claude opencode agy; do
    export DOTFILES_AI_BACKEND="$backend"
    run _dotfiles_ai_backend
    assert_success
    assert_output "$backend"
  done
}

@test "ai_backend: unknown canonical value warns and falls back to opencode" {
  export DOTFILES_AI_BACKEND=bogus
  run --separate-stderr _dotfiles_ai_backend
  assert_success
  assert_output "opencode"
  assert_equal "$stderr" "unknown DOTFILES_AI_BACKEND=bogus, using opencode"
}

# --- shared AI models ---

@test "ai_model: claude backend uses haiku" {
  run _dotfiles_ai_model claude
  assert_success
  assert_output "haiku"
}

@test "ai_model: opencode backend uses kimi 2.7" {
  run _dotfiles_ai_model opencode
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
}

@test "ai_model: agy backend uses Gemini 3.7 Flash (Low)" {
  run _dotfiles_ai_model agy
  assert_success
  assert_output "gemini-3.7-flash-low"
}

@test "ai_model: deprecated commit model warns on stderr only" {
  unset DOTFILES_AI_MODEL
  export DOTFILES_COMMIT_MODEL=legacy/model
  run --separate-stderr _dotfiles_ai_model opencode
  assert_success
  assert_output "legacy/model"
  assert_equal "$stderr" "DOTFILES_COMMIT_MODEL is deprecated; use DOTFILES_AI_MODEL"
}

@test "ai_model: canonical name wins without a deprecation warning" {
  export DOTFILES_AI_MODEL=my/custom-model DOTFILES_COMMIT_MODEL=legacy/model
  run --separate-stderr _dotfiles_ai_model opencode
  assert_success
  assert_output "my/custom-model"
  [ -z "$stderr" ]
}

@test "ai_model: explicitly empty canonical value uses the backend default without consulting the old name" {
  export DOTFILES_AI_MODEL="" DOTFILES_COMMIT_MODEL=legacy/model
  run --separate-stderr _dotfiles_ai_model opencode
  assert_success
  assert_output "opencode-go/kimi-k2.7-code"
  [ -z "$stderr" ]
}

# --- shared AI timeouts ---

@test "ai_timeout: uses the named variable and supplied default" {
  unset DOTFILES_QQ_TIMEOUT
  run _dotfiles_ai_timeout DOTFILES_QQ_TIMEOUT 60
  assert_success
  assert_output "60"

  export DOTFILES_QQ_TIMEOUT=0
  run _dotfiles_ai_timeout DOTFILES_QQ_TIMEOUT 60
  assert_success
  assert_output "0"

  export DOTFILES_QQ_TIMEOUT=bogus
  run _dotfiles_ai_timeout DOTFILES_QQ_TIMEOUT 60
  assert_success
  assert_output "60"
}

@test "qq_timeout: defaults to 60 and sanitizes configured values" {
  unset DOTFILES_QQ_TIMEOUT
  run _dotfiles_qq_timeout
  assert_success
  assert_output "60"

  export DOTFILES_QQ_TIMEOUT=42
  run _dotfiles_qq_timeout
  assert_success
  assert_output "42"
}

# --- commit timeout wrapper ---

@test "commit_timeout: defaults to 15 when unset" {
  unset DOTFILES_COMMIT_TIMEOUT
  run _dotfiles_commit_timeout
  assert_success
  assert_output "15"
}

@test "commit_timeout: honors a numeric value" {
  export DOTFILES_COMMIT_TIMEOUT=42
  run _dotfiles_commit_timeout
  assert_success
  assert_output "42"
}

@test "commit_timeout: falls back to 15 for a non-numeric value" {
  export DOTFILES_COMMIT_TIMEOUT=bogus
  run _dotfiles_commit_timeout
  assert_success
  assert_output "15"
}

@test "commit_timeout: falls back to 15 for an empty value" {
  export DOTFILES_COMMIT_TIMEOUT=""
  run _dotfiles_commit_timeout
  assert_success
  assert_output "15"
}

# --- commit status ---

@test "commit status: reports opencode backend, model, availability" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:    opencode"
  assert_output --partial "model:      opencode-go/kimi-k2.7-code"
  assert_output --partial "available:  yes"
}

@test "commit status: reports agy backend, model, availability" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=agy
    agy() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:    agy"
  assert_output --partial "model:      gemini-3.7-flash-low"
  assert_output --partial "available:  yes"
}

@test "commit status: reflects a DOTFILES_AI_MODEL override" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    export DOTFILES_AI_MODEL='my/custom-model'
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:    opencode"
  assert_output --partial "model:      my/custom-model"
}

@test "commit status: defaults to opencode/kimi 2.7" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    unset DOTFILES_AI_BACKEND DOTFILES_COMMIT_BACKEND
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "backend:    opencode"
  assert_output --partial "model:      opencode-go/kimi-k2.7-code"
}

@test "commit status: reports the configured timeout" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    export DOTFILES_COMMIT_TIMEOUT=42
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "timeout:    42s"
}

@test "commit status: defaults both timeouts when unset" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    unset DOTFILES_COMMIT_TIMEOUT DOTFILES_QQ_TIMEOUT
    opencode() { :; }
    commit status
  "
  assert_success
  assert_output --partial "timeout:    15s"
  assert_output --partial "qq timeout: 60s"
}

# --- commit backend (setter/getter) ---

@test "commit backend opencode: exports the backend for the current shell" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    commit backend opencode > /dev/null
    echo \"BACKEND=\$DOTFILES_AI_BACKEND\"
  "
  assert_success
  assert_output --partial "BACKEND=opencode"
}

@test "commit backend agy: exports the backend for the current shell" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    commit backend agy > /dev/null
    echo \"BACKEND=\$DOTFILES_AI_BACKEND\"
  "
  assert_success
  assert_output --partial "BACKEND=agy"
}

@test "commit backend opencode: prints a confirmation including the model" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    commit backend opencode
  "
  assert_success
  assert_output --partial "commit backend set to opencode (model: opencode-go/kimi-k2.7-code) for this shell"
}

@test "commit backend: with no value prints the current backend" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    commit backend
  "
  assert_success
  assert_output "opencode"
}

@test "commit backend bogus: errors, returns 1, leaves the backend unchanged" {
  run --separate-stderr bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/ai.sh'
    . '$REPO_ROOT/lib/git.sh'
    export DOTFILES_AI_BACKEND=opencode
    commit backend bogus
    echo \"RC=\$? BACKEND=\$DOTFILES_AI_BACKEND\"
  "
  assert_success
  assert_output --partial "RC=1 BACKEND=opencode"
  echo "$stderr" | grep -qF 'unknown backend: bogus (expected claude, opencode, or agy)'
}

# --- durable default ---

@test "bash_profile: exports a DOTFILES_AI_BACKEND default" {
  run grep -E "^export DOTFILES_AI_BACKEND=opencode" "$REPO_ROOT/bash_profile"
  assert_success
}

@test "bash_profile: does not export the deprecated backend name" {
  run grep -E "^export DOTFILES_COMMIT_BACKEND=" "$REPO_ROOT/bash_profile"
  assert_failure
}

@test "bash_profile: exports a DOTFILES_COMMIT_TIMEOUT default" {
  run grep -E "^export DOTFILES_COMMIT_TIMEOUT=30" "$REPO_ROOT/bash_profile"
  assert_success
}
