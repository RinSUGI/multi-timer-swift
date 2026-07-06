# タイマーの状態遷移・操作仕様

## この文書で決めること

1 つのタイマーが持つ状態と、Start / Stop / Reset / Clear および自動リセットによる状態遷移を定義する。これはブラックボックスの正本である。

一次情報源: `_archive/multi-timer-mac/src/renderer/timer.ts`（`TimerCard` クラス）。

## タイマーの状態

各タイマーは次の状態を持つ。

| 状態                    | 型                | 意味                         | 永続化 |
| ----------------------- | ----------------- | ---------------------------- | ------ |
| `id`                    | 文字列            | 一意識別子（UUID）           | する   |
| `title`                 | 文字列            | タイトル（最大 50 文字）     | する   |
| `configuredMs`          | 整数（ミリ秒）    | 設定時間。リセット時の戻り先 | する   |
| `remainingMs`           | 整数（ミリ秒）    | カウントダウン残量           | しない |
| `isRunning`             | 真偽              | 実行中か                     | しない |
| `expiredAfterCountdown` | 真偽              | 自然終了後の黄色表示か       | しない |
| `editingSegment`        | セグメント / なし | 現在編集中のセグメント       | しない |

- 永続化しない状態は、起動時に次の初期値をとる: `remainingMs = configuredMs`、`isRunning = false`、`expiredAfterCountdown = false`、`editingSegment = なし`。
- 詳細は [30-data/persistence.md](../30-data/persistence.md) を参照。

## 操作の仕様

### Start（開始）

- 前提: `isRunning = false` かつ `remainingMs > 0` のときのみ動作する。それ以外は無視する。
- 編集中のセグメントがあれば、まず編集を確定する（[time-editing.md](time-editing.md) を参照）。
- `isRunning = true`、`expiredAfterCountdown = false` にする。
- 計時の基準時刻を初期化し、カウントダウンを開始する。

### Stop（停止）

- `isRunning = false` にする。計時を止める。
- 残り時間は保持したままとする（再開できる）。

### Reset（リセット）

- 実行中・停止中どちらでも動作する。
- まず停止する。
- 編集中のセグメントがあれば、その編集は「破棄」して（入力値を適用せず）表示を元に戻す。
- `remainingMs = configuredMs` にする。
- `expiredAfterCountdown` は変更しない。ただしボタン活性条件（後述）により、自然終了直後の黄色状態では Reset ボタンは押せない。したがって「黄色のまま Reset で残る」ことは通常起きない。

### Clear（クリア）

- まず停止する。
- `remainingMs = 0`、`configuredMs = 0`、`editingSegment = なし`、`expiredAfterCountdown = false` にする。
- 表示は `00:00:00`・白になる。
- 永続化する（`configuredMs = 0` を保存）。既存はタイトル入力と同じ 300ms デバウンス経路である（[30-data/persistence.md](../30-data/persistence.md) を参照）。

### 自動リセット（カウントダウン 0 到達時）

計時が `remainingMs <= 0` に到達したとき、次の順序で処理する。

1. `remainingMs` を 0 にクランプする。
1. `expiredAfterCountdown = true` にする。
1. 終了処理を行う（チャイム音の再生と通知。[notification-and-sound.md](notification-and-sound.md) を参照）。
1. リセット処理を行う（停止し、`remainingMs = configuredMs` に戻す）。

結果として、自然終了後は「非実行・`remainingMs = configuredMs`・黄色表示」になる。

## 計時（tick）の仕様

- 経過時刻（wall-clock）ベースで計算する。前回計時時刻からの差分だけ `remainingMs` を減らす。負値は 0 にクランプする。
- 単純な「一定量ずつ減算」ではなく実時刻差分を使うため、画面更新間隔を粗くしても合計の計時精度は保たれる。
- 実装方針（更新頻度・精度分離）は [40-architecture/technology-choices.md](../40-architecture/technology-choices.md) を参照。

## ボタンの活性・非活性

`renderDisplay` 相当のロジックで、状態に応じて次のとおり決める。

| ボタン | 非活性（disabled）になる条件                                                    |
| ------ | ------------------------------------------------------------------------------- |
| Start  | `isRunning = true`、または `remainingMs <= 0`                                   |
| Stop   | `isRunning = false`                                                             |
| Reset  | `isRunning = false` かつ `!(configuredMs > 0 かつ remainingMs != configuredMs)` |
| Clear  | 常に活性（非活性にしない）                                                      |

Reset の条件は言い換えると次のとおり。

- 実行中は常に活性。
- 停止中は「設定時間が 0 より大きく、かつ残り時間が設定時間と異なる」ときのみ活性。すなわち、途中で止めた状態でのみ押せる。
- 自然終了直後（`remainingMs == configuredMs`）は非活性。

## セグメント表示の見た目

- 実行中はセグメントに「disabled」相当のスタイルを適用し、クリック編集を受け付けない。
- 非実行中はセグメントをクリック／フォーカスして編集できる。詳細は [time-editing.md](time-editing.md) を参照。

## タイトルの編集

- タイトルは実行中を含む任意の状態で編集できる（セグメントと異なり、実行中も制限しない）。
- 最大 50 文字。入力欄側でも 50 文字で制限する。
- 変更は 300ms デバウンスで永続化する（[30-data/persistence.md](../30-data/persistence.md) を参照）。
- タイトルの変更は、計時・黄色表示・ボタン活性に影響しない。

## 状態遷移まとめ表

| 現在の状態   | 操作                   | 遷移後                          |
| ------------ | ---------------------- | ------------------------------- |
| 停止・残り>0 | Start                  | 実行中                          |
| 実行中       | Stop                   | 停止・残り保持                  |
| 実行中       | Reset                  | 停止・残り=設定・黄色は付かない |
| 停止・途中   | Reset                  | 停止・残り=設定                 |
| 実行中       | 0 到達                 | 停止・残り=設定・黄色・通知     |
| 任意         | Clear                  | 停止・残り=0・設定=0・白・保存  |
| 実行中       | Start / セグメント編集 | 無視される                      |

## リソース解放

- タイマー削除時は、計時ループと保存の遅延処理（デバウンス）を確実に停止してから DOM / ビューから取り除く。
- 削除の詳細は [multi-timer.md](multi-timer.md) を参照。
