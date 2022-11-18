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

# Set path for HOMEBREW
[ ! -s "$(which brew)"  ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "$(which brew >/dev/null 2>&1)" ] && BREW_PREFIX=$(brew --prefix)


export GOPATH=$DEVPATH/go
export PATH=/usr/local/sbin:/usr/local/bin:$HOME/.fastlane/bin:$PATH:/usr/local/share/npm/bin:$GOPATH/bin:$DEVPATH/bin
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH

# fzf
[ -d "$HOME/.fzf/bin" ] && export PATH=$PATH:$HOME/.fzf/bin

# c9
[ -d "/opt/c9/local/bin" ] && export PATH=$PATH:/opt/c9/local/bin

# deno
[ -d "$HOME/.deno" ] && export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL/bin" ] && export PATH="$DENO_INSTALL/bin:$PATH"

# ruby rbenv
[ -f "$HOME/.rbenv/bin/rbenv" ] && export PATH=$PATH:$HOME/.rbenv/bin
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

_dotfiles_debug_timing "$LINENO"

# Node.js and NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && source "$NVM_DIR/nvm.sh" --no-use # This loads nvm
_dotfiles_debug_timing "$LINENO"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
_dotfiles_debug_timing "$LINENO"
export HAS_NVM=$([ $(command -v nvm) ] && echo true)
# _dotfiles_debug_timing "$LINENO"
[ -n "$HAS_NVM" ] && nvm use --delete-prefix default --silent

_dotfiles_debug_timing "$LINENO"

# Change bash prompt
export PS1="\[\033[0;34m\]\W \$([ -n "$HAS_NVM" ] && nvm current) \$(get_git_location) > \[$(tput sgr0)\]"


# AWS CLI
complete -C aws_completer aws

_dotfiles_debug_timing "$LINENO"

# Added by Amplify CLI binary installer
[ -d "$HOME/.amplify/bin" ] && export PATH="$HOME/.amplify/bin:$PATH"

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
if [ $(which pyenv) ]
then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
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
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

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

# Warnings for unset env vars
[ ! -n "$GIT_SIGNING_KEY" ] && echo 'WARNING: $GIT_SIGNING_KEY not set!'

