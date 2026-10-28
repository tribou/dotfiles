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
