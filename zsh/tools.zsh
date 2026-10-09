(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# zsh-vi-mode last: it rebinds keys
ZVM_VI_EDITOR="nvim-editor"
for f in /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh \
         $HOME/.local/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh; do
  [[ -f $f ]] && { source $f; break }
done
