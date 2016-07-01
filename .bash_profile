# Set dev path
export DEVPATH=$HOME/dev

# Change bash prompt
export PS1="\[\033[0;34m\]\h:\$(nvm current):\W> \[$(tput sgr0)\]"

# Set iTerm2 badge
set_badge()
{
  printf "\e]1337;SetBadgeFormat=%s\a"   $((git branch 2> /dev/null) | grep \* | cut -c3- | base64)
}
export PROMPT_COMMAND="$PROMPT_COMMAND set_badge ;"

# Set default editor
export EDITOR='vim'

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

# File search and replace functions
## Source recursive string replace script
SOURCE_SCRIPT=$DEVPATH/dotfiles/scripts/replace.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source remind script
SOURCE_SCRIPT=$DEVPATH/dotfiles/scripts/remind.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi
## Source curlit script
SOURCE_SCRIPT=$DEVPATH/dotfiles/scripts/curl_it.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi

# Commands and Aliases
SOURCE_SCRIPT=$DEVPATH/dotfiles/lib/commands.sh
if [ -f "$SOURCE_SCRIPT" ]
then
  . "$SOURCE_SCRIPT"
fi

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

# docker-machine
## get local running machine name
DM_LS=`docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"`
## source dmupdate script
if [ -f $DEVPATH/dotfiles/scripts/dm_update_ip.sh ]
then
  . $DEVPATH/dotfiles/scripts/dm_update_ip.sh
fi
## If the local docker-machine is available
if ! [[ -z "$DM_LS"  ]]
then 
  ## first init docker-vm
  dminit
  ## run dmupdate
  dmupdate
fi

# Less Colors for Man Pages
#export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
#export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
#export LESS_TERMCAP_me=$'\E[0m'           # end mode
#export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
#export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
#export LESS_TERMCAP_ue=$'\E[0m'           # end underline
#export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

export GOPATH=$DEVPATH/go
export PATH=/usr/local/sbin:/usr/local/bin:$PATH:/usr/local/share/npm/bin:$GOPATH/bin
export ANDROID_HOME=/usr/local/opt/android-sdk

# ruby rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm
# Read the .nvmrc and switch nvm versions if exists upon dir changes
read_nvmrc()
{
  if [ "$PWD" != "$PREV_PWD" ]
	then
    PREV_PWD="$PWD";

    if [ -e ".nvmrc" ]
		then
      nvm use;
    fi
  fi
}
export PROMPT_COMMAND="$PROMPT_COMMAND read_nvmrc ;"

export PATH=/usr/local/git/bin:$PATH

#source ~/sys/ansible/hacking/env-setup
export ANSIBLE_HOSTS=$DEVPATH/sys/ansible/ansible-hosts
export ANSIBLE_CONFIG=$DEVPATH/sys/ansible/ansible.cfg

# brew install bash-completion
if [ -f $(brew --prefix)/etc/bash_completion ]
then
  . $(brew --prefix)/etc/bash_completion
fi

# gcloud sourcing
. '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
. '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

# AWS CLI
complete -C aws_completer aws

# z
if [ -f `brew --prefix`/etc/profile.d/z.sh ]
then
  . `brew --prefix`/etc/profile.d/z.sh
fi

# import api keys
. "$HOME/.ssh/api_keys"

cd $DEVPATH

# Clear and write aliases
echo 'Welcome.'
echo ''
