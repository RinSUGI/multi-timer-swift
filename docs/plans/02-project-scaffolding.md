# フェーズ 1: SwiftPM プロジェクト雛形と共有定数

リポジトリ直下に SwiftPM パッケージを新設し、ターゲット・ディレクトリ・共有定数を用意する。以降のフェーズが載る土台を作る。

## 前提

- OQ-06 により SwiftPM 主体。`.xcodeproj` は作らない。
- 対応 OS 下限は macOS 13（`platforms: [.macOS(.v13)]`）。
- ターゲット構成は `docs/plans/00-plan-overview.md` の「モジュール構成」に従う。

## ステップ 1.1 Package.swift の作成

- 対象ファイル: `Package.swift`（新規）
- 実装内容
  - `swift-tools-version` は 5.9 以上を指定する。
  - `platforms: [.macOS(.v13)]`。
  - ターゲット定義
    - `MultiTimerCore`（library）: 依存なし。
    - `MultiTimerStorage`（library）: `MultiTimerCore` に依存。
    - `MultiTimerApp`（executableTarget）: `MultiTimerCore`・`MultiTimerStorage` に依存。`Resources/` を `.copy` または `.process` でバンドルに含める設定を後続フェーズで追加できるよう、リソースディレクトリの存在を前提にする。
    - `MultiTimerCoreTests`（testTarget）: `MultiTimerCore` に依存。
    - `MultiTimerStorageTests`（testTarget）: `MultiTimerStorage`・`MultiTimerCore` に依存。
  - `products` に executable `multi-timer`（`MultiTimerApp`）を定義する。
- 完了条件: `swift package describe` がエラーなく実行でき、5 ターゲットが認識される。
- 検証: `swift package describe`（または `swift build` が空ターゲットで通る状態）。

## ステップ 1.2 ディレクトリと空ファイルの作成

- 対象: `docs/plans/00-plan-overview.md` のツリーどおりに `Sources/` `Tests/` 配下のディレクトリを作る。
- 実装内容: 各 Swift ファイルは、まず最小の空実装（`import Foundation` と空 struct/enum のプレースホルダ）で作り、`swift build` が通る状態にする。中身は各フェーズで実装する。
  - `MultiTimerApp` は `@main` が必要なため、`App.swift` に暫定の最小 `@main struct` を置いて `swift build` が通るようにする（SwiftUI 実装はフェーズ 5・6 で差し替える）。暫定実装は空ウィンドウか `print` のみでよい。
- 完了条件: `swift build` が全ターゲットで成功する。
- 検証: `swift build`。

## ステップ 1.3 共有定数 `Constants.swift`

- 対象ファイル: `Sources/MultiTimerCore/Constants.swift`
- 実装内容: `docs/plans/00-plan-overview.md` の「共有定数」表と、`docs/design-docs/50-ui/layout-and-style.md` の配色・寸法、`docs/design-docs/20-spec/notification-and-sound.md` の周波数を、1 つの名前空間（例: `enum Constants`）に定義する。
  - `maxTimers = 12`
  - `maxTitleLength = 50`
  - `maxConfiguredMs = (99*3600 + 59*60 + 59) * 1000`（= 359_999_000）
  - セグメント上限: 時 99 / 分 59 / 秒 59
  - タイトルデバウンス: 300ms
  - ウィンドウ: 初期 360x480、最小 120x100、上端余白 28、背景 `#1c1c1e`
  - 配色: 標準文字 `#ffffff`、黄色 `#ffd60a`、Start `#34c759`、Stop `#ff3b30`、Reset `#007aff`、Clear `#8e8e93`、削除 `#ff3b30`（色は 16 進やコンポーネント値として保持し、UI 側で `Color` に変換する。`MultiTimerCore` は SwiftUI に依存しないため、生の 16 進文字列または RGBA 数値で持つ）
  - チャイム周波数（Hz）: お（E）= 261.63 / 329.63 / 392.00、メロディ 659.25、長さ 0.45 秒。ぜ（D）= 233.08 / 293.66 / 349.23、メロディ 587.33、長さ 0.90 秒。倍音比 基音 0.07 / 2 倍 0.02 / 3 倍 0.007。
- 完了条件: 上記が 1 ファイルに定義され、`maxConfiguredMs` の算出が正しい。UI・Storage から参照できる可視性（`public`）を持つ。
- 検証: `swift build`。定数はフェーズ 2 のテストからも参照して間接的に検証する。

## ステップ 1.4 バージョン定義の置き場所

- 対象: バージョン文字列（`v<version>` 表示・`.app` のバージョン）の単一定義。
- 実装内容: 初期バージョンは既存踏襲で `1.0.4` とする（`docs/design-docs/70-packaging/build-and-distribution.md` のメタデータ踏襲）。`Constants.swift`（または専用の `Version.swift`）に `appVersion = "1.0.4"` を定義し、UI のバージョン表示とフェーズ 7 の `Info.plist` 生成が同じ値を参照できるようにする。値の更新箇所を 1 つに保つ。
- 完了条件: バージョン文字列が単一箇所で定義されている。
- 検証: `swift build`。

## フェーズ 1 完了条件

- `swift build` が全ターゲットで成功する。
- `Constants.swift` に共有定数・色・寸法・周波数・バージョンが揃っている。
- ディレクトリ構成が `docs/plans/00-plan-overview.md` と一致する。
