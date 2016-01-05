# Colorize LS
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Set dev path
export DEVPATH=$HOME/dev

# Change bash prompt
export PS1="\[$(tput setaf 2)\]\h:\W> \[$(tput sgr0)\]"

# Set default editor
export EDITOR='vim'

# Case insensitive auto-completion
bind "set completion-ignore-case on"

# Single tab shows all matching directories/files
bind "set show-all-if-ambiguous on"

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
  grep -r "$@" ~/.history
  history | grep "$@"
}

# File search and replace functions
## Source recursive file search
if [ -e $DEVPATH/dotfiles/scripts/search.sh ]
then
  source $DEVPATH/dotfiles/scripts/search.sh
fi
## Source recursive string replace
if [ -e $DEVPATH/dotfiles/scripts/replace.sh ]
then
  source $DEVPATH/dotfiles/scripts/replace.sh
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
alias t='git log --graph --abbrev-commit --date=local --date=short --pretty=format:"%C(yellow)%h %C(cyan)%cd%C(green)%d %Creset%s %C(blue)<%aN>"'
alias f='git fetch'
alias b='git branch -a'
alias gbd='git branch -d'
alias top='top -o cpu'
alias r='git remote -v'
alias vim='mvim -v'
alias v='vim'
alias tree='tree -I node_modules'

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
## first init docker-vm
eval "$(docker-machine env docker-vm)"
## add aliases
alias bd='docker-machine'
alias dm='docker-machine'
alias dminit='eval "$(docker-machine env docker-vm)"'
## source dmupdate script
if [ -e $DEVPATH/dotfiles/scripts/dm_update_ip.sh ]; then source $DEVPATH/dotfiles/scripts/dm_update_ip.sh; fi
## run dmupdate
dmupdate

# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

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

# Ember.js
alias edlp='ember deploy:list --environment production'
alias edld='ember deploy:list --environment development'

export PATH=/usr/local/git/bin:$PATH

#source ~/sys/ansible/hacking/env-setup
export ANSIBLE_HOSTS=$DEVPATH/sys/ansible/ansible-hosts
export ANSIBLE_CONFIG=$DEVPATH/sys/ansible/ansible.cfg

# brew install bash-completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# gcloud sourcing
source '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
source '/opt/homebrew-cask/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'
alias gc='gcloud compute'
alias gci='gcloud compute instances'

# kubernetes aliases
alias kg='kubectl get pods,rc,svc -o wide'
alias kd='kubectl describe'

# import api keys
source "$HOME/.ssh/api_keys"

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

