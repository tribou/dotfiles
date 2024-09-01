#!/bin/bash

# Helper functions
function _dotfiles_full_path () {
  _z -e "$1"
}

function _dotfiles_git_status () {
  git status -sb
}

function _dotfiles_grep_ticket_number () {
  local a b c d e f
  # Remove origin/, feature/, etc prefix
  a=$(sed -E 's/^(bug|feature|fix|hotfix|origin|patch)\///')
  # echo "a: $a" >&2
    # For AB-123/description pattern, remove the description tail
    b=$(echo "$a" | sed -E 's/^(.*)\/.*$/\1/')
    # echo "b: $b" >&2
    # For ab123-this-thing pattern, remove the description tail
    c=$(echo "$b" | sed -E 's/^([a-zA-Z]{2}[0-9]{1,7})\-.*$/\1/')
    # echo "c: $c" >&2
    # For abc-123-this-thing pattern, remove the description tail
    d=$(echo "$c" | sed -E 's/^([a-zA-Z0-9]{2,5}-[0-9]{1,7})\-.*$/\1/')
    # echo "d: $d" >&2
    # DCX - For 123_AT_ThisThing pattern, remove the initials and description tail
    e=$(echo "$d" | sed -E 's/^([0-9]{1,7})\_.*$/DCX\1/')
    # echo "e: $e" >&2
    # Filter out anything other than ab123 or abc-123 or DCX123
    if [[ "$OSTYPE" == "darwin"* ]]; then
      f=$(echo "$e" | grep -E '^([a-zA-Z]{2}[0-9]{1,7}|[a-zA-Z0-9]{2,5}\-)\d{1,7}|DCX[0-9]{1,7}$')
    else
      f=$(echo "$e" | grep -P '^([a-zA-Z]{2}[0-9]{1,7}|[a-zA-Z0-9]{2,5}\-)\d{1,7}|DCX[0-9]{1,7}$')
    fi
    # echo "f: $f" >&2
    # Convert all letters to UPPERCASE
    echo "$f" | tr '[:lower:]' '[:upper:]'
}

function _dotfiles_commit_message () {
  local current_ticket=${1}
  local commit_msg_separator="${DOTFILES_COMMIT_SEPARATOR:-:}"
  local message="${*:2}"
  if [ $# -lt 2 ]
  then
    if [ -n "$current_ticket" ]
    then
      local message="$current_ticket${commit_msg_separator} "
    fi
  else
    if [ -z "$current_ticket" ]
    then
      local message="${*:2}"
    else
      local message="$current_ticket${commit_msg_separator} ${*:2}"
    fi
  fi
  echo "$message"
}

function _dotfiles_git_log_branch_diff () {
  local PARENT_BRANCH=${1:-$INTEGRATION_BRANCH}
  local CHILD_BRANCH=${2:-$(git branch --show-current)}
  echo
  echo "Parent branch: ${PARENT_BRANCH}"
  _eval_script "git tree-one $(git merge-base $PARENT_BRANCH HEAD)..$CHILD_BRANCH"
}

function _dotfiles_git_log_commit () {
  git log --pretty=fuller --show-signature -1
}

function _dotfiles_primary_full_path () {
  if [ -n "$1" ]
  then
    local _PRIMARY
    _PRIMARY=$(_dotfiles_full_path "$1")
  elif [ -n "$PRIMARY_REPO" ]
  then
    local _PRIMARY
    _PRIMARY=$(_dotfiles_full_path "$PRIMARY_REPO")
  else
    local _PRIMARY="$PWD"
  fi

  echo "$_PRIMARY"
}

function _dotfiles_secondary_full_path () {
  if [ -n "$1" ]
  then
    local _SECONDARY
    _SECONDARY=$(_dotfiles_full_path "$1")
  elif [ -n "$SECONDARY_REPO" ]
  then
    local _SECONDARY
    _SECONDARY=$(_dotfiles_full_path "$SECONDARY_REPO")
  else
    local _SECONDARY="$PWD"
  fi

  echo "$_SECONDARY"
}

# If in tmux, run the command from the prompt to put it in the command history.
# Otherwise, just eval
function _eval_script() {
  local SCRIPT="$1"

  if [ -n "$TMUX" ]; then
    tmux send-keys -t "$TMUX_PANE" "$SCRIPT" Enter;
  else
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  fi
}

# Parse local npm modules using jq and npm ls
function _parse_local_npm_modules () {
  local _MODULES
  _MODULES=$(npm ls --json --depth=0 | jq -r '.dependencies | keys | .[]')
  echo "$_MODULES"
}