# Color various outputs including fd which is used by ctrl-p in vim-fzf
export LS_COLORS='mi=0;38;2;250;208;122;48;2;144;32;32:pi=0;38;2;240;160;192:st=0:ex=1;38;2;255;185;100:so=0;38;2;240;160;192:di=0;38;2;198;182;238:no=0:or=0;38;2;250;208;122;48;2;144;32;32:*~=3;38;2;136;136;136:bd=0;38;2;207;106;76:cd=0;38;2;207;106;76:tw=0:ow=0:ln=0;38;2;250;208;122:fi=0:*.d=0;38;2;129;151;191:*.p=0;38;2;129;151;191:*.r=0;38;2;129;151;191:*.m=0;38;2;129;151;191:*.a=1;38;2;255;185;100:*.c=0;38;2;129;151;191:*.h=0;38;2;129;151;191:*.z=4;38;2;250;208;122:*.t=0;38;2;129;151;191:*.o=3;38;2;136;136;136:*.rm=0;38;2;218;208;133:*css=0;38;2;129;151;191:*.hh=0;38;2;129;151;191:*.as=0;38;2;129;151;191:*.cp=0;38;2;129;151;191:*.so=1;38;2;255;185;100:*.go=0;38;2;129;151;191:*.bz=4;38;2;250;208;122:*.vb=0;38;2;129;151;191:*.hs=0;38;2;129;151;191:*.ui=0;38;2;153;173;106:*.fs=0;38;2;129;151;191:*.cc=0;38;2;129;151;191:*.rs=0;38;2;129;151;191:*.cr=0;38;2;129;151;191:*.ll=0;38;2;129;151;191:*.js=0;38;2;129;151;191:*.xz=4;38;2;250;208;122:*.nb=0;38;2;129;151;191:*.hi=3;38;2;136;136;136:*.la=3;38;2;136;136;136:*.ko=1;38;2;255;185;100:*.mn=0;38;2;129;151;191:*.ml=0;38;2;129;151;191:*.pm=0;38;2;129;151;191:*.lo=3;38;2;136;136;136:*.sh=0;38;2;129;151;191:*.jl=0;38;2;129;151;191:*.td=0;38;2;129;151;191:*.gz=4;38;2;250;208;122:*.pp=0;38;2;129;151;191:*.7z=4;38;2;250;208;122:*.py=0;38;2;129;151;191:*.bc=3;38;2;136;136;136:*.md=0;38;2;102;135;153:*.rb=0;38;2;129;151;191:*.di=0;38;2;129;151;191:*.pl=0;38;2;129;151;191:*.el=0;38;2;129;151;191:*.gv=0;38;2;129;151;191:*.kt=0;38;2;129;151;191:*.ts=0;38;2;129;151;191:*.ex=0;38;2;129;151;191:*.ps=0;38;2;102;135;153:*.cs=0;38;2;129;151;191:*.bcf=3;38;2;136;136;136:*.bib=0;38;2;153;173;106:*.zip=4;38;2;250;208;122:*.ics=0;38;2;102;135;153:*.xmp=0;38;2;153;173;106:*.htm=0;38;2;102;135;153:*.sxi=0;38;2;102;135;153:*.flv=0;38;2;218;208;133:*.cxx=0;38;2;129;151;191:*.mli=0;38;2;129;151;191:*.kts=0;38;2;129;151;191:*.mid=0;38;2;218;208;133:*.rpm=4;38;2;250;208;122:*.inc=0;38;2;129;151;191:*.nix=0;38;2;153;173;106:*.odt=0;38;2;102;135;153:*.kex=0;38;2;102;135;153:*.svg=0;38;2;218;208;133:*.ltx=0;38;2;129;151;191:*.idx=3;38;2;136;136;136:*.xml=0;38;2;102;135;153:*.htc=0;38;2;129;151;191:*.psd=0;38;2;218;208;133:*.tsx=0;38;2;129;151;191:*.doc=0;38;2;102;135;153:*.h++=0;38;2;129;151;191:*.dot=0;38;2;129;151;191:*.hxx=0;38;2;129;151;191:*.pdf=0;38;2;102;135;153:*.dox=0;38;2;118;151;214:*.pkg=4;38;2;250;208;122:*.dpr=0;38;2;129;151;191:*.rar=4;38;2;250;208;122:*.fon=0;38;2;218;208;133:*.wmv=0;38;2;218;208;133:*.pro=0;38;2;118;151;214:*.pbm=0;38;2;218;208;133:*.ico=0;38;2;218;208;133:*.lua=0;38;2;129;151;191:*.mir=0;38;2;129;151;191:*.ilg=3;38;2;136;136;136:*.swf=0;38;2;218;208;133:*.aif=0;38;2;218;208;133:*.def=0;38;2;129;151;191:*.eps=0;38;2;218;208;133:*.fnt=0;38;2;218;208;133:*.wma=0;38;2;218;208;133:*hgrc=0;38;2;118;151;214:*.cfg=0;38;2;153;173;106:*.xls=0;38;2;102;135;153:*.jar=4;38;2;250;208;122:*.m4v=0;38;2;218;208;133:*.xlr=0;38;2;102;135;153:*.ps1=0;38;2;129;151;191:*.ttf=0;38;2;218;208;133:*.erl=0;38;2;129;151;191:*.exe=1;38;2;255;185;100:*.tcl=0;38;2;129;151;191:*.tar=4;38;2;250;208;122:*.apk=4;38;2;250;208;122:*.ind=3;38;2;136;136;136:*.c++=0;38;2;129;151;191:*.bag=4;38;2;250;208;122:*.toc=3;38;2;136;136;136:*TODO=0;38;2;112;185;80:*.m4a=0;38;2;218;208;133:*.gvy=0;38;2;129;151;191:*.blg=3;38;2;136;136;136:*.hpp=0;38;2;129;151;191:*.tgz=4;38;2;250;208;122:*.arj=4;38;2;250;208;122:*.otf=0;38;2;218;208;133:*.pid=3;38;2;136;136;136:*.ppt=0;38;2;102;135;153:*.yml=0;38;2;153;173;106:*.vcd=4;38;2;250;208;122:*.aux=3;38;2;136;136;136:*.iso=4;38;2;250;208;122:*.tml=0;38;2;153;173;106:*.cpp=0;38;2;129;151;191:*.pas=0;38;2;129;151;191:*.png=0;38;2;218;208;133:*.bin=4;38;2;250;208;122:*.csv=0;38;2;102;135;153:*.exs=0;38;2;129;151;191:*.pod=0;38;2;129;151;191:*.php=0;38;2;129;151;191:*.vim=0;38;2;129;151;191:*.pps=0;38;2;102;135;153:*.jpg=0;38;2;218;208;133:*.odp=0;38;2;102;135;153:*.pyc=3;38;2;136;136;136:*.sty=3;38;2;136;136;136:*.bat=1;38;2;255;185;100:*.vob=0;38;2;218;208;133:*.swp=3;38;2;136;136;136:*.sxw=0;38;2;102;135;153:*.fsx=0;38;2;129;151;191:*.mp4=0;38;2;218;208;133:*.tbz=4;38;2;250;208;122:*.bsh=0;38;2;129;151;191:*.bbl=3;38;2;136;136;136:*.deb=4;38;2;250;208;122:*.wav=0;38;2;218;208;133:*.zsh=0;38;2;129;151;191:*.awk=0;38;2;129;151;191:*.ipp=0;38;2;129;151;191:*.out=3;38;2;136;136;136:*.pgm=0;38;2;218;208;133:*.gif=0;38;2;218;208;133:*.rtf=0;38;2;102;135;153:*.img=4;38;2;250;208;122:*.epp=0;38;2;129;151;191:*.tmp=3;38;2;136;136;136:*.elm=0;38;2;129;151;191:*.ogg=0;38;2;218;208;133:*.dll=1;38;2;255;185;100:*.ini=0;38;2;153;173;106:*.inl=0;38;2;129;151;191:*.com=1;38;2;255;185;100:*.sbt=0;38;2;129;151;191:*.asa=0;38;2;129;151;191:*.xcf=0;38;2;218;208;133:*.txt=0;38;2;121;157;106:*.tif=0;38;2;218;208;133:*.bmp=0;38;2;218;208;133:*.log=3;38;2;136;136;136:*.ods=0;38;2;102;135;153:*.git=3;38;2;136;136;136:*.mp3=0;38;2;218;208;133:*.avi=0;38;2;218;208;133:*.fsi=0;38;2;129;151;191:*.bak=3;38;2;136;136;136:*.csx=0;38;2;129;151;191:*.cgi=0;38;2;129;151;191:*.rst=0;38;2;102;135;153:*.bst=0;38;2;153;173;106:*.fls=3;38;2;136;136;136:*.clj=0;38;2;129;151;191:*.mov=0;38;2;218;208;133:*.mkv=0;38;2;218;208;133:*.mpg=0;38;2;218;208;133:*.sql=0;38;2;129;151;191:*.ppm=0;38;2;218;208;133:*.dmg=4;38;2;250;208;122:*.bz2=4;38;2;250;208;122:*.tex=0;38;2;129;151;191:*.conf=0;38;2;153;173;106:*.json=0;38;2;153;173;106:*.h264=0;38;2;218;208;133:*.hgrc=0;38;2;118;151;214:*.html=0;38;2;102;135;153:*.docx=0;38;2;102;135;153:*.psd1=0;38;2;129;151;191:*.epub=0;38;2;102;135;153:*.tiff=0;38;2;218;208;133:*.java=0;38;2;129;151;191:*.lock=3;38;2;136;136;136:*.tbz2=4;38;2;250;208;122:*.psm1=0;38;2;129;151;191:*.toml=0;38;2;153;173;106:*.jpeg=0;38;2;218;208;133:*.fish=0;38;2;129;151;191:*.orig=3;38;2;136;136;136:*.pptx=0;38;2;102;135;153:*.make=0;38;2;118;151;214:*.yaml=0;38;2;153;173;106:*.purs=0;38;2;129;151;191:*.lisp=0;38;2;129;151;191:*.flac=0;38;2;218;208;133:*.dart=0;38;2;129;151;191:*.diff=0;38;2;129;151;191:*.mpeg=0;38;2;218;208;133:*.rlib=3;38;2;136;136;136:*.xlsx=0;38;2;102;135;153:*.bash=0;38;2;129;151;191:*.less=0;38;2;129;151;191:*shadow=0;38;2;153;173;106:*.dyn_o=3;38;2;136;136;136:*README=1;38;2;101;194;84:*.mdown=0;38;2;102;135;153:*.xhtml=0;38;2;102;135;153:*.shtml=0;38;2;102;135;153:*.patch=0;38;2;129;151;191:*.class=3;38;2;136;136;136:*.cabal=0;38;2;129;151;191:*passwd=0;38;2;153;173;106:*.ipynb=0;38;2;129;151;191:*.toast=4;38;2;250;208;122:*.scala=0;38;2;129;151;191:*.cache=3;38;2;136;136;136:*.cmake=0;38;2;118;151;214:*.swift=0;38;2;129;151;191:*TODO.md=0;38;2;112;185;80:*LICENSE=3;38;2;153;173;106:*.ignore=0;38;2;118;151;214:*COPYING=3;38;2;153;173;106:*.dyn_hi=3;38;2;136;136;136:*.matlab=0;38;2;129;151;191:*.gradle=0;38;2;129;151;191:*.config=0;38;2;153;173;106:*INSTALL=1;38;2;101;194;84:*.groovy=0;38;2;129;151;191:*.flake8=0;38;2;118;151;214:*setup.py=0;38;2;118;151;214:*Makefile=0;38;2;118;151;214:*TODO.txt=0;38;2;112;185;80:*.gemspec=0;38;2;118;151;214:*.desktop=0;38;2;153;173;106:*Doxyfile=0;38;2;118;151;214:*.rgignore=0;38;2;118;151;214:*README.md=1;38;2;101;194;84:*configure=0;38;2;118;151;214:*.cmake.in=0;38;2;118;151;214:*.kdevelop=0;38;2;118;151;214:*.fdignore=0;38;2;118;151;214:*.markdown=0;38;2;102;135;153:*COPYRIGHT=3;38;2;153;173;106:*.DS_Store=3;38;2;136;136;136:*.scons_opt=3;38;2;136;136;136:*Dockerfile=0;38;2;153;173;106:*README.txt=1;38;2;101;194;84:*CODEOWNERS=0;38;2;118;151;214:*.gitconfig=0;38;2;118;151;214:*.localized=3;38;2;136;136;136:*INSTALL.md=1;38;2;101;194;84:*SConscript=0;38;2;118;151;214:*SConstruct=0;38;2;118;151;214:*.gitignore=0;38;2;118;151;214:*Makefile.am=0;38;2;118;151;214:*INSTALL.txt=1;38;2;101;194;84:*Makefile.in=3;38;2;136;136;136:*MANIFEST.in=0;38;2;118;151;214:*.gitmodules=0;38;2;118;151;214:*.synctex.gz=3;38;2;136;136;136:*LICENSE-MIT=3;38;2;153;173;106:*.travis.yml=0;38;2;143;191;220:*.applescript=0;38;2;129;151;191:*configure.ac=0;38;2;118;151;214:*CONTRIBUTORS=1;38;2;101;194;84:*.fdb_latexmk=3;38;2;136;136;136:*appveyor.yml=0;38;2;143;191;220:*.clang-format=0;38;2;118;151;214:*CMakeCache.txt=3;38;2;136;136;136:*LICENSE-APACHE=3;38;2;153;173;106:*.gitattributes=0;38;2;118;151;214:*CMakeLists.txt=0;38;2;118;151;214:*CONTRIBUTORS.md=1;38;2;101;194;84:*CONTRIBUTORS.txt=1;38;2;101;194;84:*.sconsign.dblite=3;38;2;136;136;136:*requirements.txt=0;38;2;118;151;214:*package-lock.json=3;38;2;136;136;136:*.CFUserTextEncoding=3;38;2;136;136;136'
