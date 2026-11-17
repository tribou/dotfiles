# covers: scripts/perf_report.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  # perf_report.sh reads ../tests/.perf_log.jsonl relative to itself, so run a
  # copy against a fixture log.
  FIXTURE="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FIXTURE/scripts" "$FIXTURE/tests"
  cp "$REPO_ROOT/scripts/perf_report.sh" "$FIXTURE/scripts/"
}

@test "perf_report: a metric with no log entries does not abort the report" {
  printf '%s\n' '{"metric": "prompt_git_ms", "value": 42, "commit": "abc1234", "timestamp": "2026-11-17T10:20:30Z"}' \
    > "$FIXTURE/tests/.perf_log.jsonl"
  run "$FIXTURE/scripts/perf_report.sh"
  assert_success
  assert_output --partial 'Git Prompt Render Time'
  assert_output --partial '[abc1234 @ 10:20]'
}
