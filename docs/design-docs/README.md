# 設計書インデックス

macOS 向けのマルチカウントダウンタイマーアプリ Multi Timer（SwiftUI + AppKit ネイティブ）の設計書群である。

このディレクトリは、実装作業に着手する前段の「原点」となる仕様・設計・テスト設計をまとめる。ここから作業詳細プランを立てることを想定している。

## この設計書の使い方

- 実装の判断に迷ったときは、まず該当する仕様書を参照する。仕様書に書かれた振る舞いが正本である。
- 仕様書に書かれていない挙動が必要になった場合は、仕様書へ追記してから実装する。実装が先行して仕様書が後追いになる状態を残さない。
- 各ディレクトリは「設計内容の分類」であり、実装フェーズではない。番号は読む順序の目安にすぎず、上から順に実装するという意味ではない。

## ディレクトリ構成

| ディレクトリ       | 内容                                                     |
| ------------------ | -------------------------------------------------------- |
| `00-overview/`     | 目的・対象範囲・用語                                     |
| `10-requirements/` | 機能要件・非機能要件                                     |
| `20-spec/`         | ブラックボックス振る舞い仕様（正本）                     |
| `30-data/`         | 永続化・データモデル                                     |
| `40-architecture/` | 技術選定・モジュール構成                                 |
| `50-ui/`           | UI レイアウト・配色・レスポンシブ                        |
| `60-testing/`      | テスト戦略・単体テスト設計・ブラックボックステストケース |
| `70-packaging/`    | ビルド・署名・配布                                       |

## ファイル一覧

- [00-overview/purpose-and-scope.md](00-overview/purpose-and-scope.md) — 目的・対象範囲・用語集
- [10-requirements/functional.md](10-requirements/functional.md) — 機能要件
- [10-requirements/non-functional.md](10-requirements/non-functional.md) — 非機能要件
- [20-spec/timer-behavior.md](20-spec/timer-behavior.md) — タイマーの状態遷移・操作・自動リセット
- [20-spec/time-editing.md](20-spec/time-editing.md) — 時刻セグメント編集の仕様
- [20-spec/expired-coloring.md](20-spec/expired-coloring.md) — 時間切れ後の黄色表示ルール
- [20-spec/notification-and-sound.md](20-spec/notification-and-sound.md) — 通知とチャイム音
- [20-spec/multi-timer.md](20-spec/multi-timer.md) — 複数タイマーの追加・削除・上限
- [30-data/persistence.md](30-data/persistence.md) — 永続化・正規化・直列化・破損対応
- [40-architecture/technology-choices.md](40-architecture/technology-choices.md) — 技術選定
- [40-architecture/module-structure.md](40-architecture/module-structure.md) — モジュール・ディレクトリ構成
- [50-ui/layout-and-style.md](50-ui/layout-and-style.md) — UI レイアウト・配色・スケーリング
- [60-testing/strategy.md](60-testing/strategy.md) — テスト戦略
- [60-testing/unit-test-design.md](60-testing/unit-test-design.md) — 単体テスト設計
- [60-testing/blackbox-test-cases.md](60-testing/blackbox-test-cases.md) — ブラックボックステストケース
- [60-testing/blackbox-test-guide.md](60-testing/blackbox-test-guide.md) — ブラックボックステスト実施ガイド
- [70-packaging/build-and-distribution.md](70-packaging/build-and-distribution.md) — ビルド・署名・配布

## 未決事項の扱い

各設計書の末尾に `Open Questions` がある場合、そこに未決事項を集約する。各 OQ には「決定」欄を併記し、決定済みの内容は本文にも反映する。「決定: 未記入。」のままの項目は判断待ちであり、詳細プランや実装はその決定を前提にしてはならない。
