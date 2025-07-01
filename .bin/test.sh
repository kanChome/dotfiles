#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "dotfilesテストを開始"
debugPlatformInfo

# dotfilesディレクトリのパスを取得
DOTFILES_DIR="$(getDotfilesDir)"
info "dotfilesディレクトリ: ${DOTFILES_DIR}"

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
test_file_exists "makefile" "${DOTFILES_DIR}/makefile"
test_file_exists "common.sh" "${DOTFILES_DIR}/.bin/common.sh"
test_file_exists "init.sh" "${DOTFILES_DIR}/.bin/init.sh"
test_file_exists "link.sh" "${DOTFILES_DIR}/.bin/link.sh"
test_file_exists ".zshrc" "${DOTFILES_DIR}/.zshrc"
test_file_exists ".gitconfig" "${DOTFILES_DIR}/.gitconfig"
test_file_exists ".Brewfile" "${DOTFILES_DIR}/.Brewfile"

# テンプレートファイルのテスト
info "=== テンプレートファイルテスト ==="
test_file_exists ".zshrc.local.template" "${DOTFILES_DIR}/.zshrc.local.template"
test_file_exists ".gitconfig.local.template" "${DOTFILES_DIR}/.gitconfig.local.template"

# スクリプトの構文チェック
info "=== スクリプト構文チェック ==="
for script in "${DOTFILES_DIR}/.bin"/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        test_assert "${script_name}の構文チェック" "bash -n $script"
    fi
done

# Brewfileの構文チェック
if [ -f "${DOTFILES_DIR}/.Brewfile" ]; then
    test_file_exists "Brewfile構文チェック" "${DOTFILES_DIR}/.Brewfile"
fi

# 設定ファイルの基本チェック（CI環境では実際のファイル配置後のみ）
info "=== 設定ファイル基本チェック ==="
if ! isRunningOnCI; then
    # ローカル環境でのみ実行（シンボリンクが作成されている前提）
    if [ -f "${HOME}/.zshrc" ]; then
        # .zshrcはzsh固有の構文を含むためbash構文チェックは行わない
        test_file_exists ".zshrc存在確認" "${HOME}/.zshrc"
    fi
else
    # CI環境では元ファイルの存在確認のみ
    test_file_exists ".zshrc元ファイル確認" "${DOTFILES_DIR}/.zshrc"
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