#!/bin/bash -l

# Helper functions
function _dotfiles_full_path () {
  _z -e "$1"
}

function _dotfiles_git_status () {
  git status -sb
}

function _dotfiles_grep_ticket_number () {
  # Remove origin/ or feature/ prefix
  sed -E 's/^[A-Z0-9a-z]+\///' |
    # For ab123-this-thing pattern, remove the description tail
    sed -E 's/^([a-zA-Z]{2}[0-9]{1,7})\-.*$/\1/' |
    # For abc-123-this-thing pattern, remove the description tail
    sed -E 's/^([a-zA-Z]{2,4}-[0-9]{1,7})\-.*$/\1/' |
    # Filter out anything other than ab123 or abc-123
    grep -E '^([a-zA-Z]{2}[0-9]{1,7}|[a-zA-Z0-9]{2,4}-)\d{1,7}$' |
    # Convert all letters to UPPERCASE
    tr [a-z] [A-Z]
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
    local _PRIMARY=$(_dotfiles_full_path "$1")
  elif [ -n "$PRIMARY_REPO" ]
  then
    local _PRIMARY=$(_dotfiles_full_path "$PRIMARY_REPO")
  else
    local _PRIMARY="$PWD"
  fi

  echo "$_PRIMARY"
}

function _dotfiles_secondary_full_path () {
  if [ -n "$1" ]
  then
    local _SECONDARY=$(_dotfiles_full_path "$1")
  elif [ -n "$SECONDARY_REPO" ]
  then
    local _SECONDARY=$(_dotfiles_full_path "$SECONDARY_REPO")
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
    echo $SCRIPT
    echo
    eval $SCRIPT
  fi
}

# If no args are passed, open the commit editor. Otherwise commit with all
# arguments concatenated as a string
function c ()
{
  # If committing a git merge
  if [ -f "./.git/MERGE_HEAD" ]
  then
    git commit -ev && _dotfiles_git_log_commit && _dotfiles_git_status
  else
    local current_ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)
    if [ $# -eq 0 ]
    then
      if [ -z "$current_ticket" ]
      then
        git commit -ev && _dotfiles_git_log_commit && _dotfiles_git_status
      else
        local message="$current_ticket:"
        git commit -ev -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
      fi
    else
      if [ -z "$current_ticket" ]
      then
        local message="$*"
      else
        local message="$current_ticket: $*"
      fi
      git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
    fi
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
  if [ -n "$1" ]
  then
    local SCRIPT="git checkout $@ && _dotfiles_git_status"
    eval $SCRIPT
  else
    local RESULT=$(git branch -a --sort=-committerdate | fzf --preview-window wrap)
    local CLEANED_RESULT="$(echo ${RESULT//\*} | sed -E 's/^remotes\/[A-Z0-9a-z]+\///')"
    if [ -n "$CLEANED_RESULT" ]
    then
      local SCRIPT="git checkout $CLEANED_RESULT"
      _eval_script "$SCRIPT && _dotfiles_git_status"
    fi
  fi
}

function copy_to_clipboard ()
{
  if [ -n "$(command -v pbcopy)" ]
  then
    pbcopy
  elif [ -n "$(command -v xclip)" ]
  then
    xclip
  fi
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

function _dotfiles_prompt_git_branch_delete ()
{
  echo
  read -p "Run 'git branch -D $1'? (y/n): " confirm \
    && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] \
    || return 1

  git branch -D "$1"
}

function gbd ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="git branch -d $@"
    eval $SCRIPT
  else
    local RESULT=$(git branch -a --sort=-committerdate | fzf --preview-window wrap --color)
    local CLEANED_RESULT="$(echo ${RESULT//\*} | sed -E 's/^remotes\/[A-Z0-9a-z]+\///')"
    if [ -n "$CLEANED_RESULT" ]
    then
      local SCRIPT="git branch -d $CLEANED_RESULT || _dotfiles_prompt_git_branch_delete $CLEANED_RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}

function gpsu ()
{
  git push -u origin "$(git branch --show-current)" "$@" && _dotfiles_git_status
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
    git rebase "$@"
  else
    git rebase -i HEAD~$1
  fi
}

function gro ()
{
  git reset --hard "origin/$(git branch --show-current)" "$@" && _dotfiles_git_status
}

