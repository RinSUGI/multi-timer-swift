#!/usr/bin/env bash
set -euo pipefail

# Codex / Cursor 等の Agent 作業後に実行する固定検証の入口です。
# 設計等のドキュメント作成・更新のみの場合に使用する確認用スクリプトです。
# JSON / Markdown / YAML / shell の構文・整形は docs.sh 内の npm scripts が担当する。
# python による ad-hoc な JSON 事前チェックは不要。python コマンドも使わないこと。

echo "==> Running repository checks for agent docs work"

# ドキュメント品質チェック
./scripts/checks/docs.sh

echo "==> Agent docs check completed"
