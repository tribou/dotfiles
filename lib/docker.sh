#!/bin/bash
function restart-docker ()
{
  if ! is_macos; then
    echo "restart-docker is not supported on Linux. Use: sudo systemctl restart docker"
    return 1
  fi
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
alias d='docker'
alias dc='docker compose'
alias docker-compose='docker compose'
alias di='docker images'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias drm='docker rm'
alias drma='docker ps -aq | xargs docker rm -f'
alias drmi='docker rmi'
