# フェーズ 4: Platform 層（通知・チャイム音・ウィンドウ設定）

`MultiTimerCore` の `Ports`（`ChimePlaying` / `NotificationScheduling`）を OS 機能で実装し、ウィンドウ設定の AppKit 併用部分を用意する。UI（フェーズ 5）から使える形にする。

## 前提

- 標準フレームワークのみ（`UserNotifications` / `AVFoundation` / `AppKit`）。外部依存を追加しない。
- チャイムは事前レンダリング音源を採用する。
- 通知・音の「発火判断」は Core 側。Platform は「実表示・実再生」に徹する（`docs/design-docs/60-testing/strategy.md`）。

## ステップ 4.1 チャイム音源のレンダリング（開発用スクリプト）

- 対象ファイル
  - `scripts/render-chime.swift`（新規、開発用。音源を一度だけ生成する）
  - 出力: `Sources/MultiTimerApp/Resources/chime.caf`（生成物。リポジトリにコミットしてバンドルに含める）
- 実装内容
  - `Constants.swift` の周波数・倍音比・長さ（`docs/design-docs/20-spec/notification-and-sound.md`）に基づき、2 音チャイム（お＝E、ぜ＝D）を合成して 1 つの音声ファイルへレンダリングする。
    - お（E）: C4-E4-G4 和音 + メロディ E5、約 0.45 秒。
    - ぜ（D）: B♭3-D4-F4 和音 + メロディ D5、約 0.90 秒。
    - 各音は基音 0.07 / 2 倍 0.02 / 3 倍 0.007 の倍音を重ね、立ち上がり後にゆるやかに減衰。
  - `AVAudioEngine` のオフラインレンダリング、または波形を直接 PCM バッファへ書いて `AVAudioFile` に書き出す。
  - 実行方法（開発時のみ）: `swift scripts/render-chime.swift` などで生成する。生成された `chime.caf` を Resources に置く。
- 完了条件: `chime.caf` が生成され、`afplay Sources/MultiTimerApp/Resources/chime.caf` で「おぜ」に近い 2 音が鳴る（聴感一致でよい。ビット一致は不要）。
- 検証: `afplay <生成物>` で再生確認。ビット一致は問わない。

## ステップ 4.2 チャイム再生ラッパ（`ChimePlaying` 実装）

- 対象ファイル: `Sources/MultiTimerApp/Platform/ChimePlayer.swift`
- 実装内容
  - `AVAudioPlayer` で `chime.caf` を再生する `ChimePlaying` 実装。
  - **暖機（ウォームアップ）**: プレイヤーを起動直後または初回ユーザー操作時に一度初期化・`prepareToPlay()` し、終了パス上での初回初期化を避ける（NFR-03、`docs/design-docs/20-spec/notification-and-sound.md` の「初回再生の遅延対策」）。暖機用のメソッドを公開し、フェーズ 6 の App 結線から呼べるようにする。
  - 再生はメインスレッドをブロックしない。同時終了に備え、複数回連続再生に耐える（必要なら複数プレイヤーまたは `AVAudioPlayerNode` を検討。まずは単一プレイヤーで、重なりが問題になる場合のみ拡張）。
- 完了条件: 暖機メソッドと再生メソッドを持つ `ChimePlaying` 実装が `swift build` で通る。
- 検証: `swift build`。実再生の確認は BB-04（フェーズ 7）。

## ステップ 4.3 通知ラッパ（`NotificationScheduling` 実装）

- 対象ファイル: `Sources/MultiTimerApp/Platform/NotificationScheduler.swift`
- 仕様: `docs/design-docs/20-spec/notification-and-sound.md`。
- 実装内容
  - `UNUserNotificationCenter` を用いる `NotificationScheduling` 実装。
  - 起動時または初回に `requestAuthorization` で許可を要求する。未許可でも例外にせず、音は鳴る（通知だけ出ない）。
  - 終了ごとに**一意の識別子**（UUID 等）でローカル通知を送り、OS 側でまとめられないようにする（終わった順にスタック表示）。
  - 通知タイトル・本文は Core の整形結果（`<タイトル> 終了` / `タイマー終了`、本文 `設定した時間が経過しました`）を受け取って表示する。整形ロジックは Core（フェーズ 2）に置き、ここは表示のみ。
  - 通知が OS 側で無効・非対応でも静かに継続しエラーにしない。
- 完了条件: `NotificationScheduling` 実装が `swift build` で通り、許可要求・一意 ID 発行の呼び出し口が揃う。
- 検証: `swift build`。実表示の確認は BB-04/BB-11（フェーズ 7、`.app` 必須）。

## ステップ 4.4 ウィンドウ設定（AppKit 併用）

- 対象ファイル: `Sources/MultiTimerApp/Platform/WindowConfigurator.swift`（または App 側から使うヘルパ）
- 仕様: `docs/design-docs/50-ui/layout-and-style.md`、`docs/design-docs/40-architecture/technology-choices.md`。
- 実装内容（SwiftUI では届かない部分を AppKit で補う）
  - タイトルバーを隠す（`titlebarAppearsTransparent = true` + `titleVisibility = .hidden`）。信号機ボタンは残す。
  - 初期サイズ 360x480、最小サイズ 120x100。
  - 背景色 `#1c1c1e`。
  - 背景ドラッグでウィンドウ移動（`NSWindow.isMovableByWindowBackground = true`）。操作要素（入力欄・ボタン・時刻表示・削除・追加パーツ）はクリックを優先して受け取り、ドラッグ対象外にする。
  - 上端の余白 28px 以上を確保し、信号機ボタンにコンテンツが重ならないようにする（レイアウト側と合わせる）。
- 完了条件: ウィンドウ生成時にこれらの設定を適用できるフックが用意され、`swift build` が通る。
- 検証: `swift build`。見た目・ドラッグの確認は BB-10（フェーズ 7）。

## フェーズ 4 完了条件

- `chime.caf` が Resources に存在し、バンドルに含められる。
- `ChimePlaying` / `NotificationScheduling` の Platform 実装が `Ports` を満たし、`swift build` が通る。
- 暖機メソッドが用意され、終了パス上で初回初期化しない設計になっている。
- ウィンドウ設定の AppKit フックが用意されている。
- 実表示・実再生・ウィンドウ挙動の確認はフェーズ 7（`.app`）で BB により行う。
