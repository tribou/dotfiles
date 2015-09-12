#!/bin/bash -l

function dmupdate {

  # Get docker-vm IP
  DM_IP=`docker-machine ip docker-vm`

  # If the IP is available
  if [ "$DM_IP"  ]; then 

	# Check if hosts ip is same as docker-vm ip
	if [ "`echo -e "$DM_IP\tdm"`" == "`awk '/\tdm$/' /etc/hosts`"  ]; then
		echo "docker-vm IP $DM_IP doesn't need to update"
		return
	fi

  	# Save hosts temp file without dm entry
  	awk '!/\tdm$/' /etc/hosts > /tmp/hosts

	# Add dm entry to temp file
	echo -e "$DM_IP\tdm" >> /tmp/hosts

	# Move temp file to /etc/hosts
	sudo mv /tmp/hosts /etc/hosts

  fi

}

