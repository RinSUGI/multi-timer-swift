# DOCUMENTATION_GUIDE

<!--
エージェントがMarkdownドキュメントを作成・更新するときの制御用ガイドです。
作業時に守るルール、判断基準、完了条件だけを置きます。
-->

## Purpose

このファイルは、エージェントがドキュメントを変更するときに、構成・情報量・検証方法を揃えるための正本です。

エージェントは、Markdownを作成・更新する前にこのファイルを読み、完了前に `./scripts/agent-docs-check.sh` を実行してください。

## Scope

対象は、Git管理下に置くMarkdown、JSON、YAMLのドキュメント・設定ファイルと、検証用シェルスクリプトです。

- `*.md`
- `docs/**/*.md`
- `*.json`
- `*.yml`
- `*.yaml`
- `scripts/**/*.sh`

`_misc/**` など `.gitignore` に記載のあるものはローカル作業用ファイルです。作業用プロンプト原文、PR本文ドラフト、調査前の素材は原文性を優先し、ドキュメント品質の正本にはしません。

## Source of Truth

同じルールを複数のドキュメントに重複して書かないでください。既存の正本がある場合は、本文を複製せずリンクします。

## Write for エージェント and Humans

ドキュメントは人間だけでなく、エージェントが次の作業で参照する実行時コンテキストとして書きます。

- 何を決めた文書なのかを冒頭で書く。
- 対象範囲と対象外を分ける。
- 禁止事項は「なぜ」よりも「何をしてはいけないか」を先に書く。
- 未決事項は本文に紛れ込ませず、`Open Questions` や `Issues` に分ける。
- 手順は、エージェントがそのまま実行できる粒度で書く。
- 実装・仕様・運用の正本が別にある場合は、リンクだけにする。

長くなった場合は、同じファイルに追記し続けず、責務ごとに分けます。

## Style Rules

- 見出しは短くする。
- 箇条書きは、判断・条件・手順を混ぜない。
- 文末表現や言い回しの統一より、仕様の曖昧さを減らすことを優先する。
- コマンド、パス、状態値、環境変数はバッククォートで囲む。
- 外部記事の要約を正本にしない。必要なら `docs/design-docs/` または `docs/research/` に根拠として置く。
- 秘密情報、個人情報、本番データ、認証情報は書かない。詳細は `docs/SAFETY_POLICY.md` に従う。
- `.env.example` などのサンプルには、実値ではなく明らかに偽物だと分かるプレースホルダーだけを書く。
- 作業ログ、handoff、progress、PR説明、完了報告にも秘密情報の実値を貼らない。

## Tooling

ドキュメント品質は、次のツールで検証します。

| ツール            | 役割                                             |
| ----------------- | ------------------------------------------------ |
| Prettier          | Markdown / JSON / YAML の整形                    |
| markdownlint-cli2 | Markdownの見出し、リスト、空行などの構造チェック |
| textlint          | 日本語技術文書としての表記チェック               |
| shfmt             | `scripts/**/*.sh` の整形                         |
| ShellCheck        | `scripts/**/*.sh` の静的解析                     |

`shfmt` と ShellCheck は Homebrew 等で CLI をインストールしてください（`brew install shfmt shellcheck`）。
整形・lint ルールの正本は `.editorconfig`（shfmt）と `.shellcheckrc`（ShellCheck）です。
VS Code 拡張機能は任意で、エディタ上で保存時整形や問題行の警告を見たい場合に入れます。

### 導入・実行時の前提

他プロジェクトへこの検証一式を入れるとき、次だけ確認してください。

- `_misc/` や `_archive/` が無くても問題ありません。設定ファイル内の ignore 指定は、フォルダが無い場合は無視されるだけです。
- textlint は対象 Markdown が1件も無いと失敗します。ルートの `*.md` が無くても、`docs/**/*.md` などに1件以上あれば動きます。
- `scripts/**/*.sh` に `.sh` が1件も無いと、ShellCheck / shfmt の check が失敗します。最低限 `scripts/checks/docs.sh` が必要です。
- `./scripts/agent-docs-check.sh` を使う場合は、`scripts/checks/docs.sh` もセットで置いてください。
- 初回は `npm install` のほか、`shfmt` と ShellCheck の CLI インストールが必要です。

### Agent 向け検証コマンド

エージェントは、ドキュメント変更の完了前検証を `./scripts/agent-docs-check.sh` だけで行ってください。

- JSON / YAML / Markdown / shell の構文・整形は、このスクリプト内の `npm run format:check` と `npm run lint` が担当します。
- `python -c 'import json...'` や `python -m json.tool` など、Python による ad-hoc な JSON 事前チェックは実行しないでください。不要であり、環境によっては失敗します。
- macOS 開発環境では `python` コマンドは存在しないことが多いです。Python を直接実行する必要がある場合のみ、`uv run python ...`（推奨）または `python3 ...` を使い、`python` は使わないでください。

## Done Criteria

Markdown、JSON、YAML、`scripts/**/*.sh` を変更したエージェントは、完了前に次を満たしてください。

- [ ] 変更先が正しい置き場所か確認した。
- [ ] 同じルールや説明を別文書に重複させていない。
- [ ] 正本が別にある場合はリンクにした。
- [ ] 秘密情報、個人情報、本番データを含めていない。
- [ ] `./scripts/agent-docs-check.sh` を実行した。
- [ ] 実行できない検証がある場合、理由と残リスクを報告した。

## Repair Rule

検証で失敗した場合は、次の順で対応します。

1. `npm run format` または `npm run lint:fix` で機械修正できるものを直す。
2. 機械修正できない textlint / markdownlint / ShellCheck 指摘を手で直す。
3. 指摘がプロジェクト方針に合わない場合、個別に無視せず設定ファイルの見直しを提案する。
4. 直せない場合は、未解決事項として作業ログまたは最終報告に残す。
