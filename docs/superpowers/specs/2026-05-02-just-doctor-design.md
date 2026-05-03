# Design: Add `just doctor` health-check command

## Summary

A standalone bash script (`scripts/doctor.sh`) that verifies the local machine hasn't drifted from the expected bootstrap state. Covers symlinks and tool presence — the things most likely to silently break over time. Output is human-readable with one-liner remediation hints. Fully testable with bats-core.

## Approach

Pure bash with one function per check category. No goss on host — goss stays Docker-only. Each check function prints a pass/fail line and returns 0/1. The script exits non-zero if any check fails.

### Why not goss on host

The existing `goss.yaml` uses Docker-specific paths (`/dotfiles`, `/root/`). Adapting it for the host (via templating or a separate file) adds complexity and a dependency that may not be installed. Pure bash is simpler, testable with bats, and has zero extra dependencies.

## Script: `scripts/doctor.sh`

### Structure

```
#!/usr/bin/env bash
set -euo pipefail

# Source lib for $DOTFILES
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Check functions ---
check_symlinks() { ... }
check_tools() { ... }

# --- Output helpers ---
pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s → %s\n' "$1" "$2"; }

# --- Main ---
main() { ... }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

The `main` guard allows bats to source the file and call individual functions without triggering execution.

### Output format

One line per check, prefixed with ✓ or ✗:

```
Symlinks:
  ✓ ~/.gitconfig
  ✓ ~/.zshrc
  ✗ ~/.tmux.conf → run: ./bootstrap.sh

Tools:
  ✓ nvim
  ✓ git
  ✗ go → run: mise install go

doctor: 5/7 checks passed (2 failures)
```

Exit code 0 if all pass, 1 if any fail.

### Symlink checks

Verify each target exists, is a symlink, and points to the correct source in `$DOTFILES`. All 14 symlinks from bootstrap.sh:

| Target | Source (relative to $DOTFILES) |
|--------|-------------------------------|
| `~/.bash_profile` | `bash_profile` |
| `~/.vimrc` | `init.vim` |
| `~/.gitconfig` | `gitconfig` |
| `~/.zshrc` | `zshrc` |
| `~/.tmux.conf` | `tmux/tmux-conf` |
| `~/.default-node-packages` | `default-node-packages` |
| `~/.default-gems` | `default-gems` |
| `~/.default-python-packages` | `default-python-packages` |
| `~/.gnupg/gpg-agent.conf` | `gpg-agent-conf` |
| `~/.config/nvim/init.vim` | `init.vim` |
| `~/.config/alacritty/alacritty.toml` | `alacritty.toml` |
| `~/.config/mise/config.toml` | `mise-config.toml` |
| `~/.config/nvim/coc-settings.json` | `coc-settings.json` |
| `~/.claude/skills` | `skills` |

Each check verifies: (1) target exists, (2) target is a symlink, (3) raw symlink target (via `readlink` on macOS, `readlink -f` on Linux) matches `$DOTFILES/<source>`. Use `readlink` portably — on macOS the bootstrap uses `ln -sf` with absolute paths, so `readlink` (without `-f`) returns the correct absolute target.

Remediation for all symlink failures: `→ run: ./bootstrap.sh`

### Tool checks

Verify these binaries are on PATH via `command -v`:

| Tool | Managed by | Remediation |
|------|-----------|-------------|
| `git` | brew | `→ run: brew install git` |
| `nvim` | brew | `→ run: brew install neovim` |
| `tmux` | brew | `→ run: brew install tmux` |
| `mise` | brew | `→ run: brew install mise` |
| `node` | mise | `→ run: mise install node` |
| `go` | mise | `→ run: mise install go` |
| `bun` | mise | `→ run: mise install bun` |

## Justfile recipe

```just
# Run local health checks (symlinks, tools)
doctor:
    ./scripts/doctor.sh
```

## Testing: `tests/doctor.bats`

Unit tests using bats-core. The test file sources `scripts/doctor.sh` (thanks to the main guard) and tests each check function:

- **Symlink checks**: Create a temp directory as fake `$HOME`, set up correct/broken/missing symlinks, verify `check_symlinks` reports the right pass/fail for each case.
- **Tool checks**: Manipulate `$PATH` to include/exclude stub binaries, verify `check_tools` reports correctly.
- **Exit code**: Verify `main` returns 0 when all pass, 1 when any fail.
- **Output format**: Verify ✓/✗ prefixes and remediation text appear in output.

## Out of scope

- Environment variable checks (GIT_SIGNING_KEY, api_keys sourcing) — deferred from v1
- goss on host — goss stays Docker-only
- `--verbose` flag or other CLI options
- Auto-fix mode (doctor diagnoses, doesn't repair)
- Tmux plugin, neovim plugin, or SSH key checks (unlikely to drift)
