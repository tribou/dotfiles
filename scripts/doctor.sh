#!/usr/bin/env bash
set -euo pipefail

# Script directory and DOTFILES root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${DOTFILES:="$(cd "$SCRIPT_DIR/.." && pwd)"}"

# --- Output helpers ---
pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s → %s\n' "$1" "$2"; }

# --- Check functions ---
# shellcheck disable=SC2120  # Tests pass explicit mappings; production uses defaults.
check_symlinks() {
    local failed=0
    # Symlink definitions: "target~source" (accepts args to override default list)
    local -a symlinks=("$@")
    if [[ ${#symlinks[@]} -eq 0 ]]; then
        # shellcheck disable=SC2088  # Tildes are parsed and expanded below.
        symlinks=(
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
    fi

    echo "Symlinks:"
    for link in "${symlinks[@]}"; do
        local target source
        IFS='~' read -r _ target source <<< "$link"
        target="~${target}"
        local target_path="${target/#\~/$HOME}"
        local expected_source="$DOTFILES/$source"

        if [[ ! -e "$target_path" ]]; then
            fail "$target" "run: ./bootstrap.sh"
            failed=1
        elif [[ ! -L "$target_path" ]]; then
            fail "$target" "run: ./bootstrap.sh"
            failed=1
        else
            local link_target
            if [[ "$(uname)" == "Darwin" ]]; then
                link_target="$(readlink "$target_path")"
            else
                link_target="$(readlink -f "$target_path")"
            fi
            if [[ "$link_target" != "$expected_source" ]]; then
                fail "$target" "run: ./bootstrap.sh"
                failed=1
            else
                pass "$target"
            fi
        fi
    done
    return $failed
}

# --- Tool check ---
check_tools() {
    local failed=0
    # Tool definitions: "tool~remediation"
    local tools=(
        "mise~run: ./bootstrap.sh"
        "node~run: mise install node"
        "python~run: mise install python"
        "ruby~run: mise install ruby"
        "go~run: mise install go"
        "bun~run: mise install bun"
        "tombi~run: mise install tombi"
        "ansible-playbook~run: mise install ansible"
        "nvim~run: mise install neovim"
        "jq~run: mise install jq"
        "fd~run: mise install fd"
        "rg~run: mise install ripgrep"
        "bat~run: mise install bat"
        "shellcheck~run: mise install shellcheck"
        "lazydocker~run: mise install lazydocker"
        "lazygit~run: mise install lazygit"
        "just~run: mise install just"
        "tree-sitter~run: mise install tree-sitter"
        "fzf~run: mise install fzf"
        "delta~run: mise install delta"
        "gh~run: mise install gh"
        "glow~run: mise install glow"
        "zoxide~run: mise install zoxide"
        "tmux~run: mise install tmux"
        "prettier~run: mise install npm:prettier"
        "solargraph~run: mise install gem:solargraph"
        "git~run: mise bootstrap packages apply --yes"
        "bash~run: mise bootstrap packages apply --yes"
    )

    echo "Tools:"
    for tool in "${tools[@]}"; do
        local cmd="${tool%~*}"
        local remediation="${tool#*~}"
        if command -v "$cmd" &>/dev/null; then
            pass "$cmd"
        else
            fail "$cmd" "$remediation"
            failed=1
        fi
    done
    return $failed
}

# --- Main ---
main() {
    local output=""
    local passed=0
    local failed=0

    # Run symlink checks
    local symlink_output
    # shellcheck disable=SC2119  # An empty argument list selects role defaults.
    symlink_output=$(check_symlinks) || true
    output+="$symlink_output"$'\n'
    local symlink_passed=0 symlink_failed=0
    while IFS= read -r line; do
        if [[ "$line" == *"✓"* ]]; then
            (( symlink_passed += 1 ))
        elif [[ "$line" == *"✗"* ]]; then
            (( symlink_failed += 1 ))
        fi
    done <<< "$symlink_output"

    # Run tool checks
    local tool_output
    tool_output=$(check_tools) || true
    output+="$tool_output"$'\n'
    local tool_passed=0 tool_failed=0
    while IFS= read -r line; do
        if [[ "$line" == *"✓"* ]]; then
            (( tool_passed += 1 ))
        elif [[ "$line" == *"✗"* ]]; then
            (( tool_failed += 1 ))
        fi
    done <<< "$tool_output"

    passed=$((symlink_passed + tool_passed))
    failed=$((symlink_failed + tool_failed))
    local total_checks=$((passed + failed))

    # Print all output
    echo "$output"
    # Print summary
    echo "doctor: $passed/$total_checks checks passed ($failed failures)"
    
    # Exit with appropriate code
    if [[ $failed -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
