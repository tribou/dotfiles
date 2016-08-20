#!/bin/bash -l

# Commands and aliases
alias amend='git commit -S --amend'
alias b='git branch -a'
alias back='cd $OLDPWD'
alias bd='docker-machine'
alias c='git commit -S -ev'
alias cherry='git cherry-pick -S'
alias co='git checkout'
alias commit='git commit -ev' # non-signed commit
alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
alias convert-tabs-spaces="replace '	' '  '"
alias count='sed "/^\s*$/d" | wc -l | xargs'
alias dc='docker-compose'
alias di='docker images'
digitalocean () 
{
  curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN" "https://api.digitalocean.com/v2/$1?page=1&per_page=1000" | python -m json.tool
}
alias dm='docker-machine'
#alias dminit='eval "$(docker-machine env $(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"))"'
dminit ()
{
  usage='Usage: dminit [NAME]'
  dm_name=$(docker-machine ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}")

  # Return usage if 0 or more than 2 args are passed
  if [ $# -gt 1 ]
  then
    echo "$usage"
    return 1
  fi

  if [ $# -eq 1 ]
  then
    dm_name="$1"
  fi

  eval "$(docker-machine env $dm_name)"
}
alias dps='docker ps'
alias dpsa='docker ps -a'
alias drm='docker rm'
alias drmi='docker rmi'
alias edld='ember deploy:list --environment development'
alias edlp='ember deploy:list --environment production'
alias edls='ember deploy:list --environment staging'
alias f='git fetch'
alias filetypes="git ls-files | sed 's/.*\.//' | sort | uniq -c"
alias ga='git add --all'
alias gall='echo; echo; git log --oneline --all --graph --decorate  $(git reflog | awk '"'"'{print $1}'"'"')'
alias gc='gcloud compute'
alias gci='gcloud compute instances'
alias gbd='git branch -d'
alias gbdr='git branch -d -r'
alias gf='git flow'
alias gps='git push'
alias gpst='git push && git push --tags'
alias gpl='git pull'
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

  git rebase -S -i head~$1
}
alias gr2='git rebase -S -i head~2'
histgrep ()
{
  grep -r "$1" ~/.history
  history | grep "$1"
}
install-swap ()
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
alias kg='kubectl get pods,rc,svc -o wide'
alias kd='kubectl describe'
alias ll='ls -lah'
alias ls='ls -G'
alias lt='ls -lath'
alias merge='git merge -S'
alias ni='npm install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
npm-install-global ()
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
    gatsby \
    instant-markdown-d \
    jsonlint \
    node-inspector \
    nodemon \
    npm-check-updates \
    nsp \
    react-native-cli \
    serverless \
    slush
}
alias nr='npm run --silent'
alias nrs='npm rm --save'
alias nrsd='npm rm --save-dev'
alias proxy-mini='ssh -D 8001 tbomini-remote'
alias r='git remote -v'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
alias s='git status -sb'
alias search='echo; echo; git grep -n -I --untracked --break'
alias setdotglob='shopt -s dotglob'
sizes ()
{
  ls -lrt -d -1 ${PWD}/${1}* | xargs du -sh
}
alias sprofile='. ~/.bash_profile; cd $OLDPWD'
alias survey='sudo nmap -sP 10.0.1.1/24'
alias t='echo; echo; git tree'
alias tag='git tag -s -m ""'
alias top='top -o cpu'
alias tree='tree -I "bower_components|dist|node_modules|temp|tmp"'
alias unsetdotglob='shopt -u dotglob'
alias v='vim'
alias vc='vimcat'
alias vim='mvim -v'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer; cd $OLDPWD'
