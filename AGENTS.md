<!-- where: repository root; what: contributor guide; why: align contributions on shared workflows -->
# Repository Guidelines

## Project Structure & Module Organization
- `config/` 内に各ツールの設定を分離し、`config/zsh/.zshrc`・`config/git/config` は XDG パスへリンクされます。
- `local/bin/` には `set -eu` を使う Bash スクリプトを置きます。再利用ロジックは `local/bin/common.sh` に集約してください。
- `local/share/dotfiles/brewfiles/` は分割された Brewfile 群を保持し、プラットフォーム別差分を管理します。
- `docker/` と `docker-compose.test.yml` は WSL/Linux 検証用の軽量コンテナを提供します。

## Build, Test, and Development Commands
- `make init` : 初回セットアップ。anyenv 初期化と共通ディレクトリ作成を行います。
- `make link` : 主要設定ファイルを `$HOME/.config/*` へシンボリックリンクします。
- `make defaults` : macOS 用 `defaults` 設定を適用します (他 OS では無視されます)。
- `make packages` / `make brew` : `local/bin/packages.sh install` を呼び出し、Brewfile 群を同期します。
- `make test` : `local/bin/test.sh` を実行し、プラットフォーム検出・必須ファイル・構文チェックを行います。
- `make verify` : 実環境を検証し、シンボリックリンクやフォント状態を確認します。

## Coding Style & Naming Conventions
- シェルスクリプトは `#!/bin/bash` と `set -eu` を必須とし、関数名・ファイル名は `snake_case` で統一します。
- 1 インデントは半角 2 スペース。条件分岐は POSIX テスト構文 (`[ condition ]`) を使用します。
- 共有ロジックは `common.sh` へ移し、XDG 配下に配置される設定ファイルはテンプレートを `*.local.template` 名で用意します。
- フォーマッタは導入していませんが、`shellcheck` を参考に手動レビューしてください。

## Testing Guidelines
- 新規スクリプトには `make test` で実行されるテスト関数 (`test_assert`, `test_file_exists`, など) を追加します。
- 追加テストは `local/bin/test.sh` に追記し、説明文は日本語で具体的に書きます。
- 環境依存の検証は `make verify` に分離し、失敗時は `warning` ログを返す形で許容します。
- カバレッジ目標はありませんが、主要フロー (リンク生成、パッケージ同期) を最低 1 ケースで確認してください。

## Commit & Pull Request Guidelines
- Git ログは `feat: ...`, `chore: ...`, `fix: ...` のような Conventional Commits スタイルを採用しています。動詞は命令形で短く。
- コミットは論理単位ごとに分割し、生成物やキャッシュは含めないでください。
- PR には目的、影響範囲、検証手順 (`make test` など) を列挙し、UI 変更はスクリーンショットを添付します。
- Issue との関連がある場合は `Closes #123` を本文末尾に追記し、自動クローズを有効にしてください。

## Security & Configuration Tips
- 個人設定は `config/zsh/.zshrc.local.template` や `config/git/config.local.template` をコピーし、秘匿情報はコミットしないでください。
- macOS のみ適用する `defaults` を変更する際は、逆操作 (`defaults delete`) をコメントとして併記しリバーシブルに。
- `local/bin/` のスクリプトは外部コマンド依存を明記し、必要に応じて `make packages-*` 系コマンドへ追加してください。
- Docker 環境での検証時は `docker/test-entrypoint.sh` を利用し、ホスト側の `$HOME` マウントに注意してください。
