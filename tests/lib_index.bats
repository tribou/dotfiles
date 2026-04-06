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
