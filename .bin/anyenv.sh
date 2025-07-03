#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# anyenv安全インストールスクリプト
# 既存の環境を破壊せず、エラーハンドリングを含む安全な実装

info "Setting up anyenv environment"
debugPlatformInfo

# anyenvのインストールディレクトリ
ANYENV_ROOT="${HOME}/.anyenv"

# anyenvが既にインストールされているかチェック
check_anyenv_installed() {
    if [ -d "$ANYENV_ROOT" ] && [ -x "$ANYENV_ROOT/bin/anyenv" ]; then
        return 0
    fi
    return 1
}

# anyenvのインストール
install_anyenv() {
    info "Installing anyenv"
    
    if check_anyenv_installed; then
        success "anyenv is already installed at $ANYENV_ROOT"
        return 0
    fi
    
    # インターネット接続確認
    if ! checkInternetConnection; then
        error "Cannot install anyenv: No internet connection"
        return 1
    fi
    
    # 既存のディレクトリが存在する場合の処理
    if [ -d "$ANYENV_ROOT" ]; then
        if [ -d "$ANYENV_ROOT/.git" ]; then
            info "Updating existing anyenv installation"
            cd "$ANYENV_ROOT"
            if git pull origin master; then
                success "anyenv updated successfully"
                cd - >/dev/null
            else
                warning "Failed to update anyenv (continuing with existing installation)"
                cd - >/dev/null
            fi
        else
            # 不完全なインストールの場合は再インストール
            warning "anyenv directory exists but appears incomplete"
            if [ ! -f "$ANYENV_ROOT/bin/anyenv" ]; then
                info "Removing incomplete installation and reinstalling"
                rm -rf "$ANYENV_ROOT"
                if git clone https://github.com/riywo/anyenv "$ANYENV_ROOT"; then
                    success "anyenv reinstalled successfully"
                else
                    error "Failed to reinstall anyenv repository"
                    warning "Please check your internet connection and try again"
                    return 1
                fi
            else
                info "Using existing installation"
            fi
        fi
    else
        # anyenvリポジトリのクローン
        if git clone https://github.com/riywo/anyenv "$ANYENV_ROOT"; then
            success "anyenv cloned successfully"
        else
            error "Failed to clone anyenv repository"
            warning "Please check your internet connection and try again"
            return 1
        fi
    fi
    
    # anyenv-updateプラグインのインストール
    local plugins_dir="$ANYENV_ROOT/plugins"
    mkdir -p "$plugins_dir"
    
    if [ -d "$plugins_dir/anyenv-update" ]; then
        info "anyenv-update plugin already exists"
    else
        if git clone https://github.com/znz/anyenv-update.git "$plugins_dir/anyenv-update"; then
            success "anyenv-update plugin installed"
        else
            warning "Failed to install anyenv-update plugin (non-critical)"
        fi
    fi
    
    return 0
}

# シェル設定の更新
setup_shell_integration() {
    info "Setting up shell integration"
    
    # PATHの設定
    export PATH="$ANYENV_ROOT/bin:$PATH"
    
    # anyenv初期化（プロファイルに追加するためのヒント表示のみ）
    if [ -x "$ANYENV_ROOT/bin/anyenv" ]; then
        info "anyenv is ready to use"
        info "Shell integration is already configured in .zshrc"
        success "No additional shell configuration needed"
    elif [ -f "$ANYENV_ROOT/bin/anyenv" ]; then
        # 実行権限がない場合は付与
        chmod +x "$ANYENV_ROOT/bin/anyenv"
        success "anyenv binary found and made executable"
    else
        # anyenvバイナリが見つからない場合の詳細チェック
        debug "Checking anyenv installation..."
        debug "ANYENV_ROOT: $ANYENV_ROOT"
        debug "Contents of $ANYENV_ROOT:"
        ls -la "$ANYENV_ROOT" 2>/dev/null || debug "Cannot list $ANYENV_ROOT"
        debug "Contents of $ANYENV_ROOT/bin:"
        ls -la "$ANYENV_ROOT/bin" 2>/dev/null || debug "Cannot list $ANYENV_ROOT/bin"
        
        error "anyenv binary not found after installation"
        warning "This may be a temporary issue, anyenv might still work after shell restart"
        warning "Try running: source ~/.zshrc"
        # CI環境では警告のみでエラーにしない
        if isRunningOnCI; then
            warning "Continuing in CI mode despite missing binary"
            return 0
        fi
        return 1
    fi
    
    return 0
}

