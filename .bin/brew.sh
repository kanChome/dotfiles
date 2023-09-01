#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

isRunningOnMac || exit 1

info "installing brewfile"

brew bundle --global

success "installed brewfile"