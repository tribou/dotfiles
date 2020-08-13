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

    echo
    echo "Installing Neovim"
    echo

    if   [ ! $(which fuse2fs)  ]
    then
      echo "Installing FUSE"
      sudo yum --enablerepo=epel -y install fuse-sshfs
      echo "Continuing Neovim Install..."
    fi

    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv ./nvim.appimage /usr/bin/nvim

    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi

  if   [ ! $(which fasd)  ]
  then
    echo "Installing fasd"
    curl -fLo fasd.zip https://github.com/clvv/fasd/archive/1.0.1.zip
    unzip fasd.zip -d fasd
    sudo cp ./fasd/fasd-1.0.1/fasd /usr/bin/fasd
    rm fasd.zip
    rm -r fasd
  fi
fi
