# shellcheck disable=SC2016
bats_require_minimum_version 1.5.0

setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "qq: non-interactive calls join real arguments with spaces" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf "answer for: %s\n" "${!#}"; }
    _dotfiles_qq what is rebase
  '
  assert_success
  assert_output "answer for: Answer concisely for display in a terminal. Prefer short answers; use code blocks for commands.

what is rebase"
  refute_output --partial "Asking Claude"
  assert_output --partial "answer for:"
  echo "$stderr" | grep -qF "Asking Claude..."
}

@test "qq: wrapper is passed as one prompt argument and status is ordinary question text" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf "argc=%s\nprompt=%s\n" "$#" "${!#}"; }
    _dotfiles_qq status of my PR
  '
  assert_success
  assert_output --partial "prompt=Answer concisely for display in a terminal. Prefer short answers; use code blocks for commands."
  assert_output --partial "status of my PR"
  refute_output --partial "backend:"
}

@test "qq: opencode denies tools and runs pure in an empty cwd" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=opencode
    caller=$PWD
    opencode() {
      printf "permission=%s\ncaller=%s\ncwd=%s\n" "$OPENCODE_PERMISSION" "$caller" "$PWD"
      printf "arg=%s\n" "$@"
      printf "entries=%s\n" "$(ls -A | wc -l | tr -d " ")"
    }
    _dotfiles_qq explain rebase
  '
  assert_success
  assert_output --partial 'permission="deny"'
  assert_output --partial "arg=run
arg=--pure
arg=--model
arg=opencode-go/kimi-k2.7-code"
  assert_output --partial "entries=0"
  caller=$(printf '%s\n' "$output" | sed -n 's/^caller=//p')
  cwd=$(printf '%s\n' "$output" | sed -n 's/^cwd=//p')
  [ "$caller" != "$cwd" ]
}

@test "qq: claude disables built-in and MCP tools without session persistence" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf "arg=<%s>\n" "$@"; }
    _dotfiles_qq explain rebase
  '
  assert_success
  assert_output --partial "arg=<-p>
arg=<--model>
arg=<haiku>
arg=<--tools>
arg=<>
arg=<--disallowedTools>
arg=<mcp__*>
arg=<--safe-mode>
arg=<--no-session-persistence>
arg=<-->"
}

@test "qq: agy uses headless mode without adding the caller directory" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=agy
    caller=$PWD
    agy() {
      printf "caller=%s\ncwd=%s\n" "$caller" "$PWD"
      printf "arg=%s\n" "$@"
    }
    _dotfiles_qq explain rebase
  '
  assert_success
  assert_output --partial "arg=-p"
  assert_output --partial "arg=--model
arg=gemini-3.7-flash-low"
  refute_output --partial "arg=--add-dir"
  caller=$(printf '%s\n' "$output" | sed -n 's/^caller=//p')
  cwd=$(printf '%s\n' "$output" | sed -n 's/^cwd=//p')
  [ "$caller" != "$cwd" ]
}

@test "qq: preserves internal newlines and trims surrounding blank lines" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf " \n\nUse this:\n\`\`\`bash\nprintf ok\n\`\`\`\n \n\n"; }
    _dotfiles_qq show command
  '
  assert_success
  assert_output "Use this:
\`\`\`bash
printf ok
\`\`\`"
}

@test "qq: leaves caller cwd unchanged after success" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf answer; }
    before=$PWD
    _dotfiles_qq question
    printf "before=%s\nafter=%s\n" "$before" "$PWD" >&2
  '
  assert_success
  before=$(printf '%s\n' "$stderr" | sed -n 's/^before=//p')
  after=$(printf '%s\n' "$stderr" | sed -n 's/^after=//p')
  [ "$before" = "$after" ]
}

@test "qq: removes its temporary directory after success" {
  mkdir "$BATS_TEST_TMPDIR/tmp-root"
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude TMPDIR="$1"
    claude() { printf answer; }
    _dotfiles_qq question
  ' _ "$BATS_TEST_TMPDIR/tmp-root"
  assert_success
  run bash -c 'shopt -s nullglob; paths=("$1"/*); echo "${#paths[@]}"' _ "$BATS_TEST_TMPDIR/tmp-root"
  assert_output "0"
}

@test "qq: missing backend reports stderr only and returns 1" {
  local empty_path="$BATS_TEST_TMPDIR/empty-bin"
  mkdir "$empty_path"
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude PATH="$1"
    _dotfiles_qq question
  ' _ "$empty_path"
  assert_failure
  assert_output ""
  assert_equal "$stderr" "qq: claude not found"
}

@test "qq: empty backend output reports stderr only and returns 1" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf " \n\n"; }
    _dotfiles_qq question
  '
  assert_failure
  assert_output ""
  echo "$stderr" | grep -qF "qq: claude returned no answer"
}

@test "qq: nonzero backend reports stderr only and returns 1" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { printf noisy-backend-error >&2; return 7; }
    _dotfiles_qq question
  '
  assert_failure
  assert_output ""
  refute_output --partial "noisy-backend-error"
  echo "$stderr" | grep -qF "qq: claude returned no answer"
}

@test "qq: timeout reports 124 and the resolved timeout" {
  run -124 --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude DOTFILES_QQ_TIMEOUT=1
    claude() { command sleep 10; printf late; }
    _dotfiles_qq question
  '
  assert_output ""
  echo "$stderr" | grep -qF "qq: claude timed out after 1s"
}

@test "qq: Ctrl-C reports canceled and returns 130" {
  run -130 --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    claude() { command sleep 10; printf late; }
    (command sleep 0.2; kill -INT $$) &
    _dotfiles_qq question
  '
  assert_output ""
  echo "$stderr" | grep -qF "qq canceled"
}

@test "qq: prompt Ctrl-C returns 130 without calling the backend" {
  run -130 --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude
    read() { return 130; }
    claude() { printf should-not-run; }
    _dotfiles_qq
  '
  assert_output ""
  refute_output --partial "should-not-run"
}

@test "qq: zero timeout waits for a slow backend" {
  run --separate-stderr bash -c '
    . "$REPO_ROOT/lib/ai.sh"
    export DOTFILES_AI_BACKEND=claude DOTFILES_QQ_TIMEOUT=0
    claude() { command sleep 0.2; printf answer; }
    _dotfiles_qq question
  '
  assert_success
  assert_output "answer"
}
