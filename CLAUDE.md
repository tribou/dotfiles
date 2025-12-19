# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing shell configurations, Neovim/Vim setup, tmux configuration, and development environment across macOS systems. The repository uses a symlink-based approach to install configurations into the home directory.

## Key Commands

### Bootstrap and Installation

```bash
# Initial setup (creates symlinks and sets up environment)
./bootstrap.sh

# Install all dependencies (Homebrew, languages, tools, etc.)
./bootstrap.sh --install-deps

# Run tests
make test
```

### Testing

```bash
# Run all tests (local + Docker)
make test

# Run specific test
./tests/test_grep_ticket_number.sh
./tests/test_commit_message.sh
```

## Architecture

### Entry Points

- **`bootstrap.sh`**: Main installation script that:
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

- **`zshrc`**: Minimal zsh configuration (zsh branch)
  - Primarily delegates to bash-compatible configurations

### Library Structure

The `lib/` directory contains modular shell functions sourced by `lib/index.sh`:

- **`_shared.sh`**: Core helper functions used across the codebase
  - `_dotfiles_grep_ticket_number`: Extracts ticket numbers (AB-123, ab123, DCX123) from branch names
  - `_dotfiles_commit_message`: Constructs commit messages with ticket prefixes
  - `_dotfiles_git_status`: Wrapper for git status with consistent formatting
  - `_eval_script`: Executes commands either via tmux or directly

- **`commands.sh`**: Custom shell functions and aliases (primary functionality)
  - Git workflow functions:
    - `c` (commit with ticket prefix), `cn` (commit with --no-verify)
    - `co` (checkout with fzf), `f` (fetch), `ga` (git add all)
    - `gpsu` (git push with upstream tracking)
    - `merge` (wrapper that shows commit log after merge)
    - `gbd` (delete branch with fzf)
  - AWS helpers: `aws-profile` (switch profiles with fzf), `aws-set-current-account-id`
  - Supabase: `supabase-profile` (manage multiple Supabase profiles from TSV config)
  - NPM/Yarn:
    - `npm-run` (run scripts with fzf), `npm-install` (auto-detect pnpm/yarn/npm/bun)
    - `nu` (upgrade deps), `ninfo` (npm info with fzf)
    - `useLocalIfAvailable` (uses local node_modules/.bin if available, otherwise global/npx)
  - Tmux layouts: `tmux-large`, `tmux-small`, `tmux-xl` (predefined multi-pane layouts)
  - Docker: `da` (attach), `ds` (stop), `dminit` (docker-machine setup)
  - Search: `search` (git grep excluding bin/, vendor/, flow-typed/, lockfiles), `histgrep` (search command history)

- **`fzf.sh`**: FZF integration for fuzzy finding
- **`init_project.sh`**: Project initialization utilities
- **`replace.sh`**: Batch file replacement utilities
- **`remind.sh`**: Terminal notification system (displays "Welcome. 👋" on shell start)
- **`command_reference.sh`**: Command help/reference
- **`sizes.sh`**: File/directory size utilities
- **`curl_it.sh`**: HTTP request helpers
- **`notify.sh`**: System notification utilities

### Git Workflow Integration

The repository implements an automated ticket-number-based commit workflow:

1. **Branch Naming**: Expects branches like `AB-123/description`, `ab123-description`, or `123_AT_Description` (DCX pattern)
2. **Commit Prefix**: The `c` function automatically:
   - Extracts ticket number from current branch using `_dotfiles_grep_ticket_number`
   - Prefixes commit message with ticket number (e.g., "AB-123: Fix bug")
   - Shows commit signature and status after committing
3. **Commit Separator**: Configurable via `DOTFILES_COMMIT_SEPARATOR` (default: `:`)

### Environment Configuration

- **API Keys**: Stored in `~/.ssh/api_keys` and sourced by bash_profile
  - `GIT_SIGNING_KEY`: GPG signing key for commits (warns if unset)
  - Can contain any sensitive environment variables (e.g., DIGITALOCEAN_API_TOKEN)

- **Project Paths**:
  - `DEVPATH`: `~/dev` (main development directory)
  - `DOTFILES`: `~/dev/dotfiles`
  - `GOPATH`: `~/dev/go`
  - `PRIMARY_REPO`, `SECONDARY_REPO`: Used by tmux layout functions; fuzzy matched via z

