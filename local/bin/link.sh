#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# dotfilesディレクトリを動的に取得
DOTFILES_DIR="$(getDotfilesDir)"

info "linking dotfiles with XDG Base Directory Specification"

# XDG Base Directoryの環境変数を設定
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDGディレクトリを作成
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_STATE_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$HOME/.local/bin"

# XDG Config Home のシンボリックリンク作成
info "linking XDG configuration files"

# Zsh configuration
if [[ -f "$DOTFILES_DIR/config/zsh/zshrc" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/zsh"
    ln -fnsv "$DOTFILES_DIR/config/zsh/zshrc" "$XDG_CONFIG_HOME/zsh/zshrc"
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/zsh/zshrc" "$HOME/.zshrc"
fi

# Git configuration
if [[ -f "$DOTFILES_DIR/config/git/config" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/git"
    ln -fnsv "$DOTFILES_DIR/config/git/config" "$XDG_CONFIG_HOME/git/config"
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/git/config" "$HOME/.gitconfig"
fi

# Yarn configuration
if [[ -f "$DOTFILES_DIR/config/yarn/yarnrc" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/yarn"
    ln -fnsv "$DOTFILES_DIR/config/yarn/yarnrc" "$XDG_CONFIG_HOME/yarn/yarnrc"
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/yarn/yarnrc" "$HOME/.yarnrc"
fi

# Nuxt configuration
if [[ -f "$DOTFILES_DIR/config/nuxt/nuxtrc" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/nuxt"
    ln -fnsv "$DOTFILES_DIR/config/nuxt/nuxtrc" "$XDG_CONFIG_HOME/nuxt/nuxtrc"
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/nuxt/nuxtrc" "$HOME/.nuxtrc"
fi

# Claude configuration
if [[ -d "$DOTFILES_DIR/config/claude" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/claude"
    for claude_file in "$DOTFILES_DIR/config/claude"/*; do
        if [[ -f "$claude_file" ]]; then
            ln -fnsv "$claude_file" "$XDG_CONFIG_HOME/claude/"
        elif [[ -d "$claude_file" ]]; then
            ln -fnsv "$claude_file" "$XDG_CONFIG_HOME/claude/"
        fi
    done
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/claude" "$HOME/.claude"
fi

# iTerm2 configuration
if [[ -f "$DOTFILES_DIR/config/iterm2/com.googlecode.iterm2.plist" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/iterm2"
    ln -fnsv "$DOTFILES_DIR/config/iterm2/com.googlecode.iterm2.plist" "$XDG_CONFIG_HOME/iterm2/com.googlecode.iterm2.plist"
    # Legacy symlink for compatibility (iTerm2 expects it in a specific location)
    mkdir -p "$HOME/Library/Preferences"
    ln -fnsv "$XDG_CONFIG_HOME/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
fi

# VSCode configuration
if [[ -d "$DOTFILES_DIR/config/vscode" ]]; then
    mkdir -p "$XDG_CONFIG_HOME/vscode"
    for vscode_file in "$DOTFILES_DIR/config/vscode"/*; do
        if [[ -f "$vscode_file" ]]; then
            ln -fnsv "$vscode_file" "$XDG_CONFIG_HOME/vscode/"
        fi
    done
    # Legacy symlink for compatibility
    ln -fnsv "$XDG_CONFIG_HOME/vscode" "$HOME/.vscode"
fi

success "XDG configuration files linked"

# XDG Data Home のシンボリックリンク作成
info "linking XDG data files"

# Brewfiles
if [[ -d "$DOTFILES_DIR/local/share/dotfiles/brewfiles" ]]; then
    mkdir -p "$XDG_DATA_HOME/dotfiles/brewfiles"
    for brewfile in "$DOTFILES_DIR/local/share/dotfiles/brewfiles"/*; do
        if [[ -f "$brewfile" ]]; then
            ln -fnsv "$brewfile" "$XDG_DATA_HOME/dotfiles/brewfiles/"
        fi
    done
    
    # Legacy symlink for main Brewfile
    if [[ -f "$XDG_DATA_HOME/dotfiles/brewfiles/Brewfile" ]]; then
        ln -fnsv "$XDG_DATA_HOME/dotfiles/brewfiles/Brewfile" "$HOME/.Brewfile"
    fi
fi

# Package files
if [[ -d "$DOTFILES_DIR/local/share/dotfiles/packages" ]]; then
    mkdir -p "$XDG_DATA_HOME/dotfiles/packages"
    for package_file in "$DOTFILES_DIR/local/share/dotfiles/packages"/*; do
        if [[ -f "$package_file" ]]; then
            ln -fnsv "$package_file" "$XDG_DATA_HOME/dotfiles/packages/"
        fi
    done
fi

success "XDG data files linked"

# XDG State Home のシンボリックリンク作成
info "linking XDG state files"

# Backup files
if [[ -d "$DOTFILES_DIR/local/state/dotfiles" ]]; then
    mkdir -p "$XDG_STATE_HOME/dotfiles"
    for state_item in "$DOTFILES_DIR/local/state/dotfiles"/*; do
        if [[ -e "$state_item" ]]; then
            ln -fnsv "$state_item" "$XDG_STATE_HOME/dotfiles/"
        fi
    done
fi

success "XDG state files linked"

# Executable scripts
info "linking executable scripts"

if [[ -d "$DOTFILES_DIR/local/bin" ]]; then
    for script in "$DOTFILES_DIR/local/bin"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            ln -fnsv "$script" "$HOME/.local/bin/"
        fi
    done
fi

success "executable scripts linked"

# テンプレートからローカル設定ファイルを作成（存在しない場合）
info "setting up local configuration files"

# .zshrc.localのセットアップ
if [[ ! -f "$XDG_CONFIG_HOME/zsh/zshrc.local" ]] && [[ -f "$DOTFILES_DIR/config/zsh/zshrc.local.template" ]]; then
    cp "$DOTFILES_DIR/config/zsh/zshrc.local.template" "$XDG_CONFIG_HOME/zsh/zshrc.local"
    info "Created ~/.config/zsh/zshrc.local from template"
    # Legacy compatibility
    ln -fnsv "$XDG_CONFIG_HOME/zsh/zshrc.local" "$HOME/.zshrc.local"
    warning "Please edit ~/.config/zsh/zshrc.local to customize your personal settings"
else
    debug "~/.config/zsh/zshrc.local already exists or template not found"
fi

# .gitconfig.localのセットアップ
if [[ ! -f "$XDG_CONFIG_HOME/git/config.local" ]] && [[ -f "$DOTFILES_DIR/config/git/config.local.template" ]]; then
    cp "$DOTFILES_DIR/config/git/config.local.template" "$XDG_CONFIG_HOME/git/config.local"
    info "Created ~/.config/git/config.local from template"
    # Legacy compatibility
    ln -fnsv "$XDG_CONFIG_HOME/git/config.local" "$HOME/.gitconfig.local"
    warning "Please edit ~/.config/git/config.local with your Git user information"
else
    debug "~/.config/git/config.local already exists or template not found"
fi

success "local configuration setup complete"

# XDG環境変数の設定を確認
info "XDG Base Directory environment variables:"
info "  XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
info "  XDG_DATA_HOME: $XDG_DATA_HOME"
info "  XDG_STATE_HOME: $XDG_STATE_HOME"
info "  XDG_CACHE_HOME: $XDG_CACHE_HOME"

success "XDG-compliant dotfiles linking complete"

# 後続の作業についてのメッセージ
info "Next steps:"
info "1. Add XDG environment variables to your shell profile"
info "2. Configure applications to use XDG Base Directory Specification"
info "3. Legacy symlinks are created for backward compatibility"