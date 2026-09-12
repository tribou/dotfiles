*How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack*

# Development

## Tech Stack
- **Bash Scripts**: Core functionality (macOS primary, Linux secondary)
- **Docker**: For isolation and CI/CD test environments
- **bats-core**: Bash unit testing framework
- **goss**: Infrastructure/environment assertion testing
- **just**: Command runner (`justfile`)
- **mise**: Version manager (replaces nvm/rbenv/pyenv per-project)
- **Ansible**: Declarative provisioning via the `dotfiles` role
- **Molecule**: Ansible role testing framework (idempotence, multi-scenario)

## Design Principles
- Keep scripts modular by breaking them into `lib/` files
- Sourced functions should be reliable and prefer fast execution
- Provisioning supports Apple Silicon macOS and Linux; Intel macOS is unsupported
- mise loaded on shell startup; tool versions auto-switch natively on directory change via shell integration hooks

## Library Module Organization

The root-level `lib/*.sh` files are shell modules loaded by `lib/index.sh`.

- **Boundary:** Prefer one file per external tool or cohesive domain, such as `git.sh`, `docker.sh`, `tmux.sh`, or `npm.sh`. Small related tools may share a module until it approaches the size limit; for example, `cloud.sh` may group AWS, DigitalOcean, Terraform, and SSH helpers before those concerns are large enough to split.
- **Size:** Keep each module near 300 physical lines or fewer. `just test-unit` prints a warning for files over 300 lines but deliberately keeps passing so a cohesive exception does not block CI.
- **Naming:** Use lowercase `snake_case` names based on the tool or domain, such as `git.sh` or `curl_it.sh`. Reserve a leading underscore, such as `_shared.sh`, for non-domain helpers consumed by other modules.
- **Load order:** `lib/index.sh` sources all `_*.sh` modules before non-underscore modules, independently of locale. Relative order within either group is unspecified, so peer modules must not depend on alphabetical loading.

`lib/commands.sh` retains general shell utilities, while tool-specific helpers are split into focused domain modules (`git.sh`, `npm.sh`, `docker.sh`, `tmux.sh`, `cloud.sh`, `repo.sh`, `agent.sh`).

## Naming Conventions
- Internal functions typically start with an underscore (e.g., `_dotfiles_full_path`)
- Ticket-related branches use `AB-123/description`, `ab123-description`, or `123_AT_Description` (DCX pattern)

## Reliability
- Use `bashcheck` instead of `bash -n` for syntax verification
- Include bats tests for new functions in `tests/*.bats`
- GPG signing required for commits — set `GIT_SIGNING_KEY` in `~/.ssh/api_keys`
- New infrastructure dependencies (binaries, env vars) should have a `goss.yaml` assertion

## Ansible Role Development

### Molecule Dev Loop

The `dotfiles` Ansible role uses Molecule for testing. The default scenario runs in a Docker container:

```bash
# Converge (apply the role inside the test container)
molecule converge

# Idempotence check (re-run and verify no changed tasks)
molecule converge

# Full test sequence: create → converge → idempotence → verify → destroy
molecule test

# Verify-only (goss assertions and custom verify.yml checks)
molecule verify

# Destroy the test container
molecule destroy
```

### Running Tag Subsets

The role's tasks are tagged for targeted runs. Common subsets:

```bash
# Just symlinks and SSH, skipping brew/npm/mise upgrades
ansible-playbook playbook.yml --tags ssh,links

# Dry-run with diff to preview changes without applying them
ansible-playbook playbook.yml --check --diff

# Combine both: preview what linking and SSH tasks would change
ansible-playbook playbook.yml --check --diff --tags ssh,links
```

Available tags: `beads`, `brew`, `brew_casks`, `claude_opencode`, `dirs`, `gpg`, `links`, `mise`, `nvim`, `prereqs`, `rust`, `ssh`, `terminfo`, `tpm`, `upgrade`, `zoxide`. Use `ansible-playbook playbook.yml --list-tags` for the full list.

## Git Workflow with Ticket Numbers

The `c` function automatically prefixes commits with the ticket number:

```bash
co feature/AB-123/new-feature  # Checkout or create branch (fzf if no args)
# Make changes...
ga                              # git add --all
c "implement new feature"       # Commits as "AB-123: implement new feature"
gpsu                           # git push -u origin current-branch
```

- Commit separator configurable via `DOTFILES_COMMIT_SEPARATOR` (default: `:`)
- Commit model override via `DOTFILES_COMMIT_MODEL` — set it to force a specific model for the active backend, overriding the per-backend default (visible in `commit status`)

