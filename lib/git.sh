#!/bin/bash

# shellcheck disable=SC2120 # called with args interactively; bare calls below are intentional
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
function _dotfiles_commit_sanitize_message ()
{
  printf '%s' "$1" | head -n1 | sed -E "s/^[\"'\`[:space:]]+//; s/[\"'\`[:space:]]+$//"
}

function _dotfiles_commit_prompt ()
{
  local ticket="$1"

  if [ -n "$ticket" ]
  then
    printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use plain imperative mood (e.g. "fix the thing"). Do not add a type or scope prefix like "feat:" or "fix(scope):" -- a ticket prefix will be added separately. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
  else
    printf '%s' 'Write a one-line git commit message summarizing the staged diff. Use Conventional Commits style (e.g. "fix(scope): summary") when it fits, otherwise a plain imperative summary. Output a single line only, with no surrounding quotes or backticks, no Co-Authored-By line, and no other text.'
  fi
}

function _dotfiles_commit_backend ()
{
  local backend="${DOTFILES_COMMIT_BACKEND:-opencode}"
  case "$backend" in
    claude|opencode|agy) printf '%s' "$backend" ;;
    *)
      printf 'unknown DOTFILES_COMMIT_BACKEND=%s, using opencode\n' "$backend" >&2
      printf '%s' 'opencode'
      ;;
  esac
}

function _dotfiles_commit_model ()
{
  local backend="$1"
  if [ -n "${DOTFILES_COMMIT_MODEL:-}" ]
  then
    printf '%s' "$DOTFILES_COMMIT_MODEL"
    return 0
  fi
  case "$backend" in
    opencode) printf '%s' 'opencode-go/kimi-k2.7-code' ;;
    agy)      printf '%s' 'gemini-3.7-flash-low' ;;
    *)        printf '%s' 'haiku' ;;
  esac
}

function _dotfiles_commit_timeout ()
{
  local timeout_secs="${DOTFILES_COMMIT_TIMEOUT:-15}"
  case "$timeout_secs" in
    ''|*[!0-9]*) timeout_secs=15 ;;
  esac
  printf '%s' "$timeout_secs"
}

function _dotfiles_spinner_wait ()
{
  local pid="$1"
  local label="$2"
  local timeout_secs="${3:-0}"
  local interrupted=0
  local is_tty=0
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local frame_index=0

  # Enable a timeout only for a positive integer; anything else means "wait forever".
  local max_iterations=0
  if [ "$timeout_secs" -gt 0 ] 2> /dev/null
  then
    max_iterations=$(( timeout_secs * 10 ))
  fi
  local iterations=0

  trap 'interrupted=1' INT

  if [ -t 2 ]
  then
    is_tty=1
  else
    printf '%s\n' "$label" >&2
  fi

  while kill -0 "$pid" 2> /dev/null
  do
    if [ "$interrupted" -eq 1 ]
    then
      kill "$pid" 2> /dev/null
      [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2
      trap - INT
      return 130
    fi

    if [ "$max_iterations" -gt 0 ] && [ "$iterations" -ge "$max_iterations" ]
    then
      kill "$pid" 2> /dev/null
      [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2
      trap - INT
      return 124
    fi

    if [ "$is_tty" -eq 1 ]
    then
      printf '\r%s %s' "${frames[frame_index]}" "$label" >&2
      frame_index=$(( (frame_index + 1) % 10 ))
    fi

    sleep 0.1
    iterations=$(( iterations + 1 ))
  done

  [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2

  wait "$pid"
  local status=$?
  trap - INT
  return "$status"
}

function _dotfiles_commit_generate_message ()
{
  local ticket="$1"

  local backend model timeout_secs
  backend=$(_dotfiles_commit_backend)
  model=$(_dotfiles_commit_model "$backend")
  timeout_secs=$(_dotfiles_commit_timeout)

  if ! command -v "$backend" > /dev/null 2>&1
  then
    return 1
  fi

  local outfile
  outfile=$(mktemp)

  case "$backend" in
    opencode)
      git diff --cached | head -c 100000 \
        | opencode run --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
          > "$outfile" 2> /dev/null &
      ;;
    agy)
      git diff --cached | head -c 100000 \
        | agy --add-dir "$PWD" --model "$model" --print "$(_dotfiles_commit_prompt "$ticket")" \
          > "$outfile" &
      ;;
    *)
      git diff --cached | head -c 100000 \
        | claude -p --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
          > "$outfile" &
      ;;
  esac
  local pid=$!

  local backend_label
  backend_label="$(printf '%s' "$backend" | head -c 1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$backend" | tail -c +2)"
  _dotfiles_spinner_wait "$pid" "Asking ${backend_label} for a commit message..." "$timeout_secs"
  local wait_status=$?

  if [ "$wait_status" -eq 130 ]
  then
    rm -f "$outfile"
    return 130
  fi

  if [ "$wait_status" -eq 124 ]
  then
    rm -f "$outfile"
    return 124
  fi

  if [ "$wait_status" -ne 0 ]
  then
    rm -f "$outfile"
    return 1
  fi

  local raw
  raw=$(cat "$outfile")
  rm -f "$outfile"

  local sanitized
  sanitized=$(_dotfiles_commit_sanitize_message "$raw")

  if [ -z "$sanitized" ]
  then
    return 1
  fi

  printf '%s' "$sanitized"
}

