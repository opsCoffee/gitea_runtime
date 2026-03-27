#!/bin/sh

set -eu

HOOK_SOURCE="${HOME}/.claude/hooks/prepare-commit-msg.sh"
TARGET_REPO="${1:-${PWD}}"
GIT_DIR="${TARGET_REPO}/.git"
HOOK_TARGET="${GIT_DIR}/hooks/prepare-commit-msg"

if [ ! -f "$HOOK_SOURCE" ]; then
    echo "错误: 未找到 Claude hook 模板: $HOOK_SOURCE" >&2
    exit 1
fi

if [ ! -d "$GIT_DIR" ]; then
    echo "错误: 目标目录不是 Git 仓库: $TARGET_REPO" >&2
    exit 1
fi

mkdir -p "${GIT_DIR}/hooks"
cp "$HOOK_SOURCE" "$HOOK_TARGET"
chmod +x "$HOOK_TARGET"

echo "已安装 Git hook: $HOOK_TARGET"
