#!/bin/bash

# Uncomment to debug timing
# DEBUG_BASH_PROFILE=1

OS=$(uname)

function _dotfiles_debug_timing ()
{
  if [ -n "$DEBUG_BASH_PROFILE" ]
  then
    local LAST_TIME="$DOTFILES_DEBUG_LAST_TIME"
    local LAST_TIME_NANO=$(gdate -u -d "$LAST_TIME" +"%s%N")
    local NOW=$(gdate -u +"%Y-%m-%dT%H:%M:%S.%NZ")
    local NOW_NANO=$(gdate -u -d "$NOW" +"%s%N")
    local DIFF="0"
    local MSG="$NOW $1 +$DIFF"

    if [ -n "$LAST_TIME" ]
    then
      DIFF=$(( $(($NOW_NANO - $LAST_TIME_NANO)) / $((60*60*1000)) ))
      MSG="$NOW $1 +$DIFF"
    fi

    DOTFILES_DEBUG_LAST_TIME="$NOW"
    echo "$MSG"
  fi
}

# Set dev paths
export DEVPATH=$HOME/dev
export DOTFILES=$DEVPATH/dotfiles

# Reset debug timing
_dotfiles_debug_timing "$LINENO"

# import api keys and local workstation-related scripts
[ -s "$HOME/.ssh/api_keys" ] && . "$HOME/.ssh/api_keys"

# Set terminal language and UTF-8
export LANG=en_US.UTF-8

function get_git_location()
{
  # git worktrees use .git files instead of directories
  if [ -d "./.git" ] || [ -f "./.git" ]
  then
    local BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]
    then
      echo "$BRANCH"
    else
      # If no current branch name, use the current short commit sha
      git rev-parse --short HEAD 2> /dev/null || echo "$HOSTNAME_SHORT"
    fi
  else
    echo "$HOSTNAME_SHORT"
  fi
}


# Set default editor
export EDITOR='nvim'

# Set React Native editor
export REACT_EDITOR='vscode'

_dotfiles_debug_timing "$LINENO"

# Set GPG TTY and start agent
export GPG_TTY=$(tty)
if [ -S "${GPG_AGENT_INFO%%:*}" ]
then
  export GPG_AGENT_INFO
else
  eval $(gpg-agent --daemon 2>/dev/null)
fi

# Case insensitive auto-completion
bind "set completion-ignore-case on"

# Single tab shows all matching directories/files
bind "set show-all-if-ambiguous on"

# Glob includes hidden files
shopt -s dotglob

# Increase open files limit
[ "$OS" == "Darwin" ] && ulimit -n 10000

# Set hostname vars
export HOSTNAME="$(hostname)"
export HOSTNAME_SHORT="${HOSTNAME%%.*}"

# History settings
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignorespace
export HISTTIMEFORMAT='%F %T '
export HISTDIR="${HOME}/.history/$(date -u +%Y/%m)"
mkdir -p $HISTDIR
export HISTFILE="${HISTDIR}/$(date -u +%d.%H.%M.%S)_${HOSTNAME_SHORT}_$$"

_dotfiles_debug_timing "$LINENO"

# Source all lib scripts
. "$DOTFILES/lib/index.sh"


_dotfiles_debug_timing "$LINENO"


[ -s "$(which brew >/dev/null 2>&1)" ] && BREW_PREFIX=$(brew --prefix)


export GOPATH=$DEVPATH/go
export PATH=/usr/local/sbin:/usr/local/bin:$HOME/.fastlane/bin:$PATH:/usr/local/share/npm/bin:$GOPATH/bin:$DEVPATH/bin
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH

# fzf
[ -d "$HOME/.fzf/bin" ] && export PATH=$PATH:$HOME/.fzf/bin

# c9
[ -d "/opt/c9/local/bin" ] && export PATH=$PATH:/opt/c9/local/bin

# ruby rbenv
[ -f "$HOME/.rbenv/bin/rbenv" ] && export PATH=$PATH:$HOME/.rbenv/bin
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

_dotfiles_debug_timing "$LINENO"

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm
_dotfiles_debug_timing "$LINENO"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
_dotfiles_debug_timing "$LINENO"
export HAS_NVM=$([ -n "$(type nvm 2> /dev/null)" ] && echo true)
# _dotfiles_debug_timing "$LINENO"
# [ -n "$HAS_NVM" ] && nvm use --delete-prefix default --silent

_dotfiles_debug_timing "$LINENO"

# Change bash prompt
export PS1="\[\033[0;34m\]\W \$([ -n "$HAS_NVM" ] && nvm current) \$(get_git_location) > \[$(tput sgr0)\]"


# AWS CLI
complete -C aws_completer aws

_dotfiles_debug_timing "$LINENO"

# ansible scripts
if [ -s "$HOME/sys/ansible/hacking/env-setup" ]
then
  . "$HOME/sys/ansible/hacking/env-setup"
