# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zinit インストール
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

### zinit 設定
zinit ice depth=1; zinit light romkatv/powerlevel10k

# 入力補完
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# シンタックスハイライト
zinit light zdharma-continuum/fast-syntax-highlighting

zinit snippet OMZP::git
zinit snippet PZTM::helper
### zinit 設定終了

# Homebrew設定 - 動的検出と設定
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  for brew_path in "/opt/homebrew" "/usr/local" "/home/linuxbrew/.linuxbrew"; do
    if [ -x "${brew_path}/bin/brew" ]; then
      eval "$(${brew_path}/bin/brew shellenv)"
      break
    fi
  done
fi

# k8s
autoload -Uz compinit && compinit
source <(kubectl completion zsh)
alias k=kubectl

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# direnv
eval "$(direnv hook bash)"

setopt auto_cd
function history-all { history -E 1 }

bindkey '^h' zaw-history
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward


export HISTTIMEFORMAT="%F %T "

# ヒストリに保存するコマンド数
HISTSIZE=10000
# ヒストリファイルに保存するコマンド数
SAVEHIST=100000
HISTFILESIZE=100000

function setOptionOfHistory() {
  # ターミナル間で履歴を共有
  setopt share_history

  # タイムスタンプ、コマンド実行時間を記録
  setopt EXTENDED_HISTORY

  # スペース始まりのコマンドはヒストリに残さない
  setopt hist_ignore_space

  # 履歴展開後にコマンドを自動的に実行するのではなく、ユーザーが確認できるようにする
  setopt hist_verify

  # 履歴に保存されるコマンド行の先頭、末尾の空白を削除
  setopt hist_reduce_blanks

  # 連続する重複コマンドを履歴に1回だけ保存
  setopt hist_save_no_dups

  # 履歴展開を有効化
  setopt hist_expand

  # 重複するコマンド行は古い方を削除
  setopt hist_ignore_all_dups

  # 直前と同じコマンドラインはヒストリに追加しない
  setopt hist_ignore_dups

  # 履歴を追加 (毎回 .zsh_history を作るのではなく)
  setopt append_history

  # 履歴をインクリメンタルに追加
  setopt inc_append_history

  # historyコマンドは履歴に登録しない
  setopt hist_no_store
}

setOptionOfHistory

# 補完候補を詰めて表示
setopt list_packed
# ピープオンを鳴らさない
setopt no_beep

compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"

# ローカルカスタマイズ設定を読み込み（XDG対応）
[[ ! -f "${XDG_CONFIG_HOME}/zsh/zshrc.local" ]] || source "${XDG_CONFIG_HOME}/zsh/zshrc.local"
# 後方互換性のため従来の場所もチェック
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh 

# gradle
export PATH="/opt/homebrew/opt/gradle@8/bin:$PATH"
