all: init link defaults packages

init:
	.bin/init.sh

link:
	.bin/link.sh

defaults:
	.bin/defaults.sh

packages:
	.bin/packages.sh

# 後方互換性のため brew エイリアスを保持
brew: packages

test:
	.bin/test.sh

verify:
	.bin/verify.sh

ci: test
	@echo "CI用の軽量テストを実行"

# Phase 2 実装予定のコマンド
packages-sync:
	@echo "Phase 2 で実装予定: brew bundle dump → 分離ファイル同期"
	.bin/parse-brewfile.sh

packages-diff:
	@echo "Phase 2 で実装予定: 現在のインストール状況と分離ファイルの差分表示"
	@echo "現在は brew bundle check --global を使用してください"

# Windows専用コマンド
winget-export:
	@echo "Exporting current Windows packages to .packages.windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget export -o .packages.windows --include-versions; \
		echo "✓ Exported to .packages.windows"; \
	else \
		echo "✗ winget not available"; \
	fi

winget-import:
	@echo "Importing Windows packages from .packages.windows"
	@if command -v winget >/dev/null 2>&1; then \
		winget import -i .packages.windows --accept-source-agreements --accept-package-agreements; \
	else \
		echo "✗ winget not available"; \
	fi