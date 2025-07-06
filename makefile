all: init link defaults packages

init:
	local/bin/init.sh

link:
	local/bin/link.sh

defaults:
	local/bin/defaults.sh

packages:
	local/bin/packages.sh

# 後方互換性のため brew エイリアスを保持
brew: packages

test:
	local/bin/test.sh

verify:
	local/bin/verify.sh

ci: test
	@echo "CI用の軽量テストを実行"

packages-sync:
	@echo "brew bundle dump → 分離ファイル同期"
	local/bin/parse-brewfile.sh sync

packages-diff:
	@echo "現在のインストール状況と分離ファイルの差分表示"
	local/bin/parse-brewfile.sh diff

packages-parse:
	@echo ".Brewfile を解析して分離ファイルに同期"
	local/bin/parse-brewfile.sh parse

packages-status:
	@echo "現在のパッケージ管理状況を表示"
	@echo "=== 分離ファイル状況 ==="
	@if [ -f local/share/dotfiles/brewfiles/Brewfile.common ]; then echo "✓ Common packages: $$(grep -c '^[^#]*[[:alpha:]]' local/share/dotfiles/brewfiles/Brewfile.common 2>/dev/null || echo 0) items"; else echo "✗ Brewfile.common not found"; fi
	@if [ -f local/share/dotfiles/brewfiles/Brewfile.macos ]; then echo "✓ macOS packages: $$(grep -c '^[^#]*[[:alpha:]]' local/share/dotfiles/brewfiles/Brewfile.macos 2>/dev/null || echo 0) items"; else echo "✗ Brewfile.macos not found"; fi
	@if [ -f local/share/dotfiles/packages/ubuntu ]; then echo "✓ Ubuntu packages: available"; else echo "- ubuntu packages not found"; fi
	@if [ -f local/share/dotfiles/packages/windows ]; then echo "✓ Windows packages: available"; else echo "- windows packages not found"; fi
	@echo ""
	@echo "=== 利用可能なコマンド ==="
	@echo "  make packages        # パッケージインストール"
	@echo "  make packages-sync   # 現在のパッケージ → 分離ファイル同期"
	@echo "  make packages-diff   # インストール状況と分離ファイルの差分表示"
	@echo "  make packages-parse  # .Brewfile → 分離ファイル解析"

# Windows専用コマンド
winget-export:
	@echo "Exporting current Windows packages to local/share/dotfiles/packages/windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget export -o local/share/dotfiles/packages/windows --include-versions; \
		echo "✓ Exported to local/share/dotfiles/packages/windows"; \
	else \
		echo "✗ winget not available"; \
	fi

winget-import:
	@echo "Importing Windows packages from local/share/dotfiles/packages/windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget import -i local/share/dotfiles/packages/windows --accept-source-agreements --accept-package-agreements; \
	else \
		echo "✗ winget not available"; \
	fi