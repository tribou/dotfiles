#!/bin/bash
function claude-keepalive() {
  if tmux has-session -t claude-keepalive 2>/dev/null; then
    echo "Claude keep-alive is already running!"
  else
    tmux new-session -d -s claude-keepalive
    # Use single quotes around the loop so $! doesn't evaluate early in your current shell
    # shellcheck disable=SC2016
    tmux send-keys -t claude-keepalive 'while true; do claude --resume & PID=$!; sleep 15; kill $PID 2>/dev/null; sleep 21600; done' C-m
    echo "Claude keep-alive started in the background!"
  fi
}

# Stop the Claude keep-alive loop
function claude-keepalive-stop() {
  tmux kill-session -t claude-keepalive 2>/dev/null
  echo "Claude keep-alive stopped."
}
llm() { local _d; _d=$(printf '%q' "$PWD"); sudo -u agent -i bash -c "cd $_d && exec bash -li"; }
agent-grant() {
  local target="${1:-$PWD}"
  local dotfiles="${DOTFILES:-$HOME/dev/dotfiles}"
  read -rp "Grant agent group access to '$target'? (y/n): " confirm
  [[ "$confirm" == [yY] ]] || { echo "Aborted."; return 1; }
  sudo bash "$dotfiles/agent/setup-user.sh" --grant "$target"
}
