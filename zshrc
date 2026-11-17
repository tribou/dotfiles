# Load $fg / $reset_color before the prompt uses them
autoload -U colors && colors

# Change zsh prompt (show hostname only in SSH sessions). Double quotes expand
# the color codes now, so PROMPT_SUBST isn't needed.
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export PS1="%{$fg[green]%}%m:%~>%{$reset_color%} "
else
  export PS1="%{$fg[green]%}%~>%{$reset_color%} "
fi

alias -g gp='| grep -i '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# SDKMAN
if [ -d "$HOME/.sdkman" ]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

[ -d "$HOME/.maestro/bin" ] && export PATH=$PATH:$HOME/.maestro/bin

autoload -U +X bashcompinit && bashcompinit
[ -s "$(command -v terraform)" ] && complete -o nospace -C "$(command -v terraform)" terraform

# zoxide (modern directory switching)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi
