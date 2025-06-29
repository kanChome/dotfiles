#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

info "init"
debugPlatformInfo

# Xcode Command Line Tools（macOSのみ）
if isRunningOnMac; then
	info "Checking Xcode Command Line Tools"
	if ! xcode-select -p >/dev/null 2>&1; then
		info "Installing Xcode Command Line Tools"
		xcode-select --install
		info "Please complete the Xcode installation and run this script again"
		exit 0
	fi
	success "Xcode Command Line Tools are installed"
fi

# Homebrewのインストール
if ! isHomebrewInstalled; then
	info "Installing Homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	
	HOMEBREW_PATH="$(getHomebrewPath)"
	if [ -n "$HOMEBREW_PATH" ]; then
		BREW_SHELLENV="eval \"\$(${HOMEBREW_PATH}/bin/brew shellenv)\""
		
		# Add to shell profiles if not already present
		for profile in ~/.zprofile ~/.bashrc; do
			if [ -f "$profile" ] && ! grep -q "brew shellenv" "$profile"; then
				echo "$BREW_SHELLENV" >> "$profile"
				info "Added Homebrew to $profile"
			fi
		done
		
		# Apply for current session
		eval "$($HOMEBREW_PATH/bin/brew shellenv)"
		success "Homebrew installed and configured"
	else
		error "Could not determine Homebrew path for platform: $(getPlatformInfo)"
		exit 1
	fi
else
	success "Homebrew is already installed"
fi

# プラットフォーム固有のセットアップ
if isRunningOnMac; then
	# Install PowerLevel10k font
	info "Installing PowerLevel10k font"
	FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	FONT_DIR="$HOME/Library/Fonts"
	FONT_FILE="$FONT_DIR/MesloLGSNFRegular.ttf"
	
	if [ ! -f "$FONT_FILE" ]; then
		mkdir -p "$FONT_DIR"
		curl -fsSL "$FONT_URL" -o "$FONT_FILE"
		success "PowerLevel10k font installed"
	else
		success "PowerLevel10k font already installed"
	fi

elif isRunningOnWSL; then
	info "Setting up WSL environment"
	
	# Update package list
	info "Updating package list"
	sudo apt-get update -qq
	
	# Install essential packages
	info "Installing essential packages"
	sudo apt-get install -y curl wget git build-essential -qq
	
	# Handle PowerLevel10k font for WSL
	info "Installing PowerLevel10k font"
	FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	FONT_NAME="MesloLGSNFRegular.ttf"
	
	# Try automatic installation to Windows
	if installFontToWindows "$FONT_URL" "$FONT_NAME"; then
		success "PowerLevel10k font automatically installed to Windows"
		info "Configure your terminal to use 'MesloLGS NF' font"
	else
		# Fallback to manual installation
		warning "Automatic font installation failed"
		FONT_FILE="$HOME/MesloLGSNFRegular.ttf"
		
		if [ ! -f "$FONT_FILE" ]; then
			curl -fsSL "$FONT_URL" -o "$FONT_FILE"
		fi
		
		warning "Font downloaded to $FONT_FILE"
		warning "Please install this font manually in Windows:"
		warning "1. Open the font file in Windows Explorer"
		warning "2. Right-click and select 'Install'"
		warning "3. Configure your terminal to use 'MesloLGS NF' font"
	fi
	
	success "WSL environment setup complete"

elif isRunningOnLinux; then
	info "Setting up Linux environment"
	
	# Detect package manager and install essentials
	DISTRO="$(getLinuxDistro)"
	case "$DISTRO" in
		ubuntu|debian)
			sudo apt-get update -qq
			sudo apt-get install -y curl wget git build-essential -qq
			;;
		fedora|rhel|centos)
			sudo dnf install -y curl wget git @development-tools
			;;
		arch)
			sudo pacman -S --noconfirm curl wget git base-devel
			;;
		*)
			warning "Unknown distribution: $DISTRO"
			warning "Please install curl, wget, git, and build tools manually"
			;;
	esac
	
	success "Linux environment setup complete"
else
	error "Unsupported platform: $(getPlatformInfo)"
	exit 1
fi

success "Initialization complete for platform: $(getPlatformInfo)"