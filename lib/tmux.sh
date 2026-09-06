#!/bin/bash
# Create the main dev layout for large monitors
function tmux-large ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 75% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -l 35% -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -h -l 40% -c "$_SECONDARY"
  tmux select-pane -t 3
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter
  tmux send-keys -t 2 f Enter
  tmux send-keys -t 3 v Enter
  [ "$_PRIMARY" != "$_SECONDARY" ] && tmux send-keys -t 4 f Enter
}

# Create the main dev layout for extra large monitors
function tmux-xl ()
{
  tmux-large "$@"
  tmux select-pane -t 3
  tmux split-window -v -l 20% -c '#{pane_current_path}'
  tmux select-pane -t 3
}

# Create the main dev layout for small monitors
function tmux-small ()
{
  [ -z "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 50% -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux split-window -v -b -l 75% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  # tmux send-keys -t 2 v Enter
  tmux send-keys -t 3
}

# Create a crossover for small and large monitors
function tmux-small-2 ()
{
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux-small "$@"
  tmux select-pane -t 3
  tmux split-window -v -l 25% -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux send-keys -t 4 f Enter
}

# Create another crossover for small and large monitors
function tmux-small-3 ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 55% -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux split-window -v -l 75% -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -v -l 75% -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2 # PRIMARY
  tmux send-keys -t 3 f Enter # SECONDARY
  tmux send-keys -t 4 v Enter # PRIMARY
}

function tmux-small-half ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux split-window -h -l 55% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -l 50% -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2
  tmux send-keys -t 3 v Enter
}
alias tm-large='tmux-large'
alias tm-main='tmux-small-3'
alias tm-small-half='tmux-small-half'
alias tm-small='tmux-small'
alias tm-xl='tmux-xl'
alias tma='tmux -u new -A -s main'
alias tmm='tm-main'
alias tms='tmux-small'
