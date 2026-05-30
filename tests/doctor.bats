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

@test "check_skills_dirs passes for dir of valid skill symlinks" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a" "$DOTFILES/skills/skill-b"
    mkdir -p "$HOME/.claude/skills"
    ln -sf "$DOTFILES/skills/skill-a" "$HOME/.claude/skills/skill-a"
    ln -sf "$DOTFILES/skills/skill-b" "$HOME/.claude/skills/skill-b"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓"* ]]
}

@test "check_skills_dirs fails when target is a whole-dir symlink (old layout)" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a"
    mkdir -p "$HOME/.claude"
    ln -sf "$DOTFILES/skills" "$HOME/.claude/skills"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗"* ]]
    [[ "$output" == *"run: ./bootstrap.sh"* ]]
}

@test "check_skills_dirs passes for shared dir with valid foreign symlinks" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a"
    # A foreign skills source outside dotfiles (e.g. another tool's skills),
    # which lands valid symlinks in the same shared target dir.
    local foreign
    foreign="$(mktemp -d)"
    mkdir -p "$foreign/foreign-skill"
    mkdir -p "$HOME/.claude/skills"
    ln -sf "$DOTFILES/skills/skill-a" "$HOME/.claude/skills/skill-a"
    ln -sf "$foreign/foreign-skill" "$HOME/.claude/skills/foreign-skill"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓"* ]]
}

@test "check_skills_dirs fails on a broken skill symlink" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    mkdir -p "$DOTFILES/skills/skill-a"
    mkdir -p "$HOME/.claude/skills"
    ln -sf "$DOTFILES/skills/skill-a" "$HOME/.claude/skills/skill-a"
    ln -sf "$DOTFILES/skills/removed-skill" "$HOME/.claude/skills/removed-skill"

    run check_skills_dirs "$HOME/.claude/skills"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗"* ]]
}

@test "check_tools passes for available tool" {
    local tool_dir
    tool_dir="$(mktemp -d)"
    for tool in git nvim tmux mise node go bun; do
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
    [[ "$output" == *"✗ go → run: mise install go"* ]]
}

@test "main exits 0 when all checks pass" {
    export HOME="$(mktemp -d)"
    export DOTFILES="$(mktemp -d)"
    local tool_dir
    tool_dir="$(mktemp -d)"
    for tool in git nvim tmux mise node go bun; do
        touch "$tool_dir/$tool"
        chmod +x "$tool_dir/$tool"
    done
    export PATH="$tool_dir:$PATH"

    # Set up valid symlinks for all 15 entries
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

    # Set up valid per-skill symlinks for the three skills target dirs
    mkdir -p "$DOTFILES/skills/skill-a"
    for skills_dir in "$HOME/.claude/skills" "$HOME/.config/opencode/skills" "$HOME/.gemini/config/skills"; do
        mkdir -p "$skills_dir"
        ln -sf "$DOTFILES/skills/skill-a" "$skills_dir/skill-a"
    done

    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"doctor: 25/25 checks passed (0 failures)"* ]]
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
    [[ "$output" == *"doctor: 0/25 checks passed (25 failures)"* ]]
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
