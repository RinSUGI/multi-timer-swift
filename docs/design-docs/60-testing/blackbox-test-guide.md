# ブラックボックステスト実施ガイド

## この文書で決めること

ブラックボックステストの実施者（人間）に対し、対象・環境・基準・結果記録の方法を伝える。テストケースの手順と期待結果は [blackbox-test-cases.md](blackbox-test-cases.md) を正本とし、この文書には複製しない。

## 実施対象

| 区分         | ケース                                    | 正本                                                                  |
| ------------ | ----------------------------------------- | --------------------------------------------------------------------- |
| 機能テスト   | BB-01 〜 BB-12                            | [blackbox-test-cases.md](blackbox-test-cases.md)                      |
| 非機能テスト | NF-1（メモリ）、NF-2（CPU）、NF-3（起動） | [blackbox-test-cases.md](blackbox-test-cases.md) の「非機能の確認」節 |

## 実施環境

- **使用する実行形式**: `dist/Multi Timer.app`（または DMG からインストールした版）。
- 開発中の裸バイナリ（`swift run`）では通知が出ないことがある。**BB-04・BB-05・BB-11** は必ず `.app` で実施する。
- `.app` が無い場合は `./scripts/build-app.sh` で生成する。

## 実施基準

- **合否の基準**: 仕様書（`docs/design-docs/20-spec/` 配下）に記述された振る舞い。
- 差異が出た場合、仕様書と照合し、実装の不具合か仕様の記述漏れかを切り分ける。
- NF-1（メモリ）の合否判定は [backlogs/memory-footprint-measurement.md](../../backlogs/memory-footprint-measurement.md) の基準を参照する。

## 結果の記録方法

各ケースの実施後、`docs/plans/progress-list.json` の `blackboxTests.cases` 内の対応する `status` を次のルールで更新する。

| 結果                           | `status` 値   |
| ------------------------------ | ------------- |
| 期待どおり（合格）             | `"completed"` |
| 期待と異なる・要調査（不合格） | `"blocked"`   |

例: BB-01 が合格した場合、`progress-list.json` の `{ "id": "BB-01", ... }` を `"status": "completed"` に変更する。

不合格・要調査のケースは、差異の内容を別途メモしておくと調査が進めやすい（ファイルへの記載は任意）。

## フェーズ 8.3 との連携

フェーズ 8.3 の受け入れ確認では、AI が `progress-list.json` の `blackboxTests.cases` を読み、全ケースが `"completed"` であることを確認する。`"blocked"` が残っている場合は未解決課題として報告に明記する。
