#!/usr/bin/env bash
# One-time migration: remove Homebrew copies of tools that mise now owns, so
# they cannot shadow the mise versions on PATH. Runs from the bootstrap task.
#
# Lists installed formulae once, and only when something on the list is still
# installed does it verify the mise replacements (stopping if they are broken)
# before uninstalling. An uninstall failure warns but does not fail. It removes
# only the listed formulae, honoring dependents: formulae installed outside this
# repo stay untouched.
#
# Overrides (for tests): DOTFILES_BREW_BIN, DOTFILES_VERIFY_MISE.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
verify="${DOTFILES_VERIFY_MISE:-$repo/scripts/verify_mise_tools.sh}"

# Keep this migration list local; it is not desired-state inventory.
legacy=(neovim python jq fd ripgrep bat shellcheck lazydocker lazygit just
  tree-sitter-cli fzf git-delta gh glow zoxide tmux)

brew_bin="${DOTFILES_BREW_BIN:-}"
if [ -z "$brew_bin" ]; then
  for candidate in "$(command -v brew 2>/dev/null || true)" /opt/homebrew/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      brew_bin="$candidate"
      break
    fi
  done
fi
[ -n "$brew_bin" ] && [ -x "$brew_bin" ] || exit 0

installed="$("$brew_bin" list --formula -1 2>/dev/null || true)"
targets=()
for formula in "${legacy[@]}"; do
  grep -qxF "$formula" <<< "$installed" && targets+=("$formula")
done
# `brew list -1` prints the versioned python@3.x the `python` alias resolves to.
while IFS= read -r formula; do
  [ -n "$formula" ] && targets+=("$formula")
done < <(grep -E '^python@3' <<< "$installed" || true)
[ "${#targets[@]}" -gt 0 ] || exit 0

if ! MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}" "$verify" >/dev/null; then
  echo "error: mise replacements failed verification; not removing Homebrew ${targets[*]}" >&2
  exit 1
fi

failures=()
for formula in "${targets[@]}"; do
  if err="$("$brew_bin" uninstall --formula "$formula" 2>&1 >/dev/null)"; then
    echo "changed: removed legacy Homebrew $formula"
  else
    failures+=("- $formula: ${err:-unknown error}")
  fi
done

if [ "${#failures[@]}" -gt 0 ]; then
  echo "WARNING: Homebrew cleanup could not remove these legacy formulae:"
  printf '%s\n' "${failures[@]}"
fi
