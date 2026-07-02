#!/bin/bash

# FZF functions

# fcoc - checkout git commit
function fcoc ()
{
  local commits commit
  commits=$(git tree --color=always) &&
  commit=$(echo "$commits" | fzf --reverse --no-sort +m -e --ansi) &&
  git checkout "$(echo "$commit" | sed 's/^[^][a-z0-9]*//' | sed 's/ .*//')"
}

# fshow - git commit browser
function fshow ()
{
  git tree --color=always "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# https://github.com/junegunn/fzf/wiki/examples#opening-files
# Modified version where you can press
#   - CTRL-O to open with `open` command,
#   - CTRL-E or Enter key to open with the $EDITOR
fo() {
  IFS=$'\n' out=("$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)")
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
    [ "$key" = ctrl-o ] && open "$file" || ${EDITOR:-vim} "$file"
  fi
}

# Zoxide replaces custom fzf-z overrides natively with 'zi'

# _dotfiles_beads_show - interactive beads issue browser with fzf
# Aliases: bdr (beads read), bds (beads show)
function _dotfiles_beads_show() {
  local issue_id
  issue_id=$(bd list --all | fzf --ansi --reverse \
    --preview 'bd show {2}' \
    --preview-window up:60%:wrap | awk '{print $2}')
  [[ -n "$issue_id" ]] && bd show "$issue_id"
}
alias bdr='_dotfiles_beads_show'
alias bds='_dotfiles_beads_show'

# _dotfiles_ghv_show - interactive GitHub issue and PR browser with fzf
# Aliases: ghv
function _dotfiles_ghv_show() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository." >&2
    return 1
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed." >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed." >&2
    return 1
  fi

  # Fetch issues and PRs in JSON format
  local issues prs
  issues=$(gh issue list --json number,title,labels,updatedAt --limit 1000 2>/dev/null)
  local status_issues=$?
  prs=$(gh pr list --json number,title,labels,updatedAt --limit 1000 2>/dev/null)
  local status_prs=$?

  if [[ $status_issues -ne 0 && $status_prs -ne 0 ]]; then
    echo "Error: Failed to fetch issues and PRs from GitHub. Check your authentication and repository remote." >&2
    return 1
  fi

  local combined
  combined=$(
    {
      if [[ -n "$issues" && "$issues" != "[]" ]]; then
        echo "$issues" | jq -r '.[] | "issue\t#\(.number)\t\(.title)\t\(.labels | map(.name) | join(","))"' | while IFS=$'\t' read -r type num title labels; do
          printf "\033[36m%-6s\033[0m  \033[1;37m%-5s\033[0m  %-50s  \033[33m%s\033[0m\n" "$type" "$num" "$title" "$labels"
        done
      fi
      if [[ -n "$prs" && "$prs" != "[]" ]]; then
        echo "$prs" | jq -r '.[] | "pr\t#\(.number)\t\(.title)\t\(.labels | map(.name) | join(","))"' | while IFS=$'\t' read -r type num title labels; do
          printf "\033[32m%-6s\033[0m  \033[1;37m%-5s\033[0m  %-50s  \033[33m%s\033[0m\n" "$type" "$num" "$title" "$labels"
        done
      fi
    }
  )

  if [[ -z "$combined" ]]; then
    echo "No open issues or PRs found."
    return 0
  fi

  local selection
  selection=$(printf '%s\n' "$combined" | fzf --ansi --reverse \
    --preview '
      clean_line=$(printf '\''%s\n'\'' "{}" | sed -E "s/$(printf '\''\033'\'')\[[0-9;]*m//g")
      type=$(printf '\''%s\n'\'' "$clean_line" | awk "{print \$1}")
      num=$(printf '\''%s\n'\'' "$clean_line" | awk "{print \$2}" | tr -d "#")
      if [ -n "$num" ]; then
        if [ "$type" = "pr" ]; then
          gh pr view "$num"
        else
          gh issue view "$num"
        fi
      fi
    ' \
    --preview-window up:60%:wrap)

  [[ -z "$selection" ]] && return 0

  local clean_line type num
  clean_line=$(printf '%s\n' "$selection" | sed -E "s/$(printf '\033')\[[0-9;]*m//g")
  type=$(printf '%s\n' "$clean_line" | awk '{print $1}')
  num=$(printf '%s\n' "$clean_line" | awk '{print $2}' | tr -d '#')

  if [[ "$type" == "pr" ]]; then
    gh pr view "$num" "$@"
  else
    gh issue view "$num" "$@"
  fi
}
alias ghv='_dotfiles_ghv_show'

