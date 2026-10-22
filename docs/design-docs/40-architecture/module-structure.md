# モジュール・ディレクトリ構成

## この文書で決めること

モジュール分割方針と、ディレクトリ・ファイル構成の指針を示す。単体テスト容易性（NFR-07）を満たす分離を主眼とする。

## 分割方針

- 純粋ロジック層（UI・OS 非依存）と、UI 層・プラットフォーム層を分ける。
- 純粋ロジック層はフレームワークに依存させず、そのまま単体テストできるようにする。
- OS 機能（通知・音・ファイル）は薄いラッパで包み、ロジックからは抽象（プロトコル）越しに使う。テスト時に差し替えられるようにする。

## レイヤ

| レイヤ               | 責務                                               | UI/OS 依存                                | テスト                                              |
| -------------------- | -------------------------------------------------- | ----------------------------------------- | --------------------------------------------------- |
| Core（純粋ロジック） | 時刻変換、タイマー状態遷移、正規化、採番、並び替え | なし                                      | 単体テスト対象                                      |
| Persistence          | JSON 読み書き、直列化、破損対応                    | FileManager                               | 一部単体テスト（正規化・パースは Core、I/O は結合） |
| Platform             | 通知、音、ウィンドウ設定                           | UserNotifications / AVFoundation / AppKit | 手動・結合                                          |
| UI                   | SwiftUI ビュー、状態束縛                           | SwiftUI                                   | ブラックボックス                                    |

## 構成

具体的なターゲット名やファイル名は実装時に調整してよい。責務分割の指針として示す。

```text
Sources/
  MultiTimerCore/          # 純粋ロジック（UI/OS 非依存、テスト対象）
    TimeConversion.swift   # ミリ秒 ⇄ 時分秒、整形、クランプ
    TimerModel.swift       # 1 タイマーの状態と遷移（start/stop/reset/clear/tick）
    SegmentEditing.swift   # セグメント編集の確定・クランプ規則
    TimerNormalization.swift # 保存データの正規化・パース・採番
    TimerOrdering.swift    # 並び替えの挿入位置計算・id 列による並べ替え
    Constants.swift        # 最大個数/最大文字数/最大時間などの共有定数
  MultiTimerApp/           # アプリ本体
    Persistence/           # JSON 保存（直列化・破損対応）
    Platform/              # 通知・音・ウィンドウ設定のラッパ
    UI/                    # SwiftUI ビュー（並び替えのドラッグハンドル含む）
    App.swift              # エントリポイント
Tests/
  MultiTimerCoreTests/     # Core の単体テスト
```

## 依存方向

- `UI` → `Core` / `Persistence` / `Platform`。
- `Persistence`・`Platform` → `Core`（定数・型の共有）。
- `Core` は他に依存しない。

## 共有定数

- 最大タイマー数（12）、最大タイトル長（50）、最大設定時間（`99:59:59`）は `Constants.swift` に 1 箇所で定義し、UI・Persistence の双方から参照する（NFR-08）。

## テストとの対応

- `MultiTimerCore` の各ファイルが単体テストの主対象になる。テスト設計は [60-testing/unit-test-design.md](../60-testing/unit-test-design.md) を参照。
- OS 機能ラッパはプロトコルで抽象化し、テストではダミー実装に差し替える。
