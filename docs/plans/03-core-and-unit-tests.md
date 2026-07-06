# フェーズ 2: Core 純粋ロジックと単体テスト

`MultiTimerCore` の純粋ロジックを実装し、単体テストで固める。ここを完了させてから UI・Platform を載せる。全 TC-\*（Persist を除く）をここでパスさせる。

## 前提

- テストフレームワークは Swift Testing または XCTest。プロジェクトで統一する（`docs/design-docs/60-testing/strategy.md`）。以降のステップでは「テストを追加する」とだけ書くので、選んだフレームワークの記法で書く。
- 仕様の正本は各仕様書。ケース表は `docs/design-docs/60-testing/unit-test-design.md`。値が食い違う場合は仕様書の本文が正。
- Core は Foundation の基本型のみ使用可。I/O・UI・OS 機能は使わない。

## ステップ 2.1 時刻注入の基盤（`Clock`）

- 対象ファイル: `Sources/MultiTimerCore/Clock.swift`
- 実装内容
  - `protocol Clock { func now() -> TimeInterval }`（単調増加の経過秒。用途は tick の差分計算）。
  - 本番実装（例: `SystemClock`）は `Date().timeIntervalSinceReferenceDate` や `DispatchTime`/`CFAbsoluteTimeGetCurrent` ベース。
  - テスト用の可変クロック（例: `TestClock`）は、任意の経過を注入できる。テストターゲット側に置いてもよい。
- 完了条件: `TimerModel` が `Clock` を注入して受け取れる。
- 検証: `swift build`。

## ステップ 2.2 時刻変換 `TimeConversion`（TC-Time-01〜11）

- 対象ファイル: `Sources/MultiTimerCore/TimeConversion.swift`
- 仕様: `docs/design-docs/20-spec/time-editing.md` の「時刻とミリ秒の相互変換」。
- 実装内容（純粋関数）
  - ミリ秒 → 時分秒: 総秒数 = `ceil(ms / 1000)` を 0 で下限クランプ。時 = 総秒 / 3600、分 = (総秒 % 3600) / 60、秒 = 総秒 % 60。**`ceil` を使う**（残り 500ms でも秒は 1）。
  - 時分秒 → ミリ秒: `(時*3600 + 分*60 + 秒) * 1000`。
  - 整形: 2 桁ゼロ埋め文字列。
  - 負値・小数の扱いに注意（`ceil` 前に負値は 0 クランプ、ms は整数前提だが防御的に floor してよい）。
- テスト（`MultiTimerCoreTests`）: TC-Time-01〜11 を実装する。
  - TC-Time-03（500ms→1 秒）と TC-Time-04（1ms→1 秒）で `ceil` を固定する。
  - TC-Time-06 は `maxConfiguredMs` = 99/59/59。
  - TC-Time-07 は負値→0,0,0。
  - TC-Time-11 は往復（秒境界値）で元の値に一致。
- 完了条件: TC-Time-01〜11 が全パス。
- 検証: `swift test --filter TimeConversion`（フィルタ名は付けたテスト型名に合わせる）。

## ステップ 2.3 セグメントのクランプ `SegmentEditing`（TC-Clamp-01〜09）

- 対象ファイル: `Sources/MultiTimerCore/SegmentEditing.swift`
- 仕様: `docs/design-docs/20-spec/time-editing.md` の「入力の制約」。
- 実装内容
  - セグメント種別を表す型（例: `enum Segment { case hours, minutes, seconds }`）と、各種別の上限（時 99 / 分 59 / 秒 59）。
  - クランプ関数: 入力文字列から**非数字を除去**して整数化し、数値でなければ 0、範囲外は下限 0・上限（種別ごと）に丸める。符号（`-`）も非数字として除去する。
- テスト: TC-Clamp-01〜09。
  - TC-Clamp-07（"1a2"→12）と TC-Clamp-09（"-5"→5）で非数字・符号除去を固定する。
  - TC-Clamp-08（"abc"→0）で数値なし→0。
- 完了条件: TC-Clamp-01〜09 が全パス。
- 検証: `swift test --filter SegmentEditing`（または該当テスト型）。

## ステップ 2.4 セグメント確定の合成（TC-Edit-01〜04）

