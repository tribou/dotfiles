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

# --- Skills directory check ---
check_skills_dirs() {
    local failed=0
    # Target dirs of per-skill symlinks (accepts args to override default list)
    local -a dirs=("$@")
    if [[ ${#dirs[@]} -eq 0 ]]; then
        dirs=(
            "$HOME/.claude/skills"
            "$HOME/.config/opencode/skills"
            "$HOME/.gemini/config/skills"
        )
    fi

    echo "Skills:"
    for dir in "${dirs[@]}"; do
        local display="${dir/#$HOME\//~\/}"

        # Must be a real directory, not the old whole-dir symlink or missing.
        if [[ -L "$dir" || ! -d "$dir" ]]; then
            fail "$display" "run: ./bootstrap.sh"
            failed=1
            continue
        fi

        # These are shared dirs: other tools (e.g. Gemini) add their own valid
        # skill symlinks here too. Bootstrap only prunes broken symlinks and
        # coexists with foreign valid ones, so we mirror that contract — fail
        # only on a broken symlink (one that doesn't resolve to a directory).
        local dir_ok=1
        local link_path
        shopt -s nullglob
        local -a skill_links=("$dir"/*)
        shopt -u nullglob
        for link_path in "${skill_links[@]}"; do
            [[ -L "$link_path" ]] || continue
            if [[ ! -d "$link_path" ]]; then
                dir_ok=0
                break
            fi
        done

        if [[ $dir_ok -eq 1 ]]; then
            pass "$display"
        else
            fail "$display" "run: ./bootstrap.sh"
            failed=1
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
    local total_checks=25  # 15 symlinks + 3 skills dirs + 7 tools
    local output=""
    local passed=0
    local failed=0

    # Run symlink checks
    local symlink_output
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

    # Run skills directory checks
    local skills_output
    skills_output=$(check_skills_dirs) || true
    output+="$skills_output"$'\n'
    local skills_passed=0 skills_failed=0
    while IFS= read -r line; do
        if [[ "$line" == *"✓"* ]]; then
            (( skills_passed += 1 ))
        elif [[ "$line" == *"✗"* ]]; then
            (( skills_failed += 1 ))
        fi
    done <<< "$skills_output"

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

    passed=$((symlink_passed + skills_passed + tool_passed))
    failed=$((symlink_failed + skills_failed + tool_failed))

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
