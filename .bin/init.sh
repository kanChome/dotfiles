#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh
isRunningOnMac || exit 1

info "init"
if [ $(which xcode-select) = "" ]; then
	xcode-select --install > /dev/null
fi

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null
if [ $(uname -m) = 'arm64' ]; then
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
	echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
	eval "$(/usr/local/bin/brew shellenv)"
fi

# install p10k font
wget -O ~/Downloads/MesloLGSNFRegular.ttf "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
cp MesloLGSNFRegular.ttf ~/Library/Fonts/

success "done init"