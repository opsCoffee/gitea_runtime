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
REPORT_DIR="./performance_reports"
BENCHMARK_ITERATIONS=3
ANALYZE_ONLY=false
DRY_RUN=false
ONLY_RUNTIMES=""
TARGET_RUNTIMES=()

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh performance [选项]

默认行为: 不指定 --only 时，分析全部支持的 runtime

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  -i, --iterations    设置基准测试迭代次数 (默认: $BENCHMARK_ITERATIONS)
  --only RUNTIMES     仅分析指定 runtime，支持逗号分隔多个值
  --analyze-only      仅分析现有镜像，不运行基准测试
  --dry-run           仅输出计划，不实际执行分析
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
            -i|--iterations)
                require_value "$1" "${2-}"
                BENCHMARK_ITERATIONS="$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --analyze-only)
                ANALYZE_ONLY=true
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

collect_runtimes() {
    resolve_target_runtimes "$ONLY_RUNTIMES"
    TARGET_RUNTIMES=("${PARSED_RUNTIMES[@]}")
}

image_ref() {
    local runtime_name="$1"
    echo "$(runtime_image_repo "$REGISTRY" "$runtime_name"):${TAG}"
}

setup_report_dir() {
    ensure_directory "$REPORT_DIR"
    log_info "📁 报告将保存到: $REPORT_DIR"
}

analyze_image_sizes() {
    local report_file="$REPORT_DIR/image_sizes.md"
    local runtime_name

    report_reset "$report_file" \
        "# Docker 镜像大小分析报告" \
        "生成时间: $(date)" \
        "" \
        "| 镜像名称 | 大小 | 压缩大小 | 层数 | 优化建议 |" \
        "|----------|------|----------|------|----------|"

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local ref
        ref="$(image_ref "$runtime_name")"
        if ! docker image inspect "$ref" >/dev/null 2>&1; then
            report_append_line "$report_file" "| $ref | N/A | N/A | N/A | 镜像不存在 |"
            continue
        fi

        local size
        local compressed_size
        local layers
        local suggestions="已优化"
        size=$(docker image inspect "$ref" --format '{{.Size}}' | numfmt --to=iec)
        compressed_size=$(docker image inspect "$ref" --format '{{.VirtualSize}}' | numfmt --to=iec)
        layers=$(docker image inspect "$ref" --format '{{len .RootFS.Layers}}')

        if [[ "$layers" -gt 10 ]]; then
            suggestions="减少层数"
        fi
        if [[ "$size" == *G* ]]; then
            suggestions="${suggestions},考虑多阶段构建"
        fi

        report_append_line "$report_file" "| $ref | $size | $compressed_size | $layers | $suggestions |"
    done
}

benchmark_startup_time() {
    local report_file="$REPORT_DIR/startup_benchmark.md"
    local runtime_name

    if [[ "$ANALYZE_ONLY" == true ]]; then
        return
    fi

    report_reset "$report_file" \
        "# Docker 镜像启动时间基准测试" \
        "生成时间: $(date)" \
        "测试迭代次数: $BENCHMARK_ITERATIONS" \
        "" \
        "| 镜像名称 | 平均启动时间(ms) | 最小时间(ms) | 最大时间(ms) | 标准差 |" \
        "|----------|------------------|--------------|--------------|--------|"

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local ref
        ref="$(image_ref "$runtime_name")"
        if ! docker image inspect "$ref" >/dev/null 2>&1; then
            report_append_line "$report_file" "| $ref | N/A | N/A | N/A | N/A |"
            continue
        fi

        local -a times=()
        while [[ ${#times[@]} -lt "$BENCHMARK_ITERATIONS" ]]; do
            local start_time
            local end_time
            start_time=$(date +%s%3N)
            docker run --rm "$ref" echo "test" >/dev/null 2>&1
            end_time=$(date +%s%3N)
            times+=($((end_time - start_time)))
        done

        local sum=0
        local min="${times[0]}"
        local max="${times[0]}"
        local time_value
        for time_value in "${times[@]}"; do
            sum=$((sum + time_value))
            if [[ "$time_value" -lt "$min" ]]; then min="$time_value"; fi
            if [[ "$time_value" -gt "$max" ]]; then max="$time_value"; fi
        done

        local avg=$((sum / BENCHMARK_ITERATIONS))
        local variance_sum=0
        for time_value in "${times[@]}"; do
            local diff=$((time_value - avg))
            variance_sum=$((variance_sum + diff * diff))
        done

        local std_dev
        std_dev=$(echo "scale=2; sqrt($variance_sum / $BENCHMARK_ITERATIONS)" | bc -l)
        report_append_line "$report_file" "| $ref | $avg | $min | $max | $std_dev |"
    done
}

analyze_image_layers() {
    local report_file="$REPORT_DIR/layer_analysis.md"
    local runtime_name

    report_reset "$report_file" "# Docker 镜像层级分析报告" "生成时间: $(date)" ""
    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local ref
        ref="$(image_ref "$runtime_name")"
        if ! docker image inspect "$ref" >/dev/null 2>&1; then
            continue
        fi

        report_append_lines "$report_file" "## $ref" "" "### 层级详情" '```'
        docker history "$ref" --no-trunc >> "$report_file"
        report_append_lines "$report_file" '```' "" "### 大文件分析" '```'
        if ! docker run --rm "$ref" find / -type f -size +10M 2>/dev/null | head -10 >> "$report_file"; then
            report_append_line "$report_file" "无法分析大文件"
        fi
        report_append_lines "$report_file" '```' ""
    done
}

runtime_specific_suggestions() {
    local runtime_name="$1"
    case "$runtime_name" in
        markdown)
            echo "- 优化 Node.js 模块安装"
            ;;
        asustor)
            echo "- 精简 Python 包安装"
            ;;
        template)
            echo "- 优化 Go 二进制文件大小"
            ;;
        latex)
            echo "- 进一步精简 TeX 发行版"
            ;;
        base)
            echo "- 复查默认 Node / npm 工具链是否过宽"
            ;;
        maven)
            echo "- 继续固定 Node/npm 侧版本以提升可重现性"
            ;;
        claudecode)
            echo "- 收紧构建期远程依赖并提升缓存命中率"
            ;;
    esac
}

