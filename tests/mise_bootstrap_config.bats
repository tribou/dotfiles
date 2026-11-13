# covers: mise.toml mise-config.toml scripts/doctor.sh bootstrap.sh justfile lib/fzf.sh scripts/bootstrap/converge.sh scripts/upgrade.sh docker-compose.yml .gitignore
setup() {
  load 'test_helper/common_setup'
  common_setup
  PROJECT="$REPO_ROOT/mise.toml"
  GLOBAL="$REPO_ROOT/mise-config.toml"
}

# Print "target source" for each whole-file [dotfiles] entry in mise.toml.
dotfile_entries() {
  awk '/^\[dotfiles\]/{f=1;next} /^\[/{f=0} f && /^"~\//' "$PROJECT" |
    awk -F'"' '{print $2, $4}'
}

@test "ansible is gone: no role, playbook, collections, or config remain" {
  for path in roles playbook.yml requirements.yml ansible.cfg inventory Brewfile.optional.example; do
    [ ! -e "$REPO_ROOT/$path" ]
  done
  ! grep -qE '^(ansible|uv|pipx)[[:space:]]*=' "$GLOBAL"
  ! grep -rqiE 'ansible-playbook|ansible-galaxy' "$REPO_ROOT/bootstrap.sh" "$REPO_ROOT/justfile" \
    "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/.github/workflows" "$REPO_ROOT/scripts/verify_mise_tools.sh"
}

@test "mise.toml deploys every managed dotfile as a symlink from the repo" {
  local expected=(
    "~/.bash_profile bash_profile"
    "~/.vimrc init.vim"
    "~/.gitconfig gitconfig"
    "~/.zshrc zshrc"
    "~/.tmux.conf tmux/tmux-conf"
    "~/.gnupg/gpg-agent.conf gpg-agent-conf"
    "~/.config/nvim/init.vim init.vim"
    "~/.config/nvim/coc-settings.json coc-settings.json"
    "~/.config/alacritty/alacritty.toml alacritty.toml"
    "~/.config/mise/config.toml mise-config.toml"
    "~/.local/bin/dotfiles_remote_browser_open.sh scripts/dotfiles_remote_browser_open.sh"
    "~/.local/bin/dotfiles_local_browser_helper.sh scripts/dotfiles_local_browser_helper.sh"
    "~/.local/share/nvim/site/autoload/plug.vim ~/.local/share/vim-plug/plug.vim"
  )
  local actual
  actual="$(dotfile_entries)"
  for entry in "${expected[@]}"; do
    echo "$actual" | grep -qxF "$entry" || fail "missing [dotfiles] entry: $entry"
  done
  [ "$(echo "$actual" | wc -l)" -eq "${#expected[@]}" ]
  # every relative source exists in the repo
  while read -r _ source; do
    case "$source" in "~/"*) continue ;; esac
    [ -e "$REPO_ROOT/$source" ] || fail "source missing: $source"
  done <<< "$actual"
}

@test "doctor checks exactly the repo-sourced symlinks mise.toml deploys" {
  local from_toml from_doctor
  from_toml="$(dotfile_entries | awk '$2 !~ /^~\// {print $1 "~" $2}' | sort)"
  from_doctor="$(sed -n '/symlinks=(/,/)/p' "$REPO_ROOT/scripts/doctor.sh" | grep -oE '"~/[^"]+"' | tr -d '"' | sed -E 's/^~([^~]+)~/~\1~/' | sort)"
  assert_equal "$from_doctor" "$from_toml"
}

@test "mise.toml clones TPM and vim-plug as bootstrap repos" {
  grep -qF '"~/.tmux/plugins/tpm" = { url = "https://github.com/tmux-plugins/tpm"' "$PROJECT"
  grep -qF '"~/.local/share/vim-plug" = { url = "https://github.com/junegunn/vim-plug"' "$PROJECT"
}

@test "mise.toml wires the pre-dotfiles hook, bootstrap task, and upgrade task to repo scripts" {
  awk '/^\[bootstrap.hooks.pre-dotfiles\]/,/^$/' "$PROJECT" | grep -qF '{{ config_root }}/scripts/bootstrap/pre_dotfiles.sh'
  awk '/^\[tasks.bootstrap\]/,/^$/' "$PROJECT" | grep -qF 'scripts/bootstrap/converge.sh'
  awk '/^\[tasks.upgrade\]/,/^$/' "$PROJECT" | grep -qF 'scripts/upgrade.sh'
  for script in scripts/bootstrap/pre_dotfiles.sh scripts/bootstrap/converge.sh scripts/upgrade.sh scripts/brew_cleanup.sh; do
    [ -x "$REPO_ROOT/$script" ] || fail "$script missing or not executable"
  done
}

@test "global config requires a mise with bootstrap dotfiles, repos, and brew prefix creation" {
  grep -qF 'min_version = "2026.11.7"' "$GLOBAL"
}

@test "global config owns OS prerequisites that Ansible used to install" {
  for pkg in curl git build-essential zlib1g-dev xdg-utils bash-completion openssh-client; do
    grep -qF "\"apt:${pkg}\" = \"latest\"" "$GLOBAL" || fail "apt:$pkg"
  done
  for pkg in curl git base-devel zlib bash-completion openssh; do
    grep -qF "\"pacman:${pkg}\" = \"latest\"" "$GLOBAL" || fail "pacman:$pkg"
  done
}

@test "global config owns rust and gopls as mise tools" {
  grep -qE '^rust[[:space:]]*=[[:space:]]*"stable"$' "$GLOBAL"
  grep -qF '"go:golang.org/x/tools/gopls" = "latest"' "$GLOBAL"
}

@test "macOS casks are mise brew-cask packages, opt-in via the optional drop-in" {
  grep -qF '"brew-cask:' "$REPO_ROOT/mise-config.optional.toml.example"
  ! grep -qE '^[[:space:]]*"brew-cask:alacritty"' "$GLOBAL" "$REPO_ROOT/mise-config.optional.toml.example"
  ! grep -qE '^[^#]*"brew-cask:' "$REPO_ROOT/mise-config.optional.toml.example"
}

@test "no beads integration remains outside historical plans" {
  run git -C "$REPO_ROOT" ls-files .beads
  assert_output ''
  run bash -c "cd '$REPO_ROOT' && git ls-files -z -- . ':!docs/superpowers/' ':!.gitignore' ':!tests/mise_bootstrap_config.bats' | xargs -0 grep -d skip -IliE 'beads|bd prime|bd -C|dolt' --"
  assert_output ''
}
