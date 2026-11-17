#!/bin/bash
# Upgrade any dependency or devDependency in package.json with the project's
# package manager
function nu () {
  [ ! -f "package.json" ] && echo "No package.json to upgrade" && return 1
  local UPGRADE_CMD
  UPGRADE_CMD="$(_dotfiles_npm_detect_exec)"
  if [ "$UPGRADE_CMD" = "yarn" ]; then
    UPGRADE_CMD="yarn upgrade"
  else
    UPGRADE_CMD="$UPGRADE_CMD update"
  fi
  if [ -n "$1" ]
  then
    local SCRIPT="$UPGRADE_CMD $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(_parse_local_npm_modules | fzf)
    if [ -n "$RESULT" ]
    then
      local SCRIPT="$UPGRADE_CMD $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}
# Detect which package manager to use based on lock files in the current directory.
# Outputs: pnpm | yarn | bun | npm
function _dotfiles_npm_detect_exec ()
{
  if [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "bun.lock" ] || [ -f "bun.lockb" ]; then
    echo "bun"
  else
    echo "npm"
  fi
}
function npm-install ()
{
  local EXEC
  EXEC="$(_dotfiles_npm_detect_exec)"
  if [ -n "$1" ]
  then
    local SCRIPT="$EXEC install $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local SCRIPT="$EXEC install"
    _eval_script "$SCRIPT"
  fi
}
function y ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="yarn $*" && echo "$SCRIPT" && echo && eval "$SCRIPT"
  else
    local SCRIPT="npm-install"
    eval "$SCRIPT"
  fi
}
function npm-run ()
{
  local EXEC
  EXEC="$(_dotfiles_npm_detect_exec)"
  # bun uses 'bun run --silent', others use their own format
  if [ "$EXEC" = "bun" ]; then
    EXEC="bun run --silent"
  elif [ "$EXEC" = "npm" ]; then
    EXEC="npm run --silent"
  fi
  if [ -n "$1" ]
  then
    local SCRIPT="$EXEC $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(jq '.scripts' package.json | grep -E '[a-zA-Z0-9]' | fzf --tiebreak=chunk | awk -F'"' '{print $2}')
    if [ -n "$RESULT" ]
    then
      local SCRIPT="$EXEC $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}
function ninfo ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="npm info $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(_parse_local_npm_modules | fzf)
    if [ -n "$RESULT" ]
    then
      local SCRIPT="npm info $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}
function useLocalIfAvailable ()
{
  # Use local node module if available
  if [ -f "$(which ./node_modules/.bin/"${1}")" ]
  then
    "./node_modules/.bin/$1" "${@:2}"

  # Then check for existing global install
  elif [ -f "$(which "${1}")" ]
  then
    "$@"

  # Otherwise, use npx
  else
    npx "$@"
  fi
}
alias j='TZ=UTC yarn jest --watch'
alias ni='npm-install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nr='npm-run'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
alias ntsc='npx tsc --noemit --watch --pretty'
alias webpack-bundle-analyzer='npx webpack-bundle-analyzer'
alias webpack='useLocalIfAvailable webpack'
alias yi='npm-install'
alias yr='npm-run'
alias ytsc='yarn tsc --noemit --watch --pretty'
alias yw='yarn workspaces'

alias devtools='react-devtools'
alias eslint='npx eslint'
alias npm-check-updates='npx npm-check-updates'
alias react-native='npx react-native'
alias rn='react-native'
alias serverless='npx serverless'
alias sst='npx sst'
alias storybook='npx @storybook/cli'
alias yu='nu'
