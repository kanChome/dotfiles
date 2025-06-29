#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# このスクリプトは Phase 2 で実装予定
# brew bundle dump --global で生成された .Brewfile を分離ファイルに逆変換

info "parse-brewfile.sh - Phase 2 で実装予定"
info "目的: .Brewfile を分離ファイル (.Brewfile.common, .Brewfile.macos) に逆変換"

# 将来の実装で以下の機能を提供予定:
# 1. .Brewfile の解析
# 2. パッケージ種別の判定 (brew/cask/mas/vscode)
# 3. 既存の分離ファイルとの差分検出
# 4. 新しいパッケージの適切な分離ファイルへの追加

warning "現在は未実装です。代わりに以下の方法で新しいパッケージを追加してください:"
info "1. 分離ファイルを直接編集:"
info "   vim .Brewfile.common  # CLI tools"
info "   vim .Brewfile.macos   # GUI apps (macOS)"
info "2. packages.sh で反映:"
info "   make packages"
info ""
info "Phase 2 では brew install 後に自動同期する機能を実装予定です。"

exit 0