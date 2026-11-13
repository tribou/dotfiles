# covers: mise-config.toml mise-config.optional.toml.example bootstrap.sh justfile scripts/* mise.toml
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "mise config owns tools, language packages, and formula artifacts" {
  local config="$REPO_ROOT/mise-config.toml"
  grep -qE '^node[[:space:]]*=[[:space:]]*"lts"$' "$config"
  grep -qE '^ruby[[:space:]]*=[[:space:]]*"4"$' "$config"
  grep -qF 'postinstall = "python -m pip install --upgrade pynvim"' "$config"
  grep -qF '[settings.npm]' "$config"
  grep -qF 'package_manager = "npm"' "$config"

  for tool in neovim jq fd ripgrep bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux; do
    grep -qE "^${tool}[[:space:]]*=[[:space:]]*\"latest\"$" "$config"
  done
  for package in eas-cli eslint_d editorconfig intelephense js-yaml jsonlint neovim prettier react-devtools nodemon tern tslint typescript bash-language-server flow-bin vue-language-server vscode-css-languageserver-bin vscode-html-languageserver-bin; do
    grep -qF "\"npm:${package}\" = \"latest\"" "$config"
  done
  for package in neovim solargraph; do
    grep -qF "\"gem:${package}\" = \"latest\"" "$config"
  done

  for formula in bash git zlib htop gnupg editorconfig watchman ssh-copy-id git-extras lynx; do
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

@test "legacy package files are removed" {
  for file in default-node-packages default-python-packages default-gems; do
    [ ! -e "$REPO_ROOT/$file" ]
    ! grep -qF "$file" "$REPO_ROOT/mise.toml"
  done
}

@test "optional mise config owns optional tools, formulae, and casks" {
  local mise_optional="$REPO_ROOT/mise-config.optional.toml.example"

  for tool in awscli terraform-ls navi tlrc tfenv; do
    grep -qE "^#[[:space:]]+${tool}[[:space:]]*=" "$mise_optional"
  done
  for formula in nmap tree dos2unix tidy-html5 ngrok tor rename renameutils vimpager; do
    case "$formula" in
      ngrok|tor|rename|renameutils|vimpager)
        local key="${formula}"
        [ "$formula" = ngrok ] && key="ngrok/ngrok/ngrok"
        grep -qF "\"brew:${key}\" = { version = \"latest\", os = \"macos/arm64\" }" "$mise_optional"
        ;;
      *)
        grep -qF "\"brew:${formula}\" = \"latest\"" "$mise_optional"
        ;;
    esac
  done
  for cask in firefox orbstack bruno balenaetcher appcleaner imageoptim cmake font-fira-code-nerd-font font-hack-nerd-font font-fontawesome; do
    grep -qE "^# \"brew-cask:${cask}\" = " "$mise_optional" || fail "optional cask $cask"
  done
}

@test "repository never uses manager-wide brew prune" {
  ! grep -R -qF 'bootstrap packages prune --manager brew' \
    "$REPO_ROOT/bootstrap.sh" "$REPO_ROOT/mise.toml" "$REPO_ROOT/justfile" "$REPO_ROOT/scripts"
}