fi
if [ -s "$DEVPATH/sys/ansible/ansible-hosts" ]
then
  export ANSIBLE_HOSTS="$DEVPATH/sys/ansible/ansible-hosts"
fi
if [ -s "$DEVPATH/sys/ansible/ansible.cfg" ]
then
  export ANSIBLE_CONFIG="$DEVPATH/sys/ansible/ansible.cfg"
fi

# bat
export BAT_THEME=TwoDark

_dotfiles_debug_timing "$LINENO"

# brew install bash-completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
[[ -r "/etc/profile.d/bash_completion.sh" ]] && . "/etc/profile.d/bash_completion.sh"

_dotfiles_debug_timing "$LINENO"

# composer
export PATH="$HOME/.composer/vendor/bin:$PATH"

# gcloud sourcing
OLD_GCLOUD_PATH=/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk
NEW_GCLOUD_PATH=/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk
if [ -d "$OLD_GCLOUD_PATH" ]
then
  . "$OLD_GCLOUD_PATH/path.bash.inc"
  . "$OLD_GCLOUD_PATH/completion.bash.inc"
fi
if [ -d "$NEW_GCLOUD_PATH" ]
then
  . "$NEW_GCLOUD_PATH/path.bash.inc"
  . "$NEW_GCLOUD_PATH/completion.bash.inc"
fi

_dotfiles_debug_timing "$LINENO"

# fasd
[ $(which fasd) ] && eval "$(fasd --init bash-hook)"

# git
export PATH=/usr/local/git/bin:$PATH

_dotfiles_debug_timing "$LINENO"


# Lua/Torch
if [ -s "$DEVPATH/torch/install/bin/torch-activate" ]
then
  . "$DEVPATH/torch/install/bin/torch-activate"
fi

_dotfiles_debug_timing "$LINENO"

# Marker
[[ -s "$HOME/.local/share/marker/marker.sh" ]] && source "$HOME/.local/share/marker/marker.sh"

_dotfiles_debug_timing "$LINENO"

# pyenv
[ -f "$HOME/.pyenv/bin/pyenv" ] && export PATH=$PATH:$HOME/.pyenv/bin
if [ $(which pyenv) ]
then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

_dotfiles_debug_timing "$LINENO"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ripgrep
export RIPGREP_CONFIG_PATH="$DOTFILES/ripgreprc"

# yarn
[ -d "$HOME/.yarn/bin" ] && export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

_dotfiles_debug_timing "$LINENO"

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/aaron.tribou/.sdkman"
[[ -s "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh"

_dotfiles_debug_timing "$LINENO"

# set git signing key if GIT_SIGNING_KEY is set and config doesn't exist
if [ -n "$GIT_SIGNING_KEY" ] && [[ ! $(git config --global --get user.signingkey) ]]
then
  git config --global user.signingkey ${GIT_SIGNING_KEY}
fi

_dotfiles_debug_timing "$LINENO"


## Setup PROMPT_COMMAND
# Activate a version of Node that is read from a text file via NVM
function use_node_version()
{
  local TEXT_FILE_NAME="$1"
  local CURRENT_VERSION=$([ -n "$HAS_NVM" ] && nvm current)
  local PROJECT_VERSION=$([ -n "$HAS_NVM" ] && nvm version $(cat "$TEXT_FILE_NAME"))
  # If the project file version is different than the current version
  if [ "$CURRENT_VERSION" != "$PROJECT_VERSION" ]
  then
    [ -n "$HAS_NVM" ] && nvm use "$PROJECT_VERSION"
  fi
}

# Read the .nvmrc and switch nvm versions if exists upon dir changes
function read_node_version()
{
  # Only run if we actually changed directories
  if [ "$PWD" != "$READ_NODE_VERSION_PREV_PWD" ]
	then
    export READ_NODE_VERSION_PREV_PWD="$PWD";

    # If there's an .nvmrc here
    if [ -e ".nvmrc" ]
		then
      use_node_version ".nvmrc"
      return
    fi

    # If there's a .node-version here
    if [ -e ".node-version" ]
		then
      use_node_version ".node-version"
      return
    fi
  fi
}
[[ $PROMPT_COMMAND != *"read_node_version"* ]] && export PROMPT_COMMAND="$PROMPT_COMMAND read_node_version ;"

# Set iTerm2 badge
function set_badge()
{
  printf "\e]1337;SetBadgeFormat=%s\a"   $(printf '%q\n' "${PWD##*/}:$(get_git_location)" | base64)
}
[ "$TERM_PROGRAM" == "iTerm.app" ] && [[ $PROMPT_COMMAND != *"set_badge"* ]] && export PROMPT_COMMAND="$PROMPT_COMMAND set_badge ;"


# Cleanup debug timing
unset DOTFILES_DEBUG_LAST_TIME
unset DEBUG_BASH_PROFILE

if [ -d "$STARTPATH" ]
then
  cd "$STARTPATH"
elif [ "$PWD" == "$HOME" ]
then
  cd "$DEVPATH"
fi

# Welcome message
remind 'Welcome. 👋'
