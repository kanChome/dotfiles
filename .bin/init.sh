#!/bin/bash
set -eu

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi
source ./common.sh

info "init"
xcode-select --install > /dev/null

# Install homebrew
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null
info "done init"