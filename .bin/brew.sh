#!/bin/bash
set -eu

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

source ./common.sh

info "installing brewfile"

brew bundle --global

success "installed brewfile"