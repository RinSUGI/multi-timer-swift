#!/usr/bin/env bash
set -euo pipefail

# リポジトリ標準のドキュメント整形・lintを完了条件として実行する。
# Markdown / JSON / YAML と scripts 配下の shell は package.json の npm scripts を正本にする。

if [ -f package.json ]; then
  echo "==> npm run format:check"
  npm run format:check

  echo "==> npm run lint"
  npm run lint
else
  echo "==> package.json not found; skipping npm checks"
fi
