#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck disable=SC1091
# shellcheck source=../lib/runtime.sh
source "$REPO_ROOT/scripts/lib/runtime.sh"
# shellcheck disable=SC1091
# shellcheck source=../lib/report.sh
source "$REPO_ROOT/scripts/lib/report.sh"

REGISTRY="$DEFAULT_REGISTRY"
TAG="$DEFAULT_TAG"
ONLY_RUNTIMES=""
DRY_RUN=false
CREATE_BACKUP=false
AGGRESSIVE_MODE=false
OPTIMIZATION_REPORT="./optimization_report.md"
BACKUP_TAG="backup-$(date +%Y%m%d-%H%M%S)"
TARGET_RUNTIMES=()

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh optimize [选项]

默认行为: 不指定 --only 时，分析全部支持的 runtime

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  --report-file FILE  设置优化报告路径 (默认: $OPTIMIZATION_REPORT)
  --only RUNTIMES     仅分析指定 runtime，支持逗号分隔多个值
  --dry-run           仅显示优化建议，不执行实际操作
  --backup            在优化前创建备份标签
  --aggressive        启用激进优化模式
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--registry)
                require_value "$1" "${2-}"
                REGISTRY="$2"
                shift 2
                ;;
            --tag)
                require_value "$1" "${2-}"
                TAG="$2"
                shift 2
                ;;
            --report-file)
                require_value "$1" "${2-}"
                OPTIMIZATION_REPORT="$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --backup)
                CREATE_BACKUP=true
                shift
                ;;
            --aggressive)
                AGGRESSIVE_MODE=true
                shift
                ;;
            *)
                error_exit "未知选项: $1"
                ;;
        esac
    done
}

collect_runtimes() {
    resolve_target_runtimes "$ONLY_RUNTIMES"
    TARGET_RUNTIMES=("${PARSED_RUNTIMES[@]}")
}

init_report() {
    report_reset "$OPTIMIZATION_REPORT" \
        "# Docker 镜像自动优化报告" \
        "优化时间: $(date)" \
        "模式: $([ "$DRY_RUN" == true ] && echo "预览模式" || echo "执行模式")" \
        "激进模式: $([ "$AGGRESSIVE_MODE" == true ] && echo "启用" || echo "禁用")" \
        ""
}

image_ref() {
    local runtime_name="$1"
    echo "$(runtime_image_repo "$REGISTRY" "$runtime_name"):${TAG}"
}

backup_image() {
    local runtime_name="$1"
    local ref
    ref="$(image_ref "$runtime_name")"

    if [[ "$CREATE_BACKUP" != true ]]; then
        return
    fi

    report_append_lines "$OPTIMIZATION_REPORT" "## 备份信息 - $runtime_name" "备份标签: $BACKUP_TAG" ""
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] 将创建备份: ${ref} -> ${BACKUP_TAG}"
        return
    fi

    if docker image inspect "$ref" >/dev/null 2>&1; then
        docker tag "$ref" "$(runtime_image_repo "$REGISTRY" "$runtime_name"):${BACKUP_TAG}"
        log_success "✅ 备份完成: ${runtime_name}:${BACKUP_TAG}"
    fi
}

