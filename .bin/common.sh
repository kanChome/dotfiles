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