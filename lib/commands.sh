#!/bin/bash -l

# Helper functions
function _dotfiles_git_status () {
  git status -sb
}

function _dotfiles_grep_ticket_number () {
  grep -E '^[A-Z0-9]{2,4}-\d{1,7}$'
}

# Use like: useLocalIfAvailable flow-typed -v
function useLocalIfAvailable ()
{
  # Use local node module if available
  if [ -f "$(which ./node_modules/.bin/${1})" ]
  then
    "./node_modules/.bin/$@"

  # Then check for existing global install
  elif [ -f "$(which ${1})" ]
  then
    "$@"

  # Otherwise, use npx
  else
    npx "$@"
  fi
}

# If no args are passed, open the commit editor. Otherwise commit with all
# arguments concatenated as a string
function c ()
{
  if [ $# -eq 0 ]
  then
    git commit -S -ev && _dotfiles_git_status
  else
    local current_ticket=$(git branch --show-current | _dotfiles_grep_ticket_number)
    if [ -z "$current_ticket" ]
    then
      local message="$*"
    else
      local message="$current_ticket: $*"
    fi
    git commit -S -m "$message" && _dotfiles_git_status
  fi
}

function clean ()
{
  git clean -f -- build/ public/ vendor/
  if [[ $? -ne 0 ]]; then return 1; fi
  if [ -d "build/" ]; then git checkout build/; fi
  if [ -d "public/" ]; then git checkout public/; fi
  if [ -d "vendor/" ]; then git checkout vendor/; fi
}

function co ()
{
  git checkout "$@" && _dotfiles_git_status
}

function digitalocean ()
{
  curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN" "https://api.digitalocean.com/v2/$1?page=1&per_page=1000" | python -m json.tool
}

function dminit ()
{
  local usage='Usage: dminit [NAME]'
  local dm_name=$(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}")

  # Return usage if 0 or more than 2 args are passed
  if [ $# -gt 1 ]
  then
    echo "$usage"
    return 1
  fi

  if [ $# -eq 1 ]
  then
    local dm_name="$1"
  fi

  eval "$(docker-machine env $dm_name)"
}

function da ()
{
  # Select a docker container to start and attach to
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}
function ds ()
{
  # Select a running docker container to stop
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker stop "$cid"
}

function f ()
{
  git fetch --prune --progress "$@" && _dotfiles_git_status
}

function ga ()
{
  git add --all "$@" && _dotfiles_git_status
}

function gr ()
{

  local usage='Usage: gr [NUMBER]'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -eq 0 ] || [ $1 == "-h" ] || [ $1 == "--help" ]
  then
    echo "$usage"
    return 1
  fi

  if [ $# -gt 1 ]
  then
    git rebase -S "$@"
  else
    git rebase -S -i HEAD~$1
  fi
}

function histgrep ()
{
  # Remove histfile directory prefix during fzf search
  local AWK_REMOVE_HISTDIR='^\/.*\/\.history\/'
  # Remove rest of histfile prefix from selection
  local AWK_HISTFILE_DELIM='^[0-9]{4}\/[0-9]{2}\/[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}_.*_.*[0-9]+:'
  # Remove current history result prefix from selection
  local AWK_HISTORY_DELIM='^ {0,4}[0-9]+  [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} '

  # Pipe results from two history sources into cat
  local RESULT=$(cat \
    <(grep --line-buffered --color=never -r "$1" ~/.history \
    | awk -F "$AWK_REMOVE_HISTDIR" '{print $NF}' \
    | sort) \
    <(history | grep "$1") \
    | fzf +s --tac --preview-window wrap \
    | awk -F "$AWK_HISTFILE_DELIM" '{print $NF}' \
    | awk -F "$AWK_HISTORY_DELIM" '{print $NF}')

  echo "$RESULT"
  printf "$RESULT" | pbcopy
}

function install-swap ()
{
  local usage='Usage: install-swap HOST'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -lt 1 ]
  then
    echo "$usage"
    return 1
  fi
  if [ $# -gt 2 ]
  then
    echo "$usage"
    return 1
  fi

  ansible-playbook $DEVPATH/ansible-swap/site.yml \
    -i "${1}," \
    --extra-vars "target=${1}"
}

function merge ()
{
  git merge -S "$@" && _dotfiles_git_status
}

function new-docker ()
{
  local usage='Usage: new-docker [NAME] [ACCESS_TOKEN]'

  if [ $# -gt 3 ]
  then
    echo "$usage"
    return 1
  fi

  if [ -z "$1" ]
  then
    local MACHINE_NAME=dev
  else
    local MACHINE_NAME="$1"
  fi

  if [ -z "$2" ]
  then
    local ACCESS_TOKEN="${DIGITALOCEAN_RS_TOKEN}"
  else
    local ACCESS_TOKEN="$2"
  fi

  echo "Creating ${MACHINE_NAME}..."

  docker-machine create --driver digitalocean \
    --digitalocean-access-token "${DIGITALOCEAN_RS_TOKEN}" \
    --digitalocean-image ubuntu-16-04-x64 \
    --digitalocean-region nyc3 \
    --digitalocean-size 2gb \
    --digitalocean-ssh-key-fingerprint "77:70:98:0d:d6:48:01:79:7b:41:f4:66:00:95:54:12" \
    "${MACHINE_NAME}"
  local MACHINE_IP=$(docker-machine ip "$MACHINE_NAME") && \
  install-swap "${MACHINE_IP}" && \
  dminit "${MACHINE_NAME}"
}

function new-docker-generic ()
{
  local usage='Usage: new-docker-generic IP_ADDRESS [NAME] [PRIVATE_KEY_PATH]'

  if [ $# -lt 1 ]
  then
    echo "$usage"
    return 1
  fi

  local MACHINE_IP="$1"

  if [ -z "$2" ]
  then
    local MACHINE_NAME="dev"
  else
    local MACHINE_NAME="$2"
  fi

  # if [ -z "$3" ]
  # then
  #   PRIVATE_KEY='~/.ssh/id_rsa'
  # else
  #   PRIVATE_KEY="$3"
  # fi

  docker-machine create --driver generic \
    --generic-ip-address "${MACHINE_IP}" \
    # --generic-ssh-key "${PRIVATE_KEY}" \
    "${MACHINE_NAME}" && \
  install-swap "${MACHINE_IP}" && \
  dminit "${MACHINE_NAME}"
}

function npm-install-global ()
{
  if [ ! -z "$1" ]
  then
    local NPM_VERSION="$1"
  else
    local NPM_VERSION='lts'
  fi

  echo "Installing npm@$NPM_VERSION and global modules"
  npm install -g npm@"$NPM_VERSION" \
    && npm install -g \
    eslint_d \
    js-yaml \
    jsonlint \
    neovim \
    prettier \
    react-native-cli \
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
}

function search ()
{

  local usage='Usage: search PATTERN'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -ne 1 ]
  then
    echo "$usage"
    return 1
  fi

  echo
  echo
  git grep -n -I --untracked --break "$1" -- './*' \
    ':!bin/**' \
    ':!flow-typed/**' \
    ':!vendor/**' \
    ':!yarn.lock'
}

# function to execute built-in cd
function z_cd ()
{
  if [ $# -le 1 ]; then
    fasd "$@"
  else
    local _fasd_ret="$(fasd -e 'printf %s' "$@")"
    [ -z "$_fasd_ret" ] && return
    [ -d "$_fasd_ret" ] && cd "$_fasd_ret" || printf %s\n "$_fasd_ret"
  fi
}

function zz ()
{
  local dir
  dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

# Command aliases
alias ack='ag'
alias ag='rg'
alias amend='git commit -S --amend'
alias b='git branch -a --sort=-committerdate'
alias back='cd "$OLDPWD"'
alias bd='docker-machine'
alias be='bundle exec'
alias bfg='java -jar /usr/local/bin/bfg.jar'
alias cherry='git cherry-pick -S -x'
alias com='co master'
alias commit='git commit -ev' # non-signed commit
alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
alias convert-tabs-spaces="replace '	' '  '"
alias count='sed "/^\s*$/d" | wc -l | xargs'
alias d='docker'
alias dc='docker-compose'
alias di='docker images'
alias dm='docker-machine'
#alias dminit='eval "$(docker-machine env $(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"))"'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias drm='docker rm'
alias drmi='docker rmi'
alias edld='ember deploy:list --environment development'
alias edlp='ember deploy:list --environment production'
alias edls='ember deploy:list --environment staging'
alias filetypes="git ls-files | sed 's/.*\.//' | sort | uniq -c"
alias fix='git commit --amend -a --no-edit -S'
alias gall='echo; echo; git log --oneline --all --graph --decorate  $(git reflog | awk '"'"'{print $1}'"'"')'
alias gc='gcloud compute'
alias gci='gcloud compute instances'
alias gbd='git branch -d'
alias gbdr='git branch -d -r'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git flow'
alias gfix='git commit --amend -a --no-edit -S'
alias gps='git push'
alias gpst='git push --follow-tags'
alias gpl='git pull'
alias gr2='git rebase -S -i HEAD~2'
alias gs='git show'
alias hg='histgrep'
alias k='kubectl'
alias kg='kubectl get pods,rc,svc,ing -o wide --show-labels'
alias kd='kubectl describe'
alias less='less -r'
alias ll='ls -lah'
alias ls='ls -G'
alias lt='ls -lath'
alias ni='npm install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nr='npm run --silent'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
alias prettyjson='python -m json.tool'
alias proxy-mini='ssh -D 8001 tbomini-remote'
alias r='git remote -v'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
alias revert='git revert -S HEAD'
alias s='_dotfiles_git_status'
alias setdotglob='shopt -s dotglob'
alias sprofile='. ~/.bash_profile; cd "$OLDPWD"'
alias survey='sudo nmap -sP 10.0.1.1/24'
alias t='echo; echo; git tree'
alias tma='tmux attach'
alias ts='echo; echo; git tree-short'
alias to='echo; echo; git tree-one'
alias tag='git tag -s -m ""'
alias top='top -o cpu'
alias tree='tree -I "bower_components|dist|node_modules|temp|tmp"'
alias unsetdotglob='shopt -u dotglob'
alias v='nvim'
alias vc='vimcat'
alias vim='nvim'
alias webpack='useLocalIfAvailable webpack'
alias webpack-bundle-analyzer='npx webpack-bundle-analyzer'
alias y='npm run --silent yarn-bin --'
alias yi='npm run --silent yarn-bin --'
alias yr='npm run --silent yarn-bin --'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer; cd "$OLDPWD"'
alias z='z_cd -d'

# NPM GLOBAL ALIASES
# Instead of installing ALL CLI packages globally, we can use NPX to call the
# ones we need in bash
alias am='npx awsmobile-cli'
alias app-icon='npx app-icon'
alias awsmobile='npx awsmobile-cli'
alias babel-eslint='npx babel-eslint'
alias eslint='npx eslint'
alias flow='npx flow'
alias flow-typed='npx flow-typed'
alias rn='react-native'
alias react-native='react-native'
alias gatsby='npx gatsby'
alias serverless='npx serverless'
alias devtools='react-devtools'
alias react-devtools='react-devtools'
alias nodemon='nodemon'
alias nsp='npx nsp'
alias npm-check-updates='npx npm-check-updates'
alias storybook='npx @storybook/cli'
alias ember='npx ember-cli'
