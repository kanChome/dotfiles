# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zinit install
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

### zinit config
zinit ice depth=1; zinit light romkatv/powerlevel10k

# 入力補完
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# シンタックスハイライト
zinit light zdharma-continuum/fast-syntax-highlighting

zinit snippet OMZP::git
zinit snippet PZTM::helper
### end zinit config

export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# k8s
autoload -Uz compinit && compinit
source <(kubectl completion zsh)
alias k=kubectl

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# direnv
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

bindkey '^h' zaw-history

setopt share_history

setopt EXTENDED_HISTORY

setopt hist_ignore_space

setopt hist_verify

setopt hist_reduce_blanks

setopt hist_save_no_dups

setopt hist_expand

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
export HISTTIMEFORMAT="%F %T "

HISTFILE=~/.zsh_history

# ヒストリに保存するコマンド数
HISTSIZE=10000

# ヒストリファイルに保存するコマンド数
SAVEHIST=10000

# 重複するコマンド行は古い方を削除
setopt hist_ignore_all_dups

# 直前と同じコマンドラインはヒストリに追加しない
setopt hist_ignore_dups

# 履歴を追加 (毎回 .zsh_history を作るのではなく)
setopt append_history

# 履歴をインクリメンタルに追加
setopt inc_append_history

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
