all: init link defaults brew

init:
	.bin/init.sh

link:
	.bin/link.sh

defaults:
	.bin/defaults.sh

brew:
	.bin/brew.sh

test:
	.bin/test.sh

verify:
	.bin/verify.sh

ci: test
	@echo "CI用の軽量テストを実行"