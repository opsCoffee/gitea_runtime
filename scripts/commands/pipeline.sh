#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
# shellcheck source=../lib/config.sh
source "$REPO_ROOT/scripts/lib/config.sh"
# shellcheck disable=SC1091
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck disable=SC1091
# shellcheck source=../lib/report.sh
source "$REPO_ROOT/scripts/lib/report.sh"

REGISTRY="$DEFAULT_REGISTRY"
TAG="$DEFAULT_TAG"
REPORT_DIR="./pipeline_reports"
ONLY_RUNTIMES=""
SKIP_BUILD=false
SKIP_TEST=false
SKIP_SECURITY=false
SKIP_PERFORMANCE=false
SKIP_OPTIMIZATION=false
DRY_RUN=false
START_TIME=0
PIPELINE_SUCCESS=true

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh pipeline [选项]

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  --only RUNTIMES     仅处理指定 runtime，支持逗号分隔多个值
  --skip-build        跳过构建步骤
  --skip-test         跳过测试步骤
  --skip-security     跳过安全扫描
  --skip-performance  跳过性能监控
  --skip-optimization 跳过优化分析
  --quick             快速模式，跳过性能监控与优化分析
  --dry-run           仅打印将执行的子命令
EOF
}

summary_file() {
    echo "$REPORT_DIR/pipeline_summary.md"
}

report_file() {
    echo "$REPORT_DIR/comprehensive_report.md"
}

append_step_status() {
    local label="$1"
    local status="$2"
    report_append_line "$(summary_file)" "- ${status} ${label}"
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
            -d|--report-dir)
                require_value "$1" "${2-}"
                REPORT_DIR="$2"
                shift 2
                ;;
            --tag)
                require_value "$1" "${2-}"
                TAG="$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-test)
                SKIP_TEST=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE=true
                shift
                ;;
            --skip-optimization)
                SKIP_OPTIMIZATION=true
                shift
                ;;
            --quick)
                SKIP_PERFORMANCE=true
                SKIP_OPTIMIZATION=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                error_exit "未知选项: $1"
                ;;
        esac
    done
}

init_pipeline() {
    ensure_directory "$REPORT_DIR"
    report_reset "$(summary_file)" \
        "# Docker 镜像流水线执行报告" \
        "" \
        "**执行时间**: $(date)" \
        "**注册表**: $REGISTRY" \
        "**镜像标签**: $TAG" \
        "**处理 runtime**: ${ONLY_RUNTIMES:-全部}" \
        ""
}

run_subcommand() {
    local step_name="$1"
    shift
    local -a command=("$REPO_ROOT/scripts/runtimectl.sh" "$@")

    log_info ""
    log_info "▶ 执行步骤: ${step_name}"
    print_command "${command[@]}"

    if "${command[@]}"; then
        return 0
    fi

    return 1
}

run_build_step() {
    local -a args=(build --registry "$REGISTRY" --tag "$TAG")
    if [[ -n "$ONLY_RUNTIMES" ]]; then
        args+=(--only "$ONLY_RUNTIMES")
    fi
    if [[ "$DRY_RUN" == true ]]; then
        args+=(--dry-run)
    fi

    if [[ "$SKIP_BUILD" == true ]]; then
        append_step_status "构建步骤" "⏭️"
        return 0
    fi

    if run_subcommand "构建镜像" "${args[@]}"; then
        append_step_status "构建步骤" "✅"
        return 0
    fi

    append_step_status "构建步骤" "❌"
    return 1
}

run_test_step() {
    local -a args=(test --registry "$REGISTRY" --tag "$TAG")
    if [[ -n "$ONLY_RUNTIMES" ]]; then
        args+=(--only "$ONLY_RUNTIMES")
    fi
    if [[ "$DRY_RUN" == true ]]; then
        args+=(--dry-run)
    fi

    if [[ "$SKIP_TEST" == true ]]; then
        append_step_status "测试步骤" "⏭️"
        return 0
    fi

    if run_subcommand "运行测试" "${args[@]}"; then
        append_step_status "测试步骤" "✅"
        return 0
    fi

    append_step_status "测试步骤" "❌"
    return 1
}

run_security_step() {
    local security_dir="$REPORT_DIR/security"
    local -a args=(security --registry "$REGISTRY" --tag "$TAG" --report-dir "$security_dir")
    if [[ -n "$ONLY_RUNTIMES" ]]; then
        args+=(--only "$ONLY_RUNTIMES")
    fi
    if [[ "$DRY_RUN" == true ]]; then
        args+=(--dry-run)
    fi

    if [[ "$SKIP_SECURITY" == true ]]; then
        append_step_status "安全扫描" "⏭️"
        return 0
    fi

    if run_subcommand "安全扫描" "${args[@]}"; then
        append_step_status "安全扫描" "✅"
        return 0
    fi

    append_step_status "安全扫描" "⚠️"
    return 0
}

