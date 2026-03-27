#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

show_help() {
    cat <<'EOF'
用法: ./scripts/runtimectl.sh <command> [选项]

命令:
  build         构建运行时镜像
  test          运行运行时 smoke / 功能测试
  security      执行镜像安全扫描
  performance   执行镜像性能分析
  optimize      生成 Dockerfile / 镜像优化建议
  pipeline      执行完整流水线
  version       执行版本管理
  help          显示帮助信息

示例:
  ./scripts/runtimectl.sh build --only markdown,maven --dry-run
  ./scripts/runtimectl.sh test --only markdown --dry-run
  ./scripts/runtimectl.sh pipeline --only markdown,maven --quick
EOF
}

main() {
    local command_name="${1-}"
    local command_script

    case "$command_name" in
        ""|-h|--help|help)
            show_help
            return 0
            ;;
        build|test|security|performance|optimize|pipeline|version)
            shift
            ;;
        *)
            error_exit "未知命令: ${command_name}"
            ;;
    esac

    command_script="$SCRIPT_DIR/commands/${command_name}.sh"
    if [[ ! -f "$command_script" ]]; then
        error_exit "命令脚本不存在: ${command_script}"
    fi

    exec bash "$command_script" "$@"
}

main "$@"
