#!/bin/bash
set -eu

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ln -fnsv "$SCRIPT_DIR/Brewfile" "$HOME"

brew bundle