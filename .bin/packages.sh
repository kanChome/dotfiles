#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# プラットフォーム情報を取得
PLATFORM_INFO="$(getPlatformInfo)"
debug "Platform detected: $PLATFORM_INFO"

# Brewfileを動的に生成する関数
generate_brewfile() {
  local brewfile_path="$(getDotfilesDir)/.Brewfile"
  local common_file="$(getDotfilesDir)/.Brewfile.common"
  local macos_file="$(getDotfilesDir)/.Brewfile.macos"
  
  info "Generating Brewfile for current platform"
  
  # 分離ファイルの存在チェック
  if [[ ! -f "$common_file" ]]; then
    error "Common Brewfile not found: $common_file"
    return 1
  fi
  
  # ヘッダーを追加
  cat > "$brewfile_path" << 'EOF'
# メインBrewfile - このファイルは packages.sh によって自動生成されます
# 直接編集せず、.Brewfile.common や .Brewfile.macos を編集してください
# 
# 新しいパッケージの追加方法:
# 1. 分離ファイルを直接編集: vim .Brewfile.common または .Brewfile.macos
# 2. brew install後に同期: make packages-sync (Phase 2で実装予定)

EOF
  
  # 共通パッケージを追加
  cat "$common_file" >> "$brewfile_path"
  
  # プラットフォーム固有パッケージを追加
  if isRunningOnMac && [[ -f "$macos_file" ]]; then
    echo "" >> "$brewfile_path"
    echo "# macOS固有パッケージ" >> "$brewfile_path"
    cat "$macos_file" >> "$brewfile_path"
  fi
  
  success "Brewfile generated successfully: $brewfile_path"
  
  # brew bundle dump との互換性チェック
  if [[ -L "$HOME/.Brewfile" ]]; then
    debug "~/.Brewfile is correctly linked to dotfiles"
  else
    warning "~/.Brewfile is not linked to dotfiles"
    info "Run 'make link' to fix this"
  fi
}

# Ubuntu/Debianでのパッケージインストール
install_ubuntu_packages() {
  info "Installing Ubuntu/Debian packages"
  
  # パッケージリストを読み込み
  local packages_file="$(getDotfilesDir)/.packages.ubuntu"
  
  if [ ! -f "$packages_file" ]; then
    error "Ubuntu packages file not found: $packages_file"
    return 1
  fi
  
  # パッケージファイルを実行して配列を読み込み
  source "$packages_file"
  
  # システムパッケージリストを更新
  info "Updating apt package list"
  sudo apt update
  
  # APTパッケージをインストール
  if [ ${#apt_packages[@]} -gt 0 ]; then
    info "Installing APT packages"
    for package in "${apt_packages[@]}"; do
      info "Installing apt package: $package"
      sudo apt install -y "$package" || warning "Failed to install: $package"
    done
  fi
  
  # snapdがインストールされているかチェック
  if command -v snap >/dev/null 2>&1; then
    # Snapパッケージをインストール
    if [ ${#snap_packages[@]} -gt 0 ]; then
      info "Installing Snap packages"
      for package in "${snap_packages[@]}"; do
        info "Installing snap package: $package"
        sudo snap install $package || warning "Failed to install snap: $package"
      done
    fi
  else
    warning "snapd is not installed. Skipping snap packages."
    info "To install snapd: sudo apt install snapd"
  fi
  
  # Google Chrome（個別処理）
  install_google_chrome_ubuntu
  
  success "Ubuntu packages installation completed"
}

# Google Chrome for Ubuntu
install_google_chrome_ubuntu() {
  if command -v google-chrome >/dev/null 2>&1; then
    info "Google Chrome is already installed"
    return 0
  fi
  
  info "Installing Google Chrome"
  
  # GPGキーを追加
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  
  # リポジトリを追加
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
  
  # パッケージリストを更新してインストール
  sudo apt update
  sudo apt install -y google-chrome-stable || warning "Failed to install Google Chrome"
}

# VSCode拡張機能をインストール
install_vscode_extensions() {
  if ! command -v code >/dev/null 2>&1; then
    warning "VSCode is not installed. Skipping extension installation."
    return 0
  fi
  
  info "Installing VSCode extensions"
  
  # 共通ファイルからVSCode拡張機能を抽出してインストール
  local common_file="$(getDotfilesDir)/.Brewfile.common"
  
  if [ -f "$common_file" ]; then
    grep '^vscode ' "$common_file" | while read -r line; do
      local extension=$(echo "$line" | sed 's/vscode "\(.*\)"/\1/')
      info "Installing VSCode extension: $extension"
      code --install-extension "$extension" || warning "Failed to install extension: $extension"
    done
  else
    warning "Common Brewfile not found, skipping VSCode extensions"
  fi
  
  success "VSCode extensions installation completed"
}

# Windowsでのパッケージインストール
install_windows_packages() {
  info "Installing Windows packages"
  
  # パッケージリストを確認
  local packages_file="$(getDotfilesDir)/.packages.windows"
  
  if [ ! -f "$packages_file" ]; then
    error "Windows packages file not found: $packages_file"
    return 1
  fi
  
  # Wingetが利用可能かチェック
  if ! command -v winget >/dev/null 2>&1; then
    error "winget is not installed or not available"
    warning "Please install winget or use Windows 10 version 1809 or later"
    return 1
  fi
  
  # パッケージソースを更新
  info "Updating winget package sources"
  winget source update
  
  # パッケージをインポート
  info "Installing packages from .packages.windows"
  winget import -i "$packages_file" --accept-source-agreements --accept-package-agreements || warning "Some packages may have failed to install"
  
  # VSCode拡張機能もインストール
  install_vscode_extensions
  
  success "Windows packages installation completed"
}

# メイン処理
main() {
  info "Starting package installation for platform: $PLATFORM_INFO"
  
  case "$PLATFORM_INFO" in
    macos-*|macos)
      # macOSの場合
      if ! isHomebrewInstalled; then
        error "Homebrew is not installed. Please run init.sh first."
        exit 1
      fi
      
      generate_brewfile
      info "Installing packages with Homebrew"
      brew bundle --global
      success "macOS packages installed successfully"
      ;;
      
    wsl2-ubuntu|linux-ubuntu|linux-debian)
      # Ubuntu/Debianの場合
      install_ubuntu_packages
      
      # Linuxbrewも利用可能な場合は共通パッケージをインストール
      if isHomebrewInstalled; then
        info "Installing CLI tools with Linuxbrew"
        generate_brewfile
        brew bundle --global
      else
        warning "Linuxbrew is not installed. Skipping CLI tools installation."
        info "To install Linuxbrew, run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      fi
      
      install_vscode_extensions
      success "Ubuntu/Debian packages installed successfully"
      ;;
      
    windows)
      # Windowsの場合
      install_windows_packages
      success "Windows packages installed successfully"
      ;;
      
    *)
      warning "Unsupported platform: $PLATFORM_INFO"
      warning "Supported platforms: macOS, Ubuntu/Debian on WSL2 or native Linux, Windows"
      
      # Homebrewが利用可能な場合は最低限のパッケージをインストール
      if isHomebrewInstalled; then
        info "Installing CLI tools with Homebrew/Linuxbrew"
        generate_brewfile
        brew bundle --global
      fi
      ;;
  esac
  
  success "Package installation completed for $PLATFORM_INFO"
}

# デバッグ情報を出力
if [ "${DEBUG:-}" = "1" ]; then
  debugPlatformInfo
fi

# メイン処理を実行
main "$@"