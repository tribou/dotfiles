setup() {
  load 'test_helper/common_setup'
  common_setup
  STUB_BIN="$(mktemp -d)"
  TMUX_PASTE_LOG="$(mktemp)"
  export TMUX_PASTE_LOG
}

teardown() {
  rm -rf "$STUB_BIN"
  rm -f "$TMUX_PASTE_LOG"
}

@test "tmux-paste.sh uses pbpaste when available" {
  cat > "$STUB_BIN/pbpaste" <<'EOF'
#!/usr/bin/env bash
echo "pbpaste-clipboard"
EOF
  chmod +x "$STUB_BIN/pbpaste"

  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$TMUX_PASTE_LOG"
EOF
  chmod +x "$STUB_BIN/tmux"

  run bash -c "export PATH='$STUB_BIN:$PATH'; '$REPO_ROOT/scripts/tmux-paste.sh'"
  assert_success
  run grep -c "set-buffer pbpaste-clipboard" "$TMUX_PASTE_LOG"
  assert_output "1"
  run grep -c "paste-buffer -p" "$TMUX_PASTE_LOG"
  assert_output "1"
  run grep -c "display-message pasted!" "$TMUX_PASTE_LOG"
  assert_output "1"
}

@test "tmux-paste.sh uses xclip when pbpaste is absent" {
  cat > "$STUB_BIN/xclip" <<'EOF'
#!/usr/bin/env bash
echo "xclip-clipboard"
EOF
  chmod +x "$STUB_BIN/xclip"

  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$TMUX_PASTE_LOG"
EOF
  chmod +x "$STUB_BIN/tmux"

  run bash -c "export PATH='$STUB_BIN:/bin'; '$REPO_ROOT/scripts/tmux-paste.sh'"
  assert_success
  run grep -c "set-buffer xclip-clipboard" "$TMUX_PASTE_LOG"
  assert_output "1"
}

@test "tmux-paste.sh sets empty buffer when no clipboard tool exists" {
  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$TMUX_PASTE_LOG"
EOF
  chmod +x "$STUB_BIN/tmux"

  run bash -c "export PATH='$STUB_BIN:/bin'; '$REPO_ROOT/scripts/tmux-paste.sh'"
  assert_success
  run grep -c "^set-buffer \$" "$TMUX_PASTE_LOG"
  assert_output "1"
}

@test "tmux-paste.sh --copy-mode exits copy mode after paste" {
  cat > "$STUB_BIN/pbpaste" <<'EOF'
#!/usr/bin/env bash
echo "copy-mode-clipboard"
EOF
  chmod +x "$STUB_BIN/pbpaste"

  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$TMUX_PASTE_LOG"
EOF
  chmod +x "$STUB_BIN/tmux"

  run bash -c "export PATH='$STUB_BIN:$PATH'; '$REPO_ROOT/scripts/tmux-paste.sh' --copy-mode"
  assert_success
  run grep -c "send -X cancel" "$TMUX_PASTE_LOG"
  assert_output "1"
}

@test "tmux-paste.sh tolerates a failing clipboard tool" {
  cat > "$STUB_BIN/pbpaste" <<'EOF'
#!/usr/bin/env bash
echo "pbpaste failed" >&2
exit 1
EOF
  chmod +x "$STUB_BIN/pbpaste"

  cat > "$STUB_BIN/tmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$TMUX_PASTE_LOG"
EOF
  chmod +x "$STUB_BIN/tmux"

  run bash -c "export PATH='$STUB_BIN:$PATH'; '$REPO_ROOT/scripts/tmux-paste.sh'"
  assert_success
  run grep -c "^set-buffer \$" "$TMUX_PASTE_LOG"
  assert_output "1"
}
