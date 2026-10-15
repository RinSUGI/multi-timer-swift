# ビルド・署名・配布

## この文書で決めること

ビルド、Universal 化、署名、DMG 配布、バージョン運用の方針を定義する。未署名の DMG を手動配布するモデルとする。

## 到達目標

- アプリケーションフォルダにアイコンがあり、ダブルクリックで起動する通常の macOS アプリにする。
- 開発未経験のメンバーが、Google ドライブ等からダウンロードしてインストールできる配布物を作る。

## アプリのメタデータ

| 項目        | 値                                 |
| ----------- | ---------------------------------- |
| バンドル ID | `com.beyondsight.multi-timer`      |
| 製品名      | Multi Timer                        |
| カテゴリ    | `public.app-category.productivity` |
| 著作権      | Copyright © 2026 BeyondSight       |

## ビルドと成果物

- Universal（Apple Silicon + Intel 両対応）でビルドする。
- 成果物は DMG（ドラッグ＆ドロップで Applications へ入れる形式）とする。
- アイコンをアプリに埋め込む。ソースは `Sources/MultiTimerApp/Resources/AppIcon.icns`、バンドル配置は `.app/Contents/Resources/AppIcon.icns` とし、`Info.plist` の `CFBundleIconFile` に `AppIcon` を指定する。

## 署名（現状方針）

- Apple Developer ID を持たない前提とする。
- 未署名（アドホック署名）で配布する。Apple Silicon で起動するにはアドホック署名が必要なため、少なくともアドホック署名は施す。
- 受け取ったメンバーは初回のみ Gatekeeper の隔離フラグ解除が必要になる。手順はインストール手順に記載する。
  - GUI 手順: システム設定 → プライバシーとセキュリティ →「このまま開く」。
  - ターミナル手順: `xattr -dr com.apple.quarantine "/Applications/Multi Timer.app"`。
- 改ざん検知のため、DMG の SHA-256 チェックサムを添えて配布する（`shasum -a 256 <dmg>`）。

## バージョン運用

- 自動アップデート機構は設けない。
- 「誰がどの版か」は DMG のファイル名のバージョンで判別する。
- 更新のたびにバージョンを上げ、ファイル名にバージョンを含める（例: `Multi Timer-<version>-universal.dmg`）。

## 配布手順（メンバー向けドキュメント）

- 配布時は、DMG とあわせて「インストール手順」を用意する。初回起動時の Gatekeeper 回避を含む手順書として `docs/インストール手順.md` を整備する。

## 将来的な改善（任意・範囲外）

- Apple Developer ID を用意できれば、署名 + 公証（notarization）により初回の隔離解除手順を省ける。これは本プロジェクトの完了条件ではない（[00-overview/purpose-and-scope.md](../00-overview/purpose-and-scope.md) の対象外を参照）。

## ビルド自動化

- `scripts/build-app.sh` に、Universal ビルドから `.app` 組み立て・アドホック署名・DMG 生成・SHA-256 表示までを 1 コマンドで通す。外部ツール（`create-dmg` 等）には依存させず、`swift build` / `codesign` / `hdiutil` の標準機能だけで完結させる。