`commit` (no args) stages everything, asks the configured backend to draft the message, and commits — falling back to `c` (manual editor) if the backend is unavailable, errors, or times out. A spinner shows progress while waiting; Ctrl-C cancels the commit (changes stay staged) instead of falling back to `c`.

- Commit backend timeout configurable via `DOTFILES_COMMIT_TIMEOUT` (seconds, default: `15`) — if the backend takes longer (hangs, or is stalled on a usage limit) it is killed and `commit` falls back to the manual `c` editor. Shown in `commit status`.

## Package Management

```bash
y                  # Install deps (auto-detects pnpm/yarn/bun/npm)
nr                 # Run npm script (interactive fzf if no args)
nu express         # Upgrade specific package (fzf select if no args)
```

Detection order: `pnpm-lock.yaml` → `yarn.lock` → `bun.lock` → npm

### Provisioning Ownership

Select new machine-wide packages in this order:

1. Use the canonical mise registry tool when it qualifies on both macOS arm64 and Linux.
2. Use an explicit `npm:` or `gem:` tool key when the package supplies the required executable.
3. Use `pipx:` for an isolated Python application.
4. Use a tool-level `postinstall` when a library must be imported by its managed interpreter rather than run as a standalone executable.
5. Use a `brew:` bootstrap package only after dual-platform tool qualification fails or when shared-prefix artifact semantics are required.