- 対象ファイル: `Sources/MultiTimerCore/SegmentEditing.swift` と `Sources/MultiTimerCore/TimerModel.swift`
- 仕様: `docs/design-docs/20-spec/time-editing.md` の「確定時の状態変化」。
- 実装内容
  - 確定合成関数: 現在の**残り時間**から時分秒を取り出し（`TimeConversion` を使用）、編集したセグメントだけをクランプ後の値で置換し、3 桁を合成して新しいミリ秒を返す純粋関数。
  - `TimerModel` 側に確定処理を用意し、`remainingMs` と `configuredMs` の**両方**を新値にする。同時に `expiredAfterCountdown = false`（黄色解除）。保存トリガ（即時保存、OQ-05）はビューモデル／App 層で扱うため、ここでは状態変化のみを担い、変化を呼び出し側へ通知できる形にする。
- テスト: TC-Edit-01〜04。
  - TC-Edit-01（残り 00:00:00 に分 "5"→00:05:00）。
  - TC-Edit-02（残り 00:05:00 に時 "1"→01:05:00、他桁保持）。**残り時間基準の合成**を固定する。
  - TC-Edit-03（黄色→確定で黄色 false）。
  - TC-Edit-04（分 "70"→59 クランプ）。
- 完了条件: TC-Edit-01〜04 が全パス。
- 検証: `swift test`（該当テスト型フィルタ）。

## ステップ 2.5 タイマー状態遷移 `TimerModel`（TC-State-01〜16）

- 対象ファイル: `Sources/MultiTimerCore/TimerModel.swift`
- 仕様: `docs/design-docs/20-spec/timer-behavior.md`、`docs/design-docs/20-spec/expired-coloring.md`。
- 実装内容（状態と遷移。`Clock` を注入）
  - 状態: `id`・`title`・`configuredMs`・`remainingMs`・`isRunning`・`expiredAfterCountdown`・`editingSegment`。
  - `start()`: `isRunning == false && remainingMs > 0` のときのみ動作。編集中セグメントがあれば先に確定。`isRunning = true`、`expiredAfterCountdown = false`、計時基準時刻を初期化。
  - `stop()`: `isRunning = false`、残り保持。
  - `reset()`: まず停止。編集中セグメントは**破棄**。`remainingMs = configuredMs`。`expiredAfterCountdown` は変更しない。
  - `clear()`: 停止。`remainingMs = 0`、`configuredMs = 0`、`editingSegment = なし`、`expiredAfterCountdown = false`。即時保存対象（保存自体は上位層）。
  - `tick()`: wall-clock 差分（`Clock` の現在値と前回計時時刻の差）で `remainingMs` を減らす。負値は 0 クランプ。`remainingMs <= 0` 到達時は自動リセット手順: 0 クランプ → `expiredAfterCountdown = true` → 終了処理（音・通知）を**1 回**発火 → 停止し `remainingMs = configuredMs`。終了処理はプロトコル（`Ports.swift`、フェーズ 2 ステップ 2.7 で定義）越しに呼ぶ／もしくはコールバックで通知し、テストではダミーで発火回数を数える。
  - ボタン活性計算（純粋関数として公開）:
    - Start 非活性: `isRunning || remainingMs <= 0`。
    - Stop 非活性: `!isRunning`。
    - Reset 非活性: `!isRunning && !(configuredMs > 0 && remainingMs != configuredMs)`。
    - Clear: 常に活性。
- テスト: TC-State-01〜16。
  - 遷移: TC-State-01〜08（Start 無効条件、Stop 保持、Reset で黄色不変、Clear、tick で 0 到達の黄色 true と終了処理 1 回、黄色から再 Start の遷移）。
  - tick（時刻注入）: TC-State-09（300ms 経過→残り 700ms）、TC-State-10（1500ms 経過→0・黄色 true・終了処理 1 回）、TC-State-11（200ms を複数回注入→合計ぶん減少、更新頻度非依存）。
  - ボタン活性: TC-State-12〜16。とくに TC-State-16（自然終了直後 `remainingMs == configuredMs`・黄色→Reset 非活性）を固定する。
- 完了条件: TC-State-01〜16 が全パス。終了処理の発火回数がダミーで検証できる。
- 検証: `swift test`（該当テスト型フィルタ）。

