#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "dotfiles設定検証を開始"
debugPlatformInfo

# dotfilesディレクトリのパスを取得
DOTFILES_DIR="$(getDotfilesDir)"
info "dotfilesディレクトリ: ${DOTFILES_DIR}"

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

# dotfilesシンボリンクの検証（CI環境では実行しない）
if ! isRunningOnCI; then
    info "=== dotfilesシンボリンク検証 ==="
    
    # XDG準拠のシンボリックリンク確認
    # .zshrc - XDGコンフィグディレクトリに配置
    if [ -f "${DOTFILES_DIR}/config/zsh/.zshrc" ]; then
        verify_symlink ".zshrcのXDGシンボリックリンク" "${HOME}/.config/zsh/.zshrc" "${DOTFILES_DIR}/config/zsh/.zshrc"
    fi
    
    # .gitconfig - XDGコンフィグディレクトリに配置
    if [ -f "${DOTFILES_DIR}/config/git/config" ]; then
        verify_symlink "git configのXDGシンボリックリンク" "${HOME}/.config/git/config" "${DOTFILES_DIR}/config/git/config"
    fi
    
    # .Brewfileの特別検証（brew bundle dump --global 対応）
    info "=== .Brewfile検証 ==="
    if [ -f "${DOTFILES_DIR}/.Brewfile" ]; then
        verify_symlink ".Brewfileのシンボリンク" "${HOME}/.Brewfile" "${DOTFILES_DIR}/.Brewfile"
        
        # 分離ファイルの存在確認
        if [ -f "${DOTFILES_DIR}/.Brewfile.common" ]; then
            success "✓ .Brewfile.common が存在します"
        else
            warning "⚠ .Brewfile.common が見つかりません"
            VERIFY_FAILED=$((VERIFY_FAILED + 1))
        fi
        
        if isRunningOnMac && [ -f "${DOTFILES_DIR}/.Brewfile.macos" ]; then
            success "✓ .Brewfile.macos が存在します（macOS用）"
        elif isRunningOnLinux && [ -f "${DOTFILES_DIR}/.packages.ubuntu" ]; then
            success "✓ .packages.ubuntu が存在します（Ubuntu/Debian用）"
        elif isRunningOnWindows && [ -f "${DOTFILES_DIR}/.packages.windows" ]; then
            success "✓ .packages.windows が存在します（Windows用）"
        fi
    else
        warning "⚠ .Brewfileが見つかりません（make packages を実行してください）"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
else
    info "=== CI環境：シンボリンク検証をスキップ ==="
    info "CI環境ではシンボリンクの検証をスキップします"
fi

# XDGローカル設定ファイルの検証
info "=== XDGローカル設定ファイル検証 ==="
if [ -f "${HOME}/.config/zsh/.zshrc.local" ]; then
    success "✓ .zshrc.localがXDGディレクトリに作成されています"
else
    info "ℹ .zshrc.localが存在しません（初回セットアップ後に作成されます）"
fi

if [ -f "${HOME}/.config/git/config.local" ]; then
    success "✓ .gitconfig.localがXDGディレクトリに作成されています"
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
    
elif isRunningOnWindows; then
    info "=== Windows固有検証 ==="
    
    # Wingetの検証
    if command -v winget >/dev/null 2>&1; then
        success "✓ winget が利用可能です"
        
        # パッケージファイルの検証
        if [ -f "${DOTFILES_DIR}/.packages.windows" ]; then
            success "✓ .packages.windows が存在します"
        else
            warning "⚠ .packages.windows が見つかりません"
            info "make winget-export を実行してパッケージリストを作成してください"
            VERIFY_FAILED=$((VERIFY_FAILED + 1))
        fi
    else
        warning "⚠ winget が利用できません"
        info "Windows 10 version 1809 以降または Windows 11 が必要です"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
    
    # PowerShellの検証
    if command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
        success "✓ PowerShell が利用可能です"
    else
        warning "⚠ PowerShell が見つかりません"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
fi

# zshプラグイン関連の検証
info "=== zshプラグイン検証 ==="
if [ -d "${HOME}/.local/share/zinit" ]; then
    success "✓ zinitディレクトリがXDGデータディレクトリに存在します"
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