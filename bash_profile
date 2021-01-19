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
[ -s "$NVM_DIR/nvm.sh"  ] && source "$NVM_DIR/nvm.sh" # This loads nvm
_dotfiles_debug_timing "$LINENO"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
_dotfiles_debug_timing "$LINENO"
export HAS_NVM=$([ $(command -v nvm) ] && echo true)
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

# z
export _Z_NO_RESOLVE_SYMLINKS=1
[ -f "$DEVPATH/z/z.sh" ] && . "$DEVPATH/z/z.sh"

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
  # eval "$(pyenv virtualenv-init -)"
fi

_dotfiles_debug_timing "$LINENO"

# Rust
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

# Color various outputs including fd which is used by ctrl-p in vim-fzf
export LS_COLORS='mi=0;38;2;0;0;0;48;2;255;92;87:tw=0:di=0;38;2;87;199;255:ow=0:ln=0;38;2;255;106;193:pi=0;38;2;0;0;0;48;2;87;199;255:so=0;38;2;0;0;0;48;2;255;106;193:cd=0;38;2;255;106;193;48;2;51;51;51:st=0:or=0;38;2;0;0;0;48;2;255;92;87:no=0:*~=0;38;2;102;102;102:fi=0:bd=0;38;2;154;237;254;48;2;51;51;51:ex=1;38;2;255;92;87:*.z=4;38;2;154;237;254:*.o=0;38;2;102;102;102:*.d=0;38;2;90;247;142:*.m=0;38;2;90;247;142:*.r=0;38;2;90;247;142:*.c=0;38;2;90;247;142:*.p=0;38;2;90;247;142:*.t=0;38;2;90;247;142:*.a=1;38;2;255;92;87:*.h=0;38;2;90;247;142:*.ml=0;38;2;90;247;142:*.cs=0;38;2;90;247;142:*.bc=0;38;2;102;102;102:*.gv=0;38;2;90;247;142:*.cr=0;38;2;90;247;142:*.gz=4;38;2;154;237;254:*.ps=0;38;2;255;92;87:*.jl=0;38;2;90;247;142:*.cc=0;38;2;90;247;142:*css=0;38;2;90;247;142:*.lo=0;38;2;102;102;102:*.vb=0;38;2;90;247;142:*.pp=0;38;2;90;247;142:*.rb=0;38;2;90;247;142:*.ko=1;38;2;255;92;87:*.as=0;38;2;90;247;142:*.kt=0;38;2;90;247;142:*.sh=0;38;2;90;247;142:*.td=0;38;2;90;247;142:*.pl=0;38;2;90;247;142:*.so=1;38;2;255;92;87:*.el=0;38;2;90;247;142:*.xz=4;38;2;154;237;254:*.rs=0;38;2;90;247;142:*.rm=0;38;2;255;180;223:*.go=0;38;2;90;247;142:*.fs=0;38;2;90;247;142:*.hh=0;38;2;90;247;142:*.pm=0;38;2;90;247;142:*.la=0;38;2;102;102;102:*.nb=0;38;2;90;247;142:*.py=0;38;2;90;247;142:*.ts=0;38;2;90;247;142:*.bz=4;38;2;154;237;254:*.js=0;38;2;90;247;142:*.ui=0;38;2;243;249;157:*.md=0;38;2;243;249;157:*.mn=0;38;2;90;247;142:*.cp=0;38;2;90;247;142:*.ex=0;38;2;90;247;142:*.hi=0;38;2;102;102;102:*.ll=0;38;2;90;247;142:*.di=0;38;2;90;247;142:*.7z=4;38;2;154;237;254:*.hs=0;38;2;90;247;142:*.out=0;38;2;102;102;102:*.rst=0;38;2;243;249;157:*.ppt=0;38;2;255;92;87:*.tmp=0;38;2;102;102;102:*.sbt=0;38;2;90;247;142:*.tsx=0;38;2;90;247;142:*.kex=0;38;2;255;92;87:*.fsi=0;38;2;90;247;142:*.psd=0;38;2;255;180;223:*.kts=0;38;2;90;247;142:*.asa=0;38;2;90;247;142:*.pkg=4;38;2;154;237;254:*.mp3=0;38;2;255;180;223:*.inl=0;38;2;90;247;142:*.pod=0;38;2;90;247;142:*.ico=0;38;2;255;180;223:*.git=0;38;2;102;102;102:*.arj=4;38;2;154;237;254:*.ogg=0;38;2;255;180;223:*.bin=4;38;2;154;237;254:*.aux=0;38;2;102;102;102:*.lua=0;38;2;90;247;142:*.exs=0;38;2;90;247;142:*.wmv=0;38;2;255;180;223:*.eps=0;38;2;255;180;223:*.bst=0;38;2;243;249;157:*.epp=0;38;2;90;247;142:*.tgz=4;38;2;154;237;254:*.mli=0;38;2;90;247;142:*.aif=0;38;2;255;180;223:*.dot=0;38;2;90;247;142:*.hxx=0;38;2;90;247;142:*.csx=0;38;2;90;247;142:*.mp4=0;38;2;255;180;223:*.vob=0;38;2;255;180;223:*.ics=0;38;2;255;92;87:*.tex=0;38;2;90;247;142:*.odt=0;38;2;255;92;87:*.svg=0;38;2;255;180;223:*.hpp=0;38;2;90;247;142:*.inc=0;38;2;90;247;142:*.mpg=0;38;2;255;180;223:*.ilg=0;38;2;102;102;102:*.fls=0;38;2;102;102;102:*.mov=0;38;2;255;180;223:*.blg=0;38;2;102;102;102:*.xml=0;38;2;243;249;157:*.mid=0;38;2;255;180;223:*.fon=0;38;2;255;180;223:*.dox=0;38;2;165;255;195:*.m4v=0;38;2;255;180;223:*.sxi=0;38;2;255;92;87:*.pyc=0;38;2;102;102;102:*.iso=4;38;2;154;237;254:*.otf=0;38;2;255;180;223:*.txt=0;38;2;243;249;157:*.def=0;38;2;90;247;142:*.bcf=0;38;2;102;102;102:*.odp=0;38;2;255;92;87:*.sty=0;38;2;102;102;102:*.erl=0;38;2;90;247;142:*.dpr=0;38;2;90;247;142:*hgrc=0;38;2;165;255;195:*.bag=4;38;2;154;237;254:*.exe=1;38;2;255;92;87:*.wma=0;38;2;255;180;223:*.jar=4;38;2;154;237;254:*.vim=0;38;2;90;247;142:*.bmp=0;38;2;255;180;223:*.ind=0;38;2;102;102;102:*.ini=0;38;2;243;249;157:*.cgi=0;38;2;90;247;142:*.tml=0;38;2;243;249;157:*.ltx=0;38;2;90;247;142:*.flv=0;38;2;255;180;223:*.sql=0;38;2;90;247;142:*.bsh=0;38;2;90;247;142:*.fnt=0;38;2;255;180;223:*.tcl=0;38;2;90;247;142:*.avi=0;38;2;255;180;223:*.h++=0;38;2;90;247;142:*.rpm=4;38;2;154;237;254:*.bz2=4;38;2;154;237;254:*.wav=0;38;2;255;180;223:*.jpg=0;38;2;255;180;223:*.rar=4;38;2;154;237;254:*.php=0;38;2;90;247;142:*.xlr=0;38;2;255;92;87:*.ods=0;38;2;255;92;87:*.idx=0;38;2;102;102;102:*.vcd=4;38;2;154;237;254:*.bbl=0;38;2;102;102;102:*.htm=0;38;2;243;249;157:*.ipp=0;38;2;90;247;142:*.awk=0;38;2;90;247;142:*.pid=0;38;2;102;102;102:*.pas=0;38;2;90;247;142:*TODO=1:*.cxx=0;38;2;90;247;142:*.xls=0;38;2;255;92;87:*.log=0;38;2;102;102;102:*.mir=0;38;2;90;247;142:*.deb=4;38;2;154;237;254:*.rtf=0;38;2;255;92;87:*.ppm=0;38;2;255;180;223:*.tar=4;38;2;154;237;254:*.gvy=0;38;2;90;247;142:*.elm=0;38;2;90;247;142:*.img=4;38;2;154;237;254:*.cpp=0;38;2;90;247;142:*.bib=0;38;2;243;249;157:*.pro=0;38;2;165;255;195:*.clj=0;38;2;90;247;142:*.doc=0;38;2;255;92;87:*.pps=0;38;2;255;92;87:*.gif=0;38;2;255;180;223:*.fsx=0;38;2;90;247;142:*.yml=0;38;2;243;249;157:*.c++=0;38;2;90;247;142:*.ttf=0;38;2;255;180;223:*.tbz=4;38;2;154;237;254:*.pdf=0;38;2;255;92;87:*.cfg=0;38;2;243;249;157:*.htc=0;38;2;90;247;142:*.sxw=0;38;2;255;92;87:*.csv=0;38;2;243;249;157:*.xcf=0;38;2;255;180;223:*.pgm=0;38;2;255;180;223:*.ps1=0;38;2;90;247;142:*.zip=4;38;2;154;237;254:*.nix=0;38;2;243;249;157:*.swf=0;38;2;255;180;223:*.apk=4;38;2;154;237;254:*.pbm=0;38;2;255;180;223:*.com=1;38;2;255;92;87:*.swp=0;38;2;102;102;102:*.toc=0;38;2;102;102;102:*.m4a=0;38;2;255;180;223:*.zsh=0;38;2;90;247;142:*.mkv=0;38;2;255;180;223:*.dmg=4;38;2;154;237;254:*.xmp=0;38;2;243;249;157:*.png=0;38;2;255;180;223:*.tif=0;38;2;255;180;223:*.bat=1;38;2;255;92;87:*.bak=0;38;2;102;102;102:*.dll=1;38;2;255;92;87:*.hgrc=0;38;2;165;255;195:*.yaml=0;38;2;243;249;157:*.diff=0;38;2;90;247;142:*.java=0;38;2;90;247;142:*.lock=0;38;2;102;102;102:*.fish=0;38;2;90;247;142:*.lisp=0;38;2;90;247;142:*.orig=0;38;2;102;102;102:*.psm1=0;38;2;90;247;142:*.json=0;38;2;243;249;157:*.h264=0;38;2;255;180;223:*.rlib=0;38;2;102;102;102:*.tiff=0;38;2;255;180;223:*.make=0;38;2;165;255;195:*.toml=0;38;2;243;249;157:*.purs=0;38;2;90;247;142:*.xlsx=0;38;2;255;92;87:*.jpeg=0;38;2;255;180;223:*.epub=0;38;2;255;92;87:*.psd1=0;38;2;90;247;142:*.conf=0;38;2;243;249;157:*.docx=0;38;2;255;92;87:*.pptx=0;38;2;255;92;87:*.tbz2=4;38;2;154;237;254:*.bash=0;38;2;90;247;142:*.dart=0;38;2;90;247;142:*.flac=0;38;2;255;180;223:*.mpeg=0;38;2;255;180;223:*.less=0;38;2;90;247;142:*.html=0;38;2;243;249;157:*.swift=0;38;2;90;247;142:*.cmake=0;38;2;165;255;195:*passwd=0;38;2;243;249;157:*.ipynb=0;38;2;90;247;142:*.mdown=0;38;2;243;249;157:*.patch=0;38;2;90;247;142:*.class=0;38;2;102;102;102:*.cache=0;38;2;102;102;102:*.xhtml=0;38;2;243;249;157:*README=0;38;2;40;42;54;48;2;243;249;157:*.scala=0;38;2;90;247;142:*.dyn_o=0;38;2;102;102;102:*.shtml=0;38;2;243;249;157:*shadow=0;38;2;243;249;157:*.cabal=0;38;2;90;247;142:*.toast=4;38;2;154;237;254:*.ignore=0;38;2;165;255;195:*.gradle=0;38;2;90;247;142:*.config=0;38;2;243;249;157:*COPYING=0;38;2;153;153;153:*TODO.md=1:*.groovy=0;38;2;90;247;142:*LICENSE=0;38;2;153;153;153:*.dyn_hi=0;38;2;102;102;102:*.matlab=0;38;2;90;247;142:*.flake8=0;38;2;165;255;195:*INSTALL=0;38;2;40;42;54;48;2;243;249;157:*Doxyfile=0;38;2;165;255;195:*TODO.txt=1:*Makefile=0;38;2;165;255;195:*.gemspec=0;38;2;165;255;195:*.desktop=0;38;2;243;249;157:*setup.py=0;38;2;165;255;195:*README.md=0;38;2;40;42;54;48;2;243;249;157:*COPYRIGHT=0;38;2;153;153;153:*.rgignore=0;38;2;165;255;195:*.markdown=0;38;2;243;249;157:*configure=0;38;2;165;255;195:*.DS_Store=0;38;2;102;102;102:*.fdignore=0;38;2;165;255;195:*.cmake.in=0;38;2;165;255;195:*.kdevelop=0;38;2;165;255;195:*Dockerfile=0;38;2;243;249;157:*CODEOWNERS=0;38;2;165;255;195:*.localized=0;38;2;102;102;102:*SConstruct=0;38;2;165;255;195:*SConscript=0;38;2;165;255;195:*.gitconfig=0;38;2;165;255;195:*.gitignore=0;38;2;165;255;195:*README.txt=0;38;2;40;42;54;48;2;243;249;157:*INSTALL.md=0;38;2;40;42;54;48;2;243;249;157:*.scons_opt=0;38;2;102;102;102:*INSTALL.txt=0;38;2;40;42;54;48;2;243;249;157:*.synctex.gz=0;38;2;102;102;102:*.gitmodules=0;38;2;165;255;195:*.travis.yml=0;38;2;90;247;142:*MANIFEST.in=0;38;2;165;255;195:*LICENSE-MIT=0;38;2;153;153;153:*Makefile.in=0;38;2;102;102;102:*Makefile.am=0;38;2;165;255;195:*.fdb_latexmk=0;38;2;102;102;102:*configure.ac=0;38;2;165;255;195:*CONTRIBUTORS=0;38;2;40;42;54;48;2;243;249;157:*.applescript=0;38;2;90;247;142:*appveyor.yml=0;38;2;90;247;142:*.clang-format=0;38;2;165;255;195:*CMakeLists.txt=0;38;2;165;255;195:*LICENSE-APACHE=0;38;2;153;153;153:*.gitattributes=0;38;2;165;255;195:*CMakeCache.txt=0;38;2;102;102;102:*CONTRIBUTORS.md=0;38;2;40;42;54;48;2;243;249;157:*CONTRIBUTORS.txt=0;38;2;40;42;54;48;2;243;249;157:*.sconsign.dblite=0;38;2;102;102;102:*requirements.txt=0;38;2;165;255;195:*package-lock.json=0;38;2;102;102;102:*.CFUserTextEncoding=0;38;2;102;102;102'
