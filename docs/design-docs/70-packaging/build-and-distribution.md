# ビルド・署名・配布

## この文書で決めること

Swift 版のビルド、Universal 化、署名、DMG 配布、バージョン運用の方針を定義する。既存の配布モデル（未署名・DMG・手動配布）を踏襲する。

一次情報源: `_archive/multi-timer-mac/electron-builder.yml`、`README.md`（配布とインストール）、`docs/インストール手順.md`、`docs/issues/20260705_05_packaging.md`。

## 到達目標

- アプリケーションフォルダにアイコンがあり、ダブルクリックで起動する通常の macOS アプリにする。
- 開発未経験のメンバーが、Google ドライブ等からダウンロードしてインストールできる配布物を作る。

## アプリのメタデータ

既存の値を踏襲する。

| 項目        | 値                                 |
| ----------- | ---------------------------------- |
| バンドル ID | `com.beyondsight.multi-timer`      |
| 製品名      | Multi Timer                        |
| カテゴリ    | `public.app-category.productivity` |
| 著作権      | Copyright © 2026 BeyondSight       |

- バンドル ID は既存と揃える。既存データを引き継ぐ場合（[30-data/persistence.md](../30-data/persistence.md) の OQ-04）にも整合する。

## ビルドと成果物

- Universal（Apple Silicon + Intel 両対応）でビルドする。
- 成果物は DMG（ドラッグ＆ドロップで Applications へ入れる形式）とする。
- アイコンをアプリに埋め込む。既存はアイコンの元データを SVG で持ち、`.icns` を生成していた。Swift 版でも同等のアイコンを用意し、アセットに登録する。
- 具体的なビルド手段（Xcode の Archive / `xcodebuild` / DMG 生成ツール）は実装時に確定する（[Open Questions](#open-questions)）。

## 署名（現状方針）

- Apple Developer ID を持たない前提を踏襲する。
- 未署名（アドホック署名）で配布する。Apple Silicon で起動するにはアドホック署名が必要なため、少なくともアドホック署名は施す。
- 受け取ったメンバーは初回のみ Gatekeeper の隔離フラグ解除が必要になる。手順は既存 README・インストール手順の内容を踏襲する。
  - GUI 手順: システム設定 → プライバシーとセキュリティ →「このまま開く」。
  - ターミナル手順: `xattr -dr com.apple.quarantine "/Applications/Multi Timer.app"`。
- 改ざん検知のため、DMG の SHA-256 チェックサムを添えて配布する（`shasum -a 256 <dmg>`）。

## バージョン運用

- 自動アップデート機構は設けない（既存踏襲）。
- 「誰がどの版か」は DMG のファイル名のバージョンで判別する。
- 更新のたびにバージョンを上げ、ファイル名にバージョンを含める（例: `Multi Timer-<version>-universal.dmg`）。

## 配布手順（メンバー向けドキュメント）

- 配布時は、DMG とあわせて「インストール手順」を用意する。既存の `docs/インストール手順.md` に相当する、初回起動時の Gatekeeper 回避を含む手順書を Swift 版でも整備する。

## 将来的な改善（任意・範囲外）

- Apple Developer ID を用意できれば、署名 + 公証（notarization）により初回の隔離解除手順を省ける。これは本プロジェクトの完了条件ではない（[00-overview/purpose-and-scope.md](../00-overview/purpose-and-scope.md) の対象外を参照）。

## Open Questions

- OQ-09 ビルド・DMG 生成の具体手段（Xcode Archive、`xcodebuild` + `create-dmg` / `hdiutil` 等）と、その自動化スクリプトを置くか。
  - 決定: 自動化スクリプトを `scripts/` に置く。`swift build -c release --arch arm64 --arch x86_64` で Universal バイナリを作り、`.app` の組み立て（`Info.plist`・アイコン・実行ファイル配置）、`codesign --sign -`（アドホック署名）、`hdiutil` による DMG 生成までを 1 コマンドで行う。外部ツール（`create-dmg` 等）は追加依存になるため使わない。OQ-06 の決定（SwiftPM 主体か）と整合させる。
- OQ-10 アイコンの元データ（既存 SVG の流用か作り直しか）と、アセットへの登録方法。
  - 決定: 既存を流用する。`_archive/multi-timer-mac/build/` に `icon.svg`・`icon.icns`・`make-icon.sh` が揃っており、生成済みの `icon.icns` をそのままコピーして `.app` バンドルへ `CFBundleIconFile` で登録すればよい（Asset Catalog は必須ではない）。
