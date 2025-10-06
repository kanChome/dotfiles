all: init link defaults packages

init:
	local/bin/init.sh

link:
	local/bin/link.sh

defaults:
	local/bin/defaults.sh

packages:
	local/bin/packages.sh install

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
	local/bin/packages.sh brew:sync

packages-diff:
	@echo "現在のインストール状況と分離ファイルの差分表示"
	local/bin/packages.sh brew:diff

packages-parse:
	@echo "Brewfile を解析して分離ファイルに同期"
	local/bin/packages.sh brew:parse

packages-status:
	@echo "現在のパッケージ管理状況を表示 (macOS)"
	@local/bin/packages.sh status

# Windows専用コマンド