#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${SCRIPT_DIR}/common.sh

# Phase 2: Brewfile双方向変換機能
# このスクリプトは .Brewfile を解析して分離ファイルに逆変換します

DOTFILES_DIR="$(getDotfilesDir)"
BREWFILE="$DOTFILES_DIR/.Brewfile"
COMMON_FILE="$DOTFILES_DIR/.Brewfile.common"
MACOS_FILE="$DOTFILES_DIR/.Brewfile.macos"
BACKUP_DIR="$DOTFILES_DIR/.backups"
DRY_RUN=false
FORCE=false

# ヘルプメッセージ
show_help() {
    cat << 'EOF'
parse-brewfile.sh - Brewfile双方向変換ツール

使用方法:
  parse-brewfile.sh [OPTIONS] [COMMAND]

コマンド:
  generate    分離ファイルから .Brewfile を生成（デフォルト）
  parse       .Brewfile を解析して分離ファイルに同期
  sync        brew bundle dump → 分離ファイル同期
  diff        現在のインストール状況と分離ファイルの差分表示

オプション:
  -d, --dry-run    実際の変更をせず、実行内容を表示
  -f, --force      確認なしで変更を実行
  -h, --help       このヘルプを表示
  -v, --verbose    詳細ログを表示

例:
  parse-brewfile.sh                    # .Brewfile生成
  parse-brewfile.sh parse              # .Brewfile解析
  parse-brewfile.sh sync -d            # dry-runで同期確認
  parse-brewfile.sh diff               # 差分表示

EOF
}

# バックアップディレクトリ作成
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        debug "Backup directory created: $BACKUP_DIR"
    fi
}

# ファイルのバックアップ
backup_file() {
    local file="$1"
    local timestamp="$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        create_backup_dir
        local backup_file="$BACKUP_DIR/$(basename "$file").backup.$timestamp"
        cp "$file" "$backup_file"
        debug "Backup created: $backup_file"
        return 0
    fi
    return 1
}

# パッケージ種別の判定
determine_package_type() {
    local line="$1"
    
    # tapの場合
    if [[ "$line" =~ ^tap\ .*$ ]]; then
        echo "tap"
        return 0
    fi
    
    # caskの場合
    if [[ "$line" =~ ^cask\ .*$ ]]; then
        echo "cask"
        return 0
    fi
    
    # masの場合  
    if [[ "$line" =~ ^mas\ .*$ ]]; then
        echo "mas"
        return 0
    fi
    
    # vscodeの場合
    if [[ "$line" =~ ^vscode\ .*$ ]]; then
        echo "vscode"
        return 0
    fi
    
    # brewの場合
    if [[ "$line" =~ ^brew\ .*$ ]]; then
        echo "brew"
        return 0
    fi
    
    # その他・コメント等
    echo "other"
}

# パッケージ名の抽出
extract_package_name() {
    local line="$1"
    
    # 最初の引用符で囲まれた部分を抽出
    if [[ "$line" =~ \"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # 引用符がない場合、スペース区切りの第2要素
        echo "$line" | awk '{print $2}'
    fi
}

# パッケージの分類判定（より詳細）
classify_package() {
    local pkg_type="$1"
    local pkg_name="$2"
    local line="$3"
    
    case "$pkg_type" in
        "tap")
            # フォント関連tapは macOS専用
            if [[ "$pkg_name" =~ font ]] || [[ "$pkg_name" =~ cask-font ]]; then
                echo "macos"
            else
                echo "common"
            fi
            ;;
        "brew")
            # GUI開発ツールは macOS専用として扱う
            if [[ "$pkg_name" =~ ^(emacs|firefox)$ ]]; then
                echo "macos"
            else
                echo "common"
            fi
            ;;
        "cask"|"mas")
            echo "macos"
            ;;
        "vscode")
            echo "common"
            ;;
        *)
            echo "common"
            ;;
    esac
}

