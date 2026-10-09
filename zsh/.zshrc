# Load order: */path.zsh -> oh-my-zsh -> other */*.zsh -> */completion.zsh -> ~/.zshrc.local

# Repo root, resolved through the ~/.zshrc symlink
export DOTFILES=${${(%):-%x}:A:h:h}

typeset -U path config_files
config_files=($DOTFILES/*/*.zsh(N))

for file in ${(M)config_files:#*/path.zsh}; do source $file; done

export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$DOTFILES/zsh/omz"
ZSH_THEME="headline"
plugins=(git)
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

for file in ${config_files:#*/(path|completion).zsh}; do source $file; done

for file in ${(M)config_files:#*/completion.zsh}; do source $file; done

unset file config_files

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Pancake Work agent-team orchestrator (pw plugin)
alias pw='claude --agent pw:orchestrator'
