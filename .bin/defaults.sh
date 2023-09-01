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
defaults write com.apple.dock autohide-time-modifier -float 0.7


for app in "Dock" \
  "Finder" \
  "SystemUIServer"; do
  killall "$app" &> /dev/null
done

success "Success to edit defaults"