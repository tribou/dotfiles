# PATH Deduplication and Homebrew Precedence

## Problem

`brew shellenv` correctly prepends `/opt/homebrew/bin` early in `bash_profile`, but
subsequent `export PATH=...` statements (mise, composer, amplify, yarn, etc.) each
prepend additional paths in front, burying homebrew paths after `/bin`. This prevents
homebrew-installed tools like `bash` from taking precedence over system equivalents.

Additionally, many PATH entries appear two or three times in the final `$PATH` due to
repeated sourcing patterns.

## Design

### New file: `lib/path.sh`

Two helper functions, auto-sourced by the existing `lib/index.sh` glob:

**`_path_strip <pattern...>`** — removes PATH entries matching any of the given glob
patterns. Used to strip stale homebrew/linuxbrew entries before re-adding them cleanly.

**`_path_dedup`** — removes duplicate PATH entries, preserving first-occurrence order.

### Changes to `bash_profile`

1. **Keep** the early `brew shellenv` block (macOS + linuxbrew) unchanged. This ensures
   `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR`, and related env vars are available throughout
   the file, and `brew` is in PATH during `lib/index.sh` sourcing.

2. **After** `. "$DOTFILES/lib/index.sh"` (which auto-sources `lib/path.sh`), add a
   cleanup block:
   - Strip all homebrew/linuxbrew paths accumulated during profile load
   - Deduplicate all remaining PATH entries
   - Re-run `brew shellenv` to prepend clean homebrew paths at the front

## Outcome

- `/opt/homebrew/bin` (macOS) or `/home/linuxbrew/.linuxbrew/bin` (Linux) appears first
  in the final `$PATH`, before `/bin`
- No duplicate PATH entries
- Homebrew env vars (`HOMEBREW_PREFIX` etc.) still available throughout the file
- `_path_strip` and `_path_dedup` available as interactive shell utilities

## Call Site

```bash
# Deduplicate PATH and ensure homebrew takes precedence
_path_strip "*homebrew*" "*linuxbrew*"
_path_dedup
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```
