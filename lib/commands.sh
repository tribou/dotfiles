#!/bin/bash -l

function aws-profile() {
  local profile
  profile=$(aws configure list-profiles | fzf) && export AWS_PROFILE="$profile"
  if [[ -n $profile ]]; then
    echo "AWS_PROFILE set to $profile"
  else
    echo "No profile selected or no profiles available."
    return 0
  fi

  if ! aws sts get-caller-identity | grep -q "SSO"; then
    aws sso login
  fi
}

function aws-set-current-account-id () {
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export AWS_ACCOUNT_ID
  echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
}

# If no args are passed, open the commit editor. Otherwise commit with all
# arguments concatenated as a string
function c ()
{
  if [ -f "./.git/MERGE_HEAD" ]
  then
    # If committing a git merge, accept the default message
    git commit -ev && _dotfiles_git_log_commit && _dotfiles_git_status
  else
    local current_ticket
    current_ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)
    local message
    message=$(_dotfiles_commit_message "$current_ticket" "$*")

    if [ $# -eq 0 ]
    then
      # If no args were provided, open the commit msg editor
      git commit -ev -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
    else
      git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
    fi
  fi
}

# c with --no-verify
function cn ()
{
  if [ -f "./.git/MERGE_HEAD" ]
  then
    # If committing a git merge, accept the default message
    git commit -ev --no-verify && _dotfiles_git_log_commit && _dotfiles_git_status
  else
    local current_ticket
    current_ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)
    local message
    message=$(_dotfiles_commit_message "$current_ticket" "$*")

    if [ $# -eq 0 ]
    then
      # If no args were provided, open the commit msg editor
      git commit -ev -m "$message" --no-verify && _dotfiles_git_log_commit && _dotfiles_git_status
    else
      git commit -m "$message" --no-verify && _dotfiles_git_log_commit && _dotfiles_git_status
    fi
  fi
}

function clean ()
{
  if ! git clean -f -- build/ public/ vendor/; then return 1; fi
  if [ -d "build/" ]; then git checkout build/; fi
  if [ -d "public/" ]; then git checkout public/; fi
  if [ -d "vendor/" ]; then git checkout vendor/; fi
}

