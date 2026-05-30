#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup
  STUB_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "remote_browser_open: calls curl with encoded URL" {
  # Stub curl to capture arguments and succeed
  cat > "$STUB_BIN/curl" <<'EOF'
#!/usr/bin/env bash
echo "$@" > "$CURL_CAPTURE"
exit 0
EOF
  chmod +x "$STUB_BIN/curl"

  export CURL_CAPTURE="$(mktemp)"
  export PATH="$STUB_BIN:$PATH"

  run bash -c "'$REPO_ROOT/scripts/dotfiles_remote_browser_open.sh' 'http://localhost:15678?page=foo bar'"

  [ "$status" -eq 0 ]
  local captured_args
  captured_args="$(cat "$CURL_CAPTURE")"
  [[ "$captured_args" == *"http://localhost:15679/open?url="* ]]
  [[ "$captured_args" == *"foo%20bar"* ]]
}

@test "remote_browser_open: prints error when curl fails" {
  # Stub curl to always fail
  cat > "$STUB_BIN/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$STUB_BIN/curl"

  export PATH="$STUB_BIN:$PATH"

  run bash -c "'$REPO_ROOT/scripts/dotfiles_remote_browser_open.sh' 'http://localhost:15678'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"local browser helper not running"* ]]
  [[ "$output" == *"dotfiles_local_browser_helper.sh"* ]]
}
