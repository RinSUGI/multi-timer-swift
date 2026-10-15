# プラン全体方針・対応表・完了条件

このプラン全体で共有する原則、モジュール構成、テストの対応関係、検証方法、フェーズ完了条件を定義する。各フェーズファイルはここを前提にする。

## 実装対象と非対象

- 対象: `docs/design-docs/10-requirements/functional.md` の F-01〜F-12 を満たす macOS ネイティブアプリを実装する。
- 非対象: Windows/Linux 対応、通信・同期・自動アップデート、公証（notarization）の必須化。詳細は `docs/design-docs/00-overview/purpose-and-scope.md`。

## モジュール構成（このプランで採用する具体形）

`docs/design-docs/40-architecture/module-structure.md` の分割方針を、SwiftPM で次のターゲットに落とす。ファイル名・関数名は実装時に微調整してよいが、依存方向は厳守する。

```text
Package.swift
Sources/
  MultiTimerCore/          # ライブラリ。純粋ロジック（UI/OS 非依存）。テスト対象
    Constants.swift        # 共有定数（最大個数/文字数/時間、色、ウィンドウ寸法、周波数）
    TimeConversion.swift   # ミリ秒 ⇄ 時分秒・整形・クランプ
    SegmentEditing.swift   # セグメント値クランプ・確定合成
    TimerModel.swift       # 1 タイマーの状態遷移（start/stop/reset/clear/tick）とボタン活性
    TimerNormalization.swift # 正規化・パース・採番・通知タイトル整形
    Clock.swift            # 時刻注入用プロトコルと実装（テスト容易性）
    Ports.swift            # 通知・音のプロトコル（Platform が実装、テストはダミー）
  MultiTimerStorage/       # ライブラリ。JSON 永続化 I/O・直列化・破損対応。Core に依存
    TimerStore.swift       # actor によるファイル操作（save/delete/load）
  MultiTimerApp/           # 実行ファイル。Platform・UI・App。Core と Storage に依存
    Platform/              # 通知（UserNotifications）・音（AVAudioPlayer）・ウィンドウ（AppKit）
    UI/                    # SwiftUI ビュー・ビューモデル・スケーリング
    Resources/             # AppIcon.icns・chime.caf（バンドル同梱リソース）
    App.swift              # @main エントリポイント
Tests/
  MultiTimerCoreTests/     # TC-Time/Clamp/Edit/State/Norm/Number/Notify
  MultiTimerStorageTests/  # TC-Persist（一時ディレクトリを使う結合テスト）
scripts/
  Info.plist               # .app 組み立て時に Contents/ へ配置するテンプレート
  render-chime.swift       # チャイム音源を一度だけレンダリングする開発用スクリプト
  build-app.sh             # Universal ビルド → .app 組み立て → アドホック署名 → DMG
```

### 依存方向（厳守）

- `MultiTimerApp` → `MultiTimerCore` / `MultiTimerStorage`。
- `MultiTimerStorage` → `MultiTimerCore`。
- `MultiTimerCore` は他ターゲットに依存しない（Foundation の基本型のみ可、I/O 禁止）。

### テスト容易性のための設計要求（`docs/design-docs/60-testing/strategy.md`）

- 時刻取得は `Clock` プロトコルで注入する。tick テストは実時間を待たない。
- 保存先ディレクトリは `TimerStore` の初期化引数で差し替える（一時ディレクトリでテスト）。
- 通知・音は `Ports.swift` のプロトコルで抽象化し、テストではダミー実装に差し替える。

## 共有定数（1 箇所で定義。NFR-08）

`Constants.swift` に集約し、UI・Storage の双方から参照する。二重管理しない。

| 定数               | 値                                       | 由来                                       |
| ------------------ | ---------------------------------------- | ------------------------------------------ |
| `maxTimers`        | 12                                       | `docs/design-docs/20-spec/multi-timer.md`  |
| `maxTitleLength`   | 50                                       | `docs/design-docs/30-data/persistence.md`  |
| `maxConfiguredMs`  | 359_999_000（`(99*3600+59*60+59)*1000`） | 同上（`99:59:59`）                         |
| セグメント上限     | 時 99 / 分 59 / 秒 59                    | `docs/design-docs/20-spec/time-editing.md` |
| タイトルデバウンス | 300ms                                    | `docs/design-docs/30-data/persistence.md`  |

色・ウィンドウ寸法・チャイム周波数も `Constants.swift` に定義する。値は `docs/design-docs/50-ui/layout-and-style.md` と `docs/design-docs/20-spec/notification-and-sound.md` を正とする。

## 保存タイミング