# .Brewfile解析メイン関数
parse_brewfile() {
    local brewfile="$1"
    
    if [ ! -f "$brewfile" ]; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Parsing Brewfile: $brewfile"
    
    # 一時ファイルの作成
    local temp_common="/tmp/brewfile_common.tmp"
    local temp_macos="/tmp/brewfile_macos.tmp"
    
    > "$temp_common"
    > "$temp_macos"
    
    local line_num=0
    local common_count=0
    local macos_count=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # 空行やコメントはスキップ
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 自動生成ヘッダーはスキップ
        if [[ "$line" =~ ^#.*自動生成 ]]; then
            continue
        fi
        
        local pkg_type=$(determine_package_type "$line")
        
        if [ "$pkg_type" = "other" ]; then
            debug "Skipping line $line_num: $line"
            continue
        fi
        
        local pkg_name=$(extract_package_name "$line")
        local classification=$(classify_package "$pkg_type" "$pkg_name" "$line")
        
        debug "Line $line_num: $pkg_type '$pkg_name' -> $classification"
        
        case "$classification" in
            "common")
                echo "$line" >> "$temp_common"
                common_count=$((common_count + 1))
                ;;
            "macos")
                echo "$line" >> "$temp_macos"
                macos_count=$((macos_count + 1))
                ;;
        esac
        
    done < "$brewfile"
    
    info "Parsed $line_num lines: $common_count common, $macos_count macOS packages"
    
    # 分離ファイルの更新
    if [ "$DRY_RUN" = "false" ]; then
        update_separated_files "$temp_common" "$temp_macos"
    else
        info "[DRY RUN] Would update separated files"
        info "Common packages:"
        cat "$temp_common" | head -10
        if [ $common_count -gt 10 ]; then
            info "... and $((common_count - 10)) more"
        fi
        info "macOS packages:"
        cat "$temp_macos" | head -10
        if [ $macos_count -gt 10 ]; then
            info "... and $((macos_count - 10)) more"
        fi
    fi
    
    # 一時ファイルのクリーンアップ
    rm -f "$temp_common" "$temp_macos"
}

# 分離ファイルの更新
update_separated_files() {
    local temp_common="$1"
    local temp_macos="$2"
    
    # バックアップ作成
    backup_file "$COMMON_FILE"
    backup_file "$MACOS_FILE"
    
    # 新しいパッケージのマージ処理
    merge_packages "$COMMON_FILE" "$temp_common" "common"
    merge_packages "$MACOS_FILE" "$temp_macos" "macos"
    
    success "Separated files updated successfully"
}

# パッケージのマージ
merge_packages() {
    local target_file="$1"
    local temp_file="$2"
    local file_type="$3"
    
    if [ ! -s "$temp_file" ]; then
        debug "No new packages for $file_type"
        return 0
    fi
    
    local added_count=0
    
    # 既存ファイルが存在しない場合は新規作成
    if [ ! -f "$target_file" ]; then
        info "Creating new $file_type file: $target_file"
        create_file_header "$target_file" "$file_type"
    fi
    
    # 新しいパッケージの追加
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # 既に存在するかチェック
        if ! grep -Fxq "$line" "$target_file" 2>/dev/null; then
            echo "$line" >> "$target_file"
            added_count=$((added_count + 1))
            debug "Added to $file_type: $line"
        fi
    done < "$temp_file"
    
    if [ $added_count -gt 0 ]; then
        success "Added $added_count new packages to $file_type file"
    else
        info "No new packages to add to $file_type file"
    fi
}

# ファイルヘッダーの作成
create_file_header() {
    local file="$1"
    local type="$2"
    
    case "$type" in
        "common")
            cat > "$file" << 'EOF'
# 共通パッケージ（全プラットフォーム対応）
EOF
            ;;
        "macos")
            cat > "$file" << 'EOF'
# macOS専用パッケージ（cask + mas）
EOF
            ;;
    esac
}

# 差分表示機能
show_diff() {
    info "Showing differences between installed packages and separated files"
    
    if ! command -v brew >/dev/null 2>&1; then
        warning "Homebrew not found, skipping brew package diff"
        return 1
    fi
    
    # 現在のインストール状況をダンプ
    local current_brewfile="/tmp/current.Brewfile"
    info "Dumping current packages..."
    
    if brew bundle dump --file="$current_brewfile" --force 2>/dev/null; then
        success "Current packages dumped to $current_brewfile"
    else
        error "Failed to dump current packages"
        return 1
    fi
    
    # 分離ファイルから生成したBrewfileと比較
    generate_brewfile_from_separated
    
    if [ -f "$BREWFILE" ] && [ -f "$current_brewfile" ]; then
        info "Comparing files..."
        if diff -u "$BREWFILE" "$current_brewfile" > /tmp/brewfile.diff; then
            success "No differences found"
        else
            warning "Differences found:"
            cat /tmp/brewfile.diff
        fi
    fi
    
    # クリーンアップ
    rm -f "$current_brewfile" /tmp/brewfile.diff
}

