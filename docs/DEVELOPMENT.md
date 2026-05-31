*How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack*

# Development

## Tech Stack
- **Bash Scripts**: Core functionality (macOS primary, Linux secondary)
- **Docker**: For isolation and CI/CD test environments
- **bats-core**: Bash unit testing framework
- **goss**: Infrastructure/environment assertion testing
- **just**: Command runner (`justfile`)
- **mise**: Version manager (replaces nvm/rbenv/pyenv per-project)

## Design Principles
- Keep scripts modular by breaking them into `lib/` files
- Sourced functions should be reliable and prefer fast execution
- The repository assumes macOS (checks for Darwin in multiple places)
- mise loaded on shell startup; tool versions auto-switch natively on directory change via shell integration hooks

## Naming Conventions
- Internal functions typically start with an underscore (e.g., `_dotfiles_full_path`)
- Ticket-related branches use `AB-123/description`, `ab123-description`, or `123_AT_Description` (DCX pattern)

## Reliability
- Use `bashcheck` instead of `bash -n` for syntax verification
- Include bats tests for new functions in `tests/*.bats`
- GPG signing required for commits — set `GIT_SIGNING_KEY` in `~/.ssh/api_keys`
- New infrastructure dependencies (binaries, env vars) should have a `goss.yaml` assertion

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

## Package Management

```bash
y                  # Install deps (auto-detects pnpm/yarn/bun/npm)
nr                 # Run npm script (interactive fzf if no args)
nu express         # Upgrade specific package (fzf select if no args)
```

Detection order: `pnpm-lock.yaml` → `yarn.lock` → `bun.lock` → npm

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

### Discovery Behavior

- **Claude Code**: Skills are discovered from the `skills/` directory in the project root and from the user's global skills path.
- **opencode**: Skills are discovered from the `skills/` directory in the project root and from `~/.config/opencode/skills/`. The opencode `skill` tool loads the full `SKILL.md` content on demand.

When adding a new skill, ensure the frontmatter is valid YAML and the `name` matches the directory name exactly.