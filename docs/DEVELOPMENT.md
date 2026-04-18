*How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack*

# Development

## Tech Stack
- **Bash Scripts**: Core functionality
- **Docker**: For isolation and dev environments
- **bats-core**: Bash unit testing framework
- **just**: Command runner (`justfile`)
- **mise**: Version manager

## Design Principles
- Keep scripts modular by breaking them into `lib/` files
- Sourced functions should be reliable and prefer fast execution
- The repository assumes macOS (checks for Darwin in multiple places)
- NVM loaded with `--no-use` for performance; Node auto-switches on directory change via PROMPT_COMMAND

## Naming Conventions
- Internal functions typically start with an underscore (e.g., `_dotfiles_full_path`)
- Ticket-related branches use `AB-123/description`, `ab123-description`, or `123_AT_Description` (DCX pattern)

## Reliability
- Use `bashcheck` instead of `bash -n` for syntax verification
- Include bats tests for new functions
- GPG signing required for commits — set `GIT_SIGNING_KEY` in `~/.ssh/api_keys`

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

## Configuration Files

- **`.editorconfig`**: Consistent formatting across editors
- **`gitconfig`**: GPG signing, useful aliases (`tree`, `tree-one`, `diff-word`, `forget`), LFS, SSH for GitHub, nvimdiff merge tool
- **`alacritty.toml`**: Alacritty terminal emulator config
- **`ripgreprc`**: Ripgrep defaults (exported via `RIPGREP_CONFIG_PATH`)