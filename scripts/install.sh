#!/bin/bash

if [ -s "$(which yum)" ]
then

  if   [ ! -s "$(which gpg)"  ]
  then
    echo "Installing GPG"
    sudo yum install -y gnupg
  fi

  if   [ ! -s "$(which yarn)"  ]
  then
    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    echo "Adding Yarn rpm"
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
    echo "Installing Yarn"
    sudo yum install -y yarn
  fi

  if [ ! -s "$(which tmux)"  ]
  then
    echo "Installing tmux"
    brew install tmux@3.1
  fi

  if   [ ! -s "$(which nvim)"  ]
  then

    echo
    echo "Installing Neovim"
    echo

    if   [ ! -s "$(which fuse2fs)"  ]
    then
      echo "Installing FUSE"
      sudo yum --enablerepo=epel -y install fuse-sshfs
    fi

    echo "Continuing Neovim Install..."
    curl -fLo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/bin/nvim
  fi

  if [ ! -f "/etc/profile.d/bash_completion.sh" ]
  then
    echo "Installing bash-completion"
    sudo yum install -y bash-completion bash-completion-extras
  fi

  if [ ! -s "$(which rg)"  ]
  then
    echo "Installing Ripgrep"
    sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
    sudo yum install -y ripgrep
  fi

  echo "Done."
else
  echo "Yum not found."
fi
