all: init link defaults packages

init:
	scripts/init.sh

link:
	scripts/link.sh

defaults:
	scripts/defaults.sh

packages:
	scripts/packages.sh

# 後方互換性のため brew エイリアスを保持
brew: packages

test:
	scripts/test.sh

verify:
	scripts/verify.sh

# anyenv セットアップテスト
anyenv-test:
	@echo "anyenv セットアップのテストを実行"
	scripts/anyenv.sh test

anyenv-setup:
	@echo "anyenv の完全セットアップを実行"
	scripts/anyenv.sh

ci: test
	@echo "CI用の軽量テストを実行"

# Phase 2 実装済みのコマンド
packages-sync:
	@echo "brew bundle dump → 分離ファイル同期"
	scripts/parse-brewfile.sh sync

packages-diff:
	@echo "現在のインストール状況と分離ファイルの差分表示"
	scripts/parse-brewfile.sh diff

# 追加のPhase 2コマンド
packages-parse:
	@echo ".Brewfile を解析して分離ファイルに同期"
	scripts/parse-brewfile.sh parse

packages-status:
	@echo "現在のパッケージ管理状況を表示"
	@echo "=== 分離ファイル状況 ==="
	@if [ -f packages/.Brewfile.common ]; then echo "✓ Common packages: $$(grep -c '^[^#]*[[:alpha:]]' packages/.Brewfile.common 2>/dev/null || echo 0) items"; else echo "✗ packages/.Brewfile.common not found"; fi
	@if [ -f packages/.Brewfile.macos ]; then echo "✓ macOS packages: $$(grep -c '^[^#]*[[:alpha:]]' packages/.Brewfile.macos 2>/dev/null || echo 0) items"; else echo "✗ packages/.Brewfile.macos not found"; fi
	@if [ -f packages/.packages.ubuntu ]; then echo "✓ Ubuntu packages: available"; else echo "- packages/.packages.ubuntu not found"; fi
	@if [ -f packages/.packages.windows ]; then echo "✓ Windows packages: available"; else echo "- packages/.packages.windows not found"; fi
	@echo ""
	@echo "=== 利用可能なコマンド ==="
	@echo "  make packages        # パッケージインストール"
	@echo "  make packages-sync   # 現在のパッケージ → 分離ファイル同期"
	@echo "  make packages-diff   # インストール状況と分離ファイルの差分表示"
	@echo "  make packages-parse  # .Brewfile → 分離ファイル解析"

# Windows専用コマンド
winget-export:
	@echo "Exporting current Windows packages to packages/.packages.windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget export -o packages/.packages.windows --include-versions; \
		echo "✓ Exported to packages/.packages.windows"; \
	else \
		echo "✗ winget not available"; \
	fi

winget-import:
	@echo "Importing Windows packages from packages/.packages.windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget import -i packages/.packages.windows --accept-source-agreements --accept-package-agreements; \
	else \
		echo "✗ winget not available"; \
	fi