generate_optimization_suggestions() {
    local report_file="$REPORT_DIR/optimization_suggestions.md"
    local runtime_name

    report_reset "$report_file" \
        "# Docker 镜像优化建议" \
        "生成时间: $(date)" \
        "" \
        "## 通用优化建议" \
        "" \
        "1. **减少镜像层数**" \
        "2. **优化基础镜像选择**" \
        "3. **安全性优化**" \
        "4. **构建效率优化**" \
        ""

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local ref
        ref="$(image_ref "$runtime_name")"
        if ! docker image inspect "$ref" >/dev/null 2>&1; then
            continue
        fi

        report_append_lines "$report_file" "## $ref 特定建议" ""
        report_append_line "$report_file" "$(runtime_specific_suggestions "$runtime_name")"
        report_append_blank "$report_file"
    done
}

generate_summary_report() {
    local summary_file="$REPORT_DIR/performance_summary.md"
    local report

    report_reset "$summary_file" "# Docker 镜像性能监控汇总报告" "生成时间: $(date)" ""
    report_append_lines "$summary_file" "## 报告文件列表" ""
    for report in "$REPORT_DIR"/*.md; do
        if [[ -f "$report" && "$(basename "$report")" != "performance_summary.md" ]]; then
            report_append_line "$summary_file" "- [$(basename "$report" .md)]($(basename "$report"))"
        fi
    done

    report_append_blank "$summary_file"
    report_append_lines "$summary_file" \
        "## 快速统计" \
        "" \
        "- 分析的镜像数量: ${#TARGET_RUNTIMES[@]}" \
        "- 报告生成时间: $(date)" \
        "- 基准测试迭代次数: $BENCHMARK_ITERATIONS" \
        ""
}

main() {
    local runtime_name

    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    validate_positive_integer "iterations" "$BENCHMARK_ITERATIONS"
    collect_runtimes
    setup_report_dir

    log_info "🚀 开始 Docker 镜像性能监控"
    log_info "注册表: $REGISTRY"
    log_info "镜像标签: $TAG"
    log_info "目标 runtime: ${TARGET_RUNTIMES[*]}"

    if [[ "$DRY_RUN" == true ]]; then
        for runtime_name in "${TARGET_RUNTIMES[@]}"; do
            log_info "[dry-run] 将分析 $(image_ref "$runtime_name")"
        done
        return
    fi

    require_command docker
    require_command numfmt
    if [[ "$ANALYZE_ONLY" != true ]]; then
        require_command bc
    fi
    analyze_image_sizes
    benchmark_startup_time
    analyze_image_layers
    generate_optimization_suggestions
    generate_summary_report
    log_success "✨ 性能监控完成"
}

main "$@"
