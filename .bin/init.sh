#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "init"

if isRunningOnMac; then
	# macOS specific setup
	if ! command -v xcode-select >/dev/null 2>&1; then
		xcode-select --install
	fi
	
	# Install homebrew
	if ! command -v brew >/dev/null 2>&1; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	if [ $(uname -m) = 'arm64' ]; then
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
		eval "$(/opt/homebrew/bin/brew shellenv)"
	else
		echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
		eval "$(/usr/local/bin/brew shellenv)"
	fi
	
	# install p10k font
	wget -O /tmp/MesloLGSNFRegular.ttf "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	mv /tmp/MesloLGSNFRegular.ttf ~/Library/Fonts

elif isRunningOnWSL; then
	# WSL2 specific setup
	info "Setting up for WSL2"
	
	# Update package list
	sudo apt-get update > /dev/null
	
	# Install essential packages
	sudo apt-get install -y curl wget git build-essential > /dev/null
	
	# Install homebrew for Linux
	if ! command -v brew >/dev/null 2>&1; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
	echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	
	# install p10k font (download only, can't install to system fonts in WSL)
	wget -O ~/MesloLGSNFRegular.ttf "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	info "Font downloaded to ~/MesloLGSNFRegular.ttf - install manually in Windows"

else
	error "Unsupported platform: $(uname)"
	exit 1
fi

success "done init"