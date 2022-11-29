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

  if   [ ! -s "$(which nvim)"  ]
  then

    echo
    echo "Installing Neovim"
    echo

    if   [ ! -s "$(which fuse2fs)"  ]
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

  # if   [ ! -s "$(which fasd)"  ]
  # then
  #   echo "Installing fasd"
  #   curl -fLo /tmp/fasd.zip https://github.com/clvv/fasd/archive/1.0.1.zip
  #   unzip /tmp/fasd.zip -d /tmp/fasd
  #   sudo cp /tmp/fasd/fasd-1.0.1/fasd /usr/bin/fasd
  #   rm /tmp/fasd.zip
  #   rm -r /tmp/fasd
  # fi

  if [ ! -f "$HOME/dev/z/z.sh" ]
  then
    echo "Installing z"
    git clone --depth 1 https://github.com/rupa/z.git ~/dev/z
    . "$HOME/dev/z/z.sh"
  fi

  if [ ! -s "$(which fzf)"  ]
  then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi

  if [ ! -s "$(which tmux)"  ]
  then
    echo "Installing tmux"
    curl -fLo /tmp/tmux https://github.com/tmux/tmux/releases/download/3.1b/tmux-3.1b-x86_64.AppImage
    chmod u+x /tmp/tmux
    sudo mv /tmp/tmux /usr/bin/tmux
  fi

  if [ ! -d "$HOME/.rbenv/bin" ] && [ ! -s "$(which rbenv)"  ]
  then
    echo "Installing rbenv"
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    eval "$(rbenv init -)"
  fi

  if [ -z "$(ls -A $HOME/.rbenv/versions/)" ]
  then
    echo "Installing latest ruby version"
    rbenv install $(rbenv install -l | grep -v - | tail -1)
    rbenv global $(rbenv install -l | grep -v - | tail -1)
  fi

  if [ ! -d "$HOME/.pyenv/bin" ] && [ ! -s "$(which pyenv)"  ]
  then
    echo "Installing pyenv"
    curl https://pyenv.run | bash
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv install 3.11.0
    pyenv global 3.11.0
  fi

  if [ ! -d "$HOME/.pyenv/versions/py3nvim" ]
  then
    echo "Installing py3nvim virtualenv"
    pyenv virtualenv 3.11.0 py3nvim
    eval "$(pyenv virtualenv-init -)"
    pyenv activate py3nvim
    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade pynvim
    pyenv deactivate
  fi

  if [ ! -s "$(which pyls)" ]
  then
    echo "Installing python-language-server (pyls)"
    python3 -m pip install --upgrade pyls
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
