#!/bin/bash

# FZF functions

# fcoc - checkout git commit
function fcoc ()
{
  local commits commit
  commits=$(git tree --color=always) &&
  commit=$(echo "$commits" | fzf --reverse --no-sort +m -e --ansi) &&
  git checkout $(echo "$commit" | sed 's/^[^][a-z0-9]*//' | sed 's/ .*//')
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
