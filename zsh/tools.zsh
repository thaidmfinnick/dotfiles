(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# zsh-vi-mode last: it rebinds keys
ZVM_VI_EDITOR="nvim-editor"
[[ -f /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]] &&
  source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
