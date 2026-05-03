setup() {
  load 'test_helper/common_setup'
  common_setup
  # Create a temp bin dir to place stub commands in
  STUB_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "selects pbcopy when pbcopy is available" {
  touch "$STUB_BIN/pbcopy" && chmod +x "$STUB_BIN/pbcopy"
  run bash -c "export PATH='$STUB_BIN:$PATH' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "pbcopy"
}

@test "selects xclip with clipboard selection when only xclip available" {
  touch "$STUB_BIN/xclip" && chmod +x "$STUB_BIN/xclip"
  run bash -c "export PATH='$STUB_BIN' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "xclip -selection clipboard"
}

@test "returns empty when neither pbcopy nor xclip available" {
  run bash -c "export PATH='$STUB_BIN' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output ""
}

@test "pbcopy takes priority over xclip when both available" {
  touch "$STUB_BIN/pbcopy" "$STUB_BIN/xclip"
  chmod +x "$STUB_BIN/pbcopy" "$STUB_BIN/xclip"
  run bash -c "export PATH='$STUB_BIN' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_write_cmd"
  assert_output "pbcopy"
}

@test "selects pbpaste when pbpaste is available" {
  touch "$STUB_BIN/pbpaste" && chmod +x "$STUB_BIN/pbpaste"
  run bash -c "export PATH='$STUB_BIN:$PATH' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_read_cmd"
  assert_output "pbpaste"
}

@test "selects xclip read flags when only xclip available" {
  touch "$STUB_BIN/xclip" && chmod +x "$STUB_BIN/xclip"
  run bash -c "export PATH='$STUB_BIN' && . '$REPO_ROOT/lib/_shared.sh' && . '$REPO_ROOT/lib/commands.sh' && _dotfiles_clipboard_read_cmd"
  assert_output "xclip -o -sel clipboard"
}
