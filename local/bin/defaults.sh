#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

if isRunningOnMac; then
  info "Edit defaults"
else
  info "Skip defaults"
  exit 0
fi

info "Edit defaults"
## Dockを自動的に非表示
defaults write com.apple.dock autohide -bool true

## 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

## .DS_Storeが作成されないようにする
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

## キーのリピートを速くする
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 2

## バッテリー残量を％表示
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

## Dockの表示速度を速くする
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5

## マウス,トラックパットの速度を速くする
defaults write -g com.apple.mouse.scaling -float 11
defaults write -g com.apple.trackpad.scaling -float 3

## このアプリケーションを開いてもよろしいですか？のダイアログを無効化
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Dockアイコンのスクロールジェスチャーを有効にする
defaults write com.apple.dock scroll-to-open -bool true

# iTerm2の終了時に確認するか聞かれないようにする
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# 数字を常に半角にする
defaults write com.apple.inputmethod.Kotoeri JIMPrefFullWidthNumeralCharactersKey -int 0

for app in "Dock" \
  "Finder" \
  "SystemUIServer"; do
  killall "$app" &> /dev/null || true
done

success "Success to edit defaults"
