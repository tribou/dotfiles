*What is this system? — components, data flow, DB schema, external APIs, and directory layout*

# Architecture

## Entry Points

- **`bootstrap.sh`**: Thin bootstrapper that solves the chicken-and-egg problem by installing standalone mise, then hands off to `mise bootstrap`. Accepts `curl | bash` for zero-clone installs.
  - Self-locates or self-clones the repo into `$HOME/dev/dotfiles`
  - Installs native OS prerequisites needed to install mise
  - Installs `~/.local/bin/mise`, or self-updates one older than `min_version` in `mise-config.toml`
  - Links `mise-config.toml` to `~/.config/mise/config.toml` (backing up an existing file) so the packages step sees it
  - Trusts the repo's `mise.toml` and runs `mise -C <repo> bootstrap --yes`; extra arguments pass through (e.g. `--dry-run`, `--skip task`)

- **`mise-config.toml`** (global config): `[tools]`, `[settings]`, and `[bootstrap.packages]` (OS prerequisites via `apt:`/`pacman:`, formulae via `brew:`). Machine-wide, so it applies from any directory.
- **`mise.toml`** (project config for this checkout): `[dotfiles]` symlinks, `[bootstrap.repos]` (TPM, vim-plug), the `pre-dotfiles` hook, and the `bootstrap` and `upgrade` tasks. Relative sources and `{{ config_root }}` resolve to the checkout.
- **`scripts/bootstrap/pre_dotfiles.sh`**: the `pre-dotfiles` hook. Creates directories, keeps `~/.ssh` and `~/.gnupg` at `0700`, and moves a regular file at any `[dotfiles]` target to `<target>.backup` (mise refuses to replace files it did not write).
- **`scripts/bootstrap/converge.sh`**: the `bootstrap` task, run last with `[tools]` on PATH. SSH keys, the macOS keychain block, terminfo, `~/.gnupg` file modes, Neovim/CoC and TPM plugins, the `~/.z` → zoxide migration, pynvim, corepack shims, legacy Homebrew cleanup (`scripts/brew_cleanup.sh`), verification, and the `~/.dotfiles-bootstrap-done` marker.
- **`scripts/upgrade.sh`**: the `upgrade` task (`just upgrade`).

Every declarative part (packages, repos, dotfiles, tools) skips what already matches, and the hook and task print `changed: ...` only when they change something, so re-running `just install` is safe and a second run is quiet.

### Run order

`mise bootstrap` applies, in order: packages (both configs) → repos → `pre-dotfiles` hook → dotfiles → tools → the `bootstrap` task. `mise bootstrap --dry-run` previews it; `mise bootstrap status` and `mise dot status` report drift.

### Upgrades

`just upgrade` runs the `upgrade` task: a full OS upgrade (`apt-get upgrade` / `pacman -Syu`), `mise bootstrap packages upgrade`, `mise upgrade`, `mise bootstrap repos update` (fast-forwards TPM and vim-plug), a full `mise bootstrap` converge, then pynvim, rustup, Neovim and tmux plugin updates, and the claude/opencode self-updaters when installed. With no Ansible there is no interpreter for an upgrade to replace mid-run.

### Opt-in packages

The configs install a **core** set on every machine. Everything else is opt-in
via `mise-config.optional.toml.example`, copied to
`~/.config/mise/conf.d/optional.toml` — nothing in the repo needs editing per
machine. mise auto-loads `conf.d/*.toml` and merges it over `config.toml`:

- optional tools under `[tools]`
- optional formulae (`brew:`) and macOS casks (`brew-cask:`) under
  `[bootstrap.packages]`. mise installs casks itself, without Homebrew, into
  `/Applications`; on Linux it takes only font casks.

Run `just install` after uncommenting entries. A `~/.Brewfile` from the old
Homebrew cask flow is no longer applied; move its casks into the drop-in.

### Mise-First Provisioning Flow

```text
native OS prerequisites (curl, git)
        |
        v
standalone ~/.local/bin/mise  --> link global mise-config.toml, trust mise.toml
        |
        v
mise bootstrap
        +--> packages: apt:/pacman: prerequisites, brew: formulae -> canonical brew prefix
        +--> repos: TPM, vim-plug
        +--> pre-dotfiles hook: dirs, private modes, .backup of conflicting files
        +--> dotfiles: symlinks into this checkout
        +--> tools: versioned tools + shims (rust, gopls, npm:, gem: included)
        +--> bootstrap task: keys, plugins, migrations, verification
```

`brew:` is a mise package backend, not a requirement for a `brew` executable. It writes formula artifacts and links into the canonical platform prefix — `/opt/homebrew` on Apple Silicon macOS and `/home/linuxbrew/.linuxbrew` on Linux — creating the prefix with sudo when it is missing. Bootstrap, verification, and shell startup add the applicable prefix to `PATH` explicitly. In the Linux greenfield result there is no `brew` executable, while package links such as `git` and `bash` resolve from `/home/linuxbrew/.linuxbrew/bin`.

For bootstrap packages, `version = "latest"` accepts an already installed package; it does not upgrade that package during apply. Package upgrades are therefore an explicit `mise bootstrap packages upgrade` phase, separate from `mise upgrade` for `[tools]`. Manager-wide `mise bootstrap packages prune --manager brew` is prohibited because it can remove formulae installed manually outside this repository. Cleanup is limited to the explicit legacy formula list replaced by qualified mise tools.

Only Apple Silicon macOS and Linux are supported by this ownership model; Intel macOS is unsupported. The Docker greenfield suite runs two complete bootstraps and requires the second to report no changes and `mise bootstrap status --missing` to pass.

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
ruby = "4"
python = { version = "latest", postinstall = "python -m pip install --upgrade pynvim" }
go = "latest"
"go:golang.org/x/tools/gopls" = "latest"
rust = "stable"
bun = "latest"
tombi = "latest"
# Portable tools and explicit npm:/gem: executables continue here.

[bootstrap.packages]
"apt:build-essential" = "latest"   # skipped where apt is unavailable
"pacman:base-devel" = "latest"     # skipped where pacman is unavailable
"brew:bash" = "latest"
"brew:git" = "latest"
# Shared-prefix and platform-selected formula artifacts continue here.

[settings]
legacy_version_file = true  # respects .nvmrc, .ruby-version, etc.
ruby.compile = false        # precompiled ruby binaries, no source build

[settings.npm]
package_manager = "npm"     # use external npm instead of embedded aube
```

- The python `postinstall` only runs when mise installs that python, so the
  `bootstrap` task also runs `pip install pynvim`, and `just upgrade` runs
  `pip install --upgrade pynvim`.
- `legacy_version_file = true` means mise respects `.nvmrc`, `.node-version`, `.ruby-version` files automatically
- Run `mise install` to install all configured tool versions
- `mise which <tool>` to check which binary will be used

`mise-config.toml` is the single source of truth for core `[tools]` and
`[bootstrap.packages]`. `mise bootstrap` applies packages and installs tools
un-scoped, which converges this file plus any user drop-in under `~/.config/mise/conf.d/*.toml` (see [Opt-in
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

Priority is tracked via `P1`/`P2`/`P3` labels. Bugs use the `bug` label; tasks/features use `enhancement`.
