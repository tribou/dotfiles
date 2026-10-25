# covers: scripts/test_changed.sh tests/*.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  SCRIPT="$REPO_ROOT/scripts/test_changed.sh"
}

# Plan for an explicit changed-file list, computed against this repo's headers.
plan_for() {
  run bash -c 'cd "$1" && shift && "$0" --list "$@"' "$SCRIPT" "$REPO_ROOT" "$@"
}

# Minimal git repo with two test files mapped to two lib files.
make_fixture_repo() {
  FIXTURE="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FIXTURE/tests" "$FIXTURE/lib"
  printf '# covers: lib/a.sh\n@test "a" { true; }\n' > "$FIXTURE/tests/a.bats"
  printf '# covers: lib/b.sh\n@test "b" { true; }\n' > "$FIXTURE/tests/b.bats"
  echo 'a() { :; }' > "$FIXTURE/lib/a.sh"
  echo 'b() { :; }' > "$FIXTURE/lib/b.sh"
  (
    cd "$FIXTURE" &&
      git init -q &&
      git add -A &&
      git -c user.name=t -c user.email=t@example.com commit -q -m init
  )
}

fixture_plan() {
  run bash -c 'cd "$1" && "$0" --list' "$SCRIPT" "$FIXTURE"
}

@test "test_changed: a mapped lib file selects only the tests that cover it" {
  plan_for lib/fzf.sh
  assert_success
  assert_line "unit tests/fzf_lib.bats"
  refute_line "unit tests/commit_command.bats"
  refute_line "unit all"
  assert_line "docker no"
}

@test "test_changed: a shared lib file runs the full unit suite" {
  plan_for lib/_shared.sh
  assert_success
  assert_line "unit all"
}

@test "test_changed: an unmapped file runs the full unit suite and Docker suite" {
  plan_for alacritty.toml
  assert_success
  assert_line "unit all"
  assert_line "docker yes"
}

@test "test_changed: docs-only changes run nothing" {
  plan_for docs/TESTING.md README.md
  assert_success
  assert_line "unit none"
  assert_line "docker no"
}

@test "test_changed: a changed test file selects itself" {
  plan_for tests/path.bats
  assert_success
  assert_line "unit tests/path.bats"
  refute_line "unit all"
}

@test "test_changed: a covers header wins over the no-unit-tests list" {
  plan_for skills/session-outline/SKILL.md
  assert_success
  assert_line "unit tests/session_outline.bats"
  refute_line "unit all"
}

@test "test_changed: role changes select their tests and the Docker suite" {
  plan_for roles/dotfiles/tasks/upgrade.yml
  assert_success
  assert_line "unit tests/upgrade_nvim.bats"
  assert_line "docker yes"
}

@test "test_changed: integration test changes run the Docker suite, not the full unit suite" {
  plan_for tests/integration/nvim_health.bats
  assert_success
  refute_line "unit all"
  assert_line "docker yes"
}

@test "test_changed: every unit test file has a covers header matching real files" {
  run bash -c 'cd "$1" && "$0" --check-headers' "$SCRIPT" "$REPO_ROOT"
  assert_success
}

@test "test_changed: --check-headers reports missing headers and stale patterns" {
  make_fixture_repo
  printf '@test "c" { true; }\n' > "$FIXTURE/tests/c.bats"
  printf '# covers: lib/gone.sh\n@test "d" { true; }\n' > "$FIXTURE/tests/d.bats"
  run bash -c 'cd "$1" && "$0" --check-headers' "$SCRIPT" "$FIXTURE"
  assert_failure
  assert_output --partial "tests/c.bats: missing"
  assert_output --partial "tests/d.bats: 'lib/gone.sh' matches no file"
}

@test "test_changed: detects uncommitted changes to tracked files" {
  make_fixture_repo
  echo '# edit' >> "$FIXTURE/lib/a.sh"
  fixture_plan
  assert_success
  assert_line "unit tests/a.bats"
  refute_line "unit tests/b.bats"
}

@test "test_changed: detects untracked files" {
  make_fixture_repo
  printf '# covers: lib/a.sh\n@test "n" { true; }\n' > "$FIXTURE/tests/new.bats"
  fixture_plan
  assert_success
  assert_line "unit tests/new.bats"
}

@test "test_changed: detects committed changes since DOTFILES_TEST_BASE" {
  make_fixture_repo
  echo '# edit' >> "$FIXTURE/lib/b.sh"
  (cd "$FIXTURE" && git -c user.name=t -c user.email=t@example.com commit -qam edit)
  run bash -c 'cd "$1" && DOTFILES_TEST_BASE=HEAD~1 "$0" --list' "$SCRIPT" "$FIXTURE"
  assert_success
  assert_line "unit tests/b.bats"
  refute_line "unit tests/a.bats"
}

@test "test_changed: reports nothing to test on a clean tree" {
  make_fixture_repo
  run bash -c 'cd "$1" && "$0"' "$SCRIPT" "$FIXTURE"
  assert_success
  assert_output --partial "nothing to test"
}
