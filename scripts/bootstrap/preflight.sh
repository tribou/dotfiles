#!/usr/bin/env bash
# Checks bootstrap.sh makes before it installs anything. Only macOS has any.
#
# Usage: preflight.sh BREW_PREFIX DRY_RUN(0|1)
set -euo pipefail

brew_prefix="$1"
dry_run="$2"

[ "$(uname -s)" = Darwin ] || exit 0

if [ "$(uname -m)" != arm64 ]; then
  echo "bootstrap.sh: Intel macOS is not supported (mise-config.toml only declares macos/arm64 packages)." >&2
  exit 1
fi

# mise creates the Homebrew prefix with sudo. sudo prompts on the terminal;
# nothing here stores, pipes or caches the password.
if [ "$dry_run" = 0 ] && [ ! -d "$brew_prefix" ]; then
  echo "bootstrap.sh: mise will ask for your password once (sudo) to create $brew_prefix."
fi
