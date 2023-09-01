#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs..
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# k8s.
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k

# anyenv.
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

eval "$(direnv hook bash)"

function topri() {
  git config --global user.name kanChome
  git config --global user.email study.hellbird@gmail.com 
}

function towork() {
  git config --global user.name ryo.hirano 
  git config --global user.email ryo.hirano@monocrea.co.jp 
}
setopt auto_cd
function history-all { history -E 1 }

export HISTSIZE=1000

export SAVEHIST=100000

bindkey '^h' zaw-history

setopt share_history

setopt hist_ignore_dups

setopt EXTENDED_HISTORY

setopt hist_ignore_all_dups

setopt hist_ignore_space

setopt hist_verify

setopt hist_reduce_blanks

setopt hist_save_no_dups

setopt hist_expand

setopt inc_append_history

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
export HISTTIMEFORMAT="%F %T "
