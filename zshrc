# Change zsh prompt
export PS1='%{$fg[green]%}%m:%~>%{$reset_color%} '

alias -g gp='| grep -i '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/aaron.tribou/.sdkman"
[[ -s "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/aaron.tribou/.sdkman/bin/sdkman-init.sh"

[ -d "$HOME/.maestro/bin" ] && export PATH=$PATH:$HOME/.maestro/bin

autoload -U +X bashcompinit && bashcompinit
[ -s "/opt/homebrew/bin/terraform" ] && complete -o nospace -C /opt/homebrew/bin/terraform terraform
