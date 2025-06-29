#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

DOTFILES_DIR="$HOME/dotfiles"

info "linking dotfiles"
for dotfile in "${DOTFILES_DIR}"/.??* ; do
    [[ "$dotfile" == "${DOTFILES_DIR}/.git" ]] && continue
    [[ "$dotfile" == "${DOTFILES_DIR}/.github" ]] && continue
    [[ "$dotfile" == "${DOTFILES_DIR}/.DS_Store" ]] && continue
    # Skip template files
    [[ "$dotfile" == *".template" ]] && continue
    # Skip bin directory
    [[ "$dotfile" == "${DOTFILES_DIR}/.bin" ]] && continue

    ln -fnsv "$dotfile" "$HOME"
done
success "dotfiles linked"

# テンプレートからローカル設定ファイルを作成（存在しない場合）
info "setting up local configuration files"

# .zshrc.localのセットアップ
if [[ ! -f "$HOME/.zshrc.local" ]] && [[ -f "$DOTFILES_DIR/.zshrc.local.template" ]]; then
    cp "$DOTFILES_DIR/.zshrc.local.template" "$HOME/.zshrc.local"
    info "Created ~/.zshrc.local from template"
    warning "Please edit ~/.zshrc.local to customize your personal settings"
else
    debug "~/.zshrc.local already exists or template not found"
fi

# .gitconfig.localのセットアップ
if [[ ! -f "$HOME/.gitconfig.local" ]] && [[ -f "$DOTFILES_DIR/.gitconfig.local.template" ]]; then
    cp "$DOTFILES_DIR/.gitconfig.local.template" "$HOME/.gitconfig.local"
    info "Created ~/.gitconfig.local from template"
    warning "Please edit ~/.gitconfig.local with your Git user information"
else
    debug "~/.gitconfig.local already exists or template not found"
fi

success "local configuration setup complete"