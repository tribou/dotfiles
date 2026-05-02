#!/usr/bin/env bash
set -euo pipefail

# Script directory and DOTFILES root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${DOTFILES:="$(cd "$SCRIPT_DIR/.." && pwd)"}"

# --- Output helpers ---
pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s → %s\n' "$1" "$2"; }

# --- Check functions ---
check_symlinks() {
    local failed=0
    # Symlink definitions: "target~source" (accepts args to override default list)
    local -a symlinks=("$@")
    if [[ ${#symlinks[@]} -eq 0 ]]; then
        symlinks=(
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
        "git~run: brew install git"
        "nvim~run: brew install neovim"
        "tmux~run: brew install tmux"
        "mise~run: brew install mise"
        "node~run: mise install node"
        "go~run: mise install go"
        "bun~run: mise install bun"
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
    echo "doctor: starting checks"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
