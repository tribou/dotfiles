#!/usr/bin/env bats

setup() {
    # Project root is the current working directory when bats is run
    source scripts/doctor.sh
}

@test "main guard prevents automatic execution when sourced" {
    run bash -c 'source scripts/doctor.sh'
    [ "$status" -eq 0 ]
    # When sourced, main should not run, so no output
    [ "$output" = "" ]
}

@test "check_symlinks passes for valid symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    echo "test" > "$DOTFILES/test-file"
    ln -sf "$DOTFILES/test-file" "$HOME/.test-link"
    
    run check_symlinks "~/.test-link~test-file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ ~/.test-link"* ]]
}

@test "check_symlinks fails for broken symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    echo "test" > "$DOTFILES/test-file"
    ln -sf "$DOTFILES/non-existent" "$HOME/.test-link"
    
    run check_symlinks "~/.test-link~test-file"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗ ~/.test-link → run: ./bootstrap.sh"* ]]
}

@test "check_tools passes for available tool" {
    local tool_dir
    tool_dir="$(mktemp -d)"
    for tool in mise node python ruby go bun tombi ansible-playbook nvim jq fd rg bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux prettier solargraph git bash; do
        touch "$tool_dir/$tool"
        chmod +x "$tool_dir/$tool"
    done
    export PATH="$tool_dir:$PATH"

    run check_tools
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ git"* ]]
}

@test "check_tools fails for missing tool" {
    local saved_path="$PATH"
    export PATH="$(mktemp -d)"
    run check_tools
    export PATH="$saved_path"
    [ "$status" -eq 1 ]
    local expected
    for expected in \
        "mise~run: ./bootstrap.sh" \
        "node~run: mise install node" \
        "python~run: mise install python" \
        "ruby~run: mise install ruby" \
        "go~run: mise install go" \
        "bun~run: mise install bun" \
        "tombi~run: mise install tombi" \
        "ansible-playbook~run: mise install ansible" \
        "nvim~run: mise install neovim" \
        "jq~run: mise install jq" \
        "fd~run: mise install fd" \
        "rg~run: mise install ripgrep" \
        "bat~run: mise install bat" \
        "shellcheck~run: mise install shellcheck" \
        "lazydocker~run: mise install lazydocker" \
        "lazygit~run: mise install lazygit" \
        "just~run: mise install just" \
        "tree-sitter~run: mise install tree-sitter" \
        "fzf~run: mise install fzf" \
        "delta~run: mise install delta" \
        "gh~run: mise install gh" \
        "glow~run: mise install glow" \
        "zoxide~run: mise install zoxide" \
        "tmux~run: mise install tmux" \
        "prettier~run: mise install npm:prettier" \
        "solargraph~run: mise install gem:solargraph" \
        "git~run: mise bootstrap packages apply --yes" \
        "bash~run: mise bootstrap packages apply --yes"; do
        [[ "$output" == *"✗ ${expected%~*} → ${expected#*~}"* ]]
    done
}

@test "doctor uses owner-specific mise remediation" {
    grep -qF 'nvim~run: mise install neovim' scripts/doctor.sh
    grep -qF 'tmux~run: mise install tmux' scripts/doctor.sh
    grep -qF 'rg~run: mise install ripgrep' scripts/doctor.sh
    grep -qF 'ansible-playbook~run: mise install ansible' scripts/doctor.sh
    grep -qF 'git~run: mise bootstrap packages apply --yes' scripts/doctor.sh
}

@test "doctor no longer checks legacy package links" {
    ! grep -qF '.default-node-packages' scripts/doctor.sh
    ! grep -qF '.default-python-packages' scripts/doctor.sh
    ! grep -qF '.default-gems' scripts/doctor.sh
}

@test "main exits 0 when all checks pass" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    local tool_dir
    tool_dir="$(mktemp -d)"
    for tool in mise node python ruby go bun tombi ansible-playbook nvim jq fd rg bat shellcheck lazydocker lazygit just tree-sitter fzf delta gh glow zoxide tmux prettier solargraph git bash; do
        touch "$tool_dir/$tool"
        chmod +x "$tool_dir/$tool"
    done
    export PATH="$tool_dir:$PATH"

    # Set up valid symlinks for all role-owned entries.
    local symlinks=(
        "~/.bash_profile~bash_profile"
        "~/.vimrc~init.vim"
        "~/.gitconfig~gitconfig"
        "~/.zshrc~zshrc"
        "~/.tmux.conf~tmux/tmux-conf"
        "~/.gnupg/gpg-agent.conf~gpg-agent-conf"
        "~/.config/nvim/init.vim~init.vim"
        "~/.config/alacritty/alacritty.toml~alacritty.toml"
        "~/.config/mise/config.toml~mise-config.toml"
        "~/.config/nvim/coc-settings.json~coc-settings.json"
        "~/.local/bin/dotfiles_remote_browser_open.sh~scripts/dotfiles_remote_browser_open.sh"
        "~/.local/bin/dotfiles_local_browser_helper.sh~scripts/dotfiles_local_browser_helper.sh"
    )

    for link in "${symlinks[@]}"; do
        local target source target_path source_path
        IFS='~' read -r _ target source <<< "$link"
        target="~${target}"
        target_path="${target/#\~/$HOME}"
        source_path="$DOTFILES/$source"
        mkdir -p "$(dirname "$target_path")"
        mkdir -p "$(dirname "$source_path")"
        echo "test" > "$source_path"
        ln -sf "$source_path" "$target_path"
    done

    run main
    [ "$status" -eq 0 ]
    local total_checks
    total_checks="$(grep -cE '  (✓|✗) ' <<< "$output")"
    [[ "$output" == *"doctor: $total_checks/$total_checks checks passed (0 failures)"* ]]
}

@test "main exits 1 when checks fail" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    # No symlinks set up (all fail)
    local saved_path="$PATH"
    local tools_dir="$(mktemp -d)"
    cp "$(type -P grep)" "$tools_dir/"  # Only grep available
    export PATH="$tools_dir"  # No other tools (all fail)
    run main
    export PATH="$saved_path"
    [ "$status" -eq 1 ]
    local total_checks
    total_checks="$(grep -cE '  (✓|✗) ' <<< "$output")"
    [[ "$output" == *"doctor: 0/$total_checks checks passed ($total_checks failures)"* ]]
}

@test "justfile has doctor recipe" {
    run grep -A 2 '^doctor:' justfile
    [ "$status" -eq 0 ]
    [[ "$output" == *"./scripts/doctor.sh"* ]]
}

@test "doctor.sh produces output when checks fail (set -e regression)" {
    # Tests the real subprocess — BATS 'run main' disables set -e so it misses this bug.
    # When check_symlinks/check_tools return non-zero, set -e must not kill the script
    # before printing the summary line.
    local tmp_home tmp_dotfiles
    tmp_home="$(mktemp -d)"
    tmp_dotfiles="$(mktemp -d)"
    # No symlinks set up, so all symlink checks fail.
    # System tools (git, nvim, etc.) likely absent in a stripped path — tool checks fail.

    run bash -c "HOME='$tmp_home' DOTFILES='$tmp_dotfiles' bash scripts/doctor.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"doctor:"* ]]
}
