#!/bin/bash

if [ -s "$(which yum)" ]
then

  if   [ ! $(which yarn)  ]
  then
    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    echo "Adding Yarn rpm"
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
    echo "Installing Yarn"
    sudo yum install -y yarn
  fi

  if   [ ! $(which nvim)  ]
  then
    echo "Installing Neovim"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    ./nvim.appimage
  fi
fi
