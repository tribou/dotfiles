setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "mise config owns tools, language packages, and formula artifacts" {
  local config="$REPO_ROOT/mise-config.toml"
  grep -qF 'min_version = "2026.7.5"' "$config"
  grep -qE '^node[[:space:]]*=[[:space:]]*"lts"$' "$config"
  grep -qE '^ruby[[:space:]]*=[[:space:]]*"3"$' "$config"
  grep -qF 'postinstall = "python -m pip install --upgrade pynvim"' "$config"
  grep -qF '[settings.npm]' "$config"
  grep -qF 'package_manager = "npm"' "$config"

  for tool in ansible neovim jq fd ripgrep bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux; do
    grep -qE "^${tool}[[:space:]]*=[[:space:]]*\"latest\"$" "$config"
  done
  for package in eas-cli eslint_d editorconfig intelephense js-yaml jsonlint neovim prettier react-devtools nodemon tern tslint typescript bash-language-server flow-bin vue-language-server vscode-css-languageserver-bin vscode-html-languageserver-bin; do
    grep -qF "\"npm:${package}\" = \"latest\"" "$config"
  done
  for package in neovim solargraph; do
    grep -qF "\"gem:${package}\" = \"latest\"" "$config"
  done

  for formula in bash git zlib htop gnupg editorconfig watchman ssh-copy-id git-extras lynx beads; do
    grep -qF "\"brew:${formula}\" = \"latest\"" "$config"
  done
  run grep -qF '"brew:gpg" = "latest"' "$config"
  assert_failure
  run grep -qF '"brew:alacritty"' "$config"
  assert_failure
  grep -qF '"brew:gcc" = { version = "latest", os = "linux" }' "$config"
  for formula in bash-completion reattach-to-user-namespace tmux-mem-cpu-load; do
    grep -qF "\"brew:${formula}\" = { version = \"latest\", os = \"macos/arm64\" }" "$config"
  done
}

@test "legacy package files, links, and provider installers are removed" {
  for file in default-node-packages default-python-packages default-gems; do
    [ ! -e "$REPO_ROOT/$file" ]
    ! grep -qF "$file" "$REPO_ROOT/roles/dotfiles/tasks/links.yml"
  done
  ! grep -qF 'name: pynvim' "$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
  ! grep -qF 'name: neovim' "$REPO_ROOT/roles/dotfiles/tasks/nvim.yml"
}

@test "optional mise config owns optional tools and formulae while Brewfile is cask-only" {
  local mise_optional="$REPO_ROOT/mise-config.optional.toml.example"
  local brew_optional="$REPO_ROOT/Brewfile.optional.example"

  for tool in awscli terraform-ls navi tlrc tfenv; do
    grep -qE "^#[[:space:]]+${tool}[[:space:]]*=" "$mise_optional"
  done
  for formula in nmap tree dos2unix tidy-html5 ngrok tor rename renameutils vimpager; do
    grep -qF "brew:${formula}" "$mise_optional" || grep -qF "$formula" "$mise_optional"
  done
  ! grep -qE '^[[:space:]]*#?[[:space:]]*brew[[:space:]]+"' "$brew_optional"
  grep -qF '# cask ' "$brew_optional"
}

@test "repository never uses manager-wide brew prune" {
  ! grep -R -qF 'bootstrap packages prune --manager brew' \
    "$REPO_ROOT/bootstrap.sh" "$REPO_ROOT/roles" "$REPO_ROOT/justfile" "$REPO_ROOT/scripts"
}

@test "Ansible has no repository-managed formula inventory" {
  local defaults="$REPO_ROOT/roles/dotfiles/defaults/main.yml"
  ! grep -qE '^dotfiles_brew_(core|linux|macos_formulae):' "$defaults"
  ! grep -R -qF 'upgrade_all: true' "$REPO_ROOT/roles/dotfiles/tasks"
}

@test "role verifies mise before targeted cleanup and cask-only Homebrew" {
  local main="$REPO_ROOT/roles/dotfiles/tasks/main.yml"
  local mise_line cleanup_line brew_line casks_line
  mise_line="$(grep -nF 'mise.yml' "$main" | cut -d: -f1)"
  cleanup_line="$(grep -nF 'brew_cleanup.yml' "$main" | cut -d: -f1)"
  brew_line="$(grep -nF 'brew.yml' "$main" | cut -d: -f1)"
  casks_line="$(grep -nF 'brew_casks.yml' "$main" | cut -d: -f1)"
  [ "$mise_line" -lt "$cleanup_line" ]
  [ "$cleanup_line" -lt "$brew_line" ]
  [ "$brew_line" -lt "$casks_line" ]
}

@test "cleanup targets only formulae replaced by qualified tools" {
  local cleanup="$REPO_ROOT/roles/dotfiles/tasks/brew_cleanup.yml"
  grep -qF 'list --formula' "$cleanup"
  grep -qF 'uninstall --formula' "$cleanup"
  grep -qF 'failed_when: false' "$cleanup"
  grep -qF 'dotfiles_brew_cleanup_failures' "$cleanup"
  grep -qF 'failure.item.item' "$cleanup"
  grep -qF 'failure.stderr' "$cleanup"
  ! grep -qF -- '--ignore-dependencies' "$cleanup"
  ! grep -qF 'bootstrap packages prune' "$cleanup"

  for formula in neovim python jq fd ripgrep bat shellcheck lazydocker lazygit just tree-sitter-cli fzf git-delta gh glow zoxide tmux; do
    grep -qF "$formula" "$cleanup"
  done
  for formula in bash git zlib htop gpg editorconfig watchman ssh-copy-id git-extras lynx beads gcc; do
    ! grep -qE "(^|[[:space:]'-])${formula}([[:space:]']|$)" "$cleanup"
  done
}

@test "brew tasks are Darwin-only and cask-only" {
  local brew="$REPO_ROOT/roles/dotfiles/tasks/brew.yml"
  local casks="$REPO_ROOT/roles/dotfiles/tasks/brew_casks.yml"
  ! grep -qF 'dotfiles_brew_core' "$brew"
  ! grep -qF 'dotfiles_brew_linux' "$brew"
  ! grep -qF 'dotfiles_brew_macos_formulae' "$casks"
  grep -qF "ansible_facts.system == 'Darwin'" "$brew"
  grep -qF "ansible_facts.system == 'Darwin'" "$casks"
  grep -qF 'dotfiles_brew_macos_casks' "$casks"
}