## ステップ 2.6 正規化・パース・移行・採番（TC-Norm-01〜15 / TC-Number-01〜05）

- 対象ファイル: `Sources/MultiTimerCore/TimerNormalization.swift`
- 仕様: `docs/design-docs/30-data/persistence.md`、採番は `docs/design-docs/20-spec/multi-timer.md`。
- 実装内容
  - 保存レコード型（例: `struct StoredTimer: Codable { id; title; configuredMs }`）を定義。
  - 正規化（`normalizeTimer` 相当）: オブジェクトでない要素は無効（`nil`）とする。`id` は非空文字列ならそのまま、それ以外は新規 UUID を採番する。`title` は文字列なら先頭 50 文字に切り詰め、それ以外は空文字にする。`configuredMs` は有限数なら `floor` して `[0, maxConfiguredMs]` にクランプし、それ以外は 0 にする。
  - パース・移行（`parseTimers` 相当）: 正常形式 `{ timers: [...] }` は各要素正規化・無効除外・先頭 12 件切り詰め。レガシー形式 `{ title, configuredMs }` 単一オブジェクトは 1 件配列へ移行。`migrated = true` の条件（12 件超・`id` 補完・レガシー）を返す。JSON の柔軟な入力を扱うため、`JSONSerialization` 由来の `Any` またはカスタムデコードで「非数値型」「オブジェクトでない要素」を判定できるようにする。
  - 採番（`nextNewTimerNumber` 相当）: 既存タイトルのうち `新規タイマー<数字>` に一致する最大値 + 1。一致が無ければ 1。
- テスト
  - TC-Norm-01〜15（正規化 9 件・パース/移行 6 件）。TC-Norm-04（title 数値型→空）、TC-Norm-07（小数→floor）、TC-Norm-08（NaN/Inf→0）、TC-Norm-09（非オブジェクト→除外）、TC-Norm-12（13 件→先頭 12・移行あり）、TC-Norm-13（id 無し→採番・移行あり）、TC-Norm-14（レガシー→1 件・移行あり）を必ず含める。
  - TC-Number-01〜05。TC-Number-03（最大+1）、TC-Number-05（`新規タイマーA` は不一致→1）を含める。
- 完了条件: TC-Norm-01〜15、TC-Number-01〜05 が全パス。
- 検証: `swift test`（該当テスト型フィルタ）。

## ステップ 2.7 通知タイトル整形と Ports 定義（TC-Notify-01〜04）

- 対象ファイル: `Sources/MultiTimerCore/TimerNormalization.swift`（または `Notification` 用の小ファイル）と `Sources/MultiTimerCore/Ports.swift`
- 仕様: `docs/design-docs/20-spec/notification-and-sound.md`。
- 実装内容
  - 通知タイトル整形（純粋関数）: 入力タイトルを trim し、空でなければ `"<タイトル> 終了"`、空なら `"タイマー終了"`。本文は固定で `"設定した時間が経過しました"` を定数化。
  - `Ports.swift`: 終了処理の抽象を定義する。
    - `protocol ChimePlaying { func playChime() }`
    - `protocol NotificationScheduling { func scheduleFinish(title: String, body: String) }`
    - これらを `TimerModel` の終了処理から呼ぶ（発火判断は Core、実再生・実表示は Platform）。テストではダミー実装で発火・引数を検証する。
- テスト: TC-Notify-01〜04（"作業"→"作業 終了"、空→"タイマー終了"、空白のみ→trim 後空→"タイマー終了"、" 作業 "→trim→"作業 終了"）。
- 完了条件: TC-Notify-01〜04 が全パス。`Ports.swift` のプロトコルが定義され、`TimerModel` の終了処理がそれ越しに発火する。
- 検証: `swift test`（該当テスト型フィルタ）。

## フェーズ 2 完了条件

- `swift test` が全パス（TC-Time / TC-Clamp / TC-Edit / TC-State / TC-Norm / TC-Number / TC-Notify を網羅）。
- Core が Foundation の基本型のみに依存し、UI/OS 機能を含まない。
- `Ports.swift` と `Clock.swift` により、通知・音・時刻がプロトコルで抽象化されている。
- この時点で BB-02/BB-03/BB-04 の**ロジック部分**は自動テストで固定済み（UI での最終確認はフェーズ 7）。
