#!/bin/bash

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

error () {
  printf "\r\033[2K  [\033[0;31mERROR\033[0m] $1\n"
}

warning () {
  printf "\r\033[2K  [\033[0;33mWARN\033[0m] $1\n"
}

debug () {
  if [ "${DEBUG:-}" = "1" ]; then
    printf "\r  [ \033[00;90mDEBUG\033[0m ] $1\n"
  fi
}

# 基本的なプラットフォーム検出
isRunningOnMac () {
  [ "$(uname)" = "Darwin" ]
}

isRunningOnWSL () {
  [ -f /proc/version ] && grep -q microsoft /proc/version
}

isRunningOnLinux () {
  [ "$(uname)" = "Linux" ]
}

isRunningOnWindows () {
  case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS*) return 0 ;;
    *) return 1 ;;
  esac
}

# 詳細なプラットフォーム検出
isRunningOnMacARM () {
  isRunningOnMac && [ "$(uname -m)" = "arm64" ]
}

isRunningOnMacIntel () {
  isRunningOnMac && [ "$(uname -m)" = "x86_64" ]
}

isRunningOnWSL1 () {
  isRunningOnWSL && [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]
}

isRunningOnWSL2 () {
  isRunningOnWSL && [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]
}

getLinuxDistro () {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

# プラットフォーム情報を取得
getPlatformInfo () {
  local platform=""
  local arch="$(uname -m)"
  local distro=""
  
  if isRunningOnMac; then
    platform="macos"
    if isRunningOnMacARM; then
      platform="macos-arm"
    elif isRunningOnMacIntel; then
      platform="macos-intel"
    fi
  elif isRunningOnWSL; then
    distro="$(getLinuxDistro)"
    if isRunningOnWSL2; then
      platform="wsl2-${distro}"
    else
      platform="wsl1-${distro}"
    fi
  elif isRunningOnLinux; then
    distro="$(getLinuxDistro)"
    platform="linux-${distro}"
  elif isRunningOnWindows; then
    platform="windows"
  else
    platform="unknown"
  fi
  
  echo "${platform}"
}

# Homebrewのパスを動的に取得
getHomebrewPath () {
  if isRunningOnMac; then
    if isRunningOnMacARM; then
      echo "/opt/homebrew"
    else
      echo "/usr/local"
    fi
  elif isRunningOnWSL || isRunningOnLinux; then
    echo "/home/linuxbrew/.linuxbrew"
  else
    return 1
  fi
}

# Homebrewがインストールされているかチェック
isHomebrewInstalled () {
  command -v brew >/dev/null 2>&1
}

# Windowsのフォントディレクトリを取得（WSL用）
getWindowsFontDir () {
  if isRunningOnWSL; then
    local windows_root
    # WSL2では通常 /mnt/c でWindowsにアクセス可能
    if [ -d "/mnt/c/Windows" ]; then
      windows_root="/mnt/c"
    elif [ -d "/c/Windows" ]; then
      windows_root="/c"
    else
      return 1
    fi
    
    # Windowsのフォントディレクトリパス
    echo "${windows_root}/Windows/Fonts"
  else
    return 1
  fi
}

# WSL2でWindowsにフォントをインストール
installFontToWindows () {
  local font_url="$1"
  local font_name="$2"
  
  if ! isRunningOnWSL; then
    error "This function is only for WSL environments"
    return 1
  fi
  
  local windows_fonts_dir
  windows_fonts_dir="$(getWindowsFontDir)"
  
  if [ $? -ne 0 ] || [ ! -d "$windows_fonts_dir" ]; then
    warning "Could not access Windows fonts directory"
    warning "Please install font manually:"
    warning "1. Download font to Windows"
    warning "2. Right-click and select 'Install'"
    return 1
  fi
  
  # フォントファイルをダウンロード
  local temp_font="/tmp/${font_name}"
  info "Downloading font: $font_name"
  
  if curl -fsSL "$font_url" -o "$temp_font"; then
    # Windowsフォントディレクトリにコピー
    if cp "$temp_font" "$windows_fonts_dir/"; then
      success "Font installed to Windows: $font_name"
      rm -f "$temp_font"
      
      # フォントキャッシュを更新（試行）
      info "Refreshing font cache (this may take a moment)"
      if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "& {Add-Type -AssemblyName System.Drawing; [System.Drawing.Text.InstalledFontCollection]::new().Dispose()}" 2>/dev/null || true
      fi
      
      return 0
    else
      error "Failed to copy font to Windows directory"
      warning "You may need to run with administrator privileges"
      rm -f "$temp_font"
      return 1
    fi
  else
    error "Failed to download font from: $font_url"
    return 1
  fi
}

# CI環境の検出
isRunningOnCI () {
  [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]
}

# dotfilesディレクトリのパスを取得
getDotfilesDir () {
  if isRunningOnCI; then
    # CI環境では現在のディレクトリを使用
    echo "$(pwd)"
  elif [ -n "${DOTFILES_DIR:-}" ]; then
    # 環境変数が設定されている場合
    echo "$DOTFILES_DIR"
  elif [ -d "${HOME}/dotfiles" ]; then
    # 標準的な場所
    echo "${HOME}/dotfiles"
  else
    # スクリプトの親ディレクトリを推測
    echo "$(cd "$(dirname "$0")/.." && pwd)"
  fi
}

# プラットフォーム情報をデバッグ出力
debugPlatformInfo () {
  debug "Platform: $(getPlatformInfo)"
  debug "Architecture: $(uname -m)"
  debug "CI Environment: $(isRunningOnCI && echo 'Yes' || echo 'No')"
  debug "Dotfiles directory: $(getDotfilesDir)"
  debug "Homebrew path: $(getHomebrewPath 2>/dev/null || echo 'N/A')"
  debug "Homebrew installed: $(isHomebrewInstalled && echo 'Yes' || echo 'No')"
  if isRunningOnWSL; then
    debug "Windows fonts dir: $(getWindowsFontDir 2>/dev/null || echo 'N/A')"
  fi
}

# エラーハンドリング関数

# インターネット接続確認
checkInternetConnection() {
  local test_urls=("https://www.google.com" "https://github.com" "https://raw.githubusercontent.com")
  
  for url in "${test_urls[@]}"; do
    if curl -s --connect-timeout 10 --max-time 30 --head "$url" >/dev/null 2>&1; then
      debug "Internet connection confirmed via $url"
      return 0
    fi
  done
  
  return 1
}

# 安全なダウンロード
safeDownload() {
  local url="$1"
  local output="$2"
  local description="${3:-file}"
  
  info "Downloading $description"
  debug "URL: $url"
  debug "Output: $output"
  
  # インターネット接続確認
  if ! checkInternetConnection; then
    error "No internet connection available"
    warning "Please check your network connection and try again"
    warning "If you're behind a corporate firewall, you may need to configure proxy settings"
    return 1
  fi
  
  # ダウンロード実行（リトライ付き）
  local max_retries=3
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    if curl -fsSL --connect-timeout 30 --max-time 300 "$url" -o "$output"; then
      success "$description downloaded successfully"
      return 0
    else
      retry_count=$((retry_count + 1))
      if [ $retry_count -lt $max_retries ]; then
        warning "Download failed. Retrying ($retry_count/$max_retries)..."
        sleep 2
      fi
    fi
  done
  
  error "Failed to download $description after $max_retries attempts"
  warning "Please check the URL: $url"
  return 1
}

# sudo権限チェック
checkSudoAccess() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    debug "Running as root"
    return 0
  fi
  
  if sudo -n true 2>/dev/null; then
    debug "Sudo access available (passwordless)"
    return 0
  fi
  
  info "Checking sudo access"
  if sudo -v 2>/dev/null; then
    debug "Sudo access confirmed"
    return 0
  else
    warning "Sudo access not available"
    return 1
  fi
}

