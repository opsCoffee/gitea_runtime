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
REPORT_DIR="./security_reports"
SEVERITY_LEVELS="CRITICAL,HIGH,MEDIUM"
ONLY_RUNTIMES=""
GENERATE_BASELINE=false
COMPARE_BASELINE=false
DRY_RUN=false
TARGET_RUNTIMES=()
SCAN_TOOLS=(trivy grype docker-scout)

show_help() {
    cat <<EOF
用法: ./scripts/runtimectl.sh security [选项]

默认行为: 不指定 --only 时，扫描全部支持的 runtime

选项:
  -h, --help          显示此帮助信息
  -r, --registry      设置 Docker 注册表 (默认: $DEFAULT_REGISTRY)
  -d, --report-dir    设置报告输出目录 (默认: $REPORT_DIR)
  --tag TAG           指定镜像标签 (默认: $DEFAULT_TAG)
  --severity LEVELS   设置严重性级别 (默认: $SEVERITY_LEVELS)
  --tools TOOLS       指定扫描工具，支持 trivy,grype,docker-scout
  --only RUNTIMES     仅扫描指定 runtime，支持逗号分隔多个值
  --baseline          生成基线报告
  --compare           与基线报告比较
  --dry-run           仅输出计划，不实际执行扫描
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
            --severity)
                require_value "$1" "${2-}"
                SEVERITY_LEVELS="$2"
                shift 2
                ;;
            --tools)
                require_value "$1" "${2-}"
                IFS=',' read -r -a SCAN_TOOLS <<< "$2"
                shift 2
                ;;
            --only)
                require_value "$1" "${2-}"
                ONLY_RUNTIMES="$2"
                shift 2
                ;;
            --baseline)
                GENERATE_BASELINE=true
                shift
                ;;
            --compare)
                COMPARE_BASELINE=true
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

validate_scan_tools() {
    local tool

    for tool in "${SCAN_TOOLS[@]}"; do
        case "$tool" in
            trivy|grype|docker-scout)
                ;;
            *)
                error_exit "不支持的扫描工具: ${tool}"
                ;;
        esac
    done
}

check_scan_tools() {
    local tool
    local -a available_tools=()

    for tool in "${SCAN_TOOLS[@]}"; do
        case "$tool" in
            trivy)
                if command -v trivy >/dev/null 2>&1 || docker image inspect aquasec/trivy:latest >/dev/null 2>&1; then
                    available_tools+=("$tool")
                else
                    log_warn "⚠️  Trivy 不可用，将在需要时尝试使用 Docker 运行"
                    available_tools+=("$tool")
                fi
                ;;
            grype)
                if command -v grype >/dev/null 2>&1; then
                    available_tools+=("$tool")
                else
                    log_warn "⚠️  Grype 不可用，跳过"
                fi
                ;;
            docker-scout)
                if docker scout version >/dev/null 2>&1; then
                    available_tools+=("$tool")
                else
                    log_warn "⚠️  Docker Scout 不可用，跳过"
                fi
                ;;
        esac
    done

    SCAN_TOOLS=("${available_tools[@]}")
    if [[ ${#SCAN_TOOLS[@]} -eq 0 ]]; then
        error_exit "没有可用的扫描工具"
    fi
}

tool_report_prefix() {
    local tool="$1"
    case "$tool" in
        docker-scout) echo "scout" ;;
        *) echo "$tool" ;;
    esac
}

scan_with_trivy() {
    local image_ref="$1"
    local output_dir="$2"
    local runtime_name="$3"

    if command -v trivy >/dev/null 2>&1; then
        trivy image --format json --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-gitea-runtime-${runtime_name}.json" "$image_ref"
        trivy image --format table --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-gitea-runtime-${runtime_name}.txt" "$image_ref"
        trivy image --format sarif --severity "$SEVERITY_LEVELS" \
            --output "$output_dir/trivy-gitea-runtime-${runtime_name}.sarif" "$image_ref"
        return
    fi

    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$output_dir:/output" aquasec/trivy:latest \
        image --format json --severity "$SEVERITY_LEVELS" \
        --output "/output/trivy-gitea-runtime-${runtime_name}.json" "$image_ref"
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$output_dir:/output" aquasec/trivy:latest \
        image --format table --severity "$SEVERITY_LEVELS" \
        --output "/output/trivy-gitea-runtime-${runtime_name}.txt" "$image_ref"
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$output_dir:/output" aquasec/trivy:latest \
        image --format sarif --severity "$SEVERITY_LEVELS" \
        --output "/output/trivy-gitea-runtime-${runtime_name}.sarif" "$image_ref"
}

scan_with_grype() {
    local image_ref="$1"
    local output_dir="$2"
    local runtime_name="$3"

    grype "$image_ref" -o json > "$output_dir/grype-gitea-runtime-${runtime_name}.json"
    grype "$image_ref" -o table > "$output_dir/grype-gitea-runtime-${runtime_name}.txt"
}

