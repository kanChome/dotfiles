#! /bin/sh
set -eu

source ./common.sh

info "Edit defaults"
## Dockを自動的に非表示
defaults write com.apple.dock autohide -bool true

## 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

## .DS_Storeが作成されないようにする
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
killall Finder

success "Success to edit defaults"