# 分離ファイルから .Brewfile 生成
generate_brewfile_from_separated() {
    info "Generating .Brewfile from separated files"
    
    if [ ! -f "$COMMON_FILE" ]; then
        error "Common file not found: $COMMON_FILE"
        return 1
    fi
    
    if [ "$DRY_RUN" = "false" ]; then
        backup_file "$BREWFILE"
    fi
    
    # ヘッダーを生成
    cat > "$BREWFILE" << 'EOF'
# メインBrewfile - このファイルは packages.sh によって自動生成されます
# 直接編集せず、.Brewfile.common や .Brewfile.macos を編集してください
# 
# 新しいパッケージの追加方法:
# 1. 分離ファイルを直接編集: vim .Brewfile.common または .Brewfile.macos
# 2. brew install後に同期: make packages-sync

EOF
    
    # 共通パッケージを追加
    if [ "$DRY_RUN" = "false" ]; then
        cat "$COMMON_FILE" >> "$BREWFILE"
    else
        info "[DRY RUN] Would add common packages from: $COMMON_FILE"
    fi
    
    # macOS固有パッケージを追加
    if isRunningOnMac && [ -f "$MACOS_FILE" ]; then
        if [ "$DRY_RUN" = "false" ]; then
            echo "" >> "$BREWFILE"
            echo "# macOS固有パッケージ" >> "$BREWFILE"
            cat "$MACOS_FILE" >> "$BREWFILE"
        else
            info "[DRY RUN] Would add macOS packages from: $MACOS_FILE"
        fi
    fi
    
    if [ "$DRY_RUN" = "false" ]; then
        success ".Brewfile generated successfully"
    else
        info "[DRY RUN] Would generate .Brewfile"
    fi
}

# sync コマンド実装
sync_packages() {
    info "Syncing packages: brew bundle dump → separated files"
    
    if ! command -v brew >/dev/null 2>&1; then
        error "Homebrew not found"
        return 1
    fi
    
    # 現在のパッケージをダンプ
    local dump_file="/tmp/sync_dump.Brewfile"
    info "Dumping current packages..."
    
    if brew bundle dump --file="$dump_file" --force 2>/dev/null; then
        success "Current packages dumped"
    else
        error "Failed to dump current packages"
        return 1
    fi
    
    # 確認プロンプト（force でない場合）
    if [ "$FORCE" = "false" ] && [ "$DRY_RUN" = "false" ]; then
        info "This will update your separated package files based on currently installed packages."
        read -p "Continue? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Cancelled"
            rm -f "$dump_file"
            return 0
        fi
    fi
    
    # ダンプしたファイルを解析
    parse_brewfile "$dump_file"
    
    # 分離ファイルから .Brewfile を再生成
    generate_brewfile_from_separated
    
    # クリーンアップ
    rm -f "$dump_file"
    
    success "Package sync completed"
}

# メイン処理
main() {
    local command="${1:-generate}"
    
    case "$command" in
        "generate")
            generate_brewfile_from_separated
            ;;
        "parse")
            if [ ! -f "$BREWFILE" ]; then
                error "Brewfile not found: $BREWFILE"
                error "Run 'brew bundle dump --global' first"
                exit 1
            fi
            parse_brewfile "$BREWFILE"
            ;;
        "sync")
            sync_packages
            ;;
        "diff")
            show_diff
            ;;
        "-h"|"--help"|"help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# コマンドライン引数解析
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            DEBUG=1
            shift
            ;;
        generate|parse|sync|diff|help)
            COMMAND="$1"
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# コマンド実行
if [ -z "$COMMAND" ]; then
    main "generate"
else
    main "$COMMAND"
fi