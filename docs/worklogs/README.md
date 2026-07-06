# Worklog 運用ガイド

このディレクトリは、プロジェクトの作業ログをGit管理下で共有するための場所です。Claude CodeなどのAgentや人間が後から参照し、過去の判断・未解決事項・次の作業を追える状態にすることを目的とします。

## 置き場所

作業ログは、日付階層 + 作業単位のMarkdownファイルとして置きます。

```text
_misc/worklog/YYYY/MM/YYYY-MM-DD-number-short-task-slug.md
```

例:

```text
docs/worklog/2026/05/2026-05-20-01-harness-engineering-research.md
docs/worklog/2026/05/2026-05-20-02-markdown-tooling-and-codex-research.md
docs/worklog/2026/05/2026-05-25-01-codex-minimal-harness-checklist.md
```

## 命名ルール

- ファイル名は `YYYY-MM-DD-number-short-task-slug.md` とする。
- `number` は0埋め2桁の数字。01から開始する。
- `short-task-slug` は英小文字、数字、ハイフンで書く。
- 人名はファイル名やディレクトリ名に含めない。
- 同じ日に複数作業がある場合は、作業単位でファイルを分け、`number` を作業順にカウントアップして入れる。

人別ディレクトリにしない理由は、作業ログを個人の日報ではなく、プロジェクトの共有記憶として扱うためです。Codexや新しいメンバーが探すべき軸は「誰が書いたか」よりも「いつ、何の作業で、どんな判断をしたか」です。

## テンプレート

```md
# YYYY-MM-DD 作業タイトル

Date: YYYY-MM-DD  
Name: name  
Related:

- path/to/related-file.md

## Summary

-

## Done

-

## Decisions

-

## Issues

-

## Next

-
```

## 書く内容

- 実施した作業
- 決定したこと
- 未解決の問題
- 次にやること
- 関連PR、関連ドキュメント、関連Issue
- Claude CodeなどのAgentが次回読むと助かる背景や注意点

## 書かない内容

次の内容はGit管理下の作業ログに含めません。

- APIキー、トークン、パスワード、秘密情報
- 本番データ、個人情報、口座情報、取引明細などの機微情報
- 秘密情報を含む可能性のある生ログ
- 個人的な思考メモやチーム共有に不要な雑記
- 大容量の一時ログや生成物

必要な場合は、秘密情報を除去した要約だけを残します。
