# covers: scripts/bootstrap/pre_dotfiles.sh mise.toml
setup() {
  load 'test_helper/common_setup'
  common_setup
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  SCRIPT="$REPO_ROOT/scripts/bootstrap/pre_dotfiles.sh"
}

@test "pre_dotfiles: creates directories, with ~/.ssh and ~/.gnupg private" {
  run "$SCRIPT"
  assert_success
  for d in dev/bin dev/go/pkg dev/go/src/github.com/tribou .config/mise/conf.d .local/bin .local/share/nvim/site/autoload .tmux; do
    [ -d "$HOME/$d" ] || fail "missing $d"
  done
  [ "$(stat -c %a "$HOME/.ssh" 2>/dev/null || stat -f %Lp "$HOME/.ssh")" = 700 ]
  [ "$(stat -c %a "$HOME/.gnupg" 2>/dev/null || stat -f %Lp "$HOME/.gnupg")" = 700 ]
}

@test "pre_dotfiles: tightens an existing world-readable ~/.gnupg" {
  mkdir -p "$HOME/.gnupg" && chmod 755 "$HOME/.gnupg"
  run "$SCRIPT"
  assert_success
  [ "$(stat -c %a "$HOME/.gnupg" 2>/dev/null || stat -f %Lp "$HOME/.gnupg")" = 700 ]
}

@test "pre_dotfiles: backs up regular files at managed targets so mise can link them" {
  printf 'mine\n' > "$HOME/.bash_profile"
  mkdir -p "$HOME/.config/nvim" && printf 'vim\n' > "$HOME/.config/nvim/init.vim"
  run "$SCRIPT"
  assert_success
  [ ! -e "$HOME/.bash_profile" ]
  [ "$(cat "$HOME/.bash_profile.backup")" = mine ]
  [ "$(cat "$HOME/.config/nvim/init.vim.backup")" = vim ]
  assert_output --partial 'changed: backed up ~/.bash_profile'
}

@test "pre_dotfiles: leaves symlinks and unmanaged files alone" {
  ln -s /nonexistent "$HOME/.zshrc"
  printf 'x\n' > "$HOME/.unmanaged"
  run "$SCRIPT"
  assert_success
  [ -L "$HOME/.zshrc" ]
  [ -f "$HOME/.unmanaged" ]
  [ ! -e "$HOME/.zshrc.backup" ]
}

@test "pre_dotfiles: second run reports no changes" {
  printf 'mine\n' > "$HOME/.gitconfig"
  run "$SCRIPT"
  assert_success
  run "$SCRIPT"
  assert_success
  refute_output --partial 'changed:'
}
