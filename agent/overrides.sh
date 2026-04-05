#!/bin/bash

# Git identity overrides — ensure agent identity regardless of repo-level config
export GIT_AUTHOR_NAME="Agent"
export GIT_COMMITTER_NAME="Agent"
export GIT_AUTHOR_EMAIL="tribou@users.noreply.github.com"
export GIT_COMMITTER_EMAIL="tribou@users.noreply.github.com"

# Prompt — [llm] prefix on existing PS1 style (show hostname only in SSH sessions)
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  PS1="\[\033[0;34m\][llm] $HOSTNAME_SHORT:\W \$(get_git_location) > \[$(tput sgr0)\]"
else
  PS1="\[\033[0;34m\][llm] \W \$(get_git_location) > \[$(tput sgr0)\]"
fi
export PS1
