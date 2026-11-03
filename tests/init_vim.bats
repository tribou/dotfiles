# covers: init.vim
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "init.vim: CopilotChat require is guarded with pcall to avoid errors on fresh install" {
  # Unguarded: require("CopilotChat")  =>  must NOT exist bare
  # Guarded: pcall(require, "CopilotChat") or pcall(function() require(...) end)
  run bash -c "grep -n 'require.*CopilotChat' \"$REPO_ROOT/init.vim\" | grep -v pcall"
  [ "$status" -ne 0 ]
}

@test "init.vim: colorizer require is guarded with pcall to avoid errors on fresh install" {
  run bash -c "grep -n 'require.*colorizer' \"$REPO_ROOT/init.vim\" | grep -v pcall"
  [ "$status" -ne 0 ]
}

@test "init.vim: does not pin g:python3_host_prog to whatever python3 is first on PATH" {
  # Pinning to exepath('python3') breaks the provider whenever that python3's
  # minor version changes (e.g. brew python 3.14 -> 3.15) because pynvim is
  # installed per-interpreter. Neovim's own detection finds an interpreter
  # that actually has pynvim (pynvim-python, then python3, python3.14, ...).
  run grep -nE '^[[:space:]]*let[[:space:]]+g:python3_host_prog' "$REPO_ROOT/init.vim"
  [ "$status" -ne 0 ]
}

@test "init.vim: OSC 52 clipboard paste preserves the yank's register type (yy then p pastes linewise)" {
  # A g:clipboard paste function that returns only a list of lines makes nvim
  # guess the register type, and a single line guesses charwise — so yy + p
  # pastes at the cursor instead of on a new line. It must return [lines, regtype].
  command -v nvim >/dev/null || skip "nvim not installed"
  local block="$BATS_TEST_TMPDIR/clipboard.vim"
  sed -n '/^set clipboard=/,/^  \\ }$/p' "$REPO_ROOT/init.vim" > "$block"
  grep -q 'g:clipboard' "$block"
  run nvim --headless -u NONE -i NONE \
    -c "source $block" \
    -c "call setreg('0', ['alpha'], 'V')" \
    -c "call writefile([string(call(g:clipboard.paste['+'], [])), string(call(g:clipboard.paste['*'], []))], '$BATS_TEST_TMPDIR/out')" \
    -c 'qa!'
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/out"
  assert_line --index 0 "[['alpha'], 'V']"
  assert_line --index 1 "[['alpha'], 'V']"
}