run_performance_step() {
    local performance_dir="$REPORT_DIR/performance"
    local -a args=(performance --registry "$REGISTRY" --tag "$TAG" --report-dir "$performance_dir")
    if [[ -n "$ONLY_RUNTIMES" ]]; then
        args+=(--only "$ONLY_RUNTIMES")
    fi
    if [[ "$DRY_RUN" == true ]]; then
        args+=(--dry-run)
    fi

    if [[ "$SKIP_PERFORMANCE" == true ]]; then
        append_step_status "性能监控" "⏭️"
        return 0
    fi

    if run_subcommand "性能监控" "${args[@]}"; then
        append_step_status "性能监控" "✅"
        return 0
    fi

    append_step_status "性能监控" "⚠️"
    return 0
}

run_optimization_step() {
    local optimization_report="$REPORT_DIR/optimization_report.md"
    local -a args=(optimize --registry "$REGISTRY" --tag "$TAG" --report-file "$optimization_report")
    if [[ -n "$ONLY_RUNTIMES" ]]; then
        args+=(--only "$ONLY_RUNTIMES")
    fi
    if [[ "$DRY_RUN" == true ]]; then
        args+=(--dry-run)
    fi

    if [[ "$SKIP_OPTIMIZATION" == true ]]; then
        append_step_status "优化分析" "⏭️"
        return 0
    fi

    if run_subcommand "优化分析" "${args[@]}"; then
        append_step_status "优化分析" "✅"
        return 0
    fi

    append_step_status "优化分析" "⚠️"
    return 0
}

generate_comprehensive_report() {
    local final_report
    final_report="$(report_file)"

    report_reset "$final_report" \
        "# Docker 镜像流水线综合报告" \
        "" \
        "**生成时间**: $(date)" \
        "**执行耗时**: $(($(date +%s) - START_TIME)) 秒" \
        "**注册表**: $REGISTRY" \
        "**镜像标签**: $TAG" \
        "**处理 runtime**: ${ONLY_RUNTIMES:-全部}" \
        "" \
        "## 执行摘要" \
        ""
    report_append_file_from_line "$final_report" "$(summary_file)" 3
    report_append_blank "$final_report"
    report_append_lines "$final_report" "## 详细报告链接" ""

    if [[ -f "$REPORT_DIR/security/security_summary.md" ]]; then
        report_append_line "$final_report" "- [安全扫描详细报告](security/security_summary.md)"
    fi
    if [[ -f "$REPORT_DIR/performance/performance_summary.md" ]]; then
        report_append_line "$final_report" "- [性能监控详细报告](performance/performance_summary.md)"
    fi
    if [[ -f "$REPORT_DIR/optimization_report.md" ]]; then
        report_append_line "$final_report" "- [优化分析详细报告](optimization_report.md)"
    fi

    log_success "✅ 综合报告生成完成: $final_report"
}

cleanup() {
    if [[ "$DRY_RUN" == true ]]; then
        return
    fi

    if ! command -v docker >/dev/null 2>&1; then
        return
    fi

    log_info ""
    log_info "🧹 清理临时 Docker 资源"
    docker image prune -f >/dev/null 2>&1 || true
    docker builder prune -f >/dev/null 2>&1 || true
}

show_final_result() {
    local duration
    duration=$(($(date +%s) - START_TIME))
    log_info ""
    log_info "📊 流水线执行完成"
    echo "总耗时: ${duration} 秒"
    echo "综合报告: $(report_file)"

    if [[ "$PIPELINE_SUCCESS" == true ]]; then
        log_success "✨ 流水线执行成功"
        return
    fi

    log_warn "⚠️  流水线执行完成，但存在失败步骤"
}

main() {
    START_TIME=$(date +%s)
    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    init_pipeline

    if ! run_build_step; then
        PIPELINE_SUCCESS=false
    fi
    if ! run_test_step; then
        PIPELINE_SUCCESS=false
    fi
    if ! run_security_step; then
        PIPELINE_SUCCESS=false
    fi
    if ! run_performance_step; then
        PIPELINE_SUCCESS=false
    fi
    if ! run_optimization_step; then
        PIPELINE_SUCCESS=false
    fi

    generate_comprehensive_report
    cleanup
    show_final_result

    if [[ "$PIPELINE_SUCCESS" != true ]]; then
        exit 1
    fi
}

main "$@"
