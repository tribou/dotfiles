*What is this system? — components, data flow, DB schema, external APIs, and directory layout*

# Architecture

## Entry Points

- **`bootstrap.sh`**: Thin bootstrapper that solves the chicken-and-egg problem by installing standalone mise, then hands off to `mise bootstrap`. Accepts `curl | bash` for zero-clone installs.
  - Self-locates or self-clones the repo into `$HOME/dev/dotfiles`
  - Installs native OS prerequisites needed to install mise
  - Installs `~/.local/bin/mise`, or self-updates one older than `min_version` in `mise-config.toml`
  - Links `mise-config.toml` to `~/.config/mise/config.toml` (backing up an existing file) so the packages step sees it
  - Trusts the repo's `mise.toml` and hands off to `scripts/bootstrap/run.sh`, which runs `mise -C <repo> bootstrap --yes`; extra arguments pass through (e.g. `--dry-run`, `--skip task`)

- **`mise-config.toml`** (global config): `[tools]`, `[settings]`, and `[bootstrap.packages]` (OS prerequisites via `apt:`/`pacman:`, formulae via `brew:`). Machine-wide, so it applies from any directory.
- **`mise.toml`** (project config for this checkout): `[dotfiles]` symlinks, `[bootstrap.repos]` (TPM, vim-plug), the `pre-repos` and `pre-dotfiles` hooks, and the `bootstrap` and `upgrade` tasks. Relative sources and `{{ config_root }}` resolve to the checkout.
- **`scripts/bootstrap/run.sh`**: shared by `bootstrap.sh` and `just install`. Runs `mise bootstrap --yes`, or with `-n`/`--dry-run` previews it (see Run order).
- **`scripts/bootstrap/preflight.sh`**: macOS checks before mise or any package is installed. Rejects Intel, and says when mise will ask for a sudo password to create `/opt/homebrew`. `bootstrap.sh` itself first requires the Xcode Command Line Tools (`xcode-select -p`), since stock macOS ships `git`, `clang` and `make` as stubs and the self-clone needs git.
- **`scripts/bootstrap/next_steps.sh`**: the closing message, ending with a numbered "Manual follow-ups" list of steps bootstrap leaves to the user (add one with its `todo` helper). Everywhere: adding `~/.ssh/id_ed25519.pub` to GitHub, unless `ssh -T git@github.com` already authenticates (that check also records GitHub's host key). Also everywhere: creating a GPG key (it needs a passphrase) and adding it to GitHub with `gh gpg-key add`, unless `gpg` already has an active secret key that can sign (an expired or revoked key counts as none). On macOS: turning on Accessibility for Ghostty, which the quick terminal's `global:` keybind needs; when the login shell is not `/opt/homebrew/bin/bash`, the `/etc/shells` and `chsh` commands, since they need sudo and a password (only bash is configured: zsh gets no Homebrew or mise on `PATH`, and `/bin/bash` 3.2 is too old for `lib/`); and, on every run, the folders to add to Spotlight's Search Privacy list, since scripting that list needs Full Disk Access for the terminal, which bootstrap deliberately does not require.
- **`scripts/bootstrap/pre_repos.sh`**: the `pre-repos` hook (`--dry-run` reports without changing anything). mise's repos step stops on a checkout with local changes, which keeps a re-run from discarding real work. This hook clears only debris it can prove is safe to clear: plugin clones that TPM, run without `TMUX_PLUGIN_MANAGER_PATH`, left inside `~/.tmux/plugins/tpm` (untracked, clean, TPM's own origin URL for a plugin in `tmux/tmux-conf`). It removes each one when `~/.tmux/plugins` already has that plugin, and otherwise moves it there. Any other local change still stops the run.
- **`scripts/bootstrap/pre_dotfiles.sh`**: the `pre-dotfiles` hook (`--dry-run` reports without changing anything). Creates directories, keeps `~/.ssh` and `~/.gnupg` at `0700`, and moves a regular file at any `[dotfiles]` target to `<target>.backup` (mise refuses to replace files it did not write).
- **`scripts/bootstrap/converge.sh`**: the `bootstrap` task, run last with `[tools]` on PATH. SSH keys, the macOS keychain block, terminfo, `~/.gnupg` file modes, Neovim/CoC and TPM plugins, the `~/.z` → zoxide migration, pynvim, corepack shims, Docker on Linux (Docker CE from Docker's apt repo, or Arch's packages, only when no `docker` exists; then the service and the `docker` group; macOS gets the OrbStack cask instead), legacy Homebrew cleanup (`scripts/brew_cleanup.sh`, which keeps any formula another one depends on, such as watchman's python@3.x), verification, and the `~/.dotfiles-bootstrap-done` marker. Each step but the macOS keychain one (ssh-add may prompt) runs behind the `commit` spinner (`lib/spinner.sh`) labelled with what it is doing, and its output prints when it finishes.
- **`scripts/upgrade.sh`**: the `upgrade` task (`just upgrade`).

Every declarative part (packages, repos, dotfiles, tools) skips what already matches, and the hook and task print `changed: ...` only when they change something, so re-running `just install` is safe and a second run is quiet.

### Run order

`mise bootstrap` applies, in order: packages (both configs) → `pre-repos` hook → repos → `pre-dotfiles` hook → dotfiles → tools → the `bootstrap` task. `just install --dry-run` (or `./bootstrap.sh --dry-run`) previews it. Don't call `mise bootstrap --dry-run` directly: it neither clones repos nor runs the hook, so on a machine that was never bootstrapped its dotfiles check fails on the missing vim-plug source and on files the hook would back up, and it never previews the later parts. `run.sh` instead runs `pre_repos.sh --dry-run` (when repos is selected), has mise preview everything except dotfiles, then runs `pre_dotfiles.sh --dry-run` and `mise dot diff`. A dry run through `bootstrap.sh` skips the Linux package steps and applies nothing, but it still installs mise when missing and links the global config (backing up an existing `~/.config/mise/config.toml`), and when piped from curl it clones the repo to `~/dev/dotfiles` (a real piped run instead fast-forwards an existing clean checkout on `main`, and runs any other checkout as is); it stops if the installed mise is older than `min_version` instead of updating it. `just install --dry-run` changes nothing and warns when the global config is not linked to that checkout, because mise then previews another checkout's packages and global tools, or none. `mise bootstrap status` and `mise dot status` report drift.

### Upgrades

`just upgrade` runs the `upgrade` task: a full OS upgrade (`apt-get upgrade` / `pacman -Syu`), `mise bootstrap packages upgrade`, `mise upgrade`, `mise bootstrap repos update` (fast-forwards TPM and vim-plug), a full `mise bootstrap` converge, then pynvim, rustup, Neovim and tmux plugin updates, and the claude self-updater when installed (mise upgrades opencode with the other tools). With no Ansible there is no interpreter for an upgrade to replace mid-run.

### Opt-in packages

The configs install a **core** set on every machine. Everything else is opt-in
via `mise-config.optional.toml.example`, copied to
`~/.config/mise/conf.d/optional.toml` — nothing in the repo needs editing per
machine. mise auto-loads `conf.d/*.toml` and merges it over `config.toml`:

- optional tools under `[tools]`
- optional formulae (`brew:`) and macOS casks (`brew-cask:`) under
  `[bootstrap.packages]`. mise installs casks itself, without Homebrew, into
  `/Applications`; on Linux it takes only font casks.

The one core cask is Ghostty, the terminal (`"brew-cask:ghostty"`, macOS only,
`adopt = true` so an identical Ghostty.app already in `/Applications` is taken
over rather than replaced). On Linux, Ghostty is opt-in: `pacman:ghostty` on
Arch, or a package from ghostty.org on Debian/Ubuntu.

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
        +--> pre-repos hook: clear stray TPM plugin clones from ~/.tmux/plugins/tpm
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

Both platform workflows passed mise package apply, every tool install configured at the time, and the shared smoke verifier after `[settings.npm] package_manager = "npm"` selected external npm. That setting avoids embedded aube aborts for three required npm packages on both platforms.

- macOS arm64: [workflow run 34425518410, job 102709799798](https://github.com/tribou/dotfiles/actions/runs/34425518410/job/102709799798)
- Ubuntu: [workflow run 34425518399, job 102709799806](https://github.com/tribou/dotfiles/actions/runs/34425518399/job/102709799806)

- **`bash_profile`**: Main bash configuration loaded on shell startup
  - Sources all lib scripts via `lib/index.sh`
  - Sets up environment variables (DEVPATH, DOTFILES, GOPATH, etc.)
  - Configures PATH for Homebrew, mise, and other tools
  - Implements prompt customization with git branch detection
  - Activates mise, which selects Node (and other runtimes) from `.nvmrc`, `.node-version`, and similar files

- **`zshrc`**: Minimal, secondary zsh configuration (prompt, fzf, zoxide, completion). It does not source `bash_profile` or `lib/`, so the shell functions and aliases are bash-only

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
- **`ghostty.sh`**: Decides whether `bash_profile` should source Ghostty's bash shell integration (in Ghostty, outside tmux, not already loaded)

## Agent Directory

The `agent/` directory contains the isolated LLM agent-user subsystem:

- **`setup-user.sh`**: Linux-only setup script for creating the `agent` user, SSH key, sudoers entry, and shell profile wiring
- **`overrides.sh`**: Agent-only shell overrides for git identity and the `[llm]` prompt prefix

**Important boundary**: files in `agent/` are intentionally **not** sourced by `bash_profile` or `lib/index.sh`. Only consumed by the generated `agent` user's home profile.

## Scripts Directory

The `scripts/` directory contains standalone utility scripts (not sourced; run directly):

- **`bootstrap/`**: Bootstrap stages — `preflight.sh`, `run.sh` (drives `mise bootstrap`), `pre_repos.sh` (pre-repos hook), `pre_dotfiles.sh` (pre-dotfiles hook), `converge.sh` (the `bootstrap` mise task), `next_steps.sh`
- **`link_mise_config.sh`**: Links `mise-config.toml` as the global mise config, backing up any existing file
- **`verify_mise_tools.sh`**: Smoke-checks every mise package and tool (bootstrap and CI)
- **`upgrade.sh`**: The `upgrade` mise task behind `just upgrade`
- **`brew_cleanup.sh`**: One-time removal of Homebrew copies of tools mise now owns
- **`doctor.sh`**: `just doctor` health checks for symlinks and tools
- **`test_changed.sh`**: `just test-changed` change-based test selection
- **`perf_report.sh`**: Prints the startup/prompt latency history from `tests/.perf_log.jsonl`
- **`tmux-copy.sh`** / **`tmux-paste.sh`**: tmux buffer ↔ system clipboard bridges
- **`dotfiles_remote_browser_open.sh`** / **`dotfiles_local_browser_helper.sh`**: Open browser URLs from an SSH session on the local machine via a reverse tunnel
- **`battery.sh`**: Battery level reporting for terminal prompt or notifications
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
# os = "linux" keeps macOS from listing them as skipped follow-ups
"apt:build-essential" = { version = "latest", os = "linux" }  # skipped where apt is unavailable
"pacman:base-devel" = { version = "latest", os = "linux" }    # skipped where pacman is unavailable
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
  - Can contain any sensitive environment variables (e.g., DIGITALOCEAN_API_TOKEN)

- **Project Paths**:
  - `DEVPATH`: `~/dev`
  - `DOTFILES`: derived by `bash_profile` from the checkout it is symlinked from (resolves the `~/.bash_profile` symlink), so the repo can live anywhere
  - `GOPATH`: `~/dev/go`
  - `STARTPATH`: optional, user-set start directory. When set, the initial login shell (the `STARTPATH` block near the end of `bash_profile`) and new tmux windows (`prefix c`) open there instead of `DEVPATH`
  - `PRIMARY_REPO`, `SECONDARY_REPO`: Defaults for the tmux layout functions (`tmux-large [primary] [secondary]`, etc.) when no argument is given; fuzzy matched via zoxide

- **Directory Navigation**: Uses [zoxide](https://github.com/ajeetdsouza/zoxide) for frecency-based directory jumping
  - Initialized in `bash_profile` and `zshrc` with `zoxide init` when installed (mise `[tools]`)
  - `_dotfiles_full_path` uses `zoxide query` to resolve directory names
  - Bootstrap imports a legacy rupa/z `~/.z` database into zoxide once

- **History**: Timestamped files in `~/.history/YYYY/MM/DD.HH.MM.SS_hostname_pid`

## Neovim/Vim Configuration

- **`init.vim`**: Main Neovim config
- **`coc-settings.json`**: CoC LSP configuration
- Uses vim-plug for plugin management
- ALE for linting/fixing
- Language support: JavaScript/TypeScript, React, Python, Ruby, Elixir, Go

## Terminal (Ghostty)

- **`ghostty/config.ghostty`** → `~/.config/ghostty/config.ghostty`, **`ghostty/themes/dotfiles-night`** → `~/.config/ghostty/themes/dotfiles-night` (both via `[dotfiles]` in `mise.toml`, both checked by `just doctor`)
- Runs `/bin/bash --login`; `TERM=xterm-ghostty` (terminfo bundled with Ghostty). Inside tmux, `TERM` is `tmux-256color` (`tmux/tmux-256color.terminfo`, compiled by the `bootstrap` task), and `tmux-conf` declares Ghostty's features (`terminal-features`) so truecolor, undercurl, extended keys, sync and OSC 52 pass through
- Shell integration is sourced manually (`shell-integration = none`, see `lib/ghostty.sh`), because Ghostty cannot auto-inject into macOS's `/bin/bash`. It is skipped inside tmux
- tmux stays the multiplexer. Ghostty's native tabs and splits stay on their default `cmd`/`ctrl+shift` keys, which do not collide with tmux's `C-f` prefix; `ctrl+shift+left/right` are unbound in Ghostty so tmux's window swaps keep working

## Tmux Configuration

- **`tmux/tmux-conf`**: Main tmux configuration
- Prefix key: `Ctrl-f`
- System clipboard: copy-mode yanks reach it through OSC 52 (`set-clipboard on`, `allow-passthrough on`); the right-click menu's Copy and Paste items use `scripts/tmux-copy.sh` and `scripts/tmux-paste.sh` (pbcopy/pbpaste or xclip)
- Predefined layouts via shell functions: `tmux-large`, `tmux-small`, `tmux-xl`
- **Working directory of new windows vs splits** (two intentionally different rules):
  - **New windows** (`prefix c`) open at `$STARTPATH` if set, otherwise `$DEVPATH`, via the `#{?STARTPATH,#{STARTPATH},#{DEVPATH}}` format (`tmux/tmux-conf`). Requires `STARTPATH`/`DEVPATH` to be present in tmux's global environment (inherited from the launching login shell). Mirrors the initial-shell cd logic in `bash_profile`
  - **Splits** (`C-v` vertical, `C-h` horizontal) deliberately open in the **current pane's directory** (`#{pane_current_path}`, `tmux/tmux-conf`) so a split stays in the same project you are working in. This divergence from the new-window rule is intentional — do not "unify" the two
- **`tmux/tmux-right-click-menu.conf`**: Right-click pane menu with custom Paste item
  - Sourced conditionally by `tmux-conf` on non-SSH sessions only
  - Stock menu items are hand-maintained (tmux has no "extend the default menu" hook)
  - After a tmux upgrade, re-run `tmux list-keys -T root MouseDown3Pane` and reconcile any new/changed entries

## Test Infrastructure

- **`tests/*.bats`**: Unit tests (bats-core); run fast with no Docker required
- **`tests/integration/`**: Integration tests run inside Docker
  - `mise_packages.bats`: Verifies mise's brew-backend formulae install without Homebrew
  - `nvim_health.bats`: Validates Neovim plugin health
  - `nvim_keymaps.bats`: Verifies key mappings are configured correctly
  - `nvim_python_provider.bats`: Verifies Neovim's python3 provider finds pynvim
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

Priority is tracked via `P1`/`P2`/`P3` labels. Type is tracked via `type::bug`, `type::feature`, `type::task`, or `type::chore` (older issues may still carry the legacy `bug`/`enhancement` labels).
