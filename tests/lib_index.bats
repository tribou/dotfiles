# tests/lib_index.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "common_setup loads all library modules via lib/index.sh" {
  run bash -c "
    load_helper() {
      REPO_ROOT=\"\$REPO_ROOT\"
      . \"\$REPO_ROOT/tests/test_helper/common_setup.bash\"
      common_setup
    }
    load_helper
    type is_macos >/dev/null 2>&1 || exit 1
    type bashcheck >/dev/null 2>&1 || exit 2
  "
  assert_success
}

@test "lib index sources every lib file except index.sh" {
  run bash -c "
    set -euo pipefail
    tmpdir=\$(mktemp -d)
    trap 'rm -rf \"\$tmpdir\"' EXIT

    mkdir -p \"\$tmpdir/lib\"

    cat > \"\$tmpdir/lib/agent_overrides.sh\" <<'EOF'
AGENT_OVERRIDES_SOURCED=1
EOF

    cat > \"\$tmpdir/lib/normal.sh\" <<'EOF'
NORMAL_SOURCED=1
EOF

    export DOTFILES=\"\$tmpdir\"
    . '$REPO_ROOT/lib/index.sh'

    printf 'normal=%s agent=%s\n' \"\${NORMAL_SOURCED:-0}\" \"\${AGENT_OVERRIDES_SOURCED:-0}\"
  "

  assert_success
  assert_output "normal=1 agent=1"
}

@test "lib index sources underscore modules before regular modules" {
  run bash -c "
    set -euo pipefail
    tmpdir=\$(mktemp -d)
    trap 'rm -rf \"\$tmpdir\"' EXIT

    mkdir -p \"\$tmpdir/lib\"

    cat > \"\$tmpdir/lib/_z_shared.sh\" <<'EOF'
LOAD_ORDER=\"\${LOAD_ORDER:+\$LOAD_ORDER,}underscore\"
EOF

    cat > \"\$tmpdir/lib/a_regular.sh\" <<'EOF'
LOAD_ORDER=\"\${LOAD_ORDER:+\$LOAD_ORDER,}regular\"
EOF

    export DOTFILES=\"\$tmpdir\"
    export LC_ALL=en_US.UTF-8
    . '$REPO_ROOT/lib/index.sh'

    printf '%s\n' \"\$LOAD_ORDER\"
  "

  assert_success
  assert_output "underscore,regular"
}

@test "lib modules over 300 lines emit a soft warning" {
  local file line_count relative_file
  for file in "$REPO_ROOT"/lib/*.sh
  do
    line_count=$(wc -l < "$file")
    if [ "$line_count" -gt 300 ]; then
      relative_file=${file#"$REPO_ROOT/"}
      printf '# WARNING: %s has %d lines (soft limit: 300)\n' \
        "$relative_file" "$line_count" >&3
    fi
  done

  return 0
}
