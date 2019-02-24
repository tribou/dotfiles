#!/bin/bash -l

function dmupdate {

  # Host aliases to set
  local DM_HOSTS='dm dockerhost'

  # If host is running
  local DM_RUNNING=`dm ls --filter driver=virtualbox --filter state=Running --format "{{.Name}}"`

  # If the IP is available
  if [[ -z "$DM_RUNNING"  ]]
  then
    echo 'Local virtualbox docker host is not running. Skipping IP update'
    return
  fi

  # Get docker-vm IP
  local DM_IP=`docker-machine ip docker-vm`

	# Check if hosts ip is same as docker-vm ip
	if [[ "`echo -e "$DM_IP\t$DM_HOSTS"`" == "`awk "/\t$DM_HOSTS\$/" /etc/hosts`"   ]]
  then
		echo "docker-vm IP $DM_IP doesn't need to update"
		return
	fi

  	# Save hosts temp file without dm entry
  	awk "!/\t$DM_HOSTS\$/" /etc/hosts > /tmp/hosts

	# Add dm entry to temp file
	echo -e "$DM_IP\t$DM_HOSTS" >> /tmp/hosts

	# Move temp file to /etc/hosts
  echo "Updating docker-vm IP to $DM_IP"
	sudo mv /tmp/hosts /etc/hosts
}
