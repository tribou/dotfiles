# Set dev path
export DEVPATH=$HOME/dev

# Change bash prompt
export PS1="\[\033[0;34m\]\h:\$(nvm current):\W> \[$(tput sgr0)\]"

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
histgrep ()
{
  grep -r "$1" ~/.history
  history | grep "$1"
}

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

# Aliases
alias ls='ls -G'
alias ll='ls -lah'
alias lt='ls -lath'
alias survey='sudo nmap -sP 10.0.1.1/24'
alias s='git status -sb'
alias ga='git add --all'
alias c='git commit -ev'
alias co='git checkout'
alias gps='git push'
alias gpl='git pull'
#alias t='git log --graph --decorate --oneline --relative-date'
#alias t='git log --graph --abbrev-commit --date=local --date=short --pretty=format:"%C(yellow)%h %C(cyan)%cd%C(green)%d %Creset%s %C(blue)<%aN>"'
alias t='echo; echo; git tree'
alias f='git fetch'
alias b='git branch -a'
alias gbd='git branch -d'
alias gbdr='git branch -d -r'
alias gr2='git rebase -i head~2'
alias gall='echo; echo; git log --oneline --all --graph --decorate  $(git reflog | awk '"'"'{print $1}'"'"')'
alias top='top -o cpu'
alias r='git remote -v'
alias tree='tree -I "bower_components|node_modules|temp|tmp"'
alias search='echo; echo; git grep -n -I --untracked --break'
alias count='sed "/^\s*$/d" | wc -l | xargs'
alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
alias convert-tabs-spaces="replace '	' '  '"
alias setdotglob='shopt -s dotglob'
alias unsetdotglob='shopt -u dotglob'
alias sprofile='. ~/.bash_profile; cd $OLDPWD'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
sizes ()
{
  ls -lrt -d -1 ${PWD}/${1}* | xargs du -sh
}
gr ()
{

  usage='Usage: gr NUMBER'
  search_dir='.'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -ne 1 ]
  then
    echo "$usage"
    return 1
  fi

  git rebase -i head~$1
}

# Vim
alias vim='mvim -v'
alias v='vim'
alias vc='vimcat'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer'

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

# Digital Ocean shortcuts
function digitalocean() { curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN" "https://api.digitalocean.com/v2/$1?page=1&per_page=1000" | python -m json.tool ;}

# Docker shortcuts
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'
alias dc='docker-compose'

# docker-machine shortcuts
## get local running machine name
DM_LS=`docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"`
## add aliases
alias bd='docker-machine'
alias dm='docker-machine'
alias dminit='eval "$(docker-machine env $(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"))"'
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

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm
alias ni='npm install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nr='npm run'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
npm-install-global()
{
  # Crazy logic bc npm dist-tags aren't standardized
  if [ "$1" == "2" ]
  then
    NPM_VERSION='latest-2'
  elif [ "$1" == "3" ]
  then
    NPM_VERSION='3.x-latest'
  else
    NPM_VERSION='latest'
  fi

  echo "Installing NPM@$NPM_VERSION and global modules"
  npm install -g npm@$NPM_VERSION \
    && npm install -g \
    babel-node-debug \
    bower \
    ember-cli@^1 \
    eslint \
    eslint_d \
    flow-bin \
    instant-markdown-d \
    newman \
    node-inspector \
    nodemon \
    nsp \
    react-native-cli \
    serverless \
    slush
}
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

# Ember.js
alias edld='ember deploy:list --environment development'
alias edlp='ember deploy:list --environment production'
alias edls='ember deploy:list --environment staging'

export PATH=/usr/local/git/bin:$PATH

#source ~/sys/ansible/hacking/env-setup
export ANSIBLE_HOSTS=$DEVPATH/sys/ansible/ansible-hosts
export ANSIBLE_CONFIG=$DEVPATH/sys/ansible/ansible.cfg
install-swap()
{

  usage='Usage: install-swap HOST'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -ne 1 ]
  then
    echo "$usage"
    return 1
  fi

  ansible-playbook $DEVPATH/ansible-swap/site.yml --extra-vars "target=$1"

}

# brew install bash-completion
if [ -f $(brew --prefix)/etc/bash_completion ]
then
  . $(brew --prefix)/etc/bash_completion
fi

# gcloud sourcing
. '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
. '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'
alias gc='gcloud compute'
alias gci='gcloud compute instances'

# kubernetes aliases
alias kg='kubectl get pods,rc,svc -o wide'
alias kd='kubectl describe'

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
echo 'alias: digitalocean droplets   - list all do droplets'
echo 'alias: digitalocean regions    - list all do regions'
echo 'alias: digitalocean images     - list all do images'
echo 'alias: digitalocean sizes      - list all do sizes'
echo 'alias: ll                      - ls -lah'
echo 'alias: lt                      - ls -lath (sort by time modified)'
echo 'alias: survey                  - nmap -sP 10.0.1.1/24'
echo 'alias: s                       - git status -sb'
echo 'alias: c                       - git commit -ev'
echo 'alias: ga                      - git add --all'
echo 'alias: co                      - git checkout'
echo 'alias: t                       - git log --graph --decorate --oneline'
echo 'alias: f                       - git fetch'
echo 'alias: b                       - git branch'
echo 'alias: gps                     - git push'
echo 'alias: gpl                     - git pull'
echo 'alias: top                     - top -o cpu'
echo 'alias: sub                     - sublime text 2 shortcut'
echo 'alias: bd                      - boot2docker'
echo ''