Record each qualification failure and resulting owner in the package ownership table in [ARCHITECTURE.md](ARCHITECTURE.md#package-ownership-audit). Casks remain owned by the real Homebrew CLI on macOS, while native OS package managers retain bootstrap and system dependencies. Ansible executes mise convergence but must not mirror either `[tools]` or `[bootstrap.packages]`; `mise-config.toml` and optional mise drop-ins are the inventories.

## Development Environment

```bash
z dotfiles         # Jump to frequently used directory (frecency-based)
tmux-xl ~/myapp    # Create XL layout for myapp (uses z to resolve)
search "pattern"   # Git grep excluding vendor/node_modules/lockfiles
```

- `z` must be installed at `~/dev/z/z.sh`

## FZF Integration

Many commands use fzf for interactive selection when called without arguments:
- `co` — checkout branch
- `gbd` — delete branch
- `npm-run` / `nr` — select npm script
- `nu` — upgrade npm package
- `aws-profile` — select AWS profile

## Tmux-Aware Execution

`_eval_script` sends commands to a tmux pane if in a tmux session, otherwise executes directly. This puts commands in shell history when in tmux.

## Common Aliases

Defined in `lib/commands.sh`:

- **Git**: `s` (status), `amend` (commit --amend), `fix` (amend without editor), `mm`/`md`/`mp`/`ms` (merge main/develop/prod/staging), `f` (fetch), `ga` (git add --all)
- **Editor**: `v` (nvim), `vc` (vimcat)
- **Package managers**: `y` / `yi` (npm-install), `nr` / `yr` (npm-run)
- **Navigation**: `..`, `...`, `....` (up directories), `back` (cd to $OLDPWD)
- **Utilities**: `ll` (ls -lah), `lt` (ls sorted by time), `tree` (excludes node_modules/dist)
- **Docker**: `d` (docker), `dc` (docker compose), `dps` (docker ps), `da` (attach), `ds` (stop)

## Remote Development (SSH)

### Markdown Preview Over SSH

When editing markdown files on a remote server via SSH, `<space>o` can open the
browser on your **local** machine using port forwarding:

1. **Add port forwarding to your SSH config** (`~/.ssh/config`):
   ```
   Host myremote
       # Forward remote composer's HTTP server to local machine
       LocalForward 15678 localhost:15678
       # Reverse forward: remote can signal local machine to open browser
       RemoteForward 15679 localhost:15679
   ```

2. **Start the local browser helper** on your local machine:
   ```bash
   nohup dotfiles_local_browser_helper.sh >/dev/null 2>&1 &
   ```

3. **Verify**: SSH into the remote, open a markdown file in neovim, and press
   `<space>o`. The preview should open in your local browser.

The neovim config auto-detects SSH sessions via `$SSH_CLIENT`/`$SSH_TTY` and
adjusts the composer settings automatically. No manual neovim configuration is
needed beyond running `bootstrap.sh` on the remote machine.

### Stuck Mouse Reporting After a Dropped SSH Session

**Symptom**: after an SSH+tmux session dies uncleanly (laptop sleep), moving the
mouse spams the terminal with `35;133;37M...` sequences.

**Cause**: `set -g mouse on` (`tmux/tmux-conf`) enables mouse tracking on the
local alacritty; an unclean disconnect skips the "off" sequences, so alacritty
stays in motion-reporting mode. The stuck state is local — reconnecting SSH
doesn't clear it.

**Fix** (local shell prompt, dead `ssh` exited; keep mouse still while typing,
`Ctrl-U` to clear a garbled line):

- `reset` — works, but also clears scrollback.
- Mouse-mode only (keeps scrollback): `printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?1015l'`

## Configuration Files

- **`.editorconfig`**: Consistent formatting across editors
- **`gitconfig`**: GPG signing, useful aliases (`tree`, `tree-one`, `diff-word`, `forget`), LFS, SSH for GitHub, nvimdiff merge tool
- **`alacritty.toml`**: Alacritty terminal emulator config
- **`ripgreprc`**: Ripgrep defaults (exported via `RIPGREP_CONFIG_PATH`)

## AI Skills

The `skills/` directory contains custom AI agent skills used by both Claude Code and opencode.

### Directory Layout

Each skill lives in its own subdirectory under `skills/<skill-name>/` and must contain a `SKILL.md` file at minimum:

```
skills/
  organize-ai-context/
    SKILL.md
```

### SKILL.md Frontmatter

The `SKILL.md` file must begin with YAML frontmatter:

```yaml
---
name: organize-ai-context
description: Use when setting up a new repository, when AI agents lack project context, or when codebase guidelines are scattered and unstructured.
---
```

- `name`: matches the directory name (kebab-case)
- `description`: a concise trigger phrase that tells the agent when to invoke the skill

### Shared Sub-Skills

Some skills exist to be invoked *by other skills* rather than directly by a user. They are packaged the same way — a directory under `skills/` with a `SKILL.md` — but their contract is an invocation contract for callers.

- **`agent-usage-audit`** — records which model ran a workflow stage and what it consumed, as a single marked GitHub comment on the issue or PR that stage produced. Its support script lives beside it at `skills/agent-usage-audit/scripts/agent-usage-audit`. It is a `REQUIRED SUB-SKILL` of `brainstorming-to-issue` (targets `issue:<N>`), `issue-to-plan` (targets `pr:<M>`), and `plan-to-implementation` (targets `pr:<M>`, on both the successful-finish and blocker paths). Any other skill needing the same audit trail invokes it the same way; nothing re-implements probing or comment lookup.

A shared sub-skill's callers reference it by name only. Harness- and GitHub-specific mechanics stay inside the sub-skill, so adding a fourth caller is a one-line change to that caller. Each caller supplies its own kebab-case `--stage` identifier; the shared implementation does not maintain an exhaustive caller list.

### Discovery Behavior

- **Claude Code**: Skills are discovered from the `skills/` directory in the project root and from the user's global skills path.
- **opencode**: Skills are discovered from the `skills/` directory in the project root and from `~/.config/opencode/skills/`. The opencode `skill` tool loads the full `SKILL.md` content on demand.

Per-tool paths (`~/.claude/skills/`, `~/.config/opencode/skills/`, `~/.gemini/skills/`, etc.) are populated with `npx skills add` ([vercel-labs/skills](https://github.com/vercel-labs/skills)), not by `bootstrap.sh` — see below.

### Installing Skills into Agent Tools

`bootstrap.sh` no longer symlinks `skills/` into per-tool config directories. Use `npx skills add` instead:

```bash
# Install every skill in this repo, globally, to Claude Code and opencode
npx skills add . -g -a claude-code -a opencode --skill '*' -y

# Add another agent (e.g. Gemini CLI)
npx skills add . -g -a gemini-cli --skill '*' -y

# Install a single skill instead of all of them
npx skills add . -g -a claude-code --skill organize-ai-context -y
```

- Run from the `dotfiles/` repo root so `.` resolves to this repo's `skills/` directory.
- Drop `-g` to install into the current project instead of globally (`~/<agent>/skills/`).
- `npx skills list` shows what's currently installed; `npx skills update` refreshes symlinked skills after pulling repo changes; `npx skills remove <skill>` uninstalls one.

### Local Development via Symlinks

To avoid copying or having to manually update skills during local development, use relative symlinks. This ensures edits in `skills/` instantly propagate to your agent's active workspace:

1. **Link repo skills to `.agents/skills/`**:
   ```bash
   ln -s ../../skills/<skill-name> .agents/skills/<skill-name>
   ```
2. **Link `.agents/skills/` to `.claude/skills/`**:
   ```bash
   ln -s ../../.agents/skills/<skill-name> .claude/skills/<skill-name>
   ```

When adding a new skill, ensure the frontmatter is valid YAML and the `name` matches the directory name exactly.
