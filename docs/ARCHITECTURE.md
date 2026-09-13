*What is this system? — components, data flow, DB schema, external APIs, and directory layout*

# Architecture

## Entry Points

- **`bootstrap.sh`**: Thin bootstrapper that solves the chicken-and-egg problem by installing standalone mise, then hands off to the Ansible role through mise. Accepts `curl | bash` for zero-clone installs.
  - Self-locates or self-clones the repo into `$HOME/dev/dotfiles`
  - Installs native OS prerequisites needed to bootstrap mise packages
  - Exposes the global mise config, applies packages, installs tools, and runs smoke verification
  - Runs `mise exec -- ansible-playbook playbook.yml` — all repeatable provisioning lives in the role

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
    ├── brew.yml         # Real Homebrew discovery/install for macOS casks
    ├── brew_casks.yml   # Retained macOS casks + global ~/.Brewfile hook
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
    ├── upgrade.yml      # Upgrade-only tasks (mise packages/tools + macOS casks)
    └── config files in the repo root
  ```

### dotfiles_state

The `dotfiles_state` variable (defined in `roles/dotfiles/defaults/main.yml`) controls install vs upgrade mode:

| Value | Behavior |
|-------|----------|
| `present` (default) | Ensures tools/config are present but does not force the latest versions |
| `latest` | Runs explicit package, tool, native-system, and retained-cask upgrades |

Use `just upgrade` to run with `dotfiles_state=latest` and the `upgrade` tag (selectively targets only upgrade tasks).

### Opt-in packages

The role installs a **core** package set on every machine. Everything else is
opt-in via two commented templates shipped at the repo root that the user copies
into their home directory — nothing in the repo needs editing per machine.

| Repo template | Copy to | Consumed by |
|---|---|---|
| `mise-config.optional.toml.example` | `~/.config/mise/conf.d/optional.toml` | un-scoped `mise install` (`tasks/mise.yml`) |
| `Brewfile.optional.example` | `~/.Brewfile` | macOS-only `brew bundle --global` (`tasks/brew_casks.yml`) |

- Optional CLI tools **with a mise backend** live in the mise drop-in; mise
  auto-loads `~/.config/mise/conf.d/*.toml` (alphabetically) and merges
  `[tools]` additively over `config.toml`.
- Optional formulae live under `[bootstrap.packages]` in the mise drop-in.
- Optional **casks only** live in the Brewfile, which the retained real Homebrew
  flow consumes on macOS.
- Both are skipped silently when absent (a `stat` guard for the Brewfile), so a
  bare machine gets only the core set.
- `just install` applies newly enabled mise entries and runs `brew bundle
  --global --no-upgrade` for newly enabled macOS casks. `just upgrade` uses
  `mise bootstrap packages upgrade` and `mise upgrade`, then upgrades retained
  casks through Homebrew. Run `just install` after uncommenting new entries.

### Mise-First Provisioning Flow

```text
native OS prerequisites
        |
        v
standalone ~/.local/bin/mise
        |
        +--> global mise-config.toml
        |       |
        |       +--> bootstrap packages apply --> canonical brew prefix
        |       +--> mise install -------------> versioned tools + shims
        |
        v
smoke verification
        |
        +--> targeted cleanup of old [tools] formula copies, if brew already exists
        |
        v
mise exec -- ansible-playbook
        |
        +--> repeat package/tool convergence and verification
        +--> real Homebrew CLI on Apple Silicon macOS for casks only
```

`brew:` is a mise package backend, not a requirement for a `brew` executable. It writes formula artifacts and links into the canonical platform prefix: `/opt/homebrew` on Apple Silicon macOS and `/home/linuxbrew/.linuxbrew` on Linux. Bootstrap, verification, and shell startup add the applicable prefix to `PATH` explicitly. In the Linux greenfield result there is no `brew` executable, while package links such as `git` and `bash` resolve from `/home/linuxbrew/.linuxbrew/bin`.

For bootstrap packages, `version = "latest"` accepts an already installed package; it does not upgrade that package during apply. Package upgrades are therefore an explicit `mise bootstrap packages upgrade` phase, separate from `mise upgrade` for `[tools]`. Manager-wide `mise bootstrap packages prune --manager brew` is prohibited because it can remove formulae installed manually outside this repository. Cleanup is limited to the explicit legacy formula list replaced by qualified mise tools.

Only Apple Silicon macOS and Linux are supported by this ownership model; Intel macOS is unsupported. The Docker greenfield suite also passes two complete bootstrap convergences and requires the second convergence to report no changes.

### Qualification Evidence

Both platform workflows passed mise package apply, all 43 configured tool installs, and the shared smoke verifier after `[settings.npm] package_manager = "npm"` selected external npm. That setting avoids embedded aube aborts for three required npm packages on both platforms.

- macOS arm64: [workflow run 34425518410, job 102709799798](https://github.com/tribou/dotfiles/actions/runs/34425518410/job/102709799798)
- Ubuntu: [workflow run 34425518399, job 102709799806](https://github.com/tribou/dotfiles/actions/runs/34425518399/job/102709799806)

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
python = { version = "latest", postinstall = "python -m pip install --upgrade pynvim" }
go = "latest"
bun = "latest"
tombi = "latest"
# Portable tools and explicit npm:/gem: executables continue here.

[bootstrap.packages]
"brew:bash" = "latest"
"brew:git" = "latest"
# Shared-prefix and platform-selected formula artifacts continue here.

[settings]
legacy_version_file = true  # respects .nvmrc, .ruby-version, etc.
ruby.compile = false        # precompiled ruby binaries, no source build

[settings.npm]
package_manager = "npm"     # use external npm instead of embedded aube
```

- `legacy_version_file = true` means mise respects `.nvmrc`, `.node-version`, `.ruby-version` files automatically
- Run `mise install` to install all configured tool versions
- `mise which <tool>` to check which binary will be used

`mise-config.toml` is the single source of truth for core `[tools]` and
`[bootstrap.packages]`; there is no parallel inventory in the role. `mise.yml`
runs un-scoped package apply and tool install commands, which converge this file
plus any user drop-in under `~/.config/mise/conf.d/*.toml` (see [Opt-in
packages](#opt-in-packages)).

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
