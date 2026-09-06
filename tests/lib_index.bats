# tests/lib_index.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
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
