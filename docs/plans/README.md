# 実装詳細プラン インデックス

`docs/design-docs/` の設計・仕様を正本として、Swift ネイティブ版 Multi Timer を実装するための作業詳細プランである。

## このプランの読者と前提

- 実行者は Claude（Sonnet 4.6）を想定する。本会話の履歴なしで、このプランと `docs/design-docs/` だけを見て単独実行できる粒度で書く。
- 迷ったら必ず `docs/design-docs/` の該当仕様を参照する。プランと仕様が食い違う場合は仕様書が正本である。仕様の抜けを見つけたら、実装前に既存実装（`_archive/multi-timer-mac/src/`）を確認し、必要なら仕様書へ追記してから実装する。
- コミット・push・PR 作成は、人間の明示指示があるまで行わない。各フェーズ完了時に検証結果を報告し、指示を待つ。

## 進め方の原則

- Core（純粋ロジック）を先に実装し、単体テストで固めてから UI・Platform を載せる。依存方向は `docs/design-docs/40-architecture/module-structure.md` に従う。
- 各フェーズは前フェーズの完了条件を満たしてから着手する。フェーズ内のステップは原則上から順に実施する。
- ドキュメント（Markdown / JSON / YAML / シェル）を変更したステップは、完了前に `./scripts/agent-docs-check.sh` を実行する（`docs/DOCUMENTATION_GUIDE.md`）。
- Swift コードを変更したステップは、完了前に該当する `swift build` / `swift test` を実行する。

## フェーズ一覧

| フェーズ | ファイル                                                 | 内容                                                                         |
| -------- | -------------------------------------------------------- | ---------------------------------------------------------------------------- |
| 全体     | [00-plan-overview.md](00-plan-overview.md)               | 原則・依存方向・テスト対応表・完了条件・用語                                 |
| 0        | [01-doc-reconciliation.md](01-doc-reconciliation.md)     | OQ 決定の設計書反映（実装前の先行タスク）                                    |
| 1        | [02-project-scaffolding.md](02-project-scaffolding.md)   | SwiftPM パッケージ・ターゲット・ディレクトリ・共有定数                       |
| 2        | [03-core-and-unit-tests.md](03-core-and-unit-tests.md)   | Core 純粋ロジックと単体テスト（TC-Time/Clamp/Edit/State/Norm/Number/Notify） |
| 3        | [04-persistence.md](04-persistence.md)                   | 永続化 I/O・直列化・破損対応と結合テスト（TC-Persist）                       |
| 4        | [05-platform.md](05-platform.md)                         | 通知・チャイム音・ウィンドウ設定のラッパ                                     |
| 5        | [06-ui.md](06-ui.md)                                     | SwiftUI ビュー・スケーリング・ドラッグ移動                                   |
| 6        | [07-app-assembly.md](07-app-assembly.md)                 | アプリ結線・暖機・メニュー・空状態初期化                                     |
| 7        | [08-packaging.md](08-packaging.md)                       | ビルド・`.app` 組み立て・アドホック署名・DMG・配布手順書                     |
| 8        | [09-backlog-and-blackbox.md](09-backlog-and-blackbox.md) | バックログの置き場所とブラックボックステスト実施ガイド                       |

## 単体テストとフェーズの対応（要約）

詳細は [00-plan-overview.md](00-plan-overview.md) の対応表を正とする。

- TC-Time / TC-Clamp / TC-Edit / TC-State / TC-Norm / TC-Number / TC-Notify: フェーズ 2。
- TC-Persist: フェーズ 3。
- ブラックボックス BB-01〜BB-11: フェーズ 7 で `.app` を生成した後に人間が手動実施する。
