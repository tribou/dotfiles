# Set dev paths
export DEVPATH=$HOME/dev
export DOTFILES=$DEVPATH/dotfiles

# Set terminal language and UTF-8
export LANG=en_US.UTF-8

# Change bash prompt
export PS1="\[\033[0;34m\]\h:\$(nvm current):\W> \[$(tput sgr0)\]"

# Set iTerm2 badge
function set_badge()
{
  printf "\e]1337;SetBadgeFormat=%s\a"   $(printf '%q\n' "${PWD##*/}:$(git rev-parse --abbrev-ref HEAD 2> /dev/null)" | base64)
}
export PROMPT_COMMAND="$PROMPT_COMMAND set_badge ;"

# Set default editor
export EDITOR='nvim'

# Set React Native editor
export REACT_EDITOR='atom'

# Set GPG TTY and start agent
export GPG_TTY=$(tty)
if [ -S "${GPG_AGENT_INFO%%:*}" ]
then
  export GPG_AGENT_INFO
else
  eval $(gpg-agent --daemon)
fi

# Case insensitive auto-completion
bind "set completion-ignore-case on"

# Single tab shows all matching directories/files
bind "set show-all-if-ambiguous on"

# Glob includes hidden files
shopt -s dotglob

# Increase open files limit
ulimit -n 10000

# Set hostname vars
export HOSTNAME="$(hostname)"
export HOSTNAME_SHORT="${HOSTNAME%%.*}"

# History settings
export HISTSIZE=5000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignorespace
export HISTTIMEFORMAT='%F %T '
export HISTDIR="${HOME}/.history/$(date -u +%Y/%m)"
mkdir -p $HISTDIR
export HISTFILE="${HISTDIR}/$(date -u +%d.%H.%M.%S)_${HOSTNAME_SHORT}_$$"

# File replace function
## Source recursive string replace script
SOURCE_SCRIPT=$DOTFILES/scripts/replace.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source remind script
SOURCE_SCRIPT=$DOTFILES/scripts/remind.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source curlit script
SOURCE_SCRIPT=$DOTFILES/scripts/curl_it.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source init script
SOURCE_SCRIPT=$DOTFILES/scripts/init_project.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source sizes script
SOURCE_SCRIPT=$DOTFILES/scripts/sizes.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi

# Commands and Aliases
SOURCE_SCRIPT=$DOTFILES/lib/commands.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi

BREW_PREFIX=$(brew --prefix)

# Watchman shortcuts
WATCHMAN_PREFIX="$(brew --prefix watchman)"
WATCHMAN_DIR="${WATCHMAN_PREFIX}/var/run/watchman/${USER}-state"
## cat the current watchman state
alias wmans="cat ${WATCHMAN_DIR}/state"
## cat the current watchman log
alias wmanl="cat ${WATCHMAN_DIR}/log"
## set npm test trigger in current dir
alias 'watchman-npmtest'='watchman -- trigger ./ npmtest -I "*.js" "*.jsx" "*.html" "*.scss" "*.css" -X "node_modules/*" -- npm test'
alias 'watchman-npmtest-delete'='watchman trigger-del "$PWD" npmtest'

export GOPATH=$DEVPATH/go
export PATH=/usr/local/sbin:/usr/local/bin:$HOME/.fastlane/bin:$PATH:/usr/local/share/npm/bin:$GOPATH/bin
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH

# ruby rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm

# Read the .nvmrc and switch nvm versions if exists upon dir changes
function read_nvmrc()
{
  # If we actually changed directories
  if [ "$PWD" != "$PREV_PWD" ]
	then
    PREV_PWD="$PWD";

    # If there's an .nvmrc here
    if [ -e ".nvmrc" ]
		then

      # If the .nvmrc is different than the current version
      if [ "$(nvm current)" != "$(nvm version $(cat .nvmrc))" ]
      then
        nvm use
      fi
    fi
  fi
}
export PROMPT_COMMAND="$PROMPT_COMMAND read_nvmrc ;"

export PATH=/usr/local/git/bin:$PATH

#source ~/sys/ansible/hacking/env-setup
export ANSIBLE_HOSTS=$DEVPATH/sys/ansible/ansible-hosts
export ANSIBLE_CONFIG=$DEVPATH/sys/ansible/ansible.cfg

# brew install bash-completion
if [ -f "$BREW_PREFIX/etc/bash_completion" ]
then
  . "$BREW_PREFIX/etc/bash_completion"
fi

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

# AWS CLI
complete -C aws_completer aws

# z
if [ -f "$BREW_PREFIX/etc/profile.d/z.sh" ]
then
  . "$BREW_PREFIX/etc/profile.d/z.sh"
fi

# Lua/Torch
if [ -f "$DEVPATH/torch/install/bin/torch-activate" ]
then
  . "$DEVPATH/torch/install/bin/torch-activate"
fi

# import api keys
. "$HOME/.ssh/api_keys"

cd $DEVPATH

# Welcome message
remind 'Welcome.'