# パッケージインストール（エラー耐性）
safePackageInstall() {
  local package_manager="$1"
  shift
  local packages=("$@")
  local failed_packages=()
  
  info "Installing packages with $package_manager"
  
  for package in "${packages[@]}"; do
    info "Installing: $package"
    case "$package_manager" in
      apt|apt-get)
        if ! sudo apt-get install -y "$package" -qq 2>/dev/null; then
          warning "Failed to install: $package"
          failed_packages+=("$package")
        fi
        ;;
      dnf)
        if ! sudo dnf install -y "$package" -q 2>/dev/null; then
          warning "Failed to install: $package"
          failed_packages+=("$package")
        fi
        ;;
      pacman)
        if ! sudo pacman -S --noconfirm "$package" 2>/dev/null; then
          warning "Failed to install: $package"
          failed_packages+=("$package")
        fi
        ;;
      *)
        error "Unknown package manager: $package_manager"
        return 1
        ;;
    esac
  done
  
  if [ ${#failed_packages[@]} -gt 0 ]; then
    warning "Some packages failed to install: ${failed_packages[*]}"
    warning "You may need to install them manually later"
    info "Failed packages: ${failed_packages[*]}"
    return 1
  else
    success "All packages installed successfully"
    return 0
  fi
}

# Windows環境での PowerShell 確認
checkPowerShell() {
  if command -v pwsh >/dev/null 2>&1; then
    success "PowerShell Core (pwsh) is available"
    return 0
  elif command -v powershell >/dev/null 2>&1; then
    success "Windows PowerShell is available"
    return 0
  else
    warning "PowerShell is not available"
    info "Please install PowerShell Core from:"
    info "https://github.com/PowerShell/PowerShell"
    return 1
  fi
}

# Windows環境での winget 確認
checkWinget() {
  if command -v winget >/dev/null 2>&1; then
    local winget_version=$(winget --version 2>/dev/null || echo "unknown")
    success "winget is available (version: $winget_version)"
    return 0
  else
    warning "winget is not available"
    info "Please install Windows Package Manager from:"
    info "https://aka.ms/getwinget"
    info "Or update to Windows 10 version 1809 or later / Windows 11"
    return 1
  fi
}

# Windows環境でのフォントインストール
installWindowsFont() {
  local font_url="$1"
  local font_name="$2"
  local description="${3:-$font_name}"
  
  info "Installing Windows font: $description"
  
  # ユーザーフォントディレクトリにダウンロード
  local user_fonts_dir="$HOME/AppData/Local/Microsoft/Windows/Fonts"
  local font_file="$user_fonts_dir/$font_name"
  
  # ディレクトリ作成
  mkdir -p "$user_fonts_dir" 2>/dev/null || true
  
  # フォントダウンロード
  if safeDownload "$font_url" "$font_file" "$description font"; then
    success "Font downloaded to user directory: $font_file"
    info "Please configure your terminal to use the font: $description"
    return 0
  else
    # フォールバック: 一時ディレクトリにダウンロード
    local temp_font="/tmp/$font_name"
    if safeDownload "$font_url" "$temp_font" "$description font"; then
      warning "Font downloaded to temporary location: $temp_font"
      warning "Please install this font manually:"
      warning "1. Double-click the font file to open it"
      warning "2. Click 'Install' button"
      warning "3. Configure your terminal to use the font"
      return 0
    else
      error "Failed to download font: $description"
      return 1
    fi
  fi
}

# Homebrewインストール（直接実行方式）
installHomebrew() {
  info "Installing Homebrew"
  
  # 複数のURL（フォールバック対応）
  local urls=(
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    "https://cdn.jsdelivr.net/gh/Homebrew/install@HEAD/install.sh"
    "https://raw.fastgit.org/Homebrew/install/HEAD/install.sh"
  )
  
  # インターネット接続確認
  if ! checkInternetConnection; then
    error "Cannot install Homebrew: No internet connection"
    warning "Please check your network connection and try again"
    return 1
  fi
  
  local attempt=0
  local max_attempts=${#urls[@]}
  
  for url in "${urls[@]}"; do
    attempt=$((attempt + 1))
    info "Homebrew install attempt $attempt/$max_attempts"
    debug "Trying URL: $url"
    
    # 直接実行方式：curl の出力を直接 bash に渡す
    if /bin/bash -c "$(curl -fsSL --connect-timeout 30 --max-time 300 --retry 2 \
                      -H 'User-Agent: dotfiles-installer/1.0' \
                      -H 'Accept: text/plain, application/x-sh' \
                      \"$url\")"; then
      success "Homebrew installed successfully from: $url"
      
      # インストール確認
      local homebrew_path
      homebrew_path="$(getHomebrewPath)"
      if [ -n "$homebrew_path" ] && [ -x "$homebrew_path/bin/brew" ]; then
        success "Homebrew binary confirmed at: $homebrew_path/bin/brew"
        return 0
      else
        warning "Homebrew installed but binary not found at expected location"
        # PATH確認のために一度sourceしてみる
        if command -v brew >/dev/null 2>&1; then
          success "Homebrew is available in PATH"
          return 0
        else
          warning "Homebrew binary not found in PATH either"
        fi
      fi
    else
      local exit_code=$?
      warning "Homebrew install failed from URL: $url (exit code: $exit_code)"
      
      # 最後の試行でない場合は継続
      if [ $attempt -lt $max_attempts ]; then
        info "Trying next URL..."
        sleep 3
      fi
    fi
  done
  
  # 全てのURLで失敗
  error "Failed to install Homebrew from all available sources"
  warning "URLs tried:"
  for url in "${urls[@]}"; do
    warning "  - $url"
  done
  warning ""
  warning "Manual installation instructions:"
  warning "1. Visit https://brew.sh"
  warning "2. Copy and run the installation command"
  warning "3. Follow the on-screen instructions"
  
  if isRunningOnCI; then
    warning ""
    warning "CI Environment troubleshooting:"
    warning "- Check if GitHub/CDN access is blocked"
    warning "- Verify network connectivity in CI environment"
    warning "- Consider using a different base image or runner"
  fi
  
  return 1
}