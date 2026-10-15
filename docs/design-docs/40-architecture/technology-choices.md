# 技術選定

## この文書で決めること

用いる UI フレームワーク、計時、音、通知、永続化、テストの技術選定と、その理由・注意点を示す。

## 方針

- 標準フレームワークのみで完結させ、外部依存を最小化する。理由: メモリ・起動時間・保守性・配布の単純さ（NFR-01 / NFR-03 / NFR-08）。
- 純粋ロジックを UI から分離し、単体テスト可能にする（NFR-07。[module-structure.md](module-structure.md) と [60-testing/unit-test-design.md](../60-testing/unit-test-design.md) を参照）。

## UI フレームワーク

- 採用: SwiftUI を主体とし、ウィンドウ設定など SwiftUI だけでは届かない部分に AppKit を薄く併用する。
- 理由: 記述量が少なく、宣言的でこの規模のアプリに合う。ネイティブなのでメモリも小さい。
- AppKit を併用する箇所の例。
  - タイトルバーを隠したフレーム（`NSWindow.titlebarAppearsTransparent = true` と `titleVisibility = .hidden`）。信号機ボタンは残す。
  - 最小ウィンドウサイズ 120x100、初期サイズ 360x480。
  - 背景色 `#1c1c1e`。
  - 背景ドラッグによるウィンドウ移動。SwiftUI 標準では全面ドラッグ移動が難しいため、`NSWindow` 側の設定や背景ビューで対応する。
- レイアウトの詳細は [50-ui/layout-and-style.md](../50-ui/layout-and-style.md) を参照。

## 計時（tick）

- 採用: 経過時刻ベースの計算 + 表示更新用の周期タイマー。
- 設計。
  - 実行開始時に「終了予定時刻（end date）」または「開始時刻と開始時残量」を保持する。残り時間は現在時刻との差から算出する。単純な定量減算にしない。
  - 表示更新は 200〜250ms 程度の周期で行う（NFR-02）。計時精度は時刻差分で担保されるため、更新頻度を落としても合計はずれない。
  - 周期タイマーは実行中のタイマーにのみ必要。停止中は動かさない。
- 実装: モデル層の `Timer`（RunLoop、間隔 200〜250ms、`tolerance` を設定）とする。`TimelineView` はビューが消えると止まるため、終了検知・通知の発火をビューのライフサイクルから独立させる目的でモデル層に置く。実測で問題が出た場合のみ `DispatchSourceTimer` へ切り替える。
- ウィンドウ非アクティブ時は更新頻度をさらに落とすことを検討する（NFR-02）。

## 音（チャイム）

- 採用: 2 音チャイムを事前レンダリングしたオーディオファイル（`.caf`）をバンドルし、`AVAudioPlayer` で再生する。
- 理由: 実装が単純で、初回遅延も抑えやすい。
- 初回遅延対策（NFR-03、[20-spec/notification-and-sound.md](../20-spec/notification-and-sound.md)）。
  - 再生系（プレイヤー）を起動直後または最初のユーザー操作時に一度初期化・暖機し、終了時の再生が即座に返るようにする。
- 音源生成: 周波数・倍音比・エンベロープを元に開発時に一度だけレンダリングし、生成物 `chime.caf` をリポジトリに含めてバンドルに同梱する。

## 通知

- 採用: `UserNotifications`（`UNUserNotificationCenter`）。
- 設計。
  - 起動時または初回に許可を要求する。
  - 終了ごとに一意の識別子でローカル通知を送り、OS 側でまとめられないようにする（終わった順にスタック表示。[20-spec/notification-and-sound.md](../20-spec/notification-and-sound.md)）。
  - 未許可でもアプリは正常動作し、音は鳴る。
- 注意: 通知には正しくバンドル化された `.app`（バンドル ID あり）が必要。開発中の実行方法によっては通知が出ないことがあるため、動作確認は配布形式に近い `.app` で行う。

## 永続化

- 採用: `Codable` + `FileManager` による JSON 読み書き。
- 直列化: 全ファイル操作をシリアルな `DispatchQueue` または `actor` で直列実行する（[30-data/persistence.md](../30-data/persistence.md)）。
- 保存先はアプリケーションサポート配下の `multi-timer/` ディレクトリ（`FileManager.urls(for: .applicationSupportDirectory ...)` を起点にする）。

## テスト

- 採用: Swift の標準テスト（Swift Testing または XCTest）。
- 純粋ロジック（時刻変換・状態遷移・正規化・採番）をモジュール分離し、UI 非依存で検証する。
- 詳細は [60-testing/](../60-testing/strategy.md) を参照。

## ビルド・パッケージング

- SwiftPM 主体（Core / App / Tests を 1 パッケージで管理）でビルドし、`.app` バンドル生成はスクリプト（`scripts/build-app.sh`）で行う。Universal な `.app` を生成して DMG 配布する。`.xcodeproj` は使わない。
- 詳細は [70-packaging/build-and-distribution.md](../70-packaging/build-and-distribution.md) を参照。
