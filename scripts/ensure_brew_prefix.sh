#!/usr/bin/env bash
# Make sure the Homebrew prefix exists and is owned by the current user before
# `mise bootstrap packages apply` pours brew: formulae into it. On a fresh Apple
# Silicon Mac (/opt/homebrew) or for a non-root Linux user (/home/linuxbrew is
# root-owned) the prefix can't be created without sudo.
#
# Overrides (for tests): DOTFILES_BREW_PREFIX, DOTFILES_SUDO, DOTFILES_EUID.
set -euo pipefail

prefix="${DOTFILES_BREW_PREFIX:-}"
if [ -z "$prefix" ]; then
  case "$(uname -s)/$(uname -m)" in
    Darwin/arm64) prefix=/opt/homebrew ;;
    Linux/*) prefix=/home/linuxbrew/.linuxbrew ;;
    *) exit 0 ;;
  esac
fi

[ -d "$prefix" ] && exit 0

if [ "${DOTFILES_EUID:-$EUID}" -eq 0 ]; then
  mkdir -p "$prefix"
  printf 'Created Homebrew prefix %s\n' "$prefix"
  exit 0
fi

sudo_bin="${DOTFILES_SUDO:-sudo}"
"$sudo_bin" mkdir -p "$prefix"
"$sudo_bin" chown "$(id -un):$(id -gn)" "$prefix"
printf 'Created Homebrew prefix %s\n' "$prefix"
