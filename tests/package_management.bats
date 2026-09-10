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

  for tool in ansible neovim jq fd ripgrep bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux; do
    grep -qE "^${tool}[[:space:]]*=[[:space:]]*\"latest\"$" "$config"
  done
  for package in eas-cli eslint_d editorconfig intelephense js-yaml jsonlint neovim prettier react-devtools nodemon tern tslint typescript bash-language-server flow-bin vue-language-server vscode-css-languageserver-bin vscode-html-languageserver-bin; do
    grep -qF "\"npm:${package}\" = \"latest\"" "$config"
  done
  for package in neovim solargraph; do
    grep -qF "\"gem:${package}\" = \"latest\"" "$config"
  done

  for formula in bash git zlib htop gpg editorconfig watchman ssh-copy-id git-extras lynx beads; do
    grep -qF "\"brew:${formula}\" = \"latest\"" "$config"
  done
  grep -qF '"brew:gcc" = { version = "latest", os = "linux" }' "$config"
  for formula in bash-completion alacritty reattach-to-user-namespace tmux-mem-cpu-load; do
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
