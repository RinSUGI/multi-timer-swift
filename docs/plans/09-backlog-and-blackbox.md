# フェーズ 8: バックログ整備とブラックボックステスト実施ガイド

実装対象外のバックログ 2 件の置き場所を用意し、ブラックボックステストの実施を人間へ引き渡す。

## 前提

- バックログ 2 件は**本プロジェクトの実装対象外**。記録の置き場所だけを用意する。
- ブラックボックス（BB-01〜BB-11）は人間による手動実施。フェーズ 7 の `.app` が前提。

## ステップ 8.1 バックログの置き場所を作る

- 対象ファイル
  - `docs/backlogs/README.md`（バックログ一覧の入口）
  - `docs/backlogs/memory-footprint-measurement.md`
  - `docs/backlogs/keep-counting-when-window-closed.md`
- 内容
  - メモリ実測: アイドル常駐（タイマー 1 個・非実行）の footprint を実測し、30MB 以下を合格とする。15MB 前後なら確定、30MB 超なら原因調査。測定方法は `docs/design-docs/10-requirements/non-functional.md`（アクティビティモニタのメモリ列、`footprint` / `vmmap`）。測定〜対応をバックログとして残す。
  - ウィンドウ非表示時の計時継続: 「ウィンドウを閉じてもカウントを継続して通知する」改善はバックグラウンド処理の追加を伴うため本プロジェクトでは行わない。将来対応として漏れないよう記録する。
  - 各ファイルは「背景・現状・対応方針・受け入れ条件」を簡潔に書き、正本（設計書）へリンクする。本文を複製しない（`docs/DOCUMENTATION_GUIDE.md`）。
- 完了条件: 2 件のバックログが `docs/backlogs/` に記録され、一覧から辿れる。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 8.2 ブラックボックステスト実施ガイド

- 対象: 人間の実施者への引き渡し。
- 内容
  - 実施対象は `docs/design-docs/60-testing/blackbox-test-cases.md` の BB-01〜BB-11 と非機能 NF-1〜NF-3。
  - 実施環境はフェーズ 7 で生成した `.app`（または DMG からインストールした版）。開発中の裸バイナリでは通知が出ないことがあるため、通知・音・Gatekeeper に関わる BB-04/05/11 は必ず `.app` で行う。
  - 仕様書（`docs/design-docs/20-spec/` 配下）を判定基準にする。差異が出た場合は、実装の不具合か仕様の記述漏れかを切り分ける。
  - NF-1（メモリ）は `docs/backlogs/memory-footprint-measurement.md` に測定結果を記録する。
- 完了条件: 実施者が、対象・環境・基準を把握して BB を開始できる。
- 検証: ドキュメントを追加した場合は `./scripts/agent-docs-check.sh`。

## ステップ 8.3 全体の受け入れ確認

- 内容: 次を最終確認する。
  - `swift test` が全パス（TC-Time / TC-Clamp / TC-Edit / TC-State / TC-Norm / TC-Number / TC-Notify / TC-Persist）。
  - `./scripts/build-app.sh` で `.app` と DMG が生成される。
  - BB-01〜BB-11 が期待どおり（人間実施）。
  - 非機能: メモリが NFR-01 の合格ライン（30MB 以下、実測はバックログ）、CPU が実用上無視できる（NFR-02）、起動が体感即時（NFR-03）。
- 完了条件: 上記を満たし、残課題があれば報告に明記する。

## フェーズ 8 完了条件

- バックログ 2 件が `docs/backlogs/` に記録されている。
- ブラックボックステストの実施準備が整い、人間へ引き渡せる。
- 自動テストと配布物生成が揃い、プロジェクトの完了条件（`docs/design-docs/60-testing/strategy.md` の合否）を満たすことを確認できる。
