# Architecture

## Entry Points

- **`bootstrap.sh`**: Main installation script
  - Creates symlinks from dotfiles to home directory (~/.bash_profile, ~/.vimrc, ~/.gitconfig, etc.)
  - Sets up directory structure (~/dev, ~/dev/go, etc.)
  - Optionally installs dependencies with `-i` or `--install-deps` flag
  - Configures SSH keys, GPG agent, tmux plugins

- **`bash_profile`**: Main bash configuration loaded on shell startup
  - Sources all lib scripts via `lib/index.sh`
  - Sets up environment variables (DEVPATH, DOTFILES, GOPATH, etc.)
  - Configures PATH for Homebrew, NVM, pyenv, rbenv, jenv, and other tools
  - Implements prompt customization with git branch detection
  - Auto-loads correct Node version from .nvmrc or .node-version files

- **`zshrc`**: Minimal zsh configuration — primarily delegates to bash-compatible configurations

## Library Structure

The `lib/` directory contains modular shell functions sourced by `lib/index.sh`:

- **`_shared.sh`**: Core helper functions
  - `_dotfiles_grep_ticket_number`: Extracts ticket numbers (AB-123, ab123, DCX123) from branch names
  - `_dotfiles_commit_message`: Constructs commit messages with ticket prefixes
  - `_dotfiles_git_status`: Wrapper for git status with consistent formatting
  - `_eval_script`: Executes commands either via tmux or directly

- **`commands.sh`**: Custom shell functions and aliases (primary functionality)
- **`fzf.sh`**: FZF integration for fuzzy finding
- **`init_project.sh`**: Project initialization utilities
- **`replace.sh`**: Batch file replacement utilities
- **`remind.sh`**: Terminal notification system
- **`command_reference.sh`**: Command help/reference
- **`sizes.sh`**: File/directory size utilities
- **`curl_it.sh`**: HTTP request helpers
- **`notify.sh`**: System notification utilities

## Agent Directory

The `agent/` directory contains the isolated LLM agent-user subsystem:

- **`setup-user.sh`**: Linux-only setup script for creating the `agent` user, SSH key, sudoers entry, and shell profile wiring
- **`overrides.sh`**: Agent-only shell overrides for git identity and the `[llm]` prompt prefix

**Important boundary**: files in `agent/` are intentionally **not** sourced by `bash_profile` or `lib/index.sh`. Only consumed by the generated `agent` user's home profile.

## Version Management (mise)

`mise-config.toml` defines tool versions:

```toml
[tools]
node = "lts"
ruby = "3"
go = "latest"

[settings]
legacy_version_file = true  # respects .nvmrc, .ruby-version, etc.
```

- `legacy_version_file = true` means mise respects `.nvmrc`, `.node-version`, `.ruby-version` files automatically
- Run `mise install` to install all configured tool versions
- `mise which <tool>` to check which binary will be used

## Environment Configuration

- **API Keys**: Stored in `~/.ssh/api_keys`, sourced by bash_profile
  - `GIT_SIGNING_KEY`: GPG signing key for commits (warns if unset)
  - Can contain any sensitive environment variables (e.g., DIGITALOCEAN_API_TOKEN)

- **Project Paths**:
  - `DEVPATH`: `~/dev`
  - `DOTFILES`: `~/dev/dotfiles`
  - `GOPATH`: `~/dev/go`
  - `PRIMARY_REPO`, `SECONDARY_REPO`: Used by tmux layout functions; fuzzy matched via z

- **Directory Navigation**: Uses `z` (rupa/z) for frecency-based directory jumping
  - Installed at `~/dev/z/z.sh`
  - `_dotfiles_full_path` uses `_z -e` to resolve directory names

- **History**: Timestamped files in `~/.history/YYYY/MM/DD.HH.MM.SS_hostname_pid`

## Neovim/Vim Configuration

- **`init.vim`**: Main Neovim config (also symlinked as ~/.vimrc)
- **`coc-settings.json`**: CoC LSP configuration
- Uses vim-plug for plugin management
- ALE for linting/fixing
- Language support: JavaScript/TypeScript, React, Python, Ruby, Elixir, Go

## Tmux Configuration

- **`tmux/tmux-conf`**: Main tmux configuration
- Prefix key: `Ctrl-f`
- Integration with system clipboard via reattach-to-user-namespace
- Predefined layouts via shell functions: `tmux-large`, `tmux-small`, `tmux-xl`
