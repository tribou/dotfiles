#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "local_browser_helper: responds with 200 and opens browser on valid request" {
  # Stub BROWSER to prevent webbrowser.open() from launching a real browser
  export BROWSER="true"

  # Start the helper in background on a test port
  local test_port=15680
  python3 "$REPO_ROOT/scripts/dotfiles_local_browser_helper.sh" "$test_port" &
  local server_pid=$!

  # Wait for server to start
  sleep 1

  # Make request and capture response
  run curl -sf "http://127.0.0.1:$test_port/open?url=http%3A//localhost%3A15678"

  # Clean up the server process
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true

  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "local_browser_helper: responds with 404 for unknown paths" {
  local test_port=15681
  python3 "$REPO_ROOT/scripts/dotfiles_local_browser_helper.sh" "$test_port" &
  local server_pid=$!

  sleep 1

  run curl -sf "http://127.0.0.1:$test_port/unknown"

  # Clean up the server process
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true

  [ "$status" -eq 22 ]  # curl exit code 22 = HTTP 404
}
