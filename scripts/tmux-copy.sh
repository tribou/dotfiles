#!/usr/bin/env bash
# Mirror the most-recently-set tmux paste buffer into the system clipboard.
# Used by the right-click menu Copy items in tmux/tmux-right-click-menu.conf so
# that Copy lands in the same system clipboard scripts/tmux-paste.sh reads from.
#
# tmux's set-buffer only writes tmux's internal buffer; reaching the system
# clipboard otherwise depends on OSC 52 (set-clipboard on), which is terminal-
# dependent and unreliable (notably on macOS). Writing pbcopy/xclip directly
# keeps Copy and Paste on the same clipboard.

set -euo pipefail

buf=$(tmux show-buffer 2>/dev/null) || buf=""

if command -v pbcopy >/dev/null 2>&1
then
  printf '%s' "$buf" | pbcopy
elif command -v xclip >/dev/null 2>&1
then
  printf '%s' "$buf" | xclip -selection clipboard
fi
