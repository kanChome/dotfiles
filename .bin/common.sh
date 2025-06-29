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

# スクリプトファイルの検証
validateScript() {
  local file="$1"
  local description="${2:-script}"
  
  if [ ! -f "$file" ]; then
    error "File not found: $file"
    return 1
  fi
  
  # ファイルが空でないかチェック
  if [ ! -s "$file" ]; then
    error "$description file is empty"
    return 1
  fi
  
  # HTMLコンテンツの検出（よくあるHTMLタグをチェック）
  local first_few_lines=$(head -10 "$file")
  if echo "$first_few_lines" | grep -qi -E '(<html|<head|<body|<title|<script|<!DOCTYPE)'; then
    error "Downloaded file appears to be HTML content instead of $description"
    debug "First few lines of the file:"
    head -5 "$file" | while IFS= read -r line; do
      debug "  $line"
    done
    return 1
  fi
  
  # Google検索結果ページの検出
  if echo "$first_few_lines" | grep -qi -E '(google\.com|search.*results)'; then
    error "Downloaded file appears to be a Google search page"
    warning "The URL may be blocked or redirected"
    return 1
  fi
  
  # 典型的なエラーページの検出
  if echo "$first_few_lines" | grep -qi -E '(404.*not found|403.*forbidden|500.*error)'; then
    error "Downloaded file appears to be an error page"
    return 1
  fi
  
  # スクリプトファイルの場合、shebangをチェック
  if [[ "$description" == *"script"* ]] || [[ "$file" == *.sh ]]; then
    local first_line=$(head -1 "$file")
    if [[ "$first_line" != \#!* ]]; then
      warning "$description does not start with a shebang"
      warning "First line: $first_line"
      # これは警告のみで、エラーにはしない（some scriptsはshebangなしでも動作）
    fi
  fi
  
  debug "$description validation passed"
  return 0
}

# 安全なダウンロード（スクリプト検証付き）
safeDownload() {
  local url="$1"
  local output="$2"
  local description="${3:-file}"
  local validate_as_script="${4:-false}"
  
  info "Downloading $description"
  debug "URL: $url"
  debug "Output: $output"
  debug "Validate as script: $validate_as_script"
  
  # インターネット接続確認
  if ! checkInternetConnection; then
    error "No internet connection available"
    warning "Please check your network connection and try again"
    warning "If you're behind a corporate firewall, you may need to configure proxy settings"
    return 1
  fi
  
  # 複数のダウンロード方法とURL
  local download_methods=()
  local urls=()
  
  # URLに応じてフォールバックURLを準備
  if [[ "$url" == *"raw.githubusercontent.com"* ]]; then
    urls=("$url")
    # GitHubの場合、jsdelivr CDNをフォールバックとして追加
    local jsdelivr_url=$(echo "$url" | sed 's|raw\.githubusercontent\.com/\([^/]*\)/\([^/]*\)/\([^/]*\)/|cdn.jsdelivr.net/gh/\1/\2@\3/|')
    urls+=("$jsdelivr_url")
    # fastgit mirrorも追加（中国からのアクセス等で有効）
    local fastgit_url=$(echo "$url" | sed 's|raw\.githubusercontent\.com|raw.fastgit.org|')
    urls+=("$fastgit_url")
  elif [[ "$url" == *"github.com"* ]] && [[ "$url" == *"/raw/"* ]]; then
    urls=("$url")
    # fastgit mirror
    local fastgit_url=$(echo "$url" | sed 's|github\.com|hub.fastgit.org|')
    urls+=("$fastgit_url")
  else
    urls=("$url")
  fi
  
  # 各URLとメソッドを試行
  local max_retries=3
  local retry_count=0
  local total_attempts=0
  local max_total_attempts=$((${#urls[@]} * max_retries))
  
  for attempt_url in "${urls[@]}"; do
    retry_count=0
    while [ $retry_count -lt $max_retries ] && [ $total_attempts -lt $max_total_attempts ]; do
      total_attempts=$((total_attempts + 1))
      
      debug "Attempt $total_attempts/$max_total_attempts: $attempt_url"
      
      # ダウンロード実行
      if curl -fsSL --connect-timeout 30 --max-time 300 \
           -H "User-Agent: Mozilla/5.0 (compatible; dotfiles-installer)" \
           -H "Accept: text/plain, text/x-shellscript, application/octet-stream" \
           "$attempt_url" -o "$output"; then
        
        # スクリプトファイルの場合は内容を検証
        if [ "$validate_as_script" = "true" ]; then
          if validateScript "$output" "$description"; then
            success "$description downloaded and validated successfully"
            return 0
          else
            warning "Downloaded file validation failed, trying next method..."
            rm -f "$output" 2>/dev/null || true
            retry_count=$((retry_count + 1))
            continue
          fi
        else
          success "$description downloaded successfully"
          return 0
        fi
      else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
          warning "Download failed. Retrying ($retry_count/$max_retries) with $attempt_url..."
          sleep $((retry_count * 2))  # exponential backoff
        else
          warning "All retries failed for URL: $attempt_url"
        fi
      fi
    done
  done
  
  error "Failed to download $description after $total_attempts attempts"
  warning "Tried URLs:"
  for tried_url in "${urls[@]}"; do
    warning "  - $tried_url"
  done
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