scan_with_docker_scout() {
    local image_ref="$1"
    local output_dir="$2"
    local runtime_name="$3"

    docker scout cves --format json "$image_ref" > "$output_dir/scout-gitea-runtime-${runtime_name}.json"
    docker scout cves "$image_ref" > "$output_dir/scout-gitea-runtime-${runtime_name}.txt"
}

generate_image_summary() {
    local runtime_name="$1"
    local report_dir="$2"
    local image_ref="$3"
    local summary_file="$report_dir/summary.md"
    local tool

    report_reset "$summary_file" \
        "# ${runtime_name} 镜像安全扫描汇总" \
        "扫描时间: $(date)" \
        "镜像: ${image_ref}" \
        ""
    report_append_lines "$summary_file" \
        "## 漏洞统计" \
        "" \
        "| 扫描工具 | 严重 | 高危 | 中危 | 低危 | 总计 |" \
        "|----------|------|------|------|------|------|"

    for tool in "${SCAN_TOOLS[@]}"; do
        local json_file
        json_file="$report_dir/$(tool_report_prefix "$tool")-gitea-runtime-${runtime_name}.json"
        if [[ ! -f "$json_file" ]]; then
            continue
        fi

        case "$tool" in
            trivy)
                local critical
                local high
                local medium
                local low
                critical=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$json_file" 2>/dev/null || echo "0")
                high=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$json_file" 2>/dev/null || echo "0")
                medium=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$json_file" 2>/dev/null || echo "0")
                low=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' "$json_file" 2>/dev/null || echo "0")
                report_append_line "$summary_file" "| Trivy | $critical | $high | $medium | $low | $((critical + high + medium + low)) |"
                ;;
            grype)
                local critical
                local high
                local medium
                local low
                critical=$(jq -r '[.matches[] | select(.vulnerability.severity=="Critical")] | length' "$json_file" 2>/dev/null || echo "0")
                high=$(jq -r '[.matches[] | select(.vulnerability.severity=="High")] | length' "$json_file" 2>/dev/null || echo "0")
                medium=$(jq -r '[.matches[] | select(.vulnerability.severity=="Medium")] | length' "$json_file" 2>/dev/null || echo "0")
                low=$(jq -r '[.matches[] | select(.vulnerability.severity=="Low")] | length' "$json_file" 2>/dev/null || echo "0")
                report_append_line "$summary_file" "| Grype | $critical | $high | $medium | $low | $((critical + high + medium + low)) |"
                ;;
            docker-scout)
                report_append_line "$summary_file" "| Docker Scout | N/A | N/A | N/A | N/A | N/A |"
                ;;
        esac
    done

    report_append_blank "$summary_file"
    report_append_lines "$summary_file" \
        "## 修复建议" \
        "" \
        "1. **立即修复严重和高危漏洞**" \
        "2. **更新基础镜像到最新版本**" \
        "3. **移除不必要的包和依赖**" \
        "4. **定期重新扫描和更新**" \
        "" \
        "## 详细报告" \
        ""

    for tool in "${SCAN_TOOLS[@]}"; do
        local prefix
        prefix="$(tool_report_prefix "$tool")"
        if [[ -f "$report_dir/${prefix}-gitea-runtime-${runtime_name}.txt" ]]; then
            report_append_line "$summary_file" "- [$tool 文本报告](${prefix}-gitea-runtime-${runtime_name}.txt)"
        fi
        if [[ -f "$report_dir/${prefix}-gitea-runtime-${runtime_name}.json" ]]; then
            report_append_line "$summary_file" "- [$tool JSON 报告](${prefix}-gitea-runtime-${runtime_name}.json)"
        fi
    done
}

scan_runtime() {
    local runtime_name="$1"
    local image_ref
    local image_report_dir
    local tool

    image_ref="$(runtime_image_repo "$REGISTRY" "$runtime_name"):${TAG}"
    image_report_dir="$REPORT_DIR/$runtime_name"
    ensure_directory "$image_report_dir"

    log_info ""
    log_info "🔒 扫描镜像: ${image_ref}"

    if [[ "$DRY_RUN" == true ]]; then
        for tool in "${SCAN_TOOLS[@]}"; do
            log_info "[dry-run] 将使用 ${tool} 扫描 ${image_ref}"
        done
        return
    fi

    if ! docker image inspect "$image_ref" >/dev/null 2>&1; then
        log_warn "⚠️  镜像 ${image_ref} 不存在于本地，跳过扫描"
        return
    fi

    for tool in "${SCAN_TOOLS[@]}"; do
        case "$tool" in
            trivy)
                scan_with_trivy "$image_ref" "$image_report_dir" "$runtime_name"
                ;;
            grype)
                scan_with_grype "$image_ref" "$image_report_dir" "$runtime_name"
                ;;
            docker-scout)
                scan_with_docker_scout "$image_ref" "$image_report_dir" "$runtime_name"
                ;;
        esac
    done

    generate_image_summary "$runtime_name" "$image_report_dir" "$image_ref"
}

