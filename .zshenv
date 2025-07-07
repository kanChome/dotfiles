# .zshenv - XDG Base Directory Specification

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

[[ -d "$XDG_CONFIG_HOME" ]] || mkdir -p "$XDG_CONFIG_HOME"
[[ -d "$XDG_DATA_HOME" ]] || mkdir -p "$XDG_DATA_HOME"
[[ -d "$XDG_STATE_HOME" ]] || mkdir -p "$XDG_STATE_HOME"
[[ -d "$XDG_CACHE_HOME" ]] || mkdir -p "$XDG_CACHE_HOME"

[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

if [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
elif [[ -f "$HOME/.zshrc" ]]; then
    # 従来の場所から読み込み（後方互換性）
    export ZDOTDIR="$HOME"
fi

export HISTFILE="$XDG_STATE_HOME"/zsh/history

[[ -d "$XDG_CONFIG_HOME/docker" ]] || mkdir -p "$XDG_CONFIG_HOME/docker"
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

[[ -d "$XDG_CONFIG_HOME"/aws ]] || mkdir -p "$XDG_CONFIG_HOME"/aws
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config