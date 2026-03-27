#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

error_exit() {
    echo "错误: $1" >&2
    exit 1
}

check_pattern_absent() {
    local pattern="$1"
    local description="$2"
    local matches

    matches=$(grep -RInE --include='Dockerfile' "$pattern" "$REPO_ROOT"/runtime-* || true)
    if [[ -n "$matches" ]]; then
        echo "$matches" >&2
        error_exit "检测到不安全的 Dockerfile 写法: ${description}"
    fi
}

main() {
    check_pattern_absent 'curl[[:space:]].*\|[[:space:]]*(sh|bash|/bin/sh|/bin/bash|ash|/bin/ash)' 'curl 管道执行 shell'
    check_pattern_absent 'wget[[:space:]].*\|[[:space:]]*(sh|bash|/bin/sh|/bin/bash|ash|/bin/ash)' 'wget 管道执行 shell'
    # shellcheck disable=SC2016
    check_pattern_absent '\$GITHUB_WORKSPACE' '构建阶段依赖 GITHUB_WORKSPACE'

    echo "Dockerfile 安全校验通过"
    echo "检查范围: runtime-*/Dockerfile"
    echo "已校验项目: 禁止 curl|shell、wget|shell、GITHUB_WORKSPACE 构建期依赖"
}

main "$@"
