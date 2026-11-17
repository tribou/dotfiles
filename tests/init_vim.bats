# covers: init.vim vim/*.vim
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

require_nvim() {
  command -v nvim >/dev/null || skip "nvim not installed"
}

# Source init.vim (and the vim/*.vim files it sources) in an nvim that has no
# plugins: HOME and XDG dirs point at the test tmpdir, so vim-plug and every
# plugin are absent and their errors are silenced. Extra -c commands follow.
# Call require_nvim first: a skip inside `run` only ends run's subshell.
source_init_vim_isolated() {
  local home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$home"
  HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" XDG_CACHE_HOME="$home/.cache" \
    DOTFILES="$REPO_ROOT" \
    nvim --headless -u NONE -i NONE -c "silent! source $REPO_ROOT/init.vim" "$@" -c 'qa!'
}

@test "init.vim: re-sourcing (<Leader>r) does not duplicate its autocmds" {
  require_nvim
  run source_init_vim_isolated \
    -c "redir! > $BATS_TEST_TMPDIR/once | silent autocmd | redir END" \
    -c "silent! source $REPO_ROOT/init.vim" \
    -c "redir! > $BATS_TEST_TMPDIR/twice | silent autocmd | redir END"
  [ "$status" -eq 0 ]
  [ -s "$BATS_TEST_TMPDIR/once" ]
  # Sorted: re-running `syntax enable` reorders its own group without adding to it.
  sort "$BATS_TEST_TMPDIR/once" > "$BATS_TEST_TMPDIR/once.sorted"
  sort "$BATS_TEST_TMPDIR/twice" > "$BATS_TEST_TMPDIR/twice.sorted"
  run diff "$BATS_TEST_TMPDIR/once.sorted" "$BATS_TEST_TMPDIR/twice.sorted"
  assert_success
}

@test "init.vim: Makefiles keep hard tabs at a width of 4" {
  require_nvim
  local mk="$BATS_TEST_TMPDIR/Makefile"
  printf 'all:\n\techo hi\n' > "$mk"
  run source_init_vim_isolated -c "edit $mk" \
    -c "call writefile([&filetype, &expandtab, &tabstop, &shiftwidth], '$BATS_TEST_TMPDIR/out')"
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/out"
  assert_line --index 0 "make"
  assert_line --index 1 "0"
  assert_line --index 2 "4"
  assert_line --index 3 "4"
}

@test "keymaps: <Leader>r re-sources the running config (\$MYVIMRC), not ~/.vimrc" {
  # ~/.vimrc is not nvim's config; nvim loads ~/.config/nvim/init.vim.
  require_nvim
  run source_init_vim_isolated \
    -c "call writefile([maparg('<Leader>r', 'n')], '$BATS_TEST_TMPDIR/out')"
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/out"
  assert_output --partial 'source $MYVIMRC'
}

@test "ale.vim: every configured linter exists in the installed ALE" {
  # Reads the installed ALE (never installs or updates it); CI has none and skips.
  command -v nvim >/dev/null || skip "nvim not installed"
  local ale="${DOTFILES_TEST_ALE_DIR:-$HOME/.local/share/nvim/plugged/ale}"
  [ -d "$ale/ale_linters" ] || skip "ALE not installed at $ale"
  run nvim --headless -u NONE -i NONE \
    -c "set rtp^=$ale" \
    -c "runtime plugin/ale.vim" \
    -c "source $REPO_ROOT/vim/ale.vim" \
    -c "let g:missing = []" \
    -c "for [g:ft, g:names] in items(g:ale_linters) | let g:have = map(ale#linter#Get(g:ft), 'v:val.name') | let g:missing += map(filter(copy(g:names), 'index(g:have, v:val) < 0'), 'g:ft . \":\" . v:val') | endfor" \
    -c "call writefile(['checked'] + g:missing, '$BATS_TEST_TMPDIR/out')" \
    -c 'qa!'
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/out"
  assert_output "checked"
}

@test "init.vim: uses the maintained colorizer fork (norcalli's calls deprecated vim.tbl_flatten)" {
  # norcalli/nvim-colorizer.lua warns "vim.tbl_flatten is deprecated" on every
  # start under nvim 0.12; catgoose/nvim-colorizer.lua is the maintained fork.
  run grep -nE "^[[:space:]]*Plug 'norcalli/nvim-colorizer\.lua'" "$REPO_ROOT/init.vim"
  [ "$status" -ne 0 ]
  run grep -nE "^[[:space:]]*Plug 'catgoose/nvim-colorizer\.lua'" "$REPO_ROOT/init.vim"
  assert_success
}
