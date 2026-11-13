# covers: mise-config.toml mise-config.optional.toml.example Brewfile.optional.example bootstrap.sh justfile ansible.cfg roles/* scripts/verify_mise_tools.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "mise config owns tools, language packages, and formula artifacts" {
  local config="$REPO_ROOT/mise-config.toml"
  grep -qF 'min_version = "2026.7.5"' "$config"
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

# mise >= 2026.11 registers ansible as pypi:ansible with expose=["ansible-core"],
# which requires uv. ansible-core also crashes on Python 3.15 (dataclasses._is_type
# removed), so python stays on a supported minor instead of "latest".
@test "ansible declares uv and a supported python as install prerequisites" {
  local config="$REPO_ROOT/mise-config.toml"

  grep -qE '^uv[[:space:]]*=[[:space:]]*"latest"$' "$config"
  grep -qF 'ansible = { version = "latest", depends = ["python", "uv"] }' "$config"
  grep -qE '^python = \{ version = "3\.14",' "$config"
  ! grep -qE '^pipx[[:space:]]*=' "$config"
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
  ! grep -qE '^[[:space:]]*#?[[:space:]]*brew[[:space:]]+"' "$brew_optional"
  grep -qF '# cask ' "$brew_optional"
}

@test "macOS Homebrew detection uses a shell probe" {
  local brew="$REPO_ROOT/roles/dotfiles/tasks/brew.yml"
  grep -qF 'ansible.builtin.shell:' "$brew"
  grep -qF 'command -v brew' "$brew"
  ! grep -qF 'ansible.builtin.command: command -v brew' "$brew"
}

@test "mise package change detection checks both output streams" {
  local mise="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  grep -qF 'dotfiles_mise_packages.stdout' "$mise"
  grep -qF 'dotfiles_mise_packages.stderr' "$mise"
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
  grep -qF 'failure.item }}' "$cleanup"
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

@test "cleanup failure remains nonfatal and later provisioning is reachable" {
  local tmpdir fake_brew fixture
  tmpdir="$(mktemp -d)"
  fake_brew="$tmpdir/brew"
  fixture="$tmpdir/continuation.yml"

  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "-1" ]; then printf "bash\\nneovim\\n"; exit 0; fi'
    printf '%s\n' 'if [ "$1" = "uninstall" ] && [ "$2" = "--formula" ]; then printf "cannot remove %s\\n" "$3" >&2; exit 1; fi'
    printf '%s\n' 'exit 1'
  } > "$fake_brew"
  chmod +x "$fake_brew"

  {
    printf '%s\n' '---'
    printf '%s\n' '- name: Cleanup continuation fixture'
    printf '%s\n' '  hosts: localhost'
    printf '%s\n' '  connection: local'
    printf '%s\n' '  gather_facts: false'
    printf '%s\n' '  tasks:'
    printf '    - ansible.builtin.include_tasks: %s\n' "$REPO_ROOT/roles/dotfiles/tasks/brew_cleanup.yml"
    printf '%s\n' '    - name: Prove later provisioning remains reachable'
    printf '%s\n' '      ansible.builtin.debug:'
    printf '%s\n' '        msg: continuation reached'
  } > "$fixture"

  mkdir -p "$tmpdir/repo/scripts"
  printf '#!/bin/sh\nexit 0\n' > "$tmpdir/repo/scripts/verify_mise_tools.sh"
  chmod +x "$tmpdir/repo/scripts/verify_mise_tools.sh"

  run env "PATH=$tmpdir:$PATH" "ANSIBLE_CONFIG=$REPO_ROOT/ansible.cfg" ansible-playbook "$fixture" \
    -e "dotfiles_home=$tmpdir" -e "dotfiles_repo_root=$tmpdir/repo"
  assert_success
  assert_output --partial 'neovim: cannot remove neovim'
  assert_output --partial 'continuation reached'
  rm -rf "$tmpdir"
}

@test "brew_cleanup: lists installed formulae once and verifies mise tools before uninstalling" {
  local f="$REPO_ROOT/roles/dotfiles/tasks/brew_cleanup.yml"
  # One brew invocation for the whole inventory, not one per formula.
  ! grep -qE 'list --formula \{\{ item \}\}' "$f"
  grep -qE 'list --formula -1' "$f"
  # Running `--tags brew_cleanup` alone must not uninstall before mise is verified.
  verify_line="$(grep -n 'verify_mise_tools.sh' "$f" | head -1 | cut -d: -f1)"
  uninstall_line="$(grep -n 'uninstall --formula' "$f" | head -1 | cut -d: -f1)"
  [ -n "$verify_line" ] && [ "$verify_line" -lt "$uninstall_line" ]
}

@test "brew_cleanup: a failed mise verification stops the play before any uninstall" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'if [ "$1" = "list" ]; then printf "neovim\\n"; exit 0; fi'
    printf '%s\n' "if [ \"\$1\" = uninstall ]; then echo uninstalled >> '$tmpdir/uninstall.log'; fi"
    printf '%s\n' 'exit 0'
  } > "$tmpdir/brew"
  chmod +x "$tmpdir/brew"
  mkdir -p "$tmpdir/repo/scripts"
  printf '#!/bin/sh\nexit 1\n' > "$tmpdir/repo/scripts/verify_mise_tools.sh"
  chmod +x "$tmpdir/repo/scripts/verify_mise_tools.sh"
  {
    printf '%s\n' '---' '- hosts: localhost' '  connection: local' '  gather_facts: false' '  tasks:'
    printf '    - ansible.builtin.include_tasks: %s\n' "$REPO_ROOT/roles/dotfiles/tasks/brew_cleanup.yml"
  } > "$tmpdir/play.yml"

  run env "PATH=$tmpdir:$PATH" "ANSIBLE_CONFIG=$REPO_ROOT/ansible.cfg" ansible-playbook "$tmpdir/play.yml" \
    -e "dotfiles_home=$tmpdir" -e "dotfiles_repo_root=$tmpdir/repo"
  assert_failure
  [ ! -e "$tmpdir/uninstall.log" ]
  rm -rf "$tmpdir"
}

# Node 25+ (node "lts" is 26) no longer bundles corepack, and the old
# `creates: corepack-enabled` marker hid that on machines that enabled it once.
@test "corepack comes from mise and yarn/pnpm shims are checked, not marker-gated" {
  grep -qF '"npm:corepack" = "latest"' "$REPO_ROOT/mise-config.toml"
  local f="$REPO_ROOT/roles/dotfiles/tasks/mise.yml"
  ! grep -qF 'corepack-enabled' "$f"
  grep -qE 'mise"? which (yarn|pnpm)' "$f"
  grep -qF 'corepack enable' "$f"
  grep -qF 'reshim' "$f"
}