| きっかけ             | タイミング                         |
| -------------------- | ---------------------------------- |
| タイトル入力         | 300ms デバウンス                   |
| セグメント編集の確定 | 即時保存                           |
| Clear                | 即時保存                           |
| タイマー追加         | 即時インサート                     |
| タイマー削除         | 即時削除（保留中デバウンスを解除） |

## 単体・結合テストとステップの対応（必須トレーサビリティ）

各 TC-\* を実装・パスさせるステップを明示する。全 ID をどこかのステップで必ずカバーする。

| テスト群   | ID 範囲           | 対象ファイル                  | 実装ステップ                   |
| ---------- | ----------------- | ----------------------------- | ------------------------------ |
| TC-Time    | TC-Time-01〜11    | `TimeConversion.swift`        | フェーズ 2 / ステップ 2.2      |
| TC-Clamp   | TC-Clamp-01〜09   | `SegmentEditing.swift`        | フェーズ 2 / ステップ 2.3      |
| TC-Edit    | TC-Edit-01〜04    | `SegmentEditing`+`TimerModel` | フェーズ 2 / ステップ 2.4      |
| TC-State   | TC-State-01〜16   | `TimerModel.swift`            | フェーズ 2 / ステップ 2.5      |
| TC-Norm    | TC-Norm-01〜15    | `TimerNormalization.swift`    | フェーズ 2 / ステップ 2.6      |
| TC-Number  | TC-Number-01〜05  | `TimerNormalization.swift`    | フェーズ 2 / ステップ 2.6      |
| TC-Notify  | TC-Notify-01〜04  | `TimerNormalization.swift`    | フェーズ 2 / ステップ 2.7      |
| TC-Persist | TC-Persist-01〜09 | `TimerStore.swift`            | フェーズ 3 / ステップ 3.2・3.3 |

## ブラックボックステスト（BB-01〜BB-11）の実施可能時点

`docs/design-docs/60-testing/blackbox-test-cases.md` の全ケースは、配布形式に近い `.app` で人間が手動実施する。フェーズ 7 で `.app`/DMG を生成した後に実施可能になる。対応の目安は次のとおり。

| BB    | 内容                   | 実施可能時点                                   |
| ----- | ---------------------- | ---------------------------------------------- |
| BB-01 | 起動と初期表示         | フェーズ 7 後（`.app`）                        |
| BB-02 | セグメント編集         | フェーズ 7 後。ロジックはフェーズ 2 で自動化済 |
| BB-03 | 基本操作・ボタン活性   | フェーズ 7 後。ロジックはフェーズ 2 で自動化済 |
| BB-04 | 終了と黄色表示・通知   | フェーズ 7 後（通知・音は `.app` 必須）        |
| BB-05 | 初回終了の遅延回帰     | フェーズ 7 後（本番ビルドでの暖機確認）        |
| BB-06 | 複数タイマー           | フェーズ 7 後                                  |
| BB-07 | 削除                   | フェーズ 7 後                                  |
| BB-08 | 永続化                 | フェーズ 7 後。I/O はフェーズ 3 で自動化済     |
| BB-09 | 破損耐性               | フェーズ 7 後。退避はフェーズ 3 で自動化済     |
| BB-10 | ウィンドウ・レイアウト | フェーズ 7 後                                  |
| BB-11 | 通知許可               | フェーズ 7 後                                  |

- 開発中の `swift run` でも UI の目視確認はできるが、通知・音・Gatekeeper に関わる BB-04/05/11 は `.app` で確認する（`docs/design-docs/40-architecture/technology-choices.md` の注意）。

## 検証コマンド（共通）

- Swift ロジック: `swift build`、`swift test`（特定群のみは `swift test --filter <TestType>`）。
- ドキュメント: `./scripts/agent-docs-check.sh`（Prettier / markdownlint / textlint / shellcheck）。
- 配布物: フェーズ 7 の `./scripts/build-app.sh` と、生成 DMG の `shasum -a 256`。

## フェーズ共通の完了条件

各フェーズは次を満たしたら完了とし、検証ログを添えて報告する。

- そのフェーズのステップの完了条件をすべて満たす。
- 追加・変更したコードで `swift build` が通る。テストを含むフェーズは対象 `swift test` が全パスする。
- ドキュメントを変更した場合は `./scripts/agent-docs-check.sh` が通る。
- 未解決事項があれば報告に明記する。

## 環境メモ

- macOS（Darwin）。`python` コマンドは無い前提。必要なら `uv run python` か `python3`（`docs/DOCUMENTATION_GUIDE.md`）。
- lint 一式は `npm install` 済みの Node と `shfmt` / `shellcheck`（Homebrew）に依存する。