function co ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="git checkout $* && _dotfiles_git_status"
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(git branch -a --sort=-committerdate | fzf --preview-window wrap)
    local CLEANED_RESULT
    CLEANED_RESULT="$(echo ${RESULT//\*} | sed -E 's/^remotes\/[A-Z0-9a-z]+\///')"
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
  local dm_name
  dm_name=$(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}")

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
    local SCRIPT="git branch -d $*"
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(git branch -a --sort=-committerdate | fzf --preview-window wrap --color)
    local CLEANED_RESULT
    CLEANED_RESULT="$(echo ${RESULT//\*} | sed -E 's/^remotes\/[A-Z0-9a-z]+\///')"
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
  if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
  then
    echo "$usage"
    return 1
  fi

  if [ $# -gt 1 ]
  then
    git rebase "$@"
  else
    git rebase -i HEAD~"$1"
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
  local RESULT
  RESULT=$(cat \
    <(history | grep "$1") \
    <(ls -d $HOME/.history/20*/* \
      | sort -r -n \
      | xargs grep -r "$1" \
      | awk -F "$AWK_REMOVE_HISTDIR" '{print $NF}') \
    | fzf --tmux="70%,80%" \
    | awk -F "$AWK_HISTFILE_DELIM" '{print $NF}' \
    | awk -F "$AWK_HISTORY_DELIM" '{print $NF}')

  # If in tmux, we can use send-keys
  if [ -n "$TMUX" ]
  then
    tmux send-keys -t "$TMUX_PANE" "$RESULT"
  else
    echo "$RESULT"
    printf '%s' "$RESULT" | pbcopy
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

  ansible-playbook "$DEVPATH/ansible-swap/site.yml" \
    -i "${1}," \
    --extra-vars "target=${1}"
}

function merge ()
{
  local MERGE_RESULT
  MERGE_RESULT=$(git merge "$*")
  if [ "$MERGE_RESULT" != "Already up to date." ]
  then
    _dotfiles_git_log_commit && _dotfiles_git_status
  else
    _dotfiles_git_status
  fi
}

function mkrepo()
{
  if [ -z "$1" ]; then
    echo "Usage: mkrepo <project-name>"
    return 1
  fi

  # 1. Create directory and navigate into it
  mkdir -p "$1"
  cd "$1" || return

  # 2. Initialize git and create a basic README
  git init -b main
  echo "# $1" > README.md

  # 3. Initial commit
  git add README.md
  git commit -m "Initial commit"

  # 4. Create the repo under the 'tribou' owner
  # --source=. tells gh to use the current folder
  # --push automatically pushes the initial commit
  gh repo create "tribou/$1" --private --source=. --remote=origin --push

  echo "✅ Created https://github.com/tribou/$1 and synced locally."
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
  local MACHINE_IP
  MACHINE_IP=$(docker-machine ip "$MACHINE_NAME") && \
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
    "${MACHINE_NAME}" && \
  install-swap "${MACHINE_IP}" && \
  dminit "${MACHINE_NAME}"
}

function npm-install-global ()
{
  echo "Installing global modules"
  npm install --location=global \
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

function npm-install ()
{
  local EXEC="npm"
  if [ -f "pnpm-lock.yaml" ]
  then
    EXEC="pnpm"
  elif [ -f "yarn.lock" ]
  then
    EXEC="yarn"
  elif [ -f "bun.lock" ]
  then
    EXEC="bun"
  fi
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
  local EXEC="npm run --silent"
  if [ -f "pnpm-lock.yaml" ]
  then
    EXEC="pnpm"
  elif [ -f "yarn.lock" ]
  then
    EXEC="yarn"
  elif [ -f "bun.lock" ]
  then
    EXEC="bun run --silent"
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

function mise-run ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="mise run $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    local RESULT
    RESULT=$(mise tasks ls --no-header | fzf --tiebreak=chunk | awk '{print $1}')
    if [ -n "$RESULT" ]
    then
      local SCRIPT="mise run $RESULT"
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

function restart-gpg ()
{
  gpgconf --kill gpg-agent
  eval "$(gpg-agent --daemon 2>/dev/null)"
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
    ':!*.lock' \
    ':!*.pnp.*' \
    ':!package-lock.json' \
    ':!pnpm-lock.yaml'
}

function supabase-profile() {
  local cfg="${SUPABASE_PROFILES:-$HOME/.config/supabase/profiles.tsv}"

  # Create config if missing
  if [[ ! -f "$cfg" ]]; then
    mkdir -p "$(dirname "$cfg")"
    umask 077
    cat > "$cfg" <<'EOF'
# name<TAB>token<TAB>project_ref(optional)<TAB>url(optional)
work	<paste-work-token-here>	<project-ref>	https://<project>.supabase.co
personal	<paste-personal-token-here>	<project-ref>	https://<project>.supabase.co
EOF
    chmod 600 "$cfg"
    echo "Created $cfg — please fill in your tokens and rerun." >&2
    return 1
  fi

  local sel name line token proj url
  sel="$(
    awk -F'\t' 'BEGIN{OFS="\t"} /^[^#]/ && NF>=2 {
      name=$1; token=$2; proj=(NF>=3?$3:""); url=(NF>=4?$4:"");
      mask=substr(token,1,6) "…" substr(token,length(token)-3,4);
      print name, (proj?proj:"—"), (url?url:"—"), mask
    }' "$cfg" \
    | fzf --header=$'Select a Supabase profile\n(name\tproject\turl\t(token masked))' \
          --with-nth=1,2,3 \
          --preview-window=down,3,wrap \
          --preview 'printf "Name: %s\nProject: %s\nURL: %s\nToken: %s\n" {1} {2} {3} {4}'
  )" || return 1
  [[ -n "$sel" ]] || return 1

  name=$(awk -F'\t' '{print $1}' <<<"$sel")
  line="$(awk -F'\t' -v n="$name" '/^[^#]/ && $1==n {print; exit}' "$cfg")" || return 1
  IFS=$'\t' read -r _ token proj url <<<"$line"

  export SUPABASE_ACCESS_TOKEN="$token"
  [[ -n "$proj" ]] && export SUPABASE_PROJECT_REF="$proj" || unset SUPABASE_PROJECT_REF
  [[ -n "$url"  ]] && export SUPABASE_URL="$url" || unset SUPABASE_URL

  echo "Activated Supabase profile: $name  (project: ${proj:-n/a})"
}

function tf ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="terraform $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    histgrep terraform
  fi
}

# Create the main dev layout for large monitors
function tmux-large ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 75% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -l 35% -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -h -l 40% -c "$_SECONDARY"
  tmux select-pane -t 3
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter
  tmux send-keys -t 2 f Enter
  tmux send-keys -t 3 v Enter
  [ "$_PRIMARY" != "$_SECONDARY" ] && tmux send-keys -t 4 f Enter
}

# Create the main dev layout for extra large monitors
function tmux-xl ()
{
  tmux-large "$@"
  tmux select-pane -t 3
  tmux split-window -v -l 20% -c '#{pane_current_path}'
  tmux select-pane -t 3
}

# Create the main dev layout for small monitors
function tmux-small ()
{
  [ -z "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 50% -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux split-window -v -l 25% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2 v Enter
  tmux send-keys -t 3
}

# Create a crossover for small and large monitors
function tmux-small-2 ()
{
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux-small "$@"
  tmux select-pane -t 3
  tmux split-window -v -l 25% -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux send-keys -t 4 f Enter
}

# Create another crossover for small and large monitors
function tmux-small-3 ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")
  local _SECONDARY
  _SECONDARY=$(_dotfiles_secondary_full_path "$1")

  tmux new -A -s main -d
  tmux split-window -h -l 55% -c "$_SECONDARY"
  tmux select-pane -t 1
  tmux split-window -v -l 75% -c "$_PRIMARY"
  tmux select-pane -t 3
  tmux split-window -v -l 75% -c "$_PRIMARY"
  tmux select-pane -t 2
  tmux send-keys -t 1 z Space "$_PRIMARY" Enter f Enter
  tmux send-keys -t 2 # PRIMARY
  tmux send-keys -t 3 f Enter # SECONDARY
  tmux send-keys -t 4 v Enter # PRIMARY
}

function tmux-small-half ()
{
  [ ! -n "$TMUX" ] && echo "Not in a tmux session" && return 1
  local _PRIMARY
  _PRIMARY=$(_dotfiles_primary_full_path "$1")

  tmux split-window -h -l 55% -c "$_PRIMARY"
  tmux select-pane -t 1
  tmux split-window -v -l 50% -c "$_PRIMARY"
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
    "./node_modules/.bin/$*"

  # Then check for existing global install
  elif [ -f "$(which ${1})" ]
  then
    "$@"

  # Otherwise, use npx
  else
    npx "$*"
  fi
}

# Command aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
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
alias dc='docker compose'
alias docker-compose='docker compose'
alias di='docker images'
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
alias fet='f origin test:test'
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
alias mr='mise-run'
alias ms='merge staging'
alias ni='npm-install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nr='npm-run'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
alias ntsc='npx tsc --noemit --watch --pretty'
alias prettyjson='python -m json.tool'
alias proxy-mini='ssh -D 8001 tbomini-remote'
alias r='git remote -v'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
alias revert='git revert HEAD'
alias s='_dotfiles_git_status'
alias sb='supabase'
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
alias yi='npm-install'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer; cd "$OLDPWD"'
alias yr='npm-run'
alias ytsc='yarn tsc --noemit --watch --pretty'
alias yw='yarn workspaces'

# NPM GLOBAL ALIASES
# Instead of installing ALL CLI packages globally, we can use NPX to call the
# ones we need in bash
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
alias sso='aws sso login --sso-session tribou'
alias storybook='npx @storybook/cli'
alias yu='nu'