function histgrep ()
{
  # Remove histfile directory prefix during fzf search
  local AWK_REMOVE_HISTDIR='^\/.*\/\.history\/'
  # Remove rest of histfile prefix from selection
  local AWK_HISTFILE_DELIM='^[0-9]{4}\/[0-9]{2}\/\/?[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}_.*_.*[0-9]+:'
  # Remove current history result prefix from selection
  local AWK_HISTORY_DELIM='^ {0,4}[0-9]+  [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} '

  # Pipe results from two history sources into cat
  local RESULT=$(cat \
    <(history | grep "$1") \
    <(ls -d $HOME/.history/20*/* \
      | sort -r -n \
      | xargs grep -r "$1" \
      | awk -F "$AWK_REMOVE_HISTDIR" '{print $NF}') \
    | fzf \
    | awk -F "$AWK_HISTFILE_DELIM" '{print $NF}' \
    | awk -F "$AWK_HISTORY_DELIM" '{print $NF}')

  # If in tmux, we can use send-keys
  if [ -n "$TMUX" ]
  then
    tmux send-keys -t "$TMUX_PANE" "$RESULT"
  else
    echo "$RESULT"
    printf "$RESULT" | pbcopy
  fi
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
  local MERGE_RESULT=$(git merge "$@")
  if [ "$MERGE_RESULT" != "Already up to date." ]
  then
    _dotfiles_git_log_commit && _dotfiles_git_status
  else
    _dotfiles_git_status
  fi
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
}

function nr ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="npm run --silent $@"
    echo $SCRIPT
    echo
    eval $SCRIPT
  else
    local RESULT=$(jq '.scripts' package.json | fzf | awk -F'"' '{print $2}')
    if [ -n "$RESULT" ]
    then
      local SCRIPT="npm run --silent $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}

function ninfo ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="npm info $@"
    echo $SCRIPT
    echo
    eval $SCRIPT
  else
    local RESULT=$(ls node_modules | fzf)
    if [ -n "$RESULT" ]
    then
      local SCRIPT="npm info $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}

function paste_from_clipboard ()
{
  if [ -n "$(command -v pbpaste)" ]
  then
    pbpaste
  elif [ -n "$(command -v xclip)" ]
  then
    xclip -o -sel clipboard
  fi
}

function restart-docker ()
{
  printf "Restarting Docker service..."
  # Restart Docker app
  osascript -e 'quit app "Docker"' && open -a Docker
  echo "done"

  printf "Waiting for Docker to restart..."
  local max_retry=25
  local counter=1
  until docker ps >/dev/null 2>&1
  do
    # Sleep for 5 seconds the first time
    [[ counter -eq 1 ]] && sleep 3

    sleep 2

    [[ counter -eq $max_retry ]] && echo "" && echo "Docker still hasn't started. Exiting..." && return 1

    printf "."
    ((counter++))
  done
  echo "done"
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

# Create the main dev layout for large monitors
function tmux-large ()
{
  local _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -p 75 -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -p 35 -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -h -p 40 -c "$_SECONDARY"
  tmux select-pane -t 3
  tmux send-keys -t 1 z Space $_PRIMARY Enter
  tmux send-keys -t 2 f Enter
  tmux send-keys -t 3 v Enter
  [ "$_PRIMARY" != "$_SECONDARY" ] && tmux send-keys -t 4 f Enter
}

# Create the main dev layout for extra large monitors
function tmux-xl ()
{
  tmux-large "$@"
  tmux select-pane -t 3
  tmux split-window -v -p 20 -c '#{pane_current_path}'
  tmux select-pane -t 3
}

# Create the main dev layout for small monitors
function tmux-small ()
{
  local _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -p 55 -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -p 25 -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2
  tmux send-keys -t 3 v Enter
}

# Create a crossover for small and large monitors
function tmux-small-2 ()
{
  local _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux-small "$@"
  tmux select-pane -t 3
  tmux split-window -v -p 25 -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux send-keys -t 4 f Enter
}

# Create another crossover for small and large monitors
function tmux-small-3 ()
{
  local _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -p 55 -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux split-window -v -p 75 -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -v -p 75 -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2 # PRIMARY
  tmux send-keys -t 3 f Enter # SECONDARY
  tmux send-keys -t 4 v Enter # PRIMARY
}

function tmux-small-half ()
{
  local _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -p 55 -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -p 50 -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2
  tmux send-keys -t 3 v Enter
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

# function to execute built-in cd
# function z_cd ()
# {
#   if [ $# -le 1 ]; then
#     fasd "$@"
#   else
#     local _fasd_ret="$(fasd -e 'printf %s' "$@")"
#     [ -z "$_fasd_ret" ] && return
#     [ -d "$_fasd_ret" ] && cd "$_fasd_ret" || printf %s\n "$_fasd_ret"
#   fi
# }

function yr ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="yarn $@"
    echo $SCRIPT
    echo
    eval $SCRIPT
  else
    local RESULT=$(jq '.scripts' package.json | fzf | awk -F'"' '{print $2}')
    if [ -n "$RESULT" ]
    then
      local SCRIPT="yarn $RESULT"
      _eval_script "$SCRIPT"
    fi
  fi
}

# function zz ()
# {
#   local dir
#   dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
# }

# Command aliases
alias ack='ag'
alias ag='rg'
alias amend='git commit --amend && _dotfiles_git_log_commit && _dotfiles_git_status'
alias b='git branch -a --sort=-committerdate'
alias back='cd "$OLDPWD"'
alias bd='docker-machine'
alias be='bundle exec'
alias bfg='java -jar /usr/local/bin/bfg.jar'
alias cherry='git cherry-pick -x'
alias cod='co develop'
alias cop='co prod'
alias com='co main'
alias cos='co staging'
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
alias drma='docker ps -aq | xargs docker rm -f'
alias drmi='docker rmi'
alias edld='ember deploy:list --environment development'
alias edlp='ember deploy:list --environment production'
alias edls='ember deploy:list --environment staging'
alias fed='f origin develop:develop'
alias fem='f origin main:main'
alias fep='f origin prod:prod'
alias fes='f origin staging:staging'
alias filetypes="git ls-files | sed 's/.*\.//' | sort | uniq -c"
alias fix='git commit --amend -a --no-edit && _dotfiles_git_log_commit && _dotfiles_git_status'
alias gall='echo; echo; git log --oneline --all --graph --decorate  $(git reflog | awk '"'"'{print $1}'"'"')'
alias gall2='echo; echo; git log --oneline --all --graph --decorate --date=local --date=short --pretty=format:"%C(yellow)%h %C(cyan)%ad%C(auto)%d %Creset%s %C(blue)<%aN>" $(git reflog | awk '"'"'{print $1}'"'"')'
alias gbdr='git branch -d -r'
alias gc='gcloud compute'
alias gci='gcloud compute instances'
alias gd='git diff'
alias gds='git diff --staged --color-words'
alias gdw='git diff --color-words'
alias gdww='git diff-word'
alias gf='git flow'
alias gfix='git commit --amend -a --no-edit'
alias gpl='git pull'
alias gps='git push'
alias gpst='git push --follow-tags'
alias gr2='git rebase -i HEAD~2'
alias gs='git show'
alias gsp='git stash pop'
alias gss='git stash save'
alias gssk='git stash save --keep-index'
alias hg='histgrep'
alias j='TZ=UTC yarn jest --watch'
alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get pods,rc,svc,ing -o wide --show-labels'
alias less='less -r'
alias ll='ls -lah'
alias ls='ls -G'
alias lt='ls -lath'
alias md='merge develop'
alias mm='merge main'
alias mp='merge prod'
alias ms='merge staging'
alias ni='npm install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
alias ntsc='npx tsc --noemit --watch --pretty'
alias prettyjson='python -m json.tool'
alias proxy-mini='ssh -D 8001 tbomini-remote'
alias r='git remote -v'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
alias revert='git revert HEAD'
alias s='_dotfiles_git_status'
alias setdotglob='shopt -s dotglob'
alias sprofile='. ~/.bash_profile'
alias survey='sudo nmap -sP 10.0.1.1/24'
alias t='echo; echo; git tree'
alias tag='git tag -s -m ""'
alias tm-large='tmux-large'
alias tm-main='tmux-small-3'
alias tm-small-half='tmux-small-half'
alias tm-small='tmux-small'
alias tm-xl='tmux-xl'
alias tma='tmux -u new -A -s main'
alias tmm='tm-main'
alias tms='tmux-small'
alias tint='_dotfiles_git_log_branch_diff'
alias to='echo; echo; git tree-one'
alias tone='echo; echo; git tree-one'
alias top='top -o cpu'
alias tree='tree -I "bower_components|dist|node_modules|temp|tmp"'
alias ts='echo; echo; git tree-short'
alias unsetdotglob='shopt -u dotglob'
alias v='nvim'
alias vc='vimcat'
alias webpack-bundle-analyzer='npx webpack-bundle-analyzer'
alias webpack='useLocalIfAvailable webpack'
alias y='yarn'
alias yi='yarn install'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer; cd "$OLDPWD"'
alias ytsc='yarn tsc --noemit --watch --pretty'
alias yw='yarn workspaces'

# NPM GLOBAL ALIASES
# Instead of installing ALL CLI packages globally, we can use NPX to call the
# ones we need in bash
alias am='npx awsmobile-cli'
alias app-icon='npx app-icon'
alias awsmobile='npx awsmobile-cli'
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
alias storybook='npx @storybook/cli'
