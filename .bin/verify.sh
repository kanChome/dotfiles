#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "dotfiles設定検証を開始"
debugPlatformInfo

VERIFY_FAILED=0
VERIFY_COUNT=0

# 検証関数
verify_assert() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    VERIFY_COUNT=$((VERIFY_COUNT + 1))
    info "検証 ${VERIFY_COUNT}: ${description}"
    
    if eval "$command" >/dev/null 2>&1; then
        actual_exit_code=0
    else
        actual_exit_code=$?
    fi
    
    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        success "✓ ${description}"
    else
        warning "⚠ ${description} (予期される状態ではありません)"
        debug "コマンド: $command"
        debug "終了コード: 期待値=${expected_exit_code}, 実際=${actual_exit_code}"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
}

# シンボリックリンクの検証
verify_symlink() {
    local description="$1"
    local link_path="$2"
    local expected_target="$3"
    
    VERIFY_COUNT=$((VERIFY_COUNT + 1))
    info "検証 ${VERIFY_COUNT}: ${description}"
    
    if [ -L "$link_path" ]; then
        actual_target=$(readlink "$link_path")
        if [ "$actual_target" = "$expected_target" ]; then
            success "✓ ${description}"
        else
            warning "⚠ ${description} (リンク先が異なります: 期待=${expected_target}, 実際=${actual_target})"
            VERIFY_FAILED=$((VERIFY_FAILED + 1))
        fi
    else
        warning "⚠ ${description} (シンボリックリンクが存在しません: ${link_path})"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
}

# プラットフォーム検出の検証
info "=== プラットフォーム検出検証 ==="
PLATFORM_INFO=$(getPlatformInfo)
success "検出されたプラットフォーム: ${PLATFORM_INFO}"

# 基本ツールの動作検証
info "=== 基本ツール動作検証 ==="
verify_assert "Git動作確認" "git --version"

# Homebrewの検証
if isHomebrewInstalled; then
    info "=== Homebrew検証 ==="
    verify_assert "brew動作確認" "brew --version"
    HOMEBREW_PATH=$(getHomebrewPath)
    success "Homebrewパス: ${HOMEBREW_PATH}"
else
    warning "Homebrewがインストールされていません"
fi

# dotfilesシンボリンクの検証
info "=== dotfilesシンボリンク検証 ==="
DOTFILES_DIR="${HOME}/dotfiles"

# 主要なdotfilesのシンボリンク確認
for dotfile in .zshrc .gitconfig .Brewfile; do
    if [ -f "${DOTFILES_DIR}/${dotfile}" ]; then
        verify_symlink "${dotfile}のシンボリンク" "${HOME}/${dotfile}" "${DOTFILES_DIR}/${dotfile}"
    fi
done

# ローカル設定ファイルの検証
info "=== ローカル設定ファイル検証 ==="
if [ -f "${HOME}/.zshrc.local" ]; then
    success "✓ .zshrc.localが作成されています"
else
    info "ℹ .zshrc.localが存在しません（初回セットアップ後に作成されます）"
fi

if [ -f "${HOME}/.gitconfig.local" ]; then
    success "✓ .gitconfig.localが作成されています"
else
    info "ℹ .gitconfig.localが存在しません（初回セットアップ後に作成されます）"
fi

# プラットフォーム固有の検証
if isRunningOnMac; then
    info "=== macOS固有検証 ==="
    verify_assert "Xcode Command Line Tools" "xcode-select -p"
    
    # フォント確認
    if [ -f "${HOME}/Library/Fonts/MesloLGSNFRegular.ttf" ]; then
        success "✓ PowerLevel10kフォントがインストールされています"
    else
        warning "⚠ PowerLevel10kフォントが見つかりません"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
    
elif isRunningOnWSL; then
    info "=== WSL固有検証 ==="
    verify_assert "WSL環境の確認" "grep -q microsoft /proc/version"
    
    # Windowsアクセス確認
    if [ -d "/mnt/c/Windows" ] || [ -d "/c/Windows" ]; then
        success "✓ Windowsファイルシステムにアクセス可能"
        
        # フォント確認
        WINDOWS_FONTS_DIR=$(getWindowsFontDir 2>/dev/null || echo "")
        if [ -n "$WINDOWS_FONTS_DIR" ] && [ -f "${WINDOWS_FONTS_DIR}/MesloLGSNFRegular.ttf" ]; then
            success "✓ PowerLevel10kフォントがWindowsにインストールされています"
        else
            warning "⚠ PowerLevel10kフォントがWindowsに見つかりません"
            VERIFY_FAILED=$((VERIFY_FAILED + 1))
        fi
    else
        warning "⚠ Windowsファイルシステムにアクセスできません"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
    
elif isRunningOnLinux; then
    info "=== Linux固有検証 ==="
    DISTRO=$(getLinuxDistro)
    success "検出されたディストリビューション: ${DISTRO}"
fi

# zshプラグイン関連の検証
info "=== zshプラグイン検証 ==="
if [ -d "${HOME}/.local/share/zinit" ]; then
    success "✓ zinitディレクトリが存在します"
else
    info "ℹ zinitがまだインストールされていません（初回zsh起動時にインストールされます）"
fi

# Git設定の検証
info "=== Git設定検証 ==="
if git config --global user.name >/dev/null 2>&1; then
    GIT_USER_NAME=$(git config --global user.name)
    success "✓ Git user.name: ${GIT_USER_NAME}"
else
    warning "⚠ Git user.nameが設定されていません"
    VERIFY_FAILED=$((VERIFY_FAILED + 1))
fi

if git config --global user.email >/dev/null 2>&1; then
    GIT_USER_EMAIL=$(git config --global user.email)
    success "✓ Git user.email: ${GIT_USER_EMAIL}"
else
    warning "⚠ Git user.emailが設定されていません"
    VERIFY_FAILED=$((VERIFY_FAILED + 1))
fi

# 結果の出力
info "=== 検証結果 ==="
info "実行検証数: ${VERIFY_COUNT}"
if [ "$VERIFY_FAILED" -eq 0 ]; then
    success "全ての検証が成功しました！dotfilesが正しく設定されています。"
    exit 0
else
    warning "警告がある項目数: ${VERIFY_FAILED}"
    warning "一部の設定で問題が検出されました。上記の警告を確認してください。"
    exit 1
fi