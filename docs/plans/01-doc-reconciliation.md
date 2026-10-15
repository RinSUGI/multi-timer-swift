# フェーズ 0: 決定事項の設計書反映（実装前の先行タスク）

Open Questions の決定のうち、設計書本文へ反映しきれていない箇所を反映する。実装に入る前にここを片づけ、以降のフェーズが「本文どおり実装すればよい」状態にする。

## 前提

- 各設計書末尾の `Open Questions` を正とする。
- このフェーズはドキュメントのみを変更する。完了前に `./scripts/agent-docs-check.sh` を必ず実行する。
- 決定の要約と本文の食い違いがある場合、設計書側の決定文が正である。要約に引きずられて本文を書き換えない。

## ステップ 0.1 保存タイミングを本文に反映

- 対象ファイル
  - `docs/design-docs/30-data/persistence.md`
  - `docs/design-docs/20-spec/timer-behavior.md`
  - `docs/design-docs/20-spec/time-editing.md`
- 変更内容
  - タイトルは 300ms デバウンス、セグメント確定と Clear は即時保存。3 ファイルの本文が同じ結論に整合していることを確認する。
- 完了条件: 3 ファイルとも、セグメント確定と Clear の保存タイミングが「即時」と読める。タイトルのみ 300ms デバウンスのままである。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.2 対応 OS 下限を macOS 13 に明記

- 対象ファイル: `docs/design-docs/10-requirements/non-functional.md`
- 変更内容: NFR-06 の本文が「対応 OS の下限は macOS 13（Ventura）」と読めることを確認する。
- 完了条件: NFR-06 本文が macOS 13 を下限として明記している。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.3 技術選定の「計時」「ビルド」を採用として書き下す

- 対象ファイル: `docs/design-docs/40-architecture/technology-choices.md`
- 変更内容
  - 「計時（tick）」節: 採用を「モデル層の `Timer`（RunLoop、間隔 200〜250ms、`tolerance` 設定）」と本文に確定記載する。ビューのライフサイクルから独立させる理由を 1 文残す。
  - 「ビルド・パッケージング」節: 「SwiftPM 主体（Core / App / Tests を 1 パッケージ）。`.app` 生成はスクリプト（`scripts/build-app.sh`）」と確定記載する。`.xcodeproj` は使わない旨を明記する。
- 完了条件: 両節の本文が「採用」を断定形で示している。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 0.4 単体テスト設計への影響確認（保存タイミング変更）

- 対象ファイル: `docs/design-docs/60-testing/unit-test-design.md`（確認のみ。変更は原則不要）
- 確認内容: 保存タイミングをデバウンスに依存する TC が無いことを確認する。TC-Persist は保存内容・直列化・破損を対象にしており、デバウンス時間には依存しない。BB-08-3 の「デバウンス」はタイトル入力に対する手動確認であり、変更不要。
- 完了条件: デバウンス時間に依存する自動テストが無いことを確認し、その旨を報告に記す。設計書の変更が必要な箇所が見つかった場合のみ修正し、`./scripts/agent-docs-check.sh` を実行する。

## フェーズ 0 完了条件

- ステップ 0.1〜0.3 の設計書更新が完了し、`./scripts/agent-docs-check.sh` が通る。
- ステップ 0.4 の確認結果を報告した。
- 決定事項と設計書本文の食い違いが解消している。
