# フェーズ 0: OQ 決定の設計書反映（実装前の先行タスク）

OQ の決定のうち、まだ設計書本文へ反映しきれていない箇所を反映する。実装に入る前にここを片づけ、以降のフェーズが「本文どおり実装すればよい」状態にする。

## 前提

- OQ-01〜OQ-11 はすべて決定済み（各設計書末尾の `Open Questions` を正とする）。
- このフェーズはドキュメントのみを変更する。完了前に `./scripts/agent-docs-check.sh` を必ず実行する。
- 決定の要約と本文の食い違いがある場合、設計書側の決定文が正である。要約に引きずられて本文を書き換えない。

## ステップ 0.1 保存タイミングを即時保存へ更新（OQ-05）

- 対象ファイル
  - `docs/design-docs/30-data/persistence.md`
  - `docs/design-docs/20-spec/timer-behavior.md`
  - `docs/design-docs/20-spec/time-editing.md`
- 変更内容
  - `persistence.md` の「保存タイミング」表: 「セグメント編集の確定」と「Clear」の行を、既存挙動（300ms デバウンス）から Swift 版仕様の「即時保存」に書き換える。既存が 300ms デバウンス経路だった事実は、必要なら注記として 1 行残してよいが、Swift 版の採用値は「即時」であることを明確にする。
  - `timer-behavior.md` の Clear 節: 「既存はタイトルと同じ 300ms デバウンス経路である」を、「Swift 版は即時保存する（既存はデバウンス経路だった）」に更新する。
  - `time-editing.md` の「確定時の状態変化」の永続化項: 「タイトルと同じデバウンス経路を通る」を、「即時保存する（タイトルはデバウンス、確定は即時）」に更新する。
- 完了条件: 3 ファイルとも、セグメント確定と Clear の保存タイミングが「即時」と読める。タイトルのみ 300ms デバウンスのままである。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.2 対応 OS 下限を macOS 13 に確定（OQ-01）

- 対象ファイル: `docs/design-docs/10-requirements/non-functional.md`
- 変更内容: NFR-06 の本文「対応 OS の下限は実装時に確定する」を「対応 OS の下限は macOS 13（Ventura）」に更新する。`Open Questions` の OQ-01 決定文はそのまま残す。
- 完了条件: NFR-06 本文が macOS 13 を下限として明記している。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.3 技術選定の「計時」「ビルド」を採用として書き下す（OQ-06 / OQ-07）

- 対象ファイル: `docs/design-docs/40-architecture/technology-choices.md`
- 変更内容
  - 「計時（tick）」節: 「実装候補」列挙のうち、採用を「モデル層の `Timer`（RunLoop、間隔 200〜250ms、`tolerance` 設定）」と本文に確定記載する。ビューのライフサイクルから独立させる理由を 1 文残す。
  - 「ビルド・パッケージング」節: 「Xcode プロジェクト、または Swift Package + xcodebuild」を、「SwiftPM 主体（Core / App / Tests を 1 パッケージ）。`.app` 生成はスクリプト（`scripts/build-app.sh`）」と確定記載する。`.xcodeproj` は使わない旨を明記する。
- 完了条件: 両節の本文が「採用」を断定形で示している。`Open Questions` の決定文は残す。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.4 単体テスト設計への影響確認（保存タイミング変更）

- 対象ファイル: `docs/design-docs/60-testing/unit-test-design.md`（確認のみ。変更は原則不要）
- 確認内容: 保存タイミングをデバウンスに依存する TC が無いことを確認する。TC-Persist は保存内容・直列化・破損を対象にしており、デバウンス時間には依存しない。BB-08-3 の「デバウンス」はタイトル入力に対する手動確認であり、変更不要。
- 完了条件: デバウンス時間に依存する自動テストが無いことを確認し、その旨を報告に記す。設計書の変更が必要な箇所が見つかった場合のみ修正し、`./scripts/agent-docs-check.sh` を実行する。

## フェーズ 0 完了条件

- ステップ 0.1〜0.3 の設計書更新が完了し、`./scripts/agent-docs-check.sh` が通る。
- ステップ 0.4 の確認結果を報告した。
- OQ 決定と設計書本文の食い違いが解消している。
