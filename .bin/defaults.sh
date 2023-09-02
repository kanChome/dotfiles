#! /bin/sh
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

isRunningOnMac || exit 1

info "Edit defaults"
## Dockを自動的に非表示
defaults write com.apple.dock autohide -bool true

## 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

## .DS_Storeが作成されないようにする
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

## キーのリピートを速くする
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 2

## バッテリー残量を％表示
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

## Dockの表示速度を速くする
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5

## マウス,トラックパットの速度を速くする
defaults write "Apple Global Domain" com.apple.mouse.scaling 11
defaults write -g com.apple.trackpad.scaling 3

## このアプリケーションを開いてもよろしいですか？のダイアログを無効化
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Dockアイコンのスクロールジェスチャーを有効にする
defaults write com.apple.dock scroll-to-open -bool true

# iTerm2の終了時に確認するか聞かれないようにする
defaults write com.googlecode.iterm2 PromptOnQuit -bool false


for app in "Dock" \
  "Finder" \
  "SystemUIServer"; do
  killall "$app" &> /dev/null
done

success "Success to edit defaults"