function commit ()
{
  case "$1" in
    status)
      local b m t avail=no
      b=$(_dotfiles_commit_backend)
      m=$(_dotfiles_commit_model "$b")
      t=$(_dotfiles_commit_timeout)
      command -v "$b" > /dev/null 2>&1 && avail=yes
      printf 'backend:   %s\nmodel:     %s\ntimeout:   %ss\navailable: %s\n' "$b" "$m" "$t" "$avail"
      return 0
      ;;
    backend)
      shift
      if [ -z "$1" ]
      then
        printf '%s\n' "$(_dotfiles_commit_backend)"
        return 0
      fi
      case "$1" in
        claude|opencode|agy)
          export DOTFILES_COMMIT_BACKEND="$1"
          printf 'commit backend set to %s (model: %s) for this shell\n' \
            "$1" "$(_dotfiles_commit_model "$1")"
          return 0
          ;;
        *)
          printf 'unknown backend: %s (expected claude, opencode, or agy)\n' "$1" >&2
          return 1
          ;;
      esac
      ;;
  esac

  if [ -f "./.git/MERGE_HEAD" ]
  then
    # If committing a git merge, accept the default message
    # shellcheck disable=SC2119 # commit() never forwards args to c
    c
    return
  fi

  git add -A

  if git diff --cached --quiet
  then
    echo "nothing to commit"
    return 0
  fi

  local ticket
  ticket=$(git branch --show-current 2> /dev/null | _dotfiles_grep_ticket_number)

  local generated
  generated=$(_dotfiles_commit_generate_message "$ticket")
  local generate_status=$?

  if [ "$generate_status" -eq 130 ]
  then
    echo "commit canceled" >&2
    return 130
  fi

  if [ "$generate_status" -eq 124 ]
  then
    echo "$(_dotfiles_commit_backend) timed out after $(_dotfiles_commit_timeout)s, falling back to manual commit" >&2
    # shellcheck disable=SC2119 # commit() never forwards args to c
    c
    return
  fi

  if [ -z "$generated" ]
  then
    echo "$(_dotfiles_commit_backend) unavailable, falling back to manual commit" >&2
    # shellcheck disable=SC2119 # commit() never forwards args to c
    c
    return
  fi

  local message
  message=$(_dotfiles_commit_message "$ticket" "$generated")

  git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status
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
    RESULT=$({
      git for-each-ref refs/heads --sort=-committerdate --format='%(refname:short)'
      git for-each-ref refs/remotes --sort=-committerdate --format='%(refname:strip=3)' | grep -v '^HEAD$'
    } | sort -u | fzf --preview-window wrap)
    if [ -n "$RESULT" ]
    then
      local SCRIPT="git checkout \"$RESULT\""
      _eval_script "$SCRIPT && _dotfiles_git_status"
    fi
  fi
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
  read -r -p "Run 'git branch -D $1'? (y/n): " confirm \
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
    RESULT=$({
      git for-each-ref refs/heads --sort=-committerdate --format='%(refname:short)'
      git for-each-ref refs/remotes --sort=-committerdate --format='%(refname:strip=3)' | grep -v '^HEAD$'
    } | sort -u | fzf --preview-window wrap --color)
    if [ -n "$RESULT" ]
    then
      local SCRIPT="git branch -d \"$RESULT\" || _dotfiles_prompt_git_branch_delete \"$RESULT\""
      _eval_script "$SCRIPT"
    fi
  fi
}

