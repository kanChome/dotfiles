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

# Homebrewのインストール（macOS, WSL, Linuxのみ）
if isRunningOnMac || isRunningOnWSL || isRunningOnLinux; then
	if ! isHomebrewInstalled; then
		info "Installing Homebrew"
		
		# Homebrew インストール（直接実行方式）
		if ! installHomebrew; then
			error "Failed to install Homebrew"
			warning "Please visit https://brew.sh for manual installation instructions"
			exit 1
		fi
		
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
fi

# プラットフォーム固有のセットアップ
if isRunningOnMac; then
	# Install PowerLevel10k font
	info "Installing PowerLevel10k font for macOS"
	FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	FONT_DIR="$HOME/Library/Fonts"
	FONT_FILE="$FONT_DIR/MesloLGSNFRegular.ttf"
	
	if [ ! -f "$FONT_FILE" ]; then
		mkdir -p "$FONT_DIR"
		if safeDownload "$FONT_URL" "$FONT_FILE" "PowerLevel10k font"; then
			success "PowerLevel10k font installed to $FONT_DIR"
			info "Configure your terminal to use 'MesloLGS NF' font family"
		else
			warning "Failed to install PowerLevel10k font"
			info "You can download it manually from: $FONT_URL"
		fi
	else
		success "PowerLevel10k font already installed"
	fi

elif isRunningOnWSL; then
	info "Setting up WSL environment"
	
	# sudo権限確認
	if ! checkSudoAccess; then
		warning "Some operations require sudo access"
		warning "Please run 'sudo echo test' to authenticate, then retry"
	fi
	
	# パッケージリスト更新
	info "Updating package list"
	if checkSudoAccess; then
		sudo apt-get update -qq || warning "Failed to update package list"
	fi
	
	# 必須パッケージのインストール
	info "Installing essential packages"
	if checkSudoAccess; then
		safePackageInstall "apt-get" "curl" "wget" "git" "build-essential" "zsh"
	else
		warning "Cannot install packages without sudo access"
		info "Please install manually: sudo apt-get install curl wget git build-essential"
	fi

	if isPackageInstalled "apt-get" "zsh"; then
		info "Switching shell to zsh..."
		chsh -s $(which zsh)
	fi

	# PowerLevel10k フォントの処理
	info "Installing PowerLevel10k font for WSL"
	FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	FONT_NAME="MesloLGSNFRegular.ttf"
	
	# Windows への自動インストールを試行
	if installFontToWindows "$FONT_URL" "$FONT_NAME"; then
		success "PowerLevel10k font automatically installed to Windows"
		info "Configure your terminal to use 'MesloLGS NF' font"
	else
		# フォールバック: 手動インストール用ダウンロード
		warning "Automatic font installation failed"
		FONT_FILE="$HOME/$FONT_NAME"
		
		if [ ! -f "$FONT_FILE" ]; then
			if safeDownload "$FONT_URL" "$FONT_FILE" "PowerLevel10k font"; then
				warning "Font downloaded to $FONT_FILE"
				warning "Please install this font manually in Windows:"
				warning "1. Open the font file in Windows Explorer"
				warning "2. Right-click and select 'Install'"
				warning "3. Configure your terminal to use 'MesloLGS NF' font"
			else
				warning "Failed to download font"
				info "You can download manually from: $FONT_URL"
			fi
		else
			info "Font already downloaded to $FONT_FILE"
		fi
	fi
	
	success "WSL environment setup complete"

elif isRunningOnLinux; then
	info "Setting up Linux environment"
	
	# sudo権限確認
	if ! checkSudoAccess; then
		warning "Some operations require sudo access"
		warning "Please run 'sudo echo test' to authenticate, then retry"
	fi
	
	# ディストリビューション検出とパッケージインストール
	DISTRO="$(getLinuxDistro)"
	info "Detected Linux distribution: $DISTRO"
	package_manager=""

	if checkSudoAccess; then
		case "$DISTRO" in
			ubuntu|debian)
				sudo apt-get update -qq || warning "Failed to update package list"
				safePackageInstall "apt-get" "curl" "wget" "git" "build-essential" "zsh"
				package_manager="dpkg"
				;;
			fedora|rhel|centos)
				safePackageInstall "dnf" "curl" "wget" "git" "@development-tools" "zsh"
				package_manager="dnf"
				;;
			arch)
				safePackageInstall "pacman" "curl" "wget" "git" "base-devel" "zsh"
				package_manager="pacman"
				;;
			*)
				warning "Unknown distribution: $DISTRO"
				warning "Please install curl, wget, git, and build tools manually"
				info "Common packages needed: curl wget git build-essential (or equivalent)"
				;;
		esac
	else
		warning "Cannot install packages without sudo access"
		info "Please install manually based on your distribution:"
		info "Ubuntu/Debian: sudo apt-get install curl wget git build-essential"
		info "Fedora/RHEL: sudo dnf install curl wget git @development-tools"
		info "Arch: sudo pacman -S curl wget git base-devel"
	fi

	if isPackageInstalled "apt-get" "zsh"; then
		info "Switching shell to zsh..."
		chsh -s $(which zsh)
	fi
	
	success "Linux environment setup complete"

elif isRunningOnWindows; then
	info "Setting up Windows environment"
	
	# PowerShell確認
	checkPowerShell || warning "PowerShell not available - some features may not work"
	
	# winget確認
	checkWinget || warning "winget not available - package management may not work"
	
	# PowerLevel10k フォントインストール
	info "Installing PowerLevel10k font for Windows"
	FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	FONT_NAME="MesloLGSNFRegular.ttf"
	
	if installWindowsFont "$FONT_URL" "$FONT_NAME" "PowerLevel10k (MesloLGS NF)"; then
		info "Font installation completed"
	else
		warning "Font installation failed"
		info "You can download manually from: $FONT_URL"
	fi
	
	# 開発用ツールの確認
	info "Checking development tools"
	if command -v git >/dev/null 2>&1; then
		success "Git is available"
	else
		warning "Git not found"
		info "Please install Git from: https://git-scm.com/"
		info "Or use: winget install Git.Git"
	fi
	
	if command -v curl >/dev/null 2>&1; then
		success "curl is available"
	else
		info "curl not found (optional)"
		info "You can install it via: winget install cURL.cURL"
	fi
	
	success "Windows environment setup complete"
	info "Next steps:"
	info "1. Configure your terminal to use 'MesloLGS NF' font"
	info "2. Run 'make packages' to install additional software"

else
	error "Unsupported platform: $(getPlatformInfo)"
	warning "Supported platforms: macOS, WSL2, Linux, Windows"
	info "Please check your platform detection or report this issue"
	exit 1
fi

success "Initialization complete for platform: $(getPlatformInfo)"