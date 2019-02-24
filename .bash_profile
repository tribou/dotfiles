# Set dev paths
export DEVPATH=$HOME/dev
export DOTFILES=$DEVPATH/dotfiles

# import api keys and local workstation-related scripts
if [ -f "$HOME/.ssh/api_keys" ]
then
  . "$HOME/.ssh/api_keys"
fi

# Set terminal language and UTF-8
export LANG=en_US.UTF-8

# Change bash prompt
export PS1="\[\033[0;34m\]\h:\$(nvm current):\W> \[$(tput sgr0)\]"

# Set iTerm2 badge
function set_badge()
{
  printf "\e]1337;SetBadgeFormat=%s\a"   $(printf '%q\n' "${PWD##*/}:$(git rev-parse --abbrev-ref HEAD 2> /dev/null)" | base64)
}
[[ $PROMPT_COMMAND != *"set_badge"* ]] && export PROMPT_COMMAND="$PROMPT_COMMAND set_badge ;"

# Set default editor
export EDITOR='nvim'

# Set React Native editor
export REACT_EDITOR='vscode'

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
ulimit -n 10000

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


# Source all lib scripts
. "$DOTFILES/lib/index.sh"


BREW_PREFIX=$(brew --prefix)


export GOPATH=$DEVPATH/go
export PATH=/usr/local/sbin:/usr/local/bin:$HOME/.fastlane/bin:$PATH:/usr/local/share/npm/bin:$GOPATH/bin:$DEVPATH/bin
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH

# ruby rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm
nvm use --delete-prefix default --silent

# Activate a version of Node that is read from a text file via NVM
function use_node_version()
{
  local TEXT_FILE_NAME="$1"
  local CURRENT_VERSION=$(nvm current)
  local PROJECT_VERSION=$(nvm version $(cat "$TEXT_FILE_NAME"))
  # If the project file version is different than the current version
  if [ "$CURRENT_VERSION" != "$PROJECT_VERSION" ]
  then
    nvm use "$PROJECT_VERSION"
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

    # If there's a .node_version here
    if [ -e ".node_version" ]
		then
      use_node_version ".node_version"
      return
    fi
  fi
}
[[ $PROMPT_COMMAND != *"read_node_version"* ]] && export PROMPT_COMMAND="$PROMPT_COMMAND read_node_version ;"

export PATH=/usr/local/git/bin:$PATH

# ansible scripts
if [ -f "$HOME/sys/ansible/hacking/env-setup" ]
then
  . "$HOME/sys/ansible/hacking/env-setup"
fi
if [ -f "$DEVPATH/sys/ansible/ansible-hosts" ]
then
  export ANSIBLE_HOSTS="$DEVPATH/sys/ansible/ansible-hosts"
fi
if [ -f "$DEVPATH/sys/ansible/ansible.cfg" ]
then
  export ANSIBLE_CONFIG="$DEVPATH/sys/ansible/ansible.cfg"
fi

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

# Rust
export PATH="$HOME/.cargo/bin:$PATH"
if [ -f "$HOME/.cargo/env" ]
then
  . "$HOME/.cargo/env"
fi

# ripgrep
export RIPGREP_CONFIG_PATH="$DOTFILES/.ripgreprc"

# set git signing key if GIT_SIGNING_KEY is set and config doesn't exist
if [ -n "$GIT_SIGNING_KEY" ] && git config --global --get user.signingkey > /dev/null;
then
  git config --global user.signingkey ${GIT_SIGNING_KEY}
fi

cd $DEVPATH

# Welcome message
remind 'Welcome. 👋'
