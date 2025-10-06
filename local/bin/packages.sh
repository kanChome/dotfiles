#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# Mac専用: パッケージ管理の薄いフロントエンド
# サブコマンド:
#   install        -> Brewfile生成 + brew bundle --global
#   brew:generate  -> 分離ファイルからBrewfile生成
#   brew:parse     -> Brewfileを分離ファイルに反映
#   brew:sync      -> 現在の環境を分離ファイルへ同期
#   brew:diff      -> 生成Brewfileと現在の環境の差分
#   status         -> 簡易ステータス表示

BREWFILES_DIR="$(getDotfilesDir)/local/share/dotfiles/brewfiles"
BREWFILE="$BREWFILES_DIR/Brewfile"
COMMON_FILE="$BREWFILES_DIR/Brewfile.common"
MACOS_FILE="$BREWFILES_DIR/Brewfile.macos"

require_macos() {
  if ! isRunningOnMac; then
    error "このスクリプトはmacOS専用です (detected: $(getPlatformInfo))"
    exit 1
  fi
}

ensure_brew() {
  if ! isHomebrewInstalled; then
    error "Homebrewが未インストールです。先に 'make init' を実行してください。"
    exit 1
  fi
}

brew_generate() {
  require_macos
  "$SCRIPT_DIR/parse-brewfile.sh" generate
}

brew_parse() {
  require_macos
  "$SCRIPT_DIR/parse-brewfile.sh" parse
}

brew_sync() {
  require_macos
  "$SCRIPT_DIR/parse-brewfile.sh" sync
}

brew_diff() {
  require_macos
  "$SCRIPT_DIR/parse-brewfile.sh" diff
}

status() {
  require_macos
  info "Platform: $(getPlatformInfo)"
  info "Homebrew: $(isHomebrewInstalled && echo 'installed' || echo 'missing')"
  info "Brewfiles dir: $BREWFILES_DIR"
  if [ -f "$COMMON_FILE" ]; then
    info "  common: $(grep -c '^[^#[:space:]]' "$COMMON_FILE" 2>/dev/null || echo 0) entries"
  else
    warning "  common file not found: $COMMON_FILE"
  fi
  if [ -f "$MACOS_FILE" ]; then
    info "  macos : $(grep -c '^[^#[:space:]]' "$MACOS_FILE" 2>/dev/null || echo 0) entries"
  fi
  if [ -f "$BREWFILE" ]; then
    info "  Brewfile present: $BREWFILE"
  else
    warning "  Brewfile not generated yet"
  fi
  if [[ -L "$HOME/.Brewfile" ]]; then
    success "~/.Brewfile symlink is present"
  else
    warning "~/.Brewfile symlink not found (run 'make link')"
  fi
}

install_macos() {
  require_macos
  ensure_brew
  info "Brewfileを生成します"
  brew_generate
  info "Homebrewでインストールします (brew bundle --global)"
  brew bundle --global
  success "macOSパッケージのインストールが完了しました"
}

main() {
  local cmd="${1:-install}"
  case "$cmd" in
    install)       install_macos ;;
    brew:generate) brew_generate ;;
    brew:parse)    brew_parse ;;
    brew:sync)     brew_sync ;;
    brew:diff)     brew_diff ;;
    status)        status ;;
    *)
      error "不明なコマンド: $cmd"
      echo "利用可能: install | brew:generate | brew:parse | brew:sync | brew:diff | status"
      exit 1
      ;;
  esac
}

main "$@"

# デバッグ情報を出力
if [ "${DEBUG:-}" = "1" ]; then
  debugPlatformInfo
fi

# メイン処理を実行
main "$@"
