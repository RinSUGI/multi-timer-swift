# フェーズ 7: ビルド・`.app` 組み立て・アドホック署名・DMG・配布手順書

Universal ビルドから `.app` 組み立て、アドホック署名、DMG 生成までを 1 スクリプトで行い、配布手順書を整備する。これが完了すると BB-01〜BB-11 を `.app` で実施できる。

## 前提

- 仕様の正本は `docs/design-docs/70-packaging/build-and-distribution.md`。
- SwiftPM 主体。`.xcodeproj` は使わない。外部ツール（`create-dmg` 等）は追加しない（`hdiutil` を使う）。
- アイコンは `AppIcon.icns` として Resources に置き、`CFBundleIconFile` で登録する。

## ステップ 7.1 アイコンと Info.plist テンプレートの用意

- 対象ファイル
  - `Sources/MultiTimerApp/Resources/AppIcon.icns`（デザインを起こしたアイコンの `.icns`。Resources にトラッキング下で置く）
  - `scripts/Info.plist`（テンプレート、`.app` 組み立て時に `Contents/Info.plist` へコピー）
- Info.plist の値（`docs/design-docs/70-packaging/build-and-distribution.md` のメタデータ）
  - `CFBundleIdentifier`: `com.beyondsight.multi-timer`
  - `CFBundleName` / `CFBundleDisplayName`: `Multi Timer`
  - `CFBundleShortVersionString`: `Constants` の `appVersion` と同一値
  - `CFBundleVersion`: ビルド番号（`1` 起点でよい）
  - `CFBundleIconFile`: `AppIcon`（拡張子なしで参照。`AppIcon.icns` を `.app/Contents/Resources/` へ配置）
  - `LSApplicationCategoryType`: `public.app-category.productivity`
  - `LSMinimumSystemVersion`: `13.0`
  - `NSHumanReadableCopyright`: `Copyright © 2026 BeyondSight`
  - `CFBundlePackageType`: `APPL`、`CFBundleExecutable`: 実行ファイル名
  - App Sandbox は有効化しない（保存先パスの前提を守るため）。
- 完了条件: アイコンと Info.plist テンプレートがトラッキング下に揃う。
- 検証: ファイル存在確認。`plutil -lint scripts/Info.plist`。

## ステップ 7.2 ビルド・パッケージングスクリプト

- 対象ファイル: `scripts/build-app.sh`（新規）
- 実装内容（1 コマンドで通す）
  1. `swift build -c release --arch arm64 --arch x86_64` で Universal 実行ファイルを生成する。
  1. `.app` を組み立てる: `dist/Multi Timer.app/Contents/{MacOS,Resources}` を作り、実行ファイルを `MacOS/` へ、`Info.plist` を `Contents/` へ、`AppIcon.icns` と `chime.caf` を `Resources/` へ配置する。
  1. `codesign --force --deep --sign - "dist/Multi Timer.app"` でアドホック署名する（Apple Silicon 起動に必要）。
  1. `hdiutil create` で DMG を生成する（ドラッグ＆ドロップで Applications へ入れる形式）。出力名は `Multi Timer-<version>-universal.dmg`。
  1. `shasum -a 256 <dmg>` を出力してチェックサムを表示する。
- スクリプト規約
  - `set -euo pipefail`。バージョンは `Constants`（または単一ソース）から取得するか、スクリプト冒頭の変数 1 箇所で定義して Info.plist と揃える。
  - 出力先は `dist/`。`build/`（`.gitignore` 対象）や `.build/` に成果物を散らばらせない。
  - `shellcheck` / `shfmt` を通す（`docs/DOCUMENTATION_GUIDE.md`）。
- 出力先の除外
  - `.gitignore` に `dist/` を追加する（DMG・`.app` を誤ってコミットしない）。
- 完了条件: `./scripts/build-app.sh` が成功し、`dist/` に `.app` と DMG、チェックサムが生成される。生成 `.app` がダブルクリックで起動する。
- 検証: `./scripts/build-app.sh` 実行。`open "dist/Multi Timer.app"` で起動確認。`./scripts/agent-docs-check.sh`（シェルスクリプトと `.gitignore` 変更のため）。

## ステップ 7.3 配布手順書の整備

- 対象ファイル: `docs/インストール手順.md`
- 内容（`docs/design-docs/70-packaging/build-and-distribution.md`）
  - DMG からのインストール（Applications へドラッグ）。
  - 初回起動時の Gatekeeper 回避（未署名・アドホック署名のため）。
    - GUI 手順: システム設定 → プライバシーとセキュリティ →「このまま開く」。
    - ターミナル手順: `xattr -dr com.apple.quarantine "/Applications/Multi Timer.app"`。
  - 通知を有効にする手順（`UNUserNotificationCenter` の許可）。
  - 配布時に DMG の SHA-256 チェックサムを添える旨。
- 完了条件: 開発未経験のメンバーが手順書だけでインストール・初回起動・通知有効化まで到達できる。
- 検証: `./scripts/agent-docs-check.sh`。

## ステップ 7.4 ブラックボックステストの実施準備

- 対象: `docs/design-docs/60-testing/blackbox-test-cases.md` の全ケース。
- 内容: 生成した `.app`（または DMG からインストールした版）で BB-01〜BB-11 を人間が手動実施できる状態にする。実施手順・観点はブラックボックステストケースが正本。非機能（メモリ・CPU・起動）は NFR の測定方法で確認する。
- 完了条件: `.app` が起動し、通知許可要求・音・通知表示が本番相当で確認できる。BB 実施は人間が担当する（自動化しない）。
- 検証: 人間による BB 実施（フェーズ 8 のガイド参照）。

## フェーズ 7 完了条件

- `./scripts/build-app.sh` が成功し、Universal `.app` と DMG、SHA-256 が `dist/` に生成される。
- `.app` がダブルクリックで起動し、アイコンが付く。
- 配布手順書が整備され、`./scripts/agent-docs-check.sh` が通る。
- BB-01〜BB-11 を `.app` で実施できる状態になる。
