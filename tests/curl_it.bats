# covers: lib/curl_it.sh
# tests/curl_it.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "curlit: stops with an error when the request fails" {
  run timeout 5 bash -c "
    . '$REPO_ROOT/lib/curl_it.sh'
    curl() { return 6; }
    sleep() { :; }
    curlit http://dead.invalid/
  "
  assert_failure 1
  assert_output --partial "Call to http://dead.invalid/ failed"
}

@test "curlit: stops with an error when the response is empty" {
  run timeout 5 bash -c "
    . '$REPO_ROOT/lib/curl_it.sh'
    curl() { return 0; }
    sleep() { :; }
    curlit http://dead.invalid/
  "
  assert_failure 1
  assert_output --partial "Call to http://dead.invalid/ failed"
}

@test "curlit: prints a timestamped status line and passes the URL as one argument" {
  run timeout 5 bash -c "
    . '$REPO_ROOT/lib/curl_it.sh'
    calls=0
    curl() {
      [ -e '$BATS_TEST_TMPDIR/called' ] && return 7
      touch '$BATS_TEST_TMPDIR/called'
      printf 'HTTP/2 200 [%s]\r\nserver: x\r\n' \"\${@: -1}\"
    }
    sleep() { :; }
    curlit 'http://example.invalid/a b'
  "
  assert_failure 1
  assert_line --index 0 --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}[+-][0-9]{4} HTTP/2 200 \[http://example.invalid/a b\]$'
}
