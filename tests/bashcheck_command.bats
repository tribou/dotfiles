setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Fixture content is built with printf rather than a heredoc containing a
# literal "@test ... {" line, because bats-preprocess scans every physical
# line of *this* file for that pattern and would mistake an embedded heredoc
# line for a real test boundary, silently mangling the fixture.

@test "bashcheck: does not fail a valid .bats file due to @test block syntax" {
  local tmpdir fixture
  tmpdir="$(mktemp -d)"
  fixture="$tmpdir/example.bats"
  {
    printf 'setup() {\n'
    printf '  :\n'
    printf '}\n'
    printf '\n'
    printf '%s "example test" {\n' '@test'
    printf '  run true\n'
    printf '}\n'
  } > "$fixture"

  run bashcheck "$fixture"
  assert_success
  assert_output --partial "All files passed"
  rm -rf "$tmpdir"
}

@test "bashcheck: still reports a real shellcheck violation in a .bats file" {
  local tmpdir fixture
  tmpdir="$(mktemp -d)"
  fixture="$tmpdir/broken.bats"
  {
    printf '%s "example test" {\n' '@test'
    printf "  local x=\$1\n"
    printf "  echo \$x\n"
    printf '}\n'
  } > "$fixture"

  run bashcheck "$fixture"
  assert_failure
  rm -rf "$tmpdir"
}

@test "bashcheck: still runs bash -n syntax check for non-.bats files" {
  local tmpdir fixture
  tmpdir="$(mktemp -d)"
  fixture="$tmpdir/broken.sh"
  cat > "$fixture" <<'EOF'
function broken() {
  echo "missing closing brace"
EOF

  run bashcheck "$fixture"
  assert_failure
  rm -rf "$tmpdir"
}
