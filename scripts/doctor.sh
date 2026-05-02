#!/usr/bin/env bash
set -euo pipefail

# Script directory and DOTFILES root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Output helpers ---
pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s → %s\n' "$1" "$2"; }

# --- Main ---
main() {
    echo "doctor: starting checks"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