generate_baseline() {
    local baseline_file="$REPORT_DIR/baseline.json"
    local baseline_data
    local runtime_name

    baseline_data="{\"timestamp\":\"$(date -Iseconds)\",\"images\":{}}"
    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local trivy_json="$REPORT_DIR/$runtime_name/trivy-gitea-runtime-${runtime_name}.json"
        local vuln_count
        if [[ ! -f "$trivy_json" ]]; then
            continue
        fi

        vuln_count=$(jq -r '[.Results[]?.Vulnerabilities[]?] | length' "$trivy_json" 2>/dev/null || echo "0")
        baseline_data=$(echo "$baseline_data" | jq --arg runtime "$runtime_name" --arg count "$vuln_count" '.images[$runtime] = {"vulnerability_count": ($count | tonumber)}')
    done

    echo "$baseline_data" > "$baseline_file"
    log_success "✅ 基线报告已保存: $baseline_file"
}

compare_with_baseline() {
    local baseline_file="$REPORT_DIR/baseline.json"
    local comparison_file="$REPORT_DIR/comparison.md"
    local runtime_name

    if [[ ! -f "$baseline_file" ]]; then
        log_warn "⚠️  基线文件不存在，跳过比较"
        return
    fi

    report_reset "$comparison_file" \
        "# 安全扫描基线比较报告" \
        "比较时间: $(date)" \
        "" \
        "| 镜像 | 基线漏洞数 | 当前漏洞数 | 变化 | 趋势 |" \
        "|------|------------|------------|------|------|"

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local baseline_count
        local current_count=0
        local trivy_json="$REPORT_DIR/$runtime_name/trivy-gitea-runtime-${runtime_name}.json"
        local change
        local trend="→"

        baseline_count=$(jq -r ".images.${runtime_name}.vulnerability_count // 0" "$baseline_file" 2>/dev/null || echo "0")
        if [[ -f "$trivy_json" ]]; then
            current_count=$(jq -r '[.Results[]?.Vulnerabilities[]?] | length' "$trivy_json" 2>/dev/null || echo "0")
        fi

        change=$((current_count - baseline_count))
        if [[ $change -gt 0 ]]; then
            trend="↗ +$change"
        elif [[ $change -lt 0 ]]; then
            trend="↘ $change"
        fi

        report_append_line "$comparison_file" "| $runtime_name | $baseline_count | $current_count | $change | $trend |"
    done

    log_success "✅ 基线比较完成: $comparison_file"
}

generate_overall_summary() {
    local summary_file="$REPORT_DIR/security_summary.md"
    local runtime_name

    report_reset "$summary_file" \
        "# Docker 镜像安全扫描总体汇总" \
        "扫描时间: $(date)" \
        "使用的扫描工具: ${SCAN_TOOLS[*]}" \
        "严重性级别: $SEVERITY_LEVELS" \
        ""
    report_append_lines "$summary_file" \
        "## 镜像扫描状态" \
        "" \
        "| 镜像 | 状态 | 报告 |" \
        "|------|------|------|"

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        local runtime_summary="$REPORT_DIR/$runtime_name/summary.md"
        if [[ -f "$runtime_summary" ]]; then
            report_append_line "$summary_file" "| $(runtime_image_name "$runtime_name") | ✅ | [$runtime_name/summary.md]($runtime_name/summary.md) |"
        elif [[ "$DRY_RUN" == true ]]; then
            report_append_line "$summary_file" "| $(runtime_image_name "$runtime_name") | [dry-run] | N/A |"
        else
            report_append_line "$summary_file" "| $(runtime_image_name "$runtime_name") | ❌ | N/A |"
        fi
    done

    report_append_blank "$summary_file"
    report_append_lines "$summary_file" \
        "## 安全建议" \
        "" \
        "### 立即行动项" \
        "1. 修复所有严重(CRITICAL)级别漏洞" \
        "2. 修复高危(HIGH)级别漏洞" \
        "3. 更新基础镜像到最新稳定版本" \
        "" \
        "### 持续改进" \
        "1. 建立定期扫描计划" \
        "2. 集成安全扫描到 CI/CD 流程" \
        "3. 监控新漏洞披露" \
        "4. 实施最小权限原则" \
        ""

    log_success "✅ 总体汇总报告完成: $summary_file"
}

main() {
    local runtime_name

    parse_args "$@"
    validate_registry "$REGISTRY"
    validate_tag "$TAG"
    validate_scan_tools
    collect_runtimes
    ensure_directory "$REPORT_DIR"

    log_info "🚀 开始 Docker 镜像安全扫描"
    log_info "注册表: $REGISTRY"
    log_info "镜像标签: $TAG"
    log_info "报告目录: $REPORT_DIR"
    log_info "严重性级别: $SEVERITY_LEVELS"

    if [[ "$DRY_RUN" != true ]]; then
        require_command docker
        check_scan_tools
    fi

    for runtime_name in "${TARGET_RUNTIMES[@]}"; do
        scan_runtime "$runtime_name"
    done

    if [[ "$GENERATE_BASELINE" == true && "$DRY_RUN" != true ]]; then
        generate_baseline
    fi

    if [[ "$COMPARE_BASELINE" == true && "$DRY_RUN" != true ]]; then
        compare_with_baseline
    fi

    generate_overall_summary
    log_success "✨ 安全扫描完成"
}

main "$@"
