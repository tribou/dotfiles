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
