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
    export PATH="$(mktemp -d):$PATH"
    local tool_dir="$(echo "$PATH" | cut -d: -f1)"
    touch "$tool_dir/git"
    chmod +x "$tool_dir/git"
    
    run check_tools
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ git"* ]]
}

@test "check_tools fails for missing tool" {
    export PATH="$(mktemp -d)"
    
    run check_tools
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗ go → run: mise install go"* ]]
}

@test "main exits 0 when all checks pass" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    
    # Set up valid symlinks for all 14 entries
    local symlinks=(
        "~/.bash_profile~bash_profile"
        "~/.vimrc~init.vim"
        "~/.gitconfig~gitconfig"
        "~/.zshrc~zshrc"
        "~/.tmux.conf~tmux/tmux-conf"
        "~/.default-node-packages~default-node-packages"
        "~/.default-gems~default-gems"
        "~/.default-python-packages~default-python-packages"
        "~/.gnupg/gpg-agent.conf~gpg-agent-conf"
        "~/.config/nvim/init.vim~init.vim"
        "~/.config/alacritty/alacritty.toml~alacritty.toml"
        "~/.config/mise/config.toml~mise-config.toml"
        "~/.config/nvim/coc-settings.json~coc-settings.json"
        "~/.claude/skills~skills"
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
    [[ "$output" == *"doctor: 21/21 checks passed (0 failures)"* ]]
}

@test "main exits 1 when checks fail" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    # No symlinks set up (all fail)
    local tools_dir="$(mktemp -d)"
    cp "$(type -P grep)" "$tools_dir/"  # Only grep available
    export PATH="$tools_dir"  # No other tools (all fail)
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"doctor: 0/21 checks passed (21 failures)"* ]]
}

@test "justfile has doctor recipe" {
    run grep -A 2 '^doctor:' justfile
    [ "$status" -eq 0 ]
    [[ "$output" == *"./scripts/doctor.sh"* ]]
}
