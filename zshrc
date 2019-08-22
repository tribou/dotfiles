# Change zsh prompt
export PS1='%{$fg[green]%}%m:%~>%{$reset_color%} '

alias -g gp='| grep -i '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
