*What is this system? — components, data flow, DB schema, external APIs, and directory layout*

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
  - Configures PATH for Homebrew, mise, jenv, and other tools
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
- **`path.sh`**: PATH manipulation and resolution helpers
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

## Scripts Directory

The `scripts/` directory contains standalone utility scripts (not sourced; run directly):

- **`battery.sh`**: Battery level reporting for terminal prompt or notifications
- **`bootstrap-test.sh`**: Smoke test helper for bootstrap validation
- **`brew_update.sh`**: Homebrew update automation
- **`dm_update_ip.sh`**: Docker Machine IP update utility
- **`install.sh`**: Dependency installer (called by bootstrap.sh with `-i` flag)
- **`internet.sh`**: Internet connectivity check

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

## Test Infrastructure

- **`tests/*.bats`**: Unit tests (bats-core); run fast with no Docker required
- **`tests/integration/`**: Integration tests run inside Docker
  - `nvim_health.bats`: Validates Neovim plugin health
  - `nvim_keymaps.bats`: Verifies key mappings are configured correctly
  - `tmux_environment.bats`: Validates tmux session and environment setup
- **`goss.yaml`**: Infrastructure assertions (binary presence, environment variables) validated by goss inside Docker
- **`Dockerfile`** + **`docker-compose.yml`**: Defines the CI/CD test environment

## Issue Tracking (beads)

This repo uses **bd (beads)** for issue tracking. The source of truth is an embedded Dolt database under `.beads/embeddeddolt/` (gitignored). Issues sync across machines via a **Dolt remote** backed by the same GitHub repo:

- Remote `git+https://github.com/tribou/dotfiles.git`, configured as `sync.remote` in `.beads/config.yaml`.
- Dolt data lives under the `refs/dolt/data` ref on GitHub — separate from `refs/heads/main` (your code) and invisible in the file browser.
- `bd dolt pull` hydrates the local DB from that ref; `bd dolt push` uploads local commits to it. These are independent of `git pull`/`git push`.

**Authentication:** the `git+https://` remote uses git's credential helper, so it works with `gh` (run `gh auth setup-git` once; the token needs `repo` scope) — no SSH key required. A `git+ssh://git@github.com/...` URL also works on machines set up with SSH keys. The Dolt remote list is **per-machine local state** (not carried by `git pull`), so each machine must register `origin` itself: `bootstrap.sh` registers/repairs it from `sync.remote` on every run, or do it manually with `bd dolt remote add origin "<url>"`.

`.beads/issues.jsonl` is a local, **gitignored** export — a human-readable snapshot for `bv`/grep, not the sync mechanism. It is intentionally untracked: tracking it caused recurring cross-machine diffs because each machine re-derived it from its own independently-built Dolt DB, which differ in provenance fields (e.g. `created_by`). The Dolt remote is the single source of truth.

**Sync discipline:** `bd dolt pull` at session start; `bd dolt push` before `git push` at session end. Fresh clones hydrate via `bd bootstrap` (run automatically by `bootstrap.sh` when no local DB exists), which clones the database from `sync.remote`.
