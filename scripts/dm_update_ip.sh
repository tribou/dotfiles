#!/bin/bash -l

function dmupdate {

  # Host aliases to set
  DM_HOSTS='dm dockerhost'

  # Get docker-vm IP
  DM_IP=`docker-machine ip docker-vm`

  # If the IP is available
  if [ "$DM_IP"  ]; then 

	# Check if hosts ip is same as docker-vm ip
	if [ "`echo -e "$DM_IP\t$DM_HOSTS"`" == "`awk "/\t$DM_HOSTS\$/" /etc/hosts`"   ]; then	
		echo "docker-vm IP $DM_IP doesn't need to update"
		return
	fi

  	# Save hosts temp file without dm entry
  	awk "!/\t$DM_HOSTS\$/" /etc/hosts > /tmp/hosts

	# Add dm entry to temp file
	echo -e "$DM_IP\t$DM_HOSTS" >> /tmp/hosts

	# Move temp file to /etc/hosts
	sudo mv /tmp/hosts /etc/hosts

  fi

}

