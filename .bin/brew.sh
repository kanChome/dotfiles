#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

if ! isRunningOnMac && ! isRunningOnWSL; then
	error "This script requires macOS or WSL"
	exit 1
fi

info "installing brewfile"

brew bundle --global

success "installed brewfile"