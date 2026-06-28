setup() {
  load 'test_helper/common_setup'
  common_setup
  STUB_BIN="$(mktemp -d)"
  TMUX_COPY_LOG="$(mktemp)"
  export TMUX_COPY_LOG
}

teardown() {
  rm -rf "$STUB_BIN"
  rm -f "$TMUX_COPY_LOG"
}

# Stub `tmux show-buffer` to emit the given text; all other tmux calls are no-ops.
_stub_tmux_buffer() {
  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "show-buffer" ]; then echo "$1"; fi
EOF
  chmod +x "$STUB_BIN/tmux"
}

@test "tmux-copy.sh pipes the tmux buffer to pbcopy when available" {
  _stub_tmux_buffer "copied-word"

  cat > "$STUB_BIN/pbcopy" <<EOF
#!/usr/bin/env bash
cat >> "$TMUX_COPY_LOG"
EOF
  chmod +x "$STUB_BIN/pbcopy"

  run bash -c "export PATH='$STUB_BIN:$PATH'; '$REPO_ROOT/scripts/tmux-copy.sh'"
  assert_success
  run cat "$TMUX_COPY_LOG"
  assert_output "copied-word"
}

@test "tmux-copy.sh pipes the tmux buffer to xclip when pbcopy is absent" {
  _stub_tmux_buffer "copied-line"

  cat > "$STUB_BIN/xclip" <<EOF
#!/usr/bin/env bash
echo "args: \$*" >> "$TMUX_COPY_LOG"
cat >> "$TMUX_COPY_LOG"
EOF
  chmod +x "$STUB_BIN/xclip"

  run bash -c "export PATH='$STUB_BIN:/bin'; '$REPO_ROOT/scripts/tmux-copy.sh'"
  assert_success
  run grep -c "args: -selection clipboard" "$TMUX_COPY_LOG"
  assert_output "1"
  run grep -c "copied-line" "$TMUX_COPY_LOG"
  assert_output "1"
}

@test "tmux-copy.sh exits cleanly when no clipboard tool exists" {
  _stub_tmux_buffer "orphan"

  run bash -c "export PATH='$STUB_BIN:/bin'; '$REPO_ROOT/scripts/tmux-copy.sh'"
  assert_success
}