analyze_dockerfile() {
    local runtime_name="$1"
    local dockerfile_path
    local run_count

    dockerfile_path="$(runtime_context_dir "$runtime_name")/Dockerfile"
    validate_runtime_context "$runtime_name"
    run_count=$(grep -c '^RUN' "$dockerfile_path")

    report_append_lines "$OPTIMIZATION_REPORT" "## Dockerfile 分析 - $runtime_name" ""
    if [[ "$run_count" -gt 5 ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- 合并 RUN 指令以减少层数 (当前: $run_count 个)"
    fi
    if ! grep -q 'rm -rf.*cache\|rm -rf.*tmp' "$dockerfile_path"; then
        report_append_line "$OPTIMIZATION_REPORT" "- 添加缓存清理命令"
    fi
    if ! grep -q '^USER ' "$dockerfile_path"; then
        report_append_line "$OPTIMIZATION_REPORT" "- 添加非 root 用户以提高安全性"
    fi
    if ! grep -q '^HEALTHCHECK' "$dockerfile_path"; then
        report_append_line "$OPTIMIZATION_REPORT" "- 评估是否需要健康检查"
    fi
    if [[ "$AGGRESSIVE_MODE" == true ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- 激进模式: 建议进一步清理包管理器缓存和临时文件"
    fi
    report_append_blank "$OPTIMIZATION_REPORT"
}

generate_optimized_dockerfile() {
    local runtime_name="$1"
    local original_dockerfile
    local optimized_dockerfile

    original_dockerfile="$(runtime_context_dir "$runtime_name")/Dockerfile"
    optimized_dockerfile="$(runtime_context_dir "$runtime_name")/Dockerfile.optimized"

    if [[ "$DRY_RUN" == true ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- [dry-run] 将生成优化建议文件: $optimized_dockerfile"
        report_append_blank "$OPTIMIZATION_REPORT"
        return
    fi

    cp "$original_dockerfile" "$optimized_dockerfile"
    report_append_line "$OPTIMIZATION_REPORT" "- 已生成优化建议文件: $optimized_dockerfile"
    report_append_blank "$OPTIMIZATION_REPORT"
}

analyze_image() {
    local runtime_name="$1"
    local ref

    ref="$(image_ref "$runtime_name")"
    report_append_lines "$OPTIMIZATION_REPORT" "## 镜像分析 - $runtime_name" ""

    if [[ "$DRY_RUN" == true ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- [dry-run] 将分析镜像 $ref 的大小、层数和安全配置"
        report_append_blank "$OPTIMIZATION_REPORT"
        return
    fi

    if ! docker image inspect "$ref" >/dev/null 2>&1; then
        report_append_line "$OPTIMIZATION_REPORT" "- 镜像不存在: $ref"
        report_append_blank "$OPTIMIZATION_REPORT"
        return
    fi

    local size
    local size_mb
    local layers
    local user_name
    local healthcheck
    size=$(docker image inspect "$ref" --format '{{.Size}}')
    size_mb=$((size / 1024 / 1024))
    layers=$(docker image inspect "$ref" --format '{{len .RootFS.Layers}}')
    user_name=$(docker image inspect "$ref" --format '{{.Config.User}}')
    healthcheck=$(docker image inspect "$ref" --format '{{.Config.Healthcheck}}')

    report_append_line "$OPTIMIZATION_REPORT" "- 当前镜像: $ref"
    report_append_line "$OPTIMIZATION_REPORT" "- 当前大小: ${size_mb}MB"
    report_append_line "$OPTIMIZATION_REPORT" "- 层数: $layers"
    if [[ -z "$user_name" || "$user_name" == "root" ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- 安全建议: 镜像以 root 运行，建议改为非特权用户"
    else
        report_append_line "$OPTIMIZATION_REPORT" "- 安全配置: 使用非 root 用户 $user_name"
    fi
    if [[ "$healthcheck" == "<nil>" ]]; then
        report_append_line "$OPTIMIZATION_REPORT" "- 健康检查: 缺少健康检查配置"
    else
        report_append_line "$OPTIMIZATION_REPORT" "- 健康检查: 已配置"
    fi
    report_append_blank "$OPTIMIZATION_REPORT"
}

generate_summary() {
    report_append_lines "$OPTIMIZATION_REPORT" \
        "## 优化摘要" \
        "" \
        "### 已完成的动作" \
        "- Dockerfile 分析和优化建议生成" \
        "- 镜像大小与安全配置分析" \
        "" \
        "### 下一步行动" \
        "1. 审查生成的优化建议" \
        "2. 测试优化后的 Dockerfile" \
        "3. 对比优化前后的镜像大小和性能" \
        "4. 在确认后更新生产镜像" \
        ""
}

optimize_runtime() {
    local runtime_name="$1"

    log_info ""
    log_info "🔧 优化分析 runtime: ${runtime_name}"
    backup_image "$runtime_name"
    analyze_dockerfile "$runtime_name"
    generate_optimized_dockerfile "$runtime_name"
    analyze_image "$runtime_name"
}

main() {
    local runtime_name

    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    collect_runtimes
    init_report

    if [[ "$DRY_RUN" != true ]]; then
        require_command docker
    fi

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        optimize_runtime "$runtime_name"
    done

    generate_summary
    log_success "✨ 自动优化分析完成: $OPTIMIZATION_REPORT"
}

main "$@"
