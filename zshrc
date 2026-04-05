# Change zsh prompt (show hostname only in SSH sessions)
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export PS1='%{$fg[green]%}%m:%~>%{$reset_color%} '
else
  export PS1='%{$fg[green]%}%~>%{$reset_color%} '
fi

alias -g gp='| grep -i '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/aaron.tribou/.sdkman"
[[ -s "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh"

[ -d "$HOME/.maestro/bin" ] && export PATH=$PATH:$HOME/.maestro/bin

autoload -U +X bashcompinit && bashcompinit
[ -s "$(command -v terraform)" ] && complete -o nospace -C "$(command -v terraform)" terraform