- **Directory Navigation**: Uses `z` (from rupa/z) for frecency-based directory jumping
  - Installed at `~/dev/z/z.sh`
  - Functions like `_dotfiles_full_path` use `_z -e` to resolve directory names
  - Example: `z dotfiles` jumps to ~/dev/dotfiles

- **History**: Custom history setup with dated files in `~/.history/YYYY/MM/DD.HH.MM.SS_hostname_pid`

### Neovim/Vim Configuration

- **`init.vim`**: Main Neovim configuration (also symlinked as ~/.vimrc)
- **`coc-settings.json`**: CoC (Conquer of Completion) configuration for LSP
- Uses vim-plug for plugin management
- Extensive language support via CoC extensions (TypeScript, ESLint, CSS, JSON, etc.)
- ALE for linting/fixing
- Configured for: JavaScript/TypeScript, React, Python, Ruby, Elixir, Go, and more

### Tmux Configuration

- **`tmux/tmux-conf`**: Main tmux configuration
- Prefix key: `Ctrl-f` (instead of default `Ctrl-b`)
- Predefined layouts via shell functions (tmux-large, tmux-small, etc.)
- Integration with system clipboard via reattach-to-user-namespace

## Important Patterns

### FZF Integration
Many commands use fzf for interactive selection when called without arguments:
- `co` - checkout branch
- `gbd` - delete branch
- `npm-run` - select npm script
- `nu` - upgrade npm package
- `aws-profile` - select AWS profile

### Smart Tool Detection
Functions auto-detect which package manager to use:
- `npm-install`: Checks for pnpm-lock.yaml → yarn.lock → bun.lock → defaults to npm
- `npm-run`: Same detection logic for running scripts

### Tmux-Aware Execution
`_eval_script` sends commands to tmux pane if in tmux session, otherwise executes directly. This puts commands in shell history when in tmux.

### Common Aliases
Frequently used shortcuts (defined in lib/commands.sh:728-866):
- **Git**: `s` (status), `amend` (commit --amend), `fix` (amend without editor), `mm`/`md`/`mp`/`ms` (merge main/develop/prod/staging)
- **Editor**: `v` (nvim), `vc` (vimcat)
- **Package managers**: `y` (npm-install with auto-detection), `nr` (npm-run), `yi`/`yr` (same as y/nr)
- **Navigation**: `..`, `...`, `....` (up directories), `back` (cd to $OLDPWD)
- **Utilities**: `ll` (ls -lah), `lt` (ls sorted by time), `tree` (excludes node_modules/dist)
- **Docker**: `d` (docker), `dc` (docker compose), `dps` (docker ps)

## Configuration Files

- **`.editorconfig`**: EditorConfig settings for consistent formatting
- **`gitconfig`**: Git configuration with:
  - GPG commit signing enabled
  - Useful aliases (tree, tree-one, diff-word, forget)
  - LFS support
  - SSH instead of HTTPS for GitHub
  - nvimdiff as merge tool

- **`alacritty.toml`**: Alacritty terminal emulator config
- **`ripgreprc`**: Ripgrep configuration (exported via RIPGREP_CONFIG_PATH)

## Scripts Directory

- **`install.sh`**: Additional installation steps (called by bootstrap.sh)
- **`battery.sh`**: Battery status checker
- **`internet.sh`**: Internet connectivity checker

## Typical Workflows

### Git Workflow with Ticket Numbers
```bash
co feature/AB-123/new-feature  # Checkout or create branch (with fzf if no args)
# Make changes...
ga                              # git add --all
c "implement new feature"       # Commits as "AB-123: implement new feature"
gpsu                           # git push -u origin current-branch
```

### Package Management
```bash
y                  # Installs deps (auto-detects pnpm/yarn/bun/npm)
nr                 # Run npm script (interactive fzf if no args)
nu express         # Upgrade specific package (or fzf select if no args)
```

### Development Environment
```bash
z dotfiles         # Jump to frequently used directory
tmux-xl ~/myapp    # Create XL layout for myapp (uses z to resolve)
search "pattern"   # Git grep excluding vendor/node_modules/lockfiles
```

## Notes

- The repository assumes macOS (checks for Darwin in multiple places)
- GPG signing is required for commits (set `GIT_SIGNING_KEY` in `~/.ssh/api_keys`)
- NVM is loaded with `--no-use` flag for performance; Node version auto-switches on directory change via PROMPT_COMMAND
- Shell history is extensive with timestamped files for long-term retention
- The `z` tool is essential for directory navigation and must be installed at `~/dev/z/z.sh`
