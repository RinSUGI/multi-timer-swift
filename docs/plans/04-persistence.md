# フェーズ 3: 永続化 I/O・直列化・破損対応

`MultiTimerStorage` にファイル入出力を実装し、結合テスト（TC-Persist）で固める。正規化・パース・移行のロジックはフェーズ 2 の `MultiTimerCore` を再利用する。

## 前提

- 仕様の正本は `docs/design-docs/30-data/persistence.md`。
- 保存先は既存データ引き継ぎ（OQ-04）のため `~/Library/Application Support/multi-timer/timer.json`。**ディレクトリ名は `multi-timer`**（既存 Electron の `userData` と一致させる）。
- App Sandbox は無効前提（有効化するとパス前提が崩れる）。フェーズ 7 の `.app` 組み立てでも Sandbox は有効化しない。
- 全ファイル操作を直列化する（`actor` を採用）。

## ステップ 3.1 TimerStore（actor）の実装

- 対象ファイル: `Sources/MultiTimerStorage/TimerStore.swift`
- 実装内容
  - `actor TimerStore` として全ファイル操作を直列化する（`docs/design-docs/40-architecture/technology-choices.md` の永続化方針）。
  - 初期化: 保存先ディレクトリ URL を引数で受け取れるようにする（本番は `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` + `multi-timer`、テストは一時ディレクトリ）。ディレクトリが無ければ作成する。
  - `load()`: ファイルを読み、`MultiTimerCore` のパース・移行を通して `[StoredTimer]` を返す。移行が発生した場合は正規化後の内容を書き戻す。
  - `save(_:)`（`saveTimer` 相当）: 入力を正規化し、現在のファイルを読み、`id` 一致があれば更新、無ければ末尾追加、12 件に切り詰めて書き込む。
  - `delete(id:)`（`deleteTimer` 相当）: ファイルを読み、`id` 一致を除外し、変化があれば書き込む（無ければ何もしない）。
  - 書き込みは JSON（`{ "timers": [...] }` 形式）。`Codable` エンコード。整形（pretty）は任意。
- 破損・異常対応（`load()` 内）
  - ファイル無し（存在しない）: 空配列を返す。エラーにしない。
  - 読み込み失敗（存在するが読めない）: ログに記録し、空配列を返す。
  - JSON パース失敗: 破損ファイルを同ディレクトリの `timer.corrupt-<タイムスタンプ>.json` へ**退避**してから空配列を返す。退避失敗もログに記録し、空配列で継続する。
- 完了条件: `TimerStore` の API（load/save/delete）が揃い、`swift build` が通る。保存先ディレクトリを注入できる。
- 検証: `swift build`。

## ステップ 3.2 永続化結合テスト（TC-Persist-01〜08）

- 対象ファイル: `Tests/MultiTimerStorageTests/`
- 前提: 各テストは一時ディレクトリを保存先に注入し、テスト後に片づける。実時間・実ユーザーディレクトリに依存しない。
- テスト
  - TC-Persist-01: 保存 → 読み込みで内容が復元される。
  - TC-Persist-02: 同一 `id` 再保存で更新（重複しない）。
  - TC-Persist-03: 新規 `id` 保存で末尾追加。
  - TC-Persist-04: 削除 → 読み込みで対象が消える。
  - TC-Persist-05: 存在しない `id` 削除で変化なし・エラーなし。
  - TC-Persist-06: ファイル無し（初回）で空配列・エラーなし。
  - TC-Persist-07: 壊れた JSON を置いてから読み込み → 空配列、かつ `timer.corrupt-*` が退避されている（ディレクトリ内に該当ファイルが生成されることを確認）。
  - TC-Persist-08: 13 件保存 → 12 件に切り詰め。
- 完了条件: TC-Persist-01〜08 が全パス。
- 検証: `swift test --filter TimerStore`（該当テスト型）。

## ステップ 3.3 直列化テスト（TC-Persist-09）

- 対象ファイル: `Tests/MultiTimerStorageTests/`
- テスト
  - TC-Persist-09: 並行して多数の保存を発行しても、直列化されファイルが壊れない・最終状態が一貫する。`actor` により順序化されることを、多数の `Task` から同時に `save` を投げて最終読み込み結果が矛盾しない形で確認する。
- 注意: 非決定性を避けるため、最終状態の検証は「件数上限（12）を超えない」「JSON が常にパース可能」「投入した `id` 群のうち残った集合が矛盾しない」といった不変条件で行う。特定順序を期待しない。
- 完了条件: TC-Persist-09 がパスし、フレークしない。
- 検証: `swift test --filter TimerStore`（複数回実行して安定を確認）。

## フェーズ 3 完了条件

- `swift test` で TC-Persist-01〜09 が全パス。
- `TimerStore` が `actor` で直列化され、破損時に退避して空で継続する。
- 保存先ディレクトリ名が `multi-timer` で、既存データを読める（形式・正規化がフェーズ 2 と共通）。
- BB-08/BB-09 の I/O・退避部分は自動テストで固定済み（`.app` での最終確認はフェーズ 7）。
