#!/bin/bash

if [ -s "$(which yum)" ]
then

  if   [ ! $(which gpg)  ]
  then
    echo "Installing GPG"
    sudo yum install -y gnupg
  fi

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

    curl -fLo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/bin/nvim

    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi

  if   [ ! $(which fasd)  ]
  then
    echo "Installing fasd"
    curl -fLo /tmp/fasd.zip https://github.com/clvv/fasd/archive/1.0.1.zip
    unzip /tmp/fasd.zip -d /tmp/fasd
    sudo cp /tmp/fasd/fasd-1.0.1/fasd /usr/bin/fasd
    rm /tmp/fasd.zip
    rm -r /tmp/fasd
  fi

  if   [ ! $(which fzf)  ]
  then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi

  if   [ ! $(which tmux)  ]
  then
    echo "Installing tmux"
    curl -fLo /tmp/tmux https://github.com/tmux/tmux/releases/download/3.1b/tmux-3.1b-x86_64.AppImage
    chmod u+x /tmp/tmux
    sudo mv /tmp/tmux /usr/bin/tmux
  fi

  if   [ ! -d "$HOME/.rbenv/bin" ] && [ ! $(which rbenv)  ]
  then
    echo "Installing rbenv"
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    eval "$(rbenv init -)"
    rbenv install 2.7.1
    rbenv global 2.7.1
  fi

  if   [ ! -d "$HOME/.pyenv/bin" ] && [ ! $(which pyenv)  ]
  then
    echo "Installing pyenv"
    curl https://pyenv.run | bash
    pip install --upgrade pip
  fi

  if   [ ! -d "$HOME/.pyenv/versions/py2nvim" ]
  then
    echo "Installing py2nvim virtualenv"
    pyenv install 2.7.18
    pyenv virtualenv 2.7.18 py2nvim
    eval "$(pyenv virtualenv-init -)"
    pyenv activate py2nvim
    pip install --upgrade pip
    pip install --upgrade pynvim
  fi

  if   [ ! -d "$HOME/.pyenv/versions/py3nvim" ]
  then
    echo "Installing py3nvim virtualenv"
    pyenv install 3.8.2
    pyenv virtualenv 3.8.2 py3nvim
    eval "$(pyenv virtualenv-init -)"
    pyenv activate py3nvim
    pip install --upgrade pip
    pip install --upgrade pynvim
  fi

  if   [ ! -f "/etc/profile.d/bash_completion.sh" ]
  then
    echo "Installing bash-completion"
    sudo yum install -y bash-completion bash-completion-extras
  fi

  if   [ ! $(which rg)  ]
  then
    echo "Installing Ripgrep"
    sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
    sudo yum install -y ripgrep
  fi

  echo "Done."
fi