function wtc ()
{
  if [ -z "$1" ]
  then
    echo "Usage: wtc <branch-name>" >&2
    return 1
  fi

  local BRANCH="$1"
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
  local GITIGNORE="$REPO_ROOT/.gitignore"

  if ! grep -qF '.worktrees/' "$GITIGNORE" 2>/dev/null
  then
    echo '.worktrees/' >> "$GITIGNORE"
    echo "Added .worktrees/ to .gitignore"
  fi

  mkdir -p "$(dirname "$WORKTREE_PATH")"
  git worktree add -b "$BRANCH" "$WORKTREE_PATH" || return

  if [ -d "$REPO_ROOT/.claude" ]
  then
    cp -r "$REPO_ROOT/.claude" "$WORKTREE_PATH/.claude"
  fi

  cd "$WORKTREE_PATH" || return
}

function wt ()
{
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local RESULT
  RESULT=$(git worktree list | fzf --preview-window wrap --color)

  if [ -n "$RESULT" ]
  then
    cd "$(echo "$RESULT" | awk '{print $1}')" || return
  fi
}

function wtd ()
{
  local REPO_ROOT
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]
  then
    echo "Not in a git repository" >&2
    return 1
  fi

  local WORKTREE_PATH BRANCH

  if [ -n "$1" ]
  then
    BRANCH="$1"
    WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
  else
    local RESULT
    RESULT=$(git worktree list | tail -n +2 | fzf --preview-window wrap --color)
    if [ -z "$RESULT" ]
    then
      return 0
    fi
    WORKTREE_PATH=$(echo "$RESULT" | awk '{print $1}')
    BRANCH=$(echo "$RESULT" | sed -E 's/.*\[([^]]+)\].*/\1/')
  fi

  # If CWD is inside the worktree we're about to delete, cd out first
  if [[ "$PWD" == "$WORKTREE_PATH"* ]]; then
    local MAIN_REPO
    MAIN_REPO=$(dirname "$(git rev-parse --git-common-dir)")
    cd "$MAIN_REPO" || return
  fi

  local _wtd_remove_err
  if ! _wtd_remove_err=$(git worktree remove "$WORKTREE_PATH" 2>&1); then
    if [ -d "$WORKTREE_PATH" ]; then
      if echo "$_wtd_remove_err" | grep -q "submodule"; then
        # git worktree remove (even --force) cannot remove worktrees containing
        # submodules; fall back to manual removal
        rm -rf "$WORKTREE_PATH" && git worktree prune || return
      else
        echo
        read -r -p "Worktree has uncommitted changes. Run 'git worktree remove --force $WORKTREE_PATH'? (y/n): " confirm \
          && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] \
          || return 1
        git worktree remove --force "$WORKTREE_PATH" || return
      fi
    else
      git worktree prune || return
    fi
  fi
  git branch -d "$BRANCH" || _dotfiles_prompt_git_branch_delete "$BRANCH"
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
alias amend='git commit --amend && _dotfiles_git_log_commit && _dotfiles_git_status'
alias b='git branch -a --sort=-committerdate'
alias cherry='git cherry-pick -x'
alias cod='co develop'
alias cop='co prod'
alias com='co main'
alias cos='co staging'
alias convert-crlf-lf='git ls-files -z | xargs -0 dos2unix'
alias fed='f origin develop:develop'
alias fem='f origin main:main'
alias fep='f origin prod:prod'
alias fes='f origin staging:staging'
alias fet='f origin test:test'
alias filetypes="git ls-files | sed 's/.*\.//' | sort | uniq -c"
alias fix='git commit --amend -a --no-edit && _dotfiles_git_log_commit && _dotfiles_git_status'
# shellcheck disable=SC2142
alias gall='echo; echo; git log --oneline --all --graph --decorate  $(git reflog | awk '"'"'{print $1}'"'"')'
# shellcheck disable=SC2142
alias gall2='echo; echo; git log --oneline --all --graph --decorate --date=local --date=short --pretty=format:"%C(yellow)%h %C(cyan)%ad%C(auto)%d %Creset%s %C(blue)<%aN>" $(git reflog | awk '"'"'{print $1}'"'"')'
alias gbdr='git branch -d -r'
alias gd='git diff'
alias gds='git diff --staged'
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
alias md='merge develop'
alias mm='merge main'
alias mp='merge prod'
alias ms='merge staging'
alias r='git remote -v'
alias revert='git revert HEAD'
alias s='_dotfiles_git_status'
alias t='echo; echo; git tree'
alias tag='git tag -s -m ""'
alias tint='_dotfiles_git_log_branch_diff'
alias to='echo; echo; git tree-one'
alias tone='echo; echo; git tree-one'
alias ts='echo; echo; git tree-short'
