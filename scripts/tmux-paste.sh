#!/usr/bin/env bash
# Paste the system clipboard into the current tmux pane.
# Used by the MouseDown3Pane binding in tmux/tmux-conf.
#
# Over SSH, tmux-conf does not install the custom MouseDown3Pane binding;
# the terminal/SSH client's native right-click paste already sends the local
# clipboard, and remote hosts usually lack pbpaste/xclip anyway.

set -euo pipefail

_copy_mode=0
if [ "${1:-}" = "--copy-mode" ]
then
  _copy_mode=1
fi

X=""
if command -v pbpaste >/dev/null 2>&1
then
  X=$(pbpaste) || X=""
elif command -v xclip >/dev/null 2>&1
then
  X=$(xclip -o -sel clipboard) || X=""
fi

tmux set-buffer "$X"
tmux paste-buffer -p
tmux display-message 'pasted!'

if [ "$_copy_mode" -eq 1 ]
then
  tmux send -X cancel
fi
