*What is this system? — components, data flow, DB schema, external APIs, and directory layout*

# Architecture

## Entry Points

- **`bootstrap.sh`**: Thin bootstrapper that solves the chicken-and-egg problem of installing Homebrew + Ansible, then hands off to the Ansible role. Accepts `curl | bash` for zero-clone installs.
  - Self-locates or self-clones the repo into `$HOME/dev/dotfiles`
  - Installs brew (if missing) and ansible (if missing)
  - Runs `ansible-playbook playbook.yml` — all actual provisioning lives in the role

- **`playbook.yml`**: Top-level Ansible playbook that applies the `dotfiles` role to `localhost`
- **`ansible.cfg`**: Configures `roles_path = roles`, disables retry files, sets YAML output format
- **`roles/dotfiles/`**: The single Ansible role containing all provisioning logic

### roles/dotfiles Layout

```
roles/dotfiles/
├── defaults/main.yml    # All variables and their defaults
├── handlers/main.yml    # Handlers (restart services, etc.)
├── meta/main.yml        # Role metadata, dependencies, collections
├── molecule/            # Molecule test scenarios
│   └── default/
│       ├── converge.yml
│       ├── molecule.yml
│       └── verify.yml
└── tasks/
    ├── main.yml         # Role entry point — includes all task files
    ├── prereqs.yml      # Pre-requisite packages
    ├── brew.yml         # Homebrew formulae (core)
    ├── brew_casks.yml   # Homebrew casks (macOS)
    ├── links.yml        # Symlink management
    ├── dirs.yml         # Directory structure
    ├── ssh.yml          # SSH key generation
    ├── gpg.yml          # GPG agent config
    ├── mise.yml         # Version-managed runtimes
    ├── rust.yml         # Rust toolchain
    ├── nvim.yml         # Neovim plugin management
    ├── tpm.yml          # Tmux plugin manager
    ├── zoxide.yml       # zoxide init
    ├── terminfo.yml     # Terminal info DB
    ├── tools_cli.yml    # Additional CLI tools
    ├── beads.yml        # Beads issue tracking
    ├── upgrade.yml      # Upgrade-only tasks (brew upgrade, mise upgrade, npm update)
    └── config files in the repo root
  ```

### dotfiles_state

The `dotfiles_state` variable (defined in `roles/dotfiles/defaults/main.yml`) controls install vs upgrade mode:

| Value | Behavior |
|-------|----------|
| `present` (default) | Ensures tools/config are present but does not force the latest versions |
| `latest` | Upgrades formulae, runtimes, and packages to their latest versions |

Use `just upgrade` to run with `dotfiles_state=latest` and the `upgrade` tag (selectively targets only upgrade tasks).

- **`bash_profile`**: Main bash configuration loaded on shell startup
  - Sources all lib scripts via `lib/index.sh`
  - Sets up environment variables (DEVPATH, DOTFILES, GOPATH, etc.)
  - Configures PATH for Homebrew, mise, and other tools
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
  - `STARTPATH`: optional, user-set start directory. When set, the initial login shell (`bash_profile:337`) and new tmux windows (`prefix c`) open there instead of `DEVPATH`
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
- **Working directory of new windows vs splits** (two intentionally different rules):
  - **New windows** (`prefix c`) open at `$STARTPATH` if set, otherwise `$DEVPATH`, via the `#{?STARTPATH,#{STARTPATH},#{DEVPATH}}` format (`tmux/tmux-conf`). Requires `STARTPATH`/`DEVPATH` to be present in tmux's global environment (inherited from the launching login shell). Mirrors the initial-shell cd logic in `bash_profile:337-343`
  - **Splits** (`C-v` vertical, `C-h` horizontal) deliberately open in the **current pane's directory** (`#{pane_current_path}`, `tmux/tmux-conf`) so a split stays in the same project you are working in. This divergence from the new-window rule is intentional — do not "unify" the two
- **`tmux/tmux-right-click-menu.conf`**: Right-click pane menu with custom Paste item
  - Sourced conditionally by `tmux-conf` on non-SSH sessions only
  - Stock menu items are hand-maintained (tmux has no "extend the default menu" hook)
  - After a tmux upgrade, re-run `tmux list-keys -T root MouseDown3Pane` and reconcile any new/changed entries

## Test Infrastructure

- **`tests/*.bats`**: Unit tests (bats-core); run fast with no Docker required
- **`tests/integration/`**: Integration tests run inside Docker
  - `nvim_health.bats`: Validates Neovim plugin health
  - `nvim_keymaps.bats`: Verifies key mappings are configured correctly
  - `tmux_environment.bats`: Validates tmux session and environment setup
- **`goss.yaml`**: Infrastructure assertions (binary presence, environment variables) validated by goss inside Docker
- **`Dockerfile`** + **`docker-compose.yml`**: Defines the CI/CD test environment

## Issue Tracking

This repo uses **GitHub issues** for issue tracking. Issues live on the GitHub repo at `https://github.com/tribou/dotfiles/issues` and are managed via the `gh` CLI:

> [!NOTE]
> When executing `gh` in a sandboxed harness, run via `bash -c "gh ..."` to capture the current `gh` authentication.

- `gh issue list` — list open issues (run as `bash -c "gh issue list"` in sandboxed harnesses)
- `gh issue view <n>` — view issue details
- `gh issue create` — create a new issue
- `gh issue close <n>` — close an issue

Priority is tracked via `P1`/`P2`/`P3` labels. Bugs use the `bug` label; tasks/features use `enhancement`. This project previously used **bd (beads)** — an embedded Dolt database synced via a `refs/dolt/data` ref — but migrated to GitHub issues. The `.beads/` directory is gitignored and retained only as historical archive.
