#!/bin/bash -l






# Returns the write command for the system clipboard (no args: just the command string).
function _dotfiles_clipboard_write_cmd ()
{
  if [ -n "$(command -v pbcopy)" ]; then
    echo "pbcopy"
  elif [ -n "$(command -v xclip)" ]; then
    echo "xclip -selection clipboard"
  fi
}

# Returns the read command for the system clipboard.
function _dotfiles_clipboard_read_cmd ()
{
  if [ -n "$(command -v pbpaste)" ]; then
    echo "pbpaste"
  elif [ -n "$(command -v xclip)" ]; then
    echo "xclip -o -sel clipboard"
  fi
}

function copy_to_clipboard ()
{
  local cmd
  cmd="$(_dotfiles_clipboard_write_cmd)"
  [ -n "$cmd" ] && eval "$cmd"
}






function histgrep ()
{
  # Remove histfile directory prefix during fzf search
  local AWK_REMOVE_HISTDIR='^/.*/[.]history/'

  # Pipe results from two history sources into cat
  local RESULT
  # shellcheck disable=SC2012
  RESULT=$(cat \
    <(history | grep "$1") \
    <(ls -d "$HOME"/.history/20*/* \
      | sort -r -n \
      | xargs grep -r "$1" \
      | awk -F "$AWK_REMOVE_HISTDIR" '{print $NF}') \
    | fzf --tmux="70%,80%" \
    | awk -F "$DOTFILES_HISTFILE_DELIM" '{print $NF}' \
    | awk -F "$DOTFILES_HISTORY_DELIM" '{print $NF}')

  # If in tmux, we can use send-keys
  if [ -n "$TMUX" ]
  then
    tmux send-keys -t "$TMUX_PANE" "$RESULT"
  else
    echo "$RESULT"
    printf '%s' "$RESULT" | copy_to_clipboard
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


function paste_from_clipboard ()
{
  local cmd
  cmd="$(_dotfiles_clipboard_read_cmd)"
  [ -n "$cmd" ] && eval "$cmd"
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





function bashcheck ()
{
  local files=("$@")

  # Default: find all .sh files recursively, excluding common vendor dirs
  if [[ ${#files[@]} -eq 0 ]]; then
    mapfile -t files < <(find . -name "*.sh" \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" \
      -not -path "*/vendor/*" | sort)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .sh files found"
    return 1
  fi

  local errors=0
  local has_shellcheck
  command -v shellcheck &>/dev/null && has_shellcheck=1

  for file in "${files[@]}"; do
    echo "==> $file"
    if [[ ! -f "$file" ]]; then
      echo "bashcheck: $file: No such file"
      errors=$((errors + 1))
      continue
    fi
    # bats' `@test "..." { ... }` syntax isn't valid raw bash, so bash -n
    # always misfires on .bats files; shellcheck understands bats syntax
    # natively, so skip bash -n for that extension and rely on shellcheck.
    if [[ "$file" != *.bats ]]; then
      bash -n "$file" || errors=$((errors + 1))
    fi
    if [[ -n "$has_shellcheck" ]]; then
      shellcheck "$file" || errors=$((errors + 1))
    fi
  done

  echo
  if [[ $errors -eq 0 ]]; then
    echo "All files passed"
  else
    echo "$errors check(s) failed"
    return 1
  fi
}

# Command aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ack='ag'
alias ag='rg'
alias back='cd "$OLDPWD"'
alias be='bundle exec'
alias bfg='java -jar /usr/local/bin/bfg.jar'
alias convert-tabs-spaces="replace '	' '  '"
alias count='sed "/^\s*$/d" | wc -l | xargs'

alias hg='histgrep'
alias less='less -R'
alias ll='ls -lah'
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias lt='ls -lath'
alias mr='mise-run'
alias prettyjson='python3 -m json.tool'
alias sprofile='. ~/.bash_profile'
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias top='top -o cpu'
else
  alias top='top -o %CPU'
fi
alias tree='tree -I "bower_components|dist|node_modules|temp|tmp"'
alias unsetdotglob='shopt -u dotglob'
alias v='nvim'
alias vc='vimcat'
alias youcompleteme-install='cd ~/.vim/plugged/YouCompleteMe; ./install.py --clang-completer --gocode-completer --tern-completer; cd "$OLDPWD"'
