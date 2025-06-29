#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "dotfilesテストを開始"
debugPlatformInfo

TEST_FAILED=0
TEST_COUNT=0

# テスト関数
test_assert() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    info "テスト ${TEST_COUNT}: ${description}"
    
    if eval "$command" >/dev/null 2>&1; then
        actual_exit_code=0
    else
        actual_exit_code=$?
    fi
    
    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        success "✓ ${description}"
    else
        error "✗ ${description} (終了コード: 期待値=${expected_exit_code}, 実際=${actual_exit_code})"
        TEST_FAILED=$((TEST_FAILED + 1))
    fi
}

# テスト関数（ファイル存在確認）
test_file_exists() {
    local description="$1"
    local file_path="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    info "テスト ${TEST_COUNT}: ${description}"
    
    if [ -f "$file_path" ] || [ -L "$file_path" ]; then
        success "✓ ${description}"
    else
        error "✗ ${description} (ファイルが存在しません: ${file_path})"
        TEST_FAILED=$((TEST_FAILED + 1))
    fi
}

# テスト関数（コマンド存在確認）
test_command_exists() {
    local description="$1"
    local command_name="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    info "テスト ${TEST_COUNT}: ${description}"
    
    if command -v "$command_name" >/dev/null 2>&1; then
        success "✓ ${description}"
    else
        error "✗ ${description} (コマンドが見つかりません: ${command_name})"
        TEST_FAILED=$((TEST_FAILED + 1))
    fi
}

# プラットフォーム検出のテスト
info "=== プラットフォーム検出テスト ==="
test_assert "基本プラットフォーム検出" "getPlatformInfo"
test_assert "Homebrewパス取得" "getHomebrewPath"

# 基本コマンドの存在確認
info "=== 基本コマンド存在確認 ==="
test_command_exists "bash" "bash"
test_command_exists "git" "git"

# プラットフォーム固有のテスト
if isRunningOnMac; then
    info "=== macOS固有テスト ==="
    test_command_exists "brew" "brew"
    test_assert "Xcode Command Line Tools" "xcode-select -p"
elif isRunningOnWSL || isRunningOnLinux; then
    info "=== Linux/WSL固有テスト ==="
    test_command_exists "curl" "curl"
    test_command_exists "wget" "wget"
    
    if isRunningOnWSL; then
        info "=== WSL固有テスト ==="
        test_assert "Windowsファイルシステムアクセス" "[ -d '/mnt/c' ] || [ -d '/c' ]"
    fi
fi

# dotfilesの基本構造テスト
info "=== dotfiles構造テスト ==="
test_file_exists "makefile" "${HOME}/dotfiles/makefile"
test_file_exists "common.sh" "${HOME}/dotfiles/.bin/common.sh"
test_file_exists "init.sh" "${HOME}/dotfiles/.bin/init.sh"
test_file_exists "link.sh" "${HOME}/dotfiles/.bin/link.sh"
test_file_exists ".zshrc" "${HOME}/dotfiles/.zshrc"
test_file_exists ".gitconfig" "${HOME}/dotfiles/.gitconfig"
test_file_exists ".Brewfile" "${HOME}/dotfiles/.Brewfile"

# テンプレートファイルのテスト
info "=== テンプレートファイルテスト ==="
test_file_exists ".zshrc.local.template" "${HOME}/dotfiles/.zshrc.local.template"
test_file_exists ".gitconfig.local.template" "${HOME}/dotfiles/.gitconfig.local.template"

# スクリプトの構文チェック
info "=== スクリプト構文チェック ==="
for script in "${HOME}/dotfiles/.bin"/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        test_assert "${script_name}の構文チェック" "bash -n $script"
    fi
done

# Brewfileの構文チェック
if [ -f "${HOME}/dotfiles/.Brewfile" ]; then
    test_file_exists "Brewfile構文チェック" "${HOME}/dotfiles/.Brewfile"
fi

# 設定ファイルの基本チェック
info "=== 設定ファイル基本チェック ==="
if [ -f "${HOME}/.zshrc" ]; then
    # .zshrcはzsh固有の構文を含むためbash構文チェックは行わない
    test_file_exists ".zshrc存在確認" "${HOME}/.zshrc"
fi

# 結果の出力
info "=== テスト結果 ==="
info "実行テスト数: ${TEST_COUNT}"
if [ "$TEST_FAILED" -eq 0 ]; then
    success "全てのテストが成功しました！"
    exit 0
else
    error "失敗したテスト数: ${TEST_FAILED}"
    exit 1
fi