#!/bin/bash
function npm-install-global ()
{
  echo "Installing global modules"
  npm install -g \
    eas-cli \
    eslint_d \
    editorconfig \
    intelephense \
    js-yaml \
    jsonlint \
    neovim \
    prettier \
    react-devtools \
    nodemon \
    tern \
    tslint \
    typescript \
    bash-language-server \
    flow-bin \
    vue-language-server \
    vscode-css-languageserver-bin \
    vscode-html-languageserver-bin
  corepack enable
}
# npm up or yarn upgrade any dependency or devDependency in package.json
function nu () {
  [ ! -f "package.json" ] && echo "No package.json to upgrade" && return 1
  local UPGRADE_CMD="npm update"
  [ -f "yarn.lock" ] && UPGRADE_CMD="yarn upgrade"
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
  elif [ -f "bun.lock" ]; then
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
    "./node_modules/.bin/$*"

  # Then check for existing global install
  elif [ -f "$(which "${1}")" ]
  then
    "$@"

  # Otherwise, use npx
  else
    npx "$*"
  fi
}
alias edld='ember deploy:list --environment development'
alias edlp='ember deploy:list --environment production'
alias edls='ember deploy:list --environment staging'
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

alias app-icon='npx app-icon'
alias babel-eslint='npx babel-eslint'
alias devtools='react-devtools'
alias ember='npx ember-cli'
alias eslint='npx eslint'
alias flow-typed='npx flow-typed'
alias flow='npx flow'
alias gatsby='npx gatsby'
alias nodemon='nodemon'
alias npm-check-updates='npx npm-check-updates'
alias nsp='npx nsp'
alias react-devtools='react-devtools'
alias react-native='npx react-native'
alias rn='react-native'
alias serverless='npx serverless'
alias sst='npx sst'
alias storybook='npx @storybook/cli'
alias yu='nu'