# 言語環境のインストール（安全な実装）
install_language_env() {
    local env_name="$1"
    local version="$2"
    
    info "Setting up $env_name environment"
    
    # CI環境では言語のインストールをスキップ（時間短縮とリソース節約）
    if isRunningOnCI; then
        info "Skipping $env_name installation in CI environment"
        return 0
    fi
    
    # anyenvが利用可能かチェック
    if ! command -v anyenv >/dev/null 2>&1; then
        # PATHを一時的に設定
        export PATH="$ANYENV_ROOT/bin:$PATH"
        
        if ! command -v anyenv >/dev/null 2>&1; then
            error "anyenv not available in PATH"
            return 1
        fi
    fi
    
    # env (jenv, nodenv, etc.) が既にインストールされているかチェック
    if anyenv versions "$env_name" >/dev/null 2>&1; then
        success "$env_name is already installed"
    else
        info "Installing $env_name"
        if timeout 300 anyenv install "$env_name"; then
            success "$env_name installed successfully"
        else
            error "Failed to install $env_name (timeout or error)"
            return 1
        fi
    fi
    
    # シェル環境の再読み込み（execを使わない安全な方法）
    eval "$(anyenv init -)"
    
    # 指定バージョンがインストール済みかチェック
    if "$env_name" versions | grep -q "$version"; then
        success "$env_name $version is already installed"
    else
        info "Installing $env_name $version (this may take several minutes)"
        if timeout 600 "$env_name" install "$version"; then
            success "$env_name $version installed successfully"
        else
            error "Failed to install $env_name $version (timeout or error)"
            warning "You can install it manually later with: $env_name install $version"
            return 1
        fi
    fi
    
    # グローバルバージョンの設定
    info "Setting $env_name global version to $version"
    if "$env_name" global "$version"; then
        success "$env_name global version set to $version"
    else
        warning "Failed to set global version for $env_name"
        info "You can set it manually with: $env_name global $version"
    fi
    
    return 0
}

# 最新の推奨バージョンを取得する関数
get_latest_versions() {
    # 2024年現在の安定版バージョン（定期的に更新が必要）
    JAVA_VERSION="21.0.2"      # Java LTS
    NODE_VERSION="20.11.1"     # Node.js LTS
    GO_VERSION="1.22.1"        # Go最新安定版
    
    debug "Using versions: Java $JAVA_VERSION, Node $NODE_VERSION, Go $GO_VERSION"
}

# CI専用のテストモード
test_mode() {
    info "Running anyenv setup in test mode"
    
    # 最新バージョン情報の取得
    get_latest_versions
    
    # anyenvのインストール
    if ! install_anyenv; then
        error "anyenv installation failed"
        exit 1
    fi
    
    # シェル統合の設定
    if ! setup_shell_integration; then
        error "Shell integration setup failed"
        exit 1
    fi
    
    # CI環境では言語インストールをスキップし、基本的な動作確認のみ
    info "Verifying anyenv functionality (test mode)"
    
    # anyenvが正常に動作するかテスト
    export PATH="$ANYENV_ROOT/bin:$PATH"
    if command -v anyenv >/dev/null 2>&1; then
        success "anyenv is properly installed and available"
        
        # 利用可能な環境を表示
        info "Available environments:"
        anyenv install --list | head -10 || warning "Could not list available environments"
        
        success "anyenv test mode completed successfully"
    else
        error "anyenv test failed: command not available"
        exit 1
    fi
}

# メイン実行フロー
main() {
    # テストモードかチェック
    if [ "${1:-}" = "test" ] || isRunningOnCI; then
        test_mode
        return 0
    fi
    
    # 最新バージョン情報の取得
    get_latest_versions
    
    # anyenvのインストール
    if ! install_anyenv; then
        error "anyenv installation failed"
        exit 1
    fi
    
    # シェル統合の設定
    if ! setup_shell_integration; then
        error "Shell integration setup failed"
        exit 1
    fi
    
    # 言語環境のインストール（オプション）
    info "Installing language environments..."
    
    # Java環境（jenv）
    if ! install_language_env "jenv" "$JAVA_VERSION"; then
        warning "Java environment setup failed (non-critical)"
    fi
    
    # Node.js環境（nodenv）
    if ! install_language_env "nodenv" "$NODE_VERSION"; then
        warning "Node.js environment setup failed (non-critical)"
    fi
    
    # Go環境（goenv）
    if ! install_language_env "goenv" "$GO_VERSION"; then
        warning "Go environment setup failed (non-critical)"
    fi
    
    # 完了メッセージ
    success "anyenv setup completed successfully"
    info "Please restart your shell or run: source ~/.zshrc"
    info "Available commands:"
    info "  anyenv install <env>     # Install language environment"
    info "  anyenv update           # Update all environments"
    info "  <env> install <version> # Install specific version"
    info "  <env> global <version>  # Set global version"
}

# エラートラップの設定
trap 'error "anyenv setup failed at line $LINENO"' ERR

# メイン実行
